# Docker swarm 通过 docker-compose 部署应用


## 1 初始化swarm
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
## 2.  创建 Docker Compose 文件
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

## 3. 部署服务
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
