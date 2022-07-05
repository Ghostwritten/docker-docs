# Docker Swarm 快速入门 


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
### 1.1 初始化集群
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
### 1.2 加入新节点
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
### 1.3 创建 overlay 网络
群模式还引入了一种改进的网络模型。在以前的版本中，Docker需要使用外部键值存储，如Consul，以确保整个网络的一致性。对协商一致意见和KV的需求现在已被纳入Docker内部，不再依赖外部服务.

改进的网络方法遵循与前面相同的语法。覆盖网络用于不同主机上的容器之间通信。在背后，这是一个虚拟可扩展`LAN` (VXLAN)，设计用于大规模基于云的部署。

下面的命令将创建一个新的覆盖网络称为`skynet`。所有注册到这个网络的容器都可以彼此通信，而不管它们部署到哪个节点上。

```bash
$ docker network create -d overlay skynet
4a687dx7ym4qj8wddr0vn1k0r
```
### 1.4 部署服务 service
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
### 1.5 状态监测
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

### 1.6 弹缩服务 service
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
