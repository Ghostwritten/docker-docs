#  Dcoker Swarm 更新

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

##  1. Update Limits
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

##  2. Update Replicas
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
## 3.  Update Image

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

## 4. 滚动更新
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

参考：

 - [docker swarm update](https://docs.docker.com/engine/reference/commandline/swarm_update/)
 - [Updating Services in a Docker Swarm Mode Cluster](https://semaphoreci.com/community/tutorials/updating-services-in-a-docker-swarm-mode-cluster)
 - [Rolling updates with Docker Swarm](https://blog.container-solutions.com/rolling-updates-with-docker-swarm)
 - [Updating Docker Swarm Configs and Secrets Without Downtime](https://www.youtube.com/watch?v=oWrwi1NiViw)
