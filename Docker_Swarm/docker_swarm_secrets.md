# Docker swarm 管理 secrets
@[toc]

---
##  1. 初始化 swarm
默认情况下，Docker作为一个隔离的单节点工作。所有容器仅部署在引擎上。群模式将它变成了一个多主机集群感知引擎。为了使用秘密功能，Docker必须处于“群模式”。这是通过

```bash
$ docker swarm init
Swarm initialized: current node (o6ngy0xskvvhxaaiyfye21znh) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-4oa8jjlavmoihusp73vgu71mhjek6ut1qkapzqnhtxdq5xzv0t-04anuyasgyv0p4xiqn4ga16fe 172.17.0.9:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```
### 2. 创建 secrets
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

## 3. 用Compose创建Docker stack
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
## 4. 部署访问 secrets

Docker Compose Stack的部署使用Docker CLI。作为部署的一部分，堆栈将配置为对秘密的访问。使用以下命令部署任务:

```bash
docker stack deploy -c docker-compose.yml secrets1
docker logs $(docker ps -aqn1 -f status=exited)
```
如果命令错误与“docker日志”需要精确的1个参数。这意味着容器还没有启动并返回秘密。

## 5. File Based Secret
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
## 6. 使用Compose部署和访问secrets
和前面一样，部署`Docker Compose stack`

```bash
docker stack deploy -c docker-compose.yml secrets2
```
下面的命令将获取为新创建的服务退出的最后一个容器的日志文件

```bash
docker logs $(docker ps -aqn1 -f name=secrets2 -f status=exited)
```

参考：

 - [Manage sensitive data with Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
 - [The Complete Guide to Docker Secrets](https://earthly.dev/blog/docker-secrets/)
 - [Managing Secrets in Docker Swarm](https://semaphoreci.com/community/tutorials/managing-secrets-in-docker-swarm)
