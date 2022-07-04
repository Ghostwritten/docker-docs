#  Docker Swarm 创建加密覆盖网络

## 1. 初始化 swarm
默认情况下，Docker作为一个隔离的单节点工作。所有容器仅部署在引擎上。Swarm Mode将它变成了一个多主机集群感知引擎。为了使用秘密功能，Docker必须处于“群模式”。这是通过

```bash
$ docker swarm init
Swarm initialized: current node (rcy8eo8ipksi2urvndo8i38te) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-5e7sg3ldmijd0sjz20h3382up1d0hbo7nibk465i325yup9jgf-8zhcijlpb1ufbhnzu4drcy7g3 172.17.0.71:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```
在第二台主机上执行下面的命令，将它作为一个worker添加到集群中。

```bash
$ token=$(ssh -o StrictHostKeyChecking=no 172.17.0.71 "docker swarm join-token -q worker") && docker swarm join 172.17.0.71:2377 --token $token
Warning: Permanently added '172.17.0.71' (ECDSA) to the list of known hosts.
token=$(ssh -o StrictHostKeyChecking=no 172.17.0.71 "docker swarm join-token -q worker") && docker swarm join 172.17.0.71:2377 --token $token
```
## 2. 创建未加密的覆盖网络
下面的命令将创建一个未加密的覆盖网络，其中部署了两个服务

运行该命令。这将用于演示嗅探未加密网络上的流量。

```bash
docker network create -d overlay app1-network
docker service create --name redis --network app1-network redis:alpine
docker service create \
  --network app1-network -p 80:3000 \
  --replicas 1 --name app1-web \
  katacoda/redis-node-docker-example
```

## 3. 监控网络
部署好服务后，可以使用TCPDump查看不同主机之间的流量。这将在Docker主机上安装TCPDump，并开始收集通过覆盖网络发送的流量

请等待业务部署完成
第一台机器

```bash
docker service ls
```

一旦部署完成，就可以通过向web应用发送HTTP请求来产生流量。这反过来又会给Redis创建网络请求

```bash
curl host01
```

第二台机器执行

```bash
$ ssh  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@host01
Warning: Permanently added 'host01,172.17.0.71' (ECDSA) to the list of known hosts.
yes | pacman -Sy tcpdump openssl
tcpdump -s 1500 -A -i ens3 port 4789
$ yes | pacman -Sy tcpdump openssl
The program 'pacman' is currently not installed. You can install it by typing:
apt install pacman
$ tcpdump -s 1500 -A -i ens3 port 4789
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on ens3, link-type EN10MB (Ethernet), capture size 1500 bytes
06:31:12.096732 IP 172.17.0.71.35083 > host02.4789: VXLAN, flags [I] (0x08), vni 4096
IP 10.0.0.2.39040 > 10.0.0.5.http: Flags [S], seq 1229698674, win 43690, options [mss 65495,sackOK,TS val 64177 ecr 0,nop,wscale 7], length 0
E..n....@.^F...G...J.....Z...........B
....B
.....E..<h1@.@...
...
......PIK.r...................
............
06:31:12.097375 IP host02.38034 > 172.17.0.71.4789: VXLAN, flags [I] (0x08), vni 4096
IP 10.0.0.5.http > 10.0.0.2.39040: Flags [S.], seq 354703990, ack 1229698675, win 27960, options [mss 1410,sackOK,TS val 62946 ecr 64177,nop,wscale 7], length 0
E..n....@.q....J...G.....Z...........B
....B
.....E..<..@.@.&.
...
....P...$ZvIK.s..m8.$.........
............
06:31:12.098458 IP 172.17.0.71.35083 > host02.4789: VXLAN, flags [I] (0x08), vni 4096
IP 10.0.0.2.39040 > 10.0.0.5.http: Flags [.], ack 1, win 342, options [nop,nop,TS val 64178 ecr 62946], length 0
E..f....@.^M...G...J.....R...........B
....B
.....E..4h2@.@...
...
......PIK.s.$Zw...Vh......
........
06:31:12.098656 IP 172.17.0.71.35083 > host02.4789: VXLAN, flags [I] (0x08), vni 4096
IP 10.0.0.2.39040 > 10.0.0.5.http: Flags [P.], seq 1:71, ack 1, win 342, options [nop,nop,TS val 64178 ecr 62946], length 70: HTTP: GET / HTTP/1.1
E.......@.^....G...J.................B
....B
.....E..zh3@.@..D
...
......PIK.s.$Zw...VD7.....
........GET / HTTP/1.1
Host: host01
User-Agent: curl/7.47.0
Accept: */*


06:31:12.098912 IP host02.38034 > 172.17.0.71.4789: VXLAN, flags [I] (0x08), vni 4096
IP 10.0.0.5.http > 10.0.0.2.39040: Flags [.], ack 71, win 219, options [nop,nop,TS val 62947 ecr 64178], length 0
E..f....@.q....J...G.....R...........B
....B
.....E..4Jb@.@..[
...
....P...$ZwIK......h......
........
```



当查看TCPDump流时，可以识别底层的Redis API调用来设置和获取数据。例如

```bash
RESP "hgetall" "ip"

RESP "::ffff:10.255.0.3" "8"
```

如果这是敏感信息，那么如果攻击者能够拦截网络流量，就可能会带来潜在的安全风险。
使用此命令删除服务和网络。下一步，我们将使用一个安全网络重新部署它们。

```bash
docker service rm redis app1-web && docker network rm app1-network
```

## 4. 创建加密覆盖网络
附加`--opt encrypted`选项使数据包在通过覆盖网络发送之前被加密，加密选项是在创建网络时定义的。

```bash
docker network create -d overlay --opt encrypted app1-network
```
加密对应用程序是透明的，允许它们以标准方式使用网络

使用下面的命令部署Redis服务和Web UI

```bash
docker service create --name redis --network app1-network redis:alpine
docker service create \
  --network app1-network -p 80:3000 \
  --replicas 1 --name app1-web \
  katacoda/redis-node-docker-example
```
现在，当流量生成时，你将无法拦截和监控进出Redis的流量，因为它现在是加密的。

```bash
$ curl host01
This page was generated after talking to redis.

Application Build: 1

Total requests: 1

IP count: 
    ::ffff:10.0.0.2: 1
$ curl host01
This page was generated after talking to redis.

Application Build: 1

Total requests: 2
```
然而，您仍然会看到返回给客户端的HTTP web响应。这是因为应用程序不使用HTTPS在客户端和服务器之间进行通信。添加HTTPS将为应用程序创建一个完整的端到端加密解决方案。

参考：

 - [Use overlay networks](https://docs.docker.com/network/overlay/)
 - [Docker Networking Security Basics](https://dockerlabs.collabnix.com/advanced/security/networking/)
 - [Docker swarm: overlay network encryption and MTLS](https://lovethepenguin.com/docker-swarm-overlay-network-encryption-and-mtls-5fba4ce3e266)
