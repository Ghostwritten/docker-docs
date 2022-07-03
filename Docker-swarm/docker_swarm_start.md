#  Docker Swarm 快速入门

![在这里插入图片描述](https://img-blog.csdnimg.cn/bf38c9ff60d642be92bc6f2f613062a5.jpg?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_20,color_FFFFFF,t_70,g_se,x_16#pic_center)
<font color=	#40E0D0 size=4 face="楷体">"这是一个非常棒的docker swarm学习历程。我把一个国外的docker精简实践教学进行了简略的翻译，比起国内博客学习的总结性文章，它更注重让小白在实战背景下容易理解与感悟，激发萌新自我疏理总结实战演练下的小细节。"</font>

---
@[toc]

----
## 1. docker swarm爱之初体验
![在这里插入图片描述](https://img-blog.csdnimg.cn/7905104b66e04d94bd55f48ab22afcc2.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_19,color_FFFFFF,t_70,g_se,x_16)


将单主机Docker主机转换为多主机Docker swarm集群模式。默认情况下，Docker作为一个隔离的单节点工作。所有容器仅部署在引擎上。群模式将它变成了一个多主机集群感知引擎。

初始化群模式的第一个节点成为管理器。当新的节点加入集群时，它们可以在管理者或工人之间调整角色。您应该在生产环境中运行3-5个管理器，以确保高可用性。

Docker CLI内置了Swarm Mode

```bash
$ docker swarm --help

Usage:  docker swarm COMMAND

Manage Swarm

Commands:
  ca          Display and rotate the root CA
  init        Initialize a swarm
  join        Join a swarm as a node and/or manager
  join-token  Manage join tokens
  leave       Leave the swarm
  unlock      Unlock swarm
  unlock-key  Manage the unlock key
  update      Update the swarm

Run 'docker swarm COMMAND --help' for more information on a command.
```
### 20.1 初始化集群
最重要的是如何初始化群模式。初始化是通过init完成的。

```bash
$ docker swarm init
Swarm initialized: current node (d5oub8tip41v0iedsotw02k1r) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-04j3xv6fsp4h2sp2al7ast6hjcntgrztcf24e13ozxazsbuvpx-cln0834q5dzecdkeiorf84tip 172.17.0.14:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow
```

运行该命令后，Docker引擎知道如何与集群一起工作，并成为集群的管理器。初始化的结果是一个令牌，用于以安全的方式添加额外的节点。在扩展集群时，请确保此token 令牌的安全性和安全性。

在下一步中，我们将添加更多节点并在这些主机上部署容器。
### 20.2 加入新节点
启用集群模式后，可以添加额外的节点并在所有节点上发出命令。如果节点突然消失，例如，由于崩溃，在这些主机上运行的容器将自动重新调度到其他可用节点上。重新调度确保您不会损失容量，并提供高可用性。

在每个希望添加到集群的附加节点上，使用Docker CLI加入现有组。连接是通过将另一个主机指向集群的当前管理器来完成的。在本例中，是第一个主机。

Docker现在使用一个额外的端口2377来管理集群。应该阻止公共访问该端口，只允许受信任的用户和节点访问该端口。我们建议使用vpn或私有网络来确保访问安全。

第一个任务是获取向集群添加工作人员所需的令牌。出于演示的目的，我们将通过swarm join-token询问管理器这个令牌是什么。在生产中，此令牌应该安全地存储，并且只可由受信任的个人访问。
第二台机器执行：
```bash
$ token=$(ssh -o StrictHostKeyChecking=no 172.17.0.14 "docker swarm join-token -q worker") && echo $token
Warning: Permanently added '172.17.0.14' (ECDSA) to the list of known hosts.
SWMTKN-1-04j3xv6fsp4h2sp2al7ast6hjcntgrztcf24e13ozxazsbuvpx-cln0834q5dzecdkeiorf84tip
```
在第二个主机上，通过管理器请求访问加入集群。令牌作为附加参数提供。

```bash
$ docker swarm join 172.17.0.14:2377 --token $token
This node joined a swarm as a worker.
```
默认情况下，管理器将自动接受添加到集群的新节点。可以通过以下命令查看集群中的所有节点

```bash
$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
d5oub8tip41v0iedsotw02k1r *   host01              Ready               Active              Leader              19.03.13
```
### 20.3 创建overlay网络
群模式还引入了一种改进的网络模型。在以前的版本中，Docker需要使用外部键值存储，如Consul，以确保整个网络的一致性。对协商一致意见和KV的需求现在已被纳入Docker内部，不再依赖外部服务.

改进的网络方法遵循与前面相同的语法。覆盖网络用于不同主机上的容器之间通信。在背后，这是一个虚拟可扩展`LAN` (VXLAN)，设计用于大规模基于云的部署。

下面的命令将创建一个新的覆盖网络称为`skynet`。所有注册到这个网络的容器都可以彼此通信，而不管它们部署到哪个节点上。

```bash
$ docker network create -d overlay skynet
4a687dx7ym4qj8wddr0vn1k0r
```
### 20.4 部署服务service
默认情况下，Docker使用扩散复制模型来决定哪些容器应该在哪些主机上运行。扩展方法确保容器均匀地部署在集群中。这意味着，如果从集群中删除其中一个节点，实例将已经在其他节点上运行。删除节点上的工作负载将在其余可用节点上重新调度。

服务`service`的新概念用于跨集群运行容器。这是一个比容器更高级的概念。服务允许您定义应用程序应该如何大规模部署。通过更新服务，Docker以托管的方式更新所需的容器。

在本例中，我们将部署镜像 `katacoda/docker-http-server`。我们正在为一个名为`http`的服务定义一个友好的名称，并且它应该被附加到新创建的`skynet`网络。

为了确保复制和可用性，我们在集群中运行容器的两个副本实例。

最后，我们把这两个容器一起在port 80。向集群中的任何节点发送HTTP请求将由集群中的一个容器处理请求。接受请求的节点可能不是容器响应的节点。相反，Docker在所有可用的容器中对请求进行负载平衡。

```bash
$ docker service create --name http --network skynet --replicas 2 -p 80:80 katacoda/docker-http-server
rt3hun6j3rtuy33vn2vrn2zv7
overall progress: 2 out of 2 tasks 
1/2: running   [==================================================>] 
2/2: running   [==================================================>] 
verify: Service converged
```
通过CLI命令可以查看集群中运行的服务

```bash
$ docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE                                PORTS
rt3hun6j3rtu        http                replicated          2/2                 katacoda/docker-http-server:latest   *:80->80/tcp
```
当容器启动时，您将看到它们使用ps命令。您应该在每个主机上看到该容器的一个实例。
列出第一个主机上的容器

```bash
$ docker ps
CONTAINER ID        IMAGE                                COMMAND             CREATED             STATUS              PORTS               NAMES
8f732975d0a5        katacoda/docker-http-server:latest   "/app"              2 m
```
列出第二台主机上的容器

```bash
$ docker ps
CONTAINER ID        IMAGE                                COMMAND             CREATED             STATUS              PORTS               NAMES
7d5a1b2112cd        katacoda/docker-http-server:latest   "/app"              2 minutes ago       Up 2 minutes        80/tcp              http.2.vcxurhlb7j39mq4hmzz6nyagx
```
如果我们向公共端口发出HTTP请求，它将由两个容器处理

```bash
$ curl host01
<h1>This request was processed by host: 7d5a1b2112cd</h1>

$ curl host01
<h1>This request was processed by host: 8f732975d0a5</h1>
```
### 20.5 状态监测
服务概念允许您检查集群和运行中的应用程序的运行状况和状态。

您可以在集群中查看与某个服务关联的所有任务的列表。在本例中，每个任务都是一个容器

```bash
$ docker service ps http
ID                  NAME                IMAGE                                NODE                DESIRED STATE       CURRENT STATE           ERROR               PORTS
ey77icv0scbo        http.1              katacoda/docker-http-server:latest   host01              Running             Running 5 minutes ago                       
vcxurhlb7j39        http.2              katacoda/docker-http-server:latest   host02              Running             Running 5 minutes ago                      
```
您可以通过以下方式查看服务的详细信息和配置

```bash
$ docker service inspect --pretty http

ID:             rt3hun6j3rtuy33vn2vrn2zv7
Name:           http
Service Mode:   Replicated
 Replicas:      2
Placement:
UpdateConfig:
 Parallelism:   1
 On failure:    pause
 Monitoring Period: 5s
 Max failure ratio: 0
 Update order:      stop-first
RollbackConfig:
 Parallelism:   1
 On failure:    pause
 Monitoring Period: 5s
 Max failure ratio: 0
 Rollback order:    stop-first
ContainerSpec:
 Image:         katacoda/docker-http-server:latest@sha256:76dc8a47fd019f80f2a3163aba789faf55b41b2fb06397653610c754cb12d3ee
 Init:          false
Resources:
Networks: skynet 
Endpoint Mode:  vip
Ports:
 PublishedPort = 80
  Protocol = tcp
  TargetPort = 80
  PublishMode = ingress 
```
在每个节点上，您可以询问它当前正在运行哪些任务。Self是指管理节点Leader

通过节点ID可以查询单个主机

```bash
$ docker node ls -q | head -n1
d5oub8tip41v0iedsotw02k1r

$ docker node ps $(docker node ls -q | head -n1)
ID                  NAME                IMAGE                                NODE                DESIRED STATE       CURRENT STATE           ERROR               PORTS
ey77icv0scbo        http.1              katacoda/docker-http-server:latest   host01              Running             Running 7 minutes ago                       
```
在下一步中，我们将扩展服务以运行容器的更多实例。

### 20.6 弹缩服务service
服务允许我们扩展在集群中运行的任务实例的数量。由于它了解如何启动容器以及哪些容器正在运行，因此可以根据需要轻松地启动或删除容器。目前缩放是手动的。但是，API可以连接到`external system`，比如`metrics dashboard`。

目前，我们有两个运行的负载平衡容器，它们正在处理我们的请求

```bash
$ curl host01
<h1>This request was processed by host: 8f732975d0a5</h1>
$ curl host01
<h1>This request was processed by host: 7d5a1b2112cd</h1>
```
下面的命令将扩展我们的http服务，使其在五个容器中运行。

```bash
$ docker service scale http=5
http scaled to 5
overall progress: 5 out of 5 tasks 
1/5: running   [==================================================>] 
2/5: running   [==================================================>] 
3/5: running   [==================================================>] 
4/5: running   [==================================================>] 
5/5: running   [==================================================>] 
verify: Service converged 
```
负载均衡器将自动更新。

---
##  2. Overlay网络恋习
![在这里插入图片描述](https://img-blog.csdnimg.cn/c405b141e06d4e4dadc3315051be5f58.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_19,color_FFFFFF,t_70,g_se,x_16)


默认情况下，Docker作为一个隔离的单节点工作。所有容器仅部署在引擎上。群模式将它变成了一个多主机集群感知引擎。
初始化集群

```bash
$ docker swarm init
Swarm initialized: current node (korrjr24x2drfvlu78xi77lno) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-1hriikcsgzi577cl3xcu6s0x7kk3058by92vvbtdltjsz8mp9s-3j2cuvx64eqm0tmkmwru6tn9z 172.17.0.139:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

$ 
```
在第二台主机上执行下面的命令，将它作为一个worker添加到集群中。

```bash
$ token=$(ssh -o StrictHostKeyChecking=no 172.17.0.139 "docker swarm join-token -q worker") && docker swarm join 172.17.0.139:2377 --token $token
Warning: Permanently added '172.17.0.139' (ECDSA) to the list of known hosts.
This node joined a swarm as a worker.
```
Overlay Networks是通过Docker CLI创建的，类似于在主机之间创建桥接网络。当创建网络时，将使用一种覆盖驱动类型。当新的服务通过集群模式部署时，它们可以利用这个网络允许容器进行通信.

要创建`Overlay Network`，使用CLI并定义驱动程序。网络只能通过群管理器节点创建。网络名称为`app1-network`

```bash
$ docker network create -d overlay app1-network
vuq3m5hi0t0jkvo1djuhpeqsp

$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
vuq3m5hi0t0j        app1-network        overlay             swarm
f9000dd7435e        bridge              bridge              local
d17623c76ebf        docker_gwbridge     bridge              local
8b89e3388c32        host                host                local
kuugxuiaalh1        ingress             overlay             swarm
```

> 注意:你创建的overlay网络不会出现在工作节点上。manager节点处理网络创建和正在部署的服务。

```bash
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
1d52a41d7ffb        bridge              bridge              local
398c1bd88b1d        docker_gwbridge     bridge              local
8b89e3388c32        host                host                local
kuugxuiaalh1        ingress             overlay             swarm
b3dc159371bf        none                null                local
```
一旦创建了网络，就可以部署服务，并能够与网络上的其他容器通信。

下面将使用网络部署Redis服务。该服务的名称将是`redis`，可用于通过DNS发现。

```bash
$ docker service create --name redis --network app1-network redis:alpine
wdz1i71gu6c1ep54jjfja1ziu
```
下一步将在不同的节点上部署一个web应用程序，通过网络与Redis进行交互。

```bash
$ docker service create \
>     --network app1-network -p 80:3000 \
>     --replicas 1 --name app1-web \
>     katacoda/redis-node-docker-example
p8ktbxnju1cy9vopuaxwobe0q
```
对于双节点部署，每个容器将被部署到不同的主机上。

他们会利用覆盖网络和DNS发现进行通信。发送HTTP请求将在Redis中保持客户端的IP。

```bash
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
cb586ee1000f        redis:alpine        "docker-entrypoint.s…"   55 seconds ago      Up 52 seconds       6379/tcp            redis.1.ajuo5o3z4snh0shbjur9qhnsg
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

IP count: 
```
##  3. docker swam集群实现负载均衡与服务发现美
![在这里插入图片描述](https://img-blog.csdnimg.cn/81455e09f76f4621a3938aa6f5d156e2.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_19,color_FFFFFF,t_70,g_se,x_16)

### 3.1 初始化集群
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
###  3.2 虚拟IP


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

### 3.3 服务发现
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

###  3.4 多主机LB和服务发现

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

---
##  4. 跨swarm集群应用滚床单更新
![在这里插入图片描述](https://img-blog.csdnimg.cn/0485b0468aee405589a2343aed3507a3.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_19,color_FFFFFF,t_70,g_se,x_16)


服务可以动态更新，以控制各种设置和选项。在内部，Docker管理如何应用更新。对于某些命令，Docker将停止、删除和重新创建容器。对于管理连接和正常运行时间来说，让所有容器一次性停止是一个重要的考虑因素。

有各种各样的设置你可以控制，通过查看帮助

```bash
$ docker service update --help
```
要启动，需要部署HTTP服务。我们将使用它来更新/修改容器设置。

```bash
$ docker swarm init && docker service create --name http --replicas 2 -p 80:80 katacoda/docker-http-server:v1
Swarm initialized: current node (vemt8upto85rpq2c0iv26hfjb) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-3ql2gc1k1clslqhyce6ww09fshgvslde4fpkt5wabgc6gewkid-96vytrgsrua2qrgfujq8bdo08 172.17.0.40:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

2838c9f2d95l8qxzdin1zn7pa
overall progress: 2 out of 2 tasks 
1/2: running   [==================================================>] 
2/2: running   [==================================================>] 
verify: Service converged 
```

###  4.1 Update Limits
一旦启动，就可以更新各种属性。例如，向容器添加一个新的环境变量。

```bash
$ docker service update --env-add KEY=VALUE http
http
overall progress: 0 out of 2 tasks 
overall progress: 2 out of 2 tasks 
1/2: running   [==================================================>] 
2/2: running   [==================================================>] 
verify: Service converged 
```

或者，更新CPU和内存限制。

```bash
$ docker service update --limit-cpu 2 --limit-memory 512mb http
http
overall progress: 2 out of 2 tasks 
1/2: running   [==================================================>] 
2/2: running   [==================================================>] 
verify: Service converged 
```
一旦执行，当您检查服务时，结果将是可见的.

```bash
$ docker service inspect --pretty http

ID:             2838c9f2d95l8qxzdin1zn7pa
Name:           http
Service Mode:   Replicated
 Replicas:      2
UpdateStatus:
 State:         completed
 Started:       38 seconds ago
 Completed:     23 seconds ago
 Message:       update completed
Placement:
UpdateConfig:
 Parallelism:   1
 On failure:    pause
 Monitoring Period: 5s
 Max failure ratio: 0
 Update order:      stop-first
RollbackConfig:
 Parallelism:   1
 On failure:    pause
 Monitoring Period: 5s
 Max failure ratio: 0
 Rollback order:    stop-first
ContainerSpec:
 Image:         katacoda/docker-http-server:v1@sha256:4d7bfcb1e38912d286c5cda63aeddc850a4be16127094ffacbb7abfc6298c5fa
 Env:           KEY=VALUE 
Resources:
 Limits:
  CPU:          2
  Memory:       512MiB
Endpoint Mode:  vip
Ports:
 PublishedPort = 80
  Protocol = tcp
  TargetPort = 80
  PublishMode = ingress 
```
但是，在列出所有容器时，您将看到它们在每次更新时都被重新创建.

```bash
$ docker ps -a
CONTAINER ID        IMAGE                            COMMAND             CREATED              STATUS                          PORTS               NAMES
26e2064259ff        katacoda/docker-http-server:v1   "/app"              About a minute ago   Up About a minute               80/tcp              http.1.vsv080fuwlsgcqo16m0d3czz9
74c412f02426        katacoda/docker-http-server:v1   "/app"              About a minute ago   Up About a minute               80/tcp              http.2.z6sp9scii6kj4ponoz0wrmv05
deda0102a7e2        katacoda/docker-http-server:v1   "/app"              2 minutes ago        Exited (2) About a minute ago                       http.2.ugilx2q6zkkkw0pwo2f6ydrmi
9b9d3addcc2f        katacoda/docker-http-server:v1   "/app"              2 minutes ago        Exited (2) About a minute ago                       http.1.lvhnd9zywl7ioax9t5wi3y9c8
9806903d549f        katacoda/docker-http-server:v1   "/app"              2 minutes ago        Exited (2) 2 minutes ago                            http.1.9m8l4jz9cxicel0ff8w3sq8k7
cdcd87d9487d        katacoda/docker-http-server:v1   "/app"              2 minutes ago        Exited (2) 2 minutes ago                            http.2.ahrvwdkcd9kkkxp868ppx14v5
```

###  4.2 Update Replicas
并非所有更新都需要重新创建每个容器。例如，扩展副本的数量不会影响现有容器。`docker service scale`作为一种替代docker服务规模的方法，可以使用更新来定义应该运行多少个副本。下面将把副本从2更新为6。然后Docker将重新安排要部署的另外四个容器。

```bash
$ docker service update --replicas=6 http
http
overall progress: 6 out of 6 tasks 
1/6: running   [==================================================>] 
2/6: running   [==================================================>] 
3/6: running   [==================================================>] 
4/6: running   [==================================================>] 
5/6: running   [==================================================>] 
6/6: running   [==================================================>] 
verify: Service converged 
```
副本的数量在检查服务时是可见的

```bash
$ docker service inspect --pretty http

ID:             2838c9f2d95l8qxzdin1zn7pa
Name:           http
Service Mode:   Replicated
 Replicas:      6
```
### 4.3  Update Image

使用更新的最常见场景是通过更新的Docker Image发布应用程序的新版本。由于Docker Image是容器的属性，所以可以像前面的步骤一样对其进行更新。

下面的命令将使用Docker镜像的`v2`标记重新创建HTTP服务的实例。

```bash
$ docker service update --image katacoda/docker-http-server:v2 http
http
overall progress: 6 out of 6 tasks 
1/6: running   [==================================================>] 
2/6: running   [==================================================>] 
3/6: running   [==================================================>] 
4/6: running   [==================================================>] 
5/6: running   [==================================================>] 
6/6: running   [==================================================>] 
verify: Service converged 
```
如果你打开一个新的终端窗口，你会注意到Swarm正在执行滚动更新。

```bash
$ docker ps
CONTAINER ID        IMAGE                            COMMAND             CREATED              STATUS              PORTS               NAMES
35d342b07967        katacoda/docker-http-server:v2   "/app"              49 seconds ago       Up 44 seconds       80/tcp              http.5.bjdoq1c85l2q2hdv1xkx0q8tb
18da1f1606ef        katacoda/docker-http-server:v2   "/app"              54 seconds ago       Up 49 seconds       80/tcp              http.2.gx464snpuedj2dm0iq1rzgad6
725fdaafe45b        katacoda/docker-http-server:v2   "/app"              About a minute ago   Up 54 seconds       80/tcp              http.1.4n0ub4wo24zi8v7ptigbahtsz
5987cf3c84e8        katacoda/docker-http-server:v2   "/app"              About a minute ago   Up About a minute   80/tcp              http.3.rm9ehbhf8gaay83dkb44frd3o
7c68ffd7eb76        katacoda/docker-http-server:v2   "/app"              About a minute ago   Up About a minute   80/tcp              http.6.u9yzhw2reneuipj5na0vkwp8r
2c1b365d7601        katacoda/docker-http-server:v2   "/app"              About a minute ago   Up About a minute   80/tcp              http.4.i8r9ulpxfcldjorqucfryjtgl

```
通过使用多个副本进行滚动更新，应用程序永远不会宕机，并且可以执行零停机部署。

```bash
$ curl http://docker
<h1>New Release! Now v2! This request was processed by host: 35d342b07967</h1>
$ curl http://docker
<h1>New Release! Now v2! This request was processed by host: 18da1f1606ef</h1>
$ curl http://docker
<h1>New Release! Now v2! This request was processed by host: 725fdaafe45b</h1>
$ curl http://docker
<h1>New Release! Now v2! This request was processed by host: 5987cf3c84e8</h1>
$ curl http://docker
<h1>New Release! Now v2! This request was processed by host: 7c68ffd7eb76</h1>
$ curl http://docker
<h1>New Release! Now v2! This request was processed by host: 2c1b365d7601</h1>
$ curl http://docker
<h1>New Release! Now v2! This request was processed by host: 35d342b07967</h1>
$ 
```
下一步将讨论如何控制推出和零停机部署。

### 4.4 滚动更新
其目的是部署一个新的Docker镜像而不引起任何停机时间。通过设置并行性和延迟，可以实现零停机时间。Docker可以批处理更新，并将其作为跨集群的`rollout`执行。

 - `update-parallelism`：定义了Docker一次应该更新多少个容器。副本的数量取决于您将对请求进行批量处理的大小。
 - `update-delay`：定义在每个更新批之间等待多长时间。如果应用程序有预热时间(例如启动JVM或CLR)，那么延迟是有用的。通过指定延迟，可以确保在流程启动时仍然可以处理请求。

这两个参数在运行docker服务更新时应用。在这个例子中，它一次更新一个容器，在每次更新之间等待10秒。该更新将影响所使用的Docker映像，但参数可以应用于任何可能的更新值

```bash
$  docker service update --update-delay=10s --update-parallelism=1 --image katacoda/docker-http-server:v3 http
```
启动之后，您会慢慢地看到容器的新v3版本启动并替换现有的v2版本。

```bash
$ docker ps
CONTAINER ID        IMAGE                            COMMAND             CREATED             STATUS              PORTS               NAMES
bf72245972b2        katacoda/docker-http-server:v3   "/app"              8 seconds ago       Up 2 seconds        80/tcp              http.5.nk6451tjyjof7bmhrbz8mwa8t
db63c2989df4        katacoda/docker-http-server:v3   "/app"              24 seconds ago      Up 18 seconds       80/tcp              http.2.ymml1p2qcyndx7wdpzt4fgnmd
b5e45490f79b        katacoda/docker-http-server:v3   "/app"              39 seconds ago      Up 34 seconds       80/tcp              http.1.l6la8w8cqu87ndenxico2fx4q
5987cf3c84e8        katacoda/docker-http-server:v2   "/app"              7 minutes ago       Up 6 minutes        80/tcp              http.3.rm9ehbhf8gaay83dkb44frd3o
7c68ffd7eb76        katacoda/docker-http-server:v2   "/app"              7 minutes ago       Up 7 minutes        80/tcp              http.6.u9yzhw2reneuipj5na0vkwp8r
2c1b365d7601        katacoda/docker-http-server:v2   "/app"              7 minutes ago       Up 7 minutes        80/tcp              http.4.i8r9ulpxfcldjorqucfryjtgl
```
向负载均衡器发出HTTP请求将请求v2和v3容器处理它们，从而产生不同的输出。

```bash
$ curl http://docker
<h1>New Release! Now v2! This request was processed by host: 5987cf3c84e8</h1>
$ curl http://docker
<h1>New Another Release! Now v3! This request was processed by host: 8349dd465a7e</h1>
$ curl http://docker
<h1>New Another Release! Now v3! This request was processed by host: 09860150d9b1</h1>
$ curl http://docker
<h1>New Another Release! Now v3! This request was processed by host: bf72245972b2</h1>
$ curl http://docker
<h1>New Another Release! Now v3! This request was processed by host: db63c2989df4</h1>
$ curl http://docker
<h1>New Another Release! Now v3! This request was processed by host: b5e45490f79b</h1>
```
应用程序必须考虑到这一点，并同时处理两个不同的版本。

---

## 5. 容器运行状况

###  5.1 容器添加健康检查
新的`Healthcheck`功能是作为`Dockerfile`的扩展创建的，并在构建Docker映像时定义。

下面的Dockerfile扩展了现有的HTTP服务并添加了健康检查。

`healthcheck`将每秒钟对HTTP服务器进行curl操作以确保其正常运行。如果服务器以非200请求响应，curl将失败，并返回退出码1。在三次失败后，Docker将标记容器为不健康。
说明格式为`HEALTHCHECK [OPTIONS] CMD`命令。

```bash
$ vim Dockerfile
FROM katacoda/docker-http-server:health
HEALTHCHECK --timeout=1s --interval=1s --retries=3 \
  CMD curl -s --fail http://localhost:80/ || exit 1
```
目前，Healthcheck支持三种不同的选项:

 - `interval=DURATION (default: 30s)`.这是执行健康检查之间的时间间隔。
 - `timeout=DURATION (default: 30s)` 如果检查在超时前没有完成，则认为它失败了。
 - `retries=N (default: 3)` 在将容器标记为不健康之前需要重新检查多少次。

执行的命令必须作为容器部署的一部分安装。在幕后，Docker将使用`Docker exec`来执行该命令。

在继续之前，构建并运行HTTP服务。

```bash
$ docker build -t http .
Sending build context to Docker daemon  2.048kB
Step 1/2 : FROM katacoda/docker-http-server:health
health: Pulling from katacoda/docker-http-server
12b41071e6ce: Pull complete 
fb1cef6edba2: Pull complete 
1061ea2815dd: Pull complete 
Digest: sha256:fee2132b14b4148ded82aacd8f06bdcb9efa535b4dfd2f1d88518996f4b2fb1d
Status: Downloaded newer image for katacoda/docker-http-server:health
 ---> 7f16ea0c8bd8
Step 2/2 : HEALTHCHECK --timeout=1s --interval=1s --retries=3   CMD curl -s --fail http://localhost:80/ || exit 1
 ---> Running in fcfcf750b855
Removing intermediate container fcfcf750b855
 ---> 333a8ac14b75
Successfully built 333a8ac14b75
Successfully tagged http:latest
```

```bash
$ docker run -d -p 80:80 --name srv http
6702ab36060fc2efb112081ab0ebf96f8a14f1139417fac7dc0dad04e6d33b86
```
在接下来的步骤中，我们将导致HTTP服务器开始抛出错误。当HTTP服务器作为容器运行时，Docker守护进程将根据选项自动检查健康检查。例如，当您列出所有正在运行的容器时，它将返回状态.

```bash
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED              STATUS                        PORTS                NAMES
6702ab36060f        http                "/app"              About a minute ago   Up About a minute (healthy)   0.0.0.0:80->80/tcp   srv
```
HTTP服务器有一个特殊的端点，它将导致它开始报告错误。
### 5.2 崩溃命令
```bash
$ curl http://docker/unhealthy
```
服务现在将进入错误模式。在下一步中，我们将看看Docker是如何处理这个问题的。
由于HTTP服务器处于错误状态，健康检查应该失败。Docker会将此报告为元数据的一部分。

### 5.3 验证状态
Docker会报告不同地方的健康状况。要获取原始文本流(在自动化过程中非常有用)，请使用`Docker Inspect`提取健康状态字段。

```bash
$ docker inspect --format "{{json .State.Health.Status }}" srv
"unhealthy"
```

运行状况状态存储所有失败和命令的任何输出的日志。这对于调试为什么认为容器不健康非常有用。

```bash
$ docker inspect --format "{{json .State.Health }}" srv
{"Status":"unhealthy","FailingStreak":75,"Log":[{"Start":"2021-10-11T02:19:07.166147032Z","End":"2021-10-11T02:19:07.233788055Z","ExitCode":1,"Output":""},{"Start":"2021-10-11T02:19:08.253738183Z","End":"2021-10-11T02:19:08.333500914Z","ExitCode":1,"Output":""},{"Start":"2021-10-11T02:19:09.354272859Z","End":"2021-10-11T02:19:09.436257557Z","ExitCode":1,"Output":""},{"Start":"2021-10-11T02:19:10.508515556Z","End":"2021-10-11T02:19:10.571064095Z","ExitCode":1,"Output":""},{"Start":"2021-10-11T02:19:11.590597522Z","End":"2021-10-11T02:19:11.663932528Z","ExitCode":1,"Output":""}]}
```

```bash
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                     PORTS                NAMES
6702ab36060f        http                "/app"              3 minutes ago       Up 3 minutes (unhealthy)   0.0.0.0:80->80/tcp   srv
```
### 5.4 状态修复
```bash
$ curl http://docker/healthy


$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                   PORTS                NAMES
6702ab36060f        http                "/app"              5 minutes ago       Up 5 minutes (healthy)   0.0.0.0:80->80/tcp   srv

$ docker inspect --format "{{json .State.Health.Status }}" srv
"healthy"
```
###  5.5 swarm运用Healthchecks
Docker Swarm可以使用这些运行状况检查来了解何时需要重新启动/重新创建服务。

初始化一个Swarm集群，并将新创建的映像部署为具有两个副本的服务。

```bash
docker rm -f $(docker ps -qa); 
docker swarm init
docker service create --name http --replicas 2 -p 80:80 http
```
您应该看到两个容器在响应

```bash
$ curl host01
<h1>A healthy request was processed by host: f3da8c49a948</h1>
```
随机导致其中一个节点不正常,

```bash
$ curl host01/unhealthy
```
您应该只看到一个节点处理请求，因为Swarm已经自动从负载均衡器中删除了它

```bash
$ curl host01
<h1>A healthy request was processed by host: 01c394673bc0</h1>
$ curl host01
<h1>A healthy request was processed by host: 01c394673bc0</h1>
$ curl host01
<h1>A healthy request was processed by host: 01c394673bc0</h1>
```
群集现在将自动重启不健康的服务

```bash
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED              STATUS                        PORTS               NAMES
c2ba9356b47e        http:latest         "/app"              36 seconds ago       Up 30 seconds (healthy)       80/tcp              http.2.kg7bky9gy65r77ym7dkoxke84
01c394673bc0        http:latest         "/app"              About a minute ago   Up About a minute (healthy)   80/tcp              http.1.jit13g50cohbsv3qa1ht3o9h1
```
在Swarm重启服务后，你应该再次看到两个节点

```bash
$ curl host01
<h1>A healthy request was processed by host: c2ba9356b47e</h1>
$ curl host01
<h1>A healthy request was processed by host: 01c394673bc0</h1>
```

## 6. docker-compose v3部署docker swarm
###  6.1 初始化swarm
默认情况下，Docker作为一个隔离的单节点工作。所有容器仅部署在引擎上。群模式将它变成了一个多主机集群感知引擎。

为了使用秘密功能，Docker必须处于“群模式”。这是通过

```bash
$ docker swarm init
Swarm initialized: current node (ean4r3wx8dutbj2hlkp4lsfu0) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-2t5z3yzsmq4xlhilsuh04ltiprnqt1h1cv8gmmaq6eip3day99-advgpojck21b1hlh3v6vgpncq 172.17.0.86:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```
在第二台主机上执行下面的命令，将它作为一个worker添加到集群中。

```bash
$ token=$(ssh -o StrictHostKeyChecking=no 172.17.0.86 "docker swarm join-token -q worker") && docker swarm join 172.17.0.86:2377 --token $token
Warning: Permanently added '172.17.0.86' (ECDSA) to the list of known hosts.
This node joined a swarm as a worker.
```
### 6.2  创建Docker Compose文件
使用`Docker Compose v3`，可以定义一个Docker部署以及生产细节。这为管理可以部署到集群模式集群中的应用程序部署提供了一个中央位置。

一个Docker Compose文件已经创建，它定义了使用web前端部署Redis服务器。使用以下命令查看文件.

```bash
$ cat docker-compose.yml
version: "3"
services:
  redis:
    image: redis:alpine
    volumes:
      - db-data:/data
    networks:
      appnet1:
        aliases:
          - db
    deploy:
      placement:
        constraints: [node.role == manager]

  web:
    image: katacoda/redis-node-docker-example
    networks:
      - appnet1
    depends_on:
      - redis
    deploy:
      mode: replicated
      replicas: 2
      labels: [APP=WEB]
      resources:
        limits:
          cpus: '0.25'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: continue
        monitor: 60s
        max_failure_ratio: 0.3
      placement:
        constraints: [node.role == worker]

networks:
    appnet1:
```
该文件已扩展到利用群集部署选项。

第一个配置选项使用`depends_on`。这意味着Redis必须在网络之前部署，并允许我们控制服务启动的顺序。

下一个配置选项定义应该如何使用新的部署选项部署应用程序。

首先，`mode: replicated`和`replicas: 2`决定服务应该启动多少个replicas。
其次，定义资源。限制是应用程序不能超过的硬限制，预留是Docker Swarm指示应用程序需要的资源的指南。

第三，`restart_policy`指出进程崩溃时应该如何操作。

第四，`update_config`定义如何应用和推出更新。

最后，位置允许我们添加约束，以确定服务应该部署在哪里。
[更多docker-compose file文件配置细节请参考](https://docs.docker.com/compose/compose-file/#deploy)

###  6.3 部署服务
Docker Compose文件被称为`Docker Compose Stack`。堆叠可以通过CLI部署到Swarm。
`docker stack`命令用于通过Swarm部署`docker Compose stack`。在本例中，它将以myapp作为服务的前缀。

```bash
$ docker stack deploy --compose-file docker-compose.yml myapp
Creating network myapp_appnet1
```
一旦部署完毕，就可以使用CLI检查状态。

```bash
$ docker stack ls
NAME                SERVICES            ORCHESTRATOR
myapp               2                   Swarm
```
可以通过以下方式发现内部服务的详细信息

```bash
$ docker stack services myapp
ID                  NAME                MODE                REPLICAS            IMAGE                                       PORTS
l8c8oztncboc        myapp_web           replicated          2/2                 katacoda/redis-node-docker-example:latest   
```
注意，该命令指示服务的`Desired / Running`状态。如果不能部署服务，那么这将是不同的。
每个服务容器的详细信息可以使用

```bash
$ docker stack ps myapp
ID                  NAME                IMAGE                                       NODE                DESIRED STATE       CURRENT STATE           ERROR               PORTS
x90dytk7svj7        myapp_web.1         katacoda/redis-node-docker-example:latest   host02              Running             Running 3 minutes ago                       
92a3t08318ne        myapp_redis.1       redis:alpine                                host01              Running             Running 3 minutes ago                       
ikmrz4pufzyd        myapp_web.2         katacoda/redis-node-docker-example:latest   host02              Running             Running 3 minutes ago                       
```
所有这些信息仍然可以被发现使用

```bash
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
21bbc04a9e8d        redis:alpine        "docker-entrypoint.s…"   3 minutes ago       Up 3 minutes        6379/tcp            myapp_redis.1.92a3t08318neq5g5sd1akrwzo
```
----

##  7. docker swarm使用secrets
###  7.1 初始化swarm
默认情况下，Docker作为一个隔离的单节点工作。所有容器仅部署在引擎上。群模式将它变成了一个多主机集群感知引擎。为了使用秘密功能，Docker必须处于“群模式”。这是通过

```bash
$ docker swarm init
Swarm initialized: current node (o6ngy0xskvvhxaaiyfye21znh) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-4oa8jjlavmoihusp73vgu71mhjek6ut1qkapzqnhtxdq5xzv0t-04anuyasgyv0p4xiqn4ga16fe 172.17.0.9:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```
### 7.2 创建secrets
下面的命令将首先创建一个随机的64个字符的令牌，该令牌将存储在一个文件中以供测试之用。令牌文件用于创建名为`deep_thought_answer_secure`的秘密文件

```bash
$ < /dev/urandom tr -dc A-Za-z0-9 | head -c64 > tokenfile
$ docker secret create deep_thought_answer_secure tokenfile
5yk3llezwli4atuua81dw6hg5
```

例如，还可以使用stdin创建秘密

```bash
$ echo "the_answer_is_42" | docker secret create lesssecure -
sxzk4itvh9dwvcenfz037uwab
```
注意，这种方法将在用户bash历史文件中保留`the_answer_is_42`的值。
所有的秘密名称都可以使用

```bash
$ docker secret ls
ID                          NAME                         DRIVER              CREATED              UPDATED
5yk3llezwli4atuua81dw6hg5   deep_thought_answer_secure                       About a minute ago   About a minute ago
sxzk4itvh9dwvcenfz037uwab   lesssecure                                       53 seconds ago       53 seconds ago
```
这将不会暴露底层的secrets的values，这个秘密可以在通过Swarm部署服务时使用。例如，deploy让Redis服务可以访问这个秘密。

```bash
$ docker service create --name="redis" --secret="deep_thought_answer_secure" redis
llfxs9rk9e88n7jh99q971uwb
overall progress: 1 out of 1 tasks 
1/1: running   [==================================================>] 
verify: Service converged 
```
secret作为一个文件出现在secrets目录中。

```bash
$ docker exec $(docker ps --filter name=redis -q) ls -l /run/secrets
ls: cannot access '/run/secrets': Operation not permitted
```
这可以作为一个普通文件从磁盘读取。

```bash
$ docker exec $(docker ps --filter name=redis -q) cat /run/secrets/deep_thought_answer_secure
SbrptUbQhcF7oWdfhmlSn70XCDvCNH2REuYSRv55tgUPEjPjKvB1zeLDTZTTcAxf$ 
```

###  7.3 用Compose创建Docker stack
使用`Docker Compose Stacks`也可以使用`secrets`功能。在下面的例子中，观众服务可以访问我们的`Swarm Secret _deep_thoughtanswer`。它被安装并被称为`deep_thoughtanswer`

```bash
version: '3.1'
services:
    viewer:
        image: 'alpine'
        command: 'cat /run/secrets/deep_thought_answer_secure'
        secrets:
            - deep_thought_answer_secure

secrets:
    deep_thought_answer_secure:
        external: true
```
###  7.4 部署访问secrets

Docker Compose Stack的部署使用Docker CLI。作为部署的一部分，堆栈将配置为对秘密的访问。使用以下命令部署任务:

```bash
docker stack deploy -c docker-compose.yml secrets1
docker logs $(docker ps -aqn1 -f status=exited)
```
如果命令错误与“docker日志”需要精确的1个参数。这意味着容器还没有启动并返回秘密。

###  7.5 File Based Secret
另一种创建秘密的方法是通过文件。既然如此，我们有个秘密。需要从容器中访问的CRT文件。

```bash
echo "my-super-secure-cert" > secret.crt
```
更新`docker-compose Stack`以使用基于机密的文件

```bash
version: '3.1'
services:
    test:
        image: 'alpine'
        command: 'cat /run/secrets/secretcert'
        secrets:
            - secretcert

secrets:
    secretcert:
        file: ./secret.crt
```
###  7.6 使用Compose部署和访问secrets
和前面一样，部署`Docker Compose stack`

```bash
docker stack deploy -c docker-compose.yml secrets2
```
下面的命令将获取为新创建的服务退出的最后一个容器的日志文件

```bash
docker logs $(docker ps -aqn1 -f name=secrets2 -f status=exited)
```

---

##  8. 创建加密覆盖网络
### 8.1 初始化swarm
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
###  8.2 创建未加密的覆盖网络
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

### 8.3 监控网络
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

###  8.4 创建加密覆盖网络
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

##  9. 设置节点进入维护模式
### 9.1 创建集群
第一台执行：
```bash
$ docker swarm init
Swarm initialized: current node (qgowushrnwa87hul908vicsph) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-5kk5jzz8rnjh0wctnsdm19yuvnvayw6eik9k3udyg4pupkklbx-0opd5tey2uxdplbzibg9uw104 172.17.0.14:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```
在第二台主机上执行下面的命令，将它作为一个worker添加到集群中。

```bash
token=$(ssh -o StrictHostKeyChecking=no 172.17.0.14 "docker swarm join-token -q worker") && docker swarm join 172.17.0.14:2377 --token $token
```
###  9.2 部署服务
首先在两个集群模式节点上部署一个带有两个副本的HTTP服务器。部署将导致在每个节点上部署一个容器。

```bash
$ docker service create --name lbapp1 --replicas 2 -p 80:80 katacoda/docker-http-server

$ docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE                                PORTS
ud5scjjdmsu2        lbapp1              replicated          2/2                 katacoda/docker-http-server:latest   *:80->80/tcp
$ docker ps
CONTAINER ID        IMAGE                                COMMAND             CREATED             STATUS              PORTS               NAMES
d584747866f1        katacoda/docker-http-server:latest   "/app"              45 
```

###  9.3 开启维护模式
当需要维护时，正确管理流程以确保可靠性是很重要的。第一个操作是从负载平衡器中删除节点，并让所有活动会话都完成。这将确保没有请求被发送到主机。其次，需要重新部署系统上的工作负载，以确保容量得到维护。

Docker Swarm将在设置节点的可用性时为你管理这一点,设置可用性需要知道集群模式的IP。


```bash
$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
qgowushrnwa87hul908vicsph *   host01              Ready               Active              Leader              19.03.13
ksjozt8473y0vwpvsg2uxxyue     host02              Ready               Active                                  19.03.13


$ worker=$(docker node ls | grep -v "Leader" | awk '{print $1}' | tail -n1); echo $worker
ksjozt8473y0vwpvsg2uxxyue
```
通过更新节点来设置可用性

```bash
$ docker node update $worker --availability=drain
ksjozt8473y0vwpvsg2uxxyue
```
容器现在应该都运行在单个管理器节点上。

```bash
$ docker ps
CONTAINER ID        IMAGE                                COMMAND             CREATED             STATUS              PORTS               NAMES
342a28429e8c        katacoda/docker-http-server:latest   "/app"              33 seconds ago      Up 27 seconds       80/tcp              lbapp1.2.c1rpw4q1lnohsdi12eclvzn9f
d584747866f1        katacoda/docker-http-server:latest   "/app"              7 minutes ago       Up 7 minutes        80/tcp              lbapp1.1.qevzgg0osytfsp0l6jfqryrq1
```
当查看所有节点时，可用性将发生变化

```bash
$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
qgowushrnwa87hul908vicsph *   host01              Ready               Active              Leader              19.03.13
ksjozt8473y0vwpvsg2uxxyue     host02              Ready               Drain                                   19.03.13
```
###  9.4 关闭维护模式
一旦完成了工作，节点应该可以用于未来的工作负载。这是通过设置可用性为活动。

```bash
$ docker node update $worker --availability=active
ksjozt8473y0vwpvsg2uxxyue
```
现在可用性又变回来了

```bash
$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
qgowushrnwa87hul908vicsph *   host01              Ready               Active              Leader              19.03.13
ksjozt8473y0vwpvsg2uxxyue     host02              Ready               Active                                  19.03.13
```
值得注意的是，Docker不会重新安排现有的工作负载。查看这些容器，您将看到它们仍然运行在单个主机上。

```bash
$ docker ps
CONTAINER ID        IMAGE                                COMMAND             CREATED             STATUS              PORTS               NAMES
342a28429e8c        katacoda/docker-http-server:latest   "/app"              2 minutes ago       Up 2 minutes        80/tcp              lbapp1.2.c1rpw4q1lnohsdi12eclvzn9f
d584747866f1        katacoda/docker-http-server:latest   "/app"              10 minutes ago      Up 9 minutes        80/tcp              lbapp1.1.qevzgg0osytfsp0l6jfqryrq1
```
相反，Swarm只会将新的工作负载安排到新可用的主机上。这可以通过扩展所需的副本数量进行测试。

```bash
$ docker service scale lbapp1=3
lbapp1 scaled to 3
overall progress: 3 out of 3 tasks 
1/3: running   [==================================================>] 
2/3: running   [==================================================>] 
3/3: running   [==================================================>] 
verify: Service converged 
```
新容器将被调度到第二个节点。

---

##  10. 部署UI界面Portainer到Docker集群
### 10.1 创建集群
第一台机器：

```bash
docker swarm init
```

第二台机器：

```bash
token=$(ssh -o StrictHostKeyChecking=no 172.17.0.46 "docker swarm join-token -q worker") && echo $token
docker swarm join 172.17.0.46:2377 --token $token
```
第一台机器：

```bash
docker node ls
```

###  10.2 Deploy Portainer
配置了集群后，下一阶段是部署Portainer。Portainer作为运行在Docker集群或Docker主机上的容器部署。
要完成这个场景，需要将Portainer部署为Docker服务。通过部署Docker服务，Swarm将确保该服务始终在管理器上运行，即使主机宕机。

该服务对外公开`9000`端口，并将内部Portainer数据保存在“`/host/data`”目录下。当Portainer启动时，它使用docker进行连接。`sock`文件到`Docker Swarm manager`。

还有一个附加的约束，即容器只能在管理器节点上运行
第一台执行：
```bash
docker service create \
    --name portainer \
    --publish 9000:9000 \
    --constraint 'node.role == manager' \
    --mount type=bind,src=/host/data,dst=/data \
     --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    portainer/portainer \
    -H unix:///var/run/docker.sock
```
另一种运行Portainer的方法是直接在主机上运行。在本例中，该命令在端口9000上暴露Portainer仪表板，将数据持久化到主机，并通过Docker连接到它正在运行的Docker主机。袜子文件。

```bash
docker run -d -p 9000:9000 --name=portainer \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -v /host/data:/data \
  portainer/portainer
```
###  10.3 界面访问Portainer Dashboard
随着Portainer的运行，现在可以通过UI访问仪表板并管理集群。仪表板运行在Port 9000上，可以通过这个链接访问
第一个屏幕要求您为admin用户创建一个密码
![在这里插入图片描述](https://img-blog.csdnimg.cn/98e7aedc653b484e9fc051eb7e118f22.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_15,color_FFFFFF,t_70,g_se,x_16)
配置完成后，第二个屏幕将要求您使用定义的密码登录到仪表板。
![在这里插入图片描述](https://img-blog.csdnimg.cn/fcdcb920db414ecfa80a0d1e3521ea10.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_15,color_FFFFFF,t_70,g_se,x_16)
###  10.4 部署模板
Portainer的众多特性之一是，它可以基于预定义的容器部署服务。
![在这里插入图片描述](https://img-blog.csdnimg.cn/a88a12923bb24a5e8b91036eb262c51f.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_20,color_FFFFFF,t_70,g_se,x_16)
在这种情况下，您将部署nginx模板。

 - 通过“应用模板”页签查看可用的模板。
 - 选择nginx模板
 - 例如，为容器输入一个友好的名称`nginx-web`
 - 勾选“显示高级选项”，将80端口绑定到主机端口80
 - 创建容器对象
 - 访问容器通过80端口

###  10.5 管理容器
将部署一个Nginx实例。使用指示板，您将看到状态并能够控制集群。

![在这里插入图片描述](https://img-blog.csdnimg.cn/20b32d2434024bafbf8a1d4bb8e0f6a1.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_20,color_FFFFFF,t_70,g_se,x_16)
