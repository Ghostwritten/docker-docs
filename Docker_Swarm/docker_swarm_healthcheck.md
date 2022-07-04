# Docker Swarm 健康检查

## 1. 容器添加健康检查
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
## 2. 崩溃命令
```bash
$ curl http://docker/unhealthy
```
服务现在将进入错误模式。在下一步中，我们将看看Docker是如何处理这个问题的。
由于HTTP服务器处于错误状态，健康检查应该失败。Docker会将此报告为元数据的一部分。

## 3. 验证状态
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
## 4. 状态修复
```bash
$ curl http://docker/healthy


$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                   PORTS                NAMES
6702ab36060f        http                "/app"              5 minutes ago       Up 5 minutes (healthy)   0.0.0.0:80->80/tcp   srv

$ docker inspect --format "{{json .State.Health.Status }}" srv
"healthy"
```
## 5. swarm 运用 Healthchecks
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

参考：

 - [Docker Swarm Health Check](https://bobcares.com/blog/docker-swarm-health-check/)
 - [Healthchecks in a Docker Swarm](https://statusq.org/archives/2022/02/01/10830/)
 - [How To Successfully Implement A Healthcheck In Docker Compose](https://medium.com/geekculture/how-to-successfully-implement-a-healthcheck-in-docker-compose-efced60bc08e)
