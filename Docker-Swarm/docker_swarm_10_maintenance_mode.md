#  Docker Swarm 维护模式

## 1. 创建集群
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
## 2. 部署服务
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

## 3. 开启维护模式
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
## 4. 关闭维护模式
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

参考：

 - [Drain a node on the swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/drain-node/)
