#  docker swam 集群实现负载均衡


## 1. 初始化集群
第一个节点（manager）：
```bash
$ docker swarm init
Swarm initialized: current node (9qksq9kb8tt9i5un3y2eqbhlj) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-5b3w5w10px9ok0t39zs1nujng8x37rcapfkg885hmrokb5wvqi-9v45djurbjeajp3ln80zqcevu 172.17.0.6:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```
第二个节点（worker）：

```bash
$ docker swarm join 172.17.0.6:2377 --token $(ssh -o StrictHostKeyChecking=no 172.17.0.6 "docker swarm join-token -q worker")
Warning: Permanently added '172.17.0.6' (ECDSA) to the list of known hosts.
This node joined a swarm as a worker.
```
默认情况下，对服务的请求基于公共端口进行负载均衡。
##  2. 虚拟IP


下面的命令将创建一个名为`lbapp1`的新服务，其中运行两个容器。服务通过端口公开`81`

```bash
$ docker service create --name lbapp1 --replicas 2 -p 81:80 katacoda/docker-http-server
7w8k1esxuyx1gs17hwa4svop5
```
当向集群中端口81上的节点发出请求时，它会将负载分散到两个容器上。

```bash
$ curl host01:81
<h1>This request was processed by host: cbc4fa365043</h1>
$ curl host01:81
<h1>This request was processed by host: faecced3dc9f</h1>
```
HTTP响应指示哪个容器处理请求。在第二台主机上运行命令会得到相同的结果，它会跨这两台主机处理请求。

在下一步中，我们将探讨如何使用它来部署一个实际的应用程序。

## 3. 服务发现
Docker群模式包括一个路由网，它支持多主机网络。它允许两个不同主机上的容器通信，就像它们在同一主机上一样。它通过创建虚拟可扩展LAN (VXLAN)来实现这一点，VXLAN是为基于云的网络设计的。

路由以两种不同的方式工作。首先，基于公共端口暴露的服务。任何对端口的请求都将被分发。其次，该服务被赋予一个虚拟IP地址，该IP地址仅在Docker网络内部可路由。当向IP地址发出请求时，它们被分发到底层容器。这个虚拟IP是在Docker中的嵌入式DNS服务器上注册的。当基于服务名进行DNS解析时，返回`Virtual IP`。

在这个步骤中，你将创建一个负载均衡的http，它被附加到一个覆盖网络，并查找它是虚拟IP。

```bash
$ docker network create --attachable -d overlay eg1
cf4fx7p2a75irup0pjafylpd4
```
这个网络将是一个“群体范围网络”。这意味着只有作为服务启动的容器才能将自己附加到网络上。

```bash
$ docker service create --name http --network eg1 --replicas 2 katacoda/docker-http-server
```
通过调用服务http, Docker添加了一个条目到它是嵌入式DNS服务器。网络上的其他容器可以使用友好的名称来发现IP地址。与端口一起，这个IP地址可以在网络内部使用，以达到负载均衡。

使用Dig查找内部虚拟IP。通过使用`--attable`标志，Swarm服务之外的容器可以访问网络。


```bash
$ docker run --name=dig --network eg1 benhall/dig dig http
Unable to find image 'benhall/dig:latest' locally
latest: Pulling from benhall/dig
12b41071e6ce: Pull complete d23aaa6caac4: Pull complete a3ed95caeb02: Pull complete Digest: sha256:ed7d241f0faea3a015d13117824c04a433a79032619862e4e3741a31eb9e4272
Status: Downloaded newer image for benhall/dig:latest

; <<>> DiG 9.10.2 <<>> http
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 59560
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;http.                          IN      A

;; ANSWER SECTION:
http.                   600     IN      A       10.0.1.2

;; Query time: 1 msec
;; SERVER: 127.0.0.11#53(127.0.0.11)
;; WHEN: Thu Sep 30 07:59:23 UTC 2021
;; MSG SIZE  rcvd: 42

```
通过ping该名称还可以发现IP地址。

```bash
$ docker run --name=ping --network eg1 alpine ping -c5 http
PING http (10.0.1.2): 56 data bytes
64 bytes from 10.0.1.2: seq=0 ttl=64 time=0.287 ms
64 bytes from 10.0.1.2: seq=1 ttl=64 time=0.108 ms
64 bytes from 10.0.1.2: seq=2 ttl=64 time=0.160 ms
64 bytes from 10.0.1.2: seq=3 ttl=64 time=0.157 ms
64 bytes from 10.0.1.2: seq=4 ttl=64 time=0.131 ms

--- http ping statistics ---
5 packets transmitted, 5 packets received, 0% packet loss
round-trip min/avg/max = 0.108/0.168/0.287 ms
```
这应该与给服务的虚拟IP相匹配。您可以通过检查服务来发现这一点。

```bash
$ docker service inspect http --format="{{.Endpoint.VirtualIPs}}"
[{cf4fx7p2a75irup0pjafylpd4 10.0.1.2/24}]
```
每个容器仍然会被赋予一个唯一的IP地址。

```bash
$ docker inspect --format="{{.NetworkSettings.Networks.eg1.IPAddress}}" $(docker'{print $1}')cker-http-server | head -n1 | awk  
10.0.1.4
```
这个虚拟IP确保在集群中按照预期的方式进行负载平衡。而IP地址确保它在集群外工作。

## 4. 多主机LB和服务发现

虚拟IP和端口负载均衡和服务发现都可以用于多主机场景，应用程序可以在不同的主机上与不同的服务通信。

在这个步骤中，我们将部署一个复制的`Node.js`应用程序，它与`Redis`通信来存储数据。

首先，需要有一个覆盖网络，应用程序和数据存储可以连接。

```bash
$ docker network create -d overlay app1-network
```
部署Redis时，可以连接网络。应用程序希望能够连接到一个名为Redis的实例。为了使应用程序能够通过嵌入式DNS发现虚拟IP，我们调用服务Redis。

```bash
$ docker service create --name redis --network app1-network redis:alpine
```
每个主机都应该有一个Node.js容器实例，其中一个主机存储Redis。

```bash
$ docker ps
CONTAINER ID        IMAGE                                COMMAND                  CREATED             STATUS              PORTS               NAMES
06f131fda216        redis:alpine                         "docker-entrypoint.s…"   27 seconds ago      Up 25 seconds       6379/tcp            redis.1.mq95cigfa7etgefqs1pye9crv
1890d08df8cc        katacoda/docker-http-server:latest   "/app"                   7 minutes ago       Up 7 minutes        80/tcp              http.2.j5c4ari06egpy3zqw6b0n3iyl
```
调用HTTP服务器将在Redis中存储请求并返回结果。这是负载平衡，两个容器通过覆盖网络与Redis容器通信。

应用程序现在分布在多个主机上。


参考:

 - [Docker Swarm (cluster communication, service discovery, load balancing)](https://javamana.com/2021/07/20210727110105455F.html)
 - [The Definitive Guide to Docker Swarm](https://gabrieltanner.org/blog/docker-swarm/)
 - [How to get started with load balancing Docker Swarm mode](https://upcloud.com/resources/tutorials/load-balancing-docker-swarm-mode)
 - [Traefik and Docker Swarm: A Dynamic Duo for Cloud-Native Container Networking](https://traefik.io/blog/traefik-and-docker-swarm-a-dynamic-duo-for-cloud-native-container-networking/)
 - [HAProxy on Docker Swarm: Load Balancing and DNS Service Discovery](https://www.haproxy.com/blog/haproxy-on-docker-swarm-load-balancing-and-dns-service-discovery/)
