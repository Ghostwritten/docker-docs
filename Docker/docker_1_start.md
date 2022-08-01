# 入门

![在这里插入图片描述](https://img-blog.csdnimg.cn/566192a1cfc84a339f1f31ff0d84a177.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_20,color_FFFFFF,t_70,g_se,x_16#pic_center)


<font color=#FFA500 size=3 face="楷体">"这是一个非常棒的docker学习历程。我把一个国外的docker实践入门教学进行了简略的翻译，比起国内博客学习的总结性文章，它更注重让小白在实战背景下容易理解与感悟，激发萌新自我疏理总结实战演练下的小细节。"</font>



## 1. 运行redis容器
第一个任务是识别配置为运行Redis的Docker映像的名称。使用Docker，所有容器都是基于Docker映像启动的。这些图像包含启动流程所需的所有内容;主机不需要任何配置或依赖项。

```bash
$ docker search redis
NAME                             DESCRIPTION                                     STARS               OFFICIAL            AUTOMATED
redis                            Redis is an open source key-value store that…   9971                [OK]                
sameersbn/redis                                                                  83                                      [OK]
grokzen/redis-cluster            Redis cluster 3.0, 3.2, 4.0, 5.0, 6.0, 6.2      79                                      
rediscommander/redis-commander   Alpine image for redis-commander - Redis man…   66                                      [OK]
redislabs/redisearch             Redis With the RedisSearch module pre-loaded…   39                                      
redislabs/redisinsight           RedisInsight - The GUI for Redis                35                                      
kubeguide/redis-master           redis-master with "Hello World!"                33                                      
redislabs/redis                  Clustered in-memory database engine compatib…   31                                      
oliver006/redis_exporter          Prometheus Exporter for Redis Metrics. Supp…   30                                      
redislabs/rejson                 RedisJSON - Enhanced JSON data type processi…   27                                      
arm32v7/redis                    Redis is an open source key-value store that…   24                                      
redislabs/redisgraph             A graph database module for Redis               16                                      [OK]
arm64v8/redis                    Redis is an open source key-value store that…   15                                      
redislabs/redismod               An automated build of redismod - latest Redi…   15                                      [OK]
redislabs/rebloom                A probablistic datatypes module for Redis       14                                      [OK]
webhippie/redis                  Docker image for redis                          11                                      [OK]
insready/redis-stat              Docker image for the real-time Redis monitor…   10                                      [OK]
s7anley/redis-sentinel-docker    Redis Sentinel                                  10                                      [OK]
redislabs/redistimeseries        A time series database module for Redis         10                                      
goodsmileduck/redis-cli          redis-cli on alpine                             9                                       [OK]
centos/redis-32-centos7          Redis in-memory data structure store, used a…   5                                       
clearlinux/redis                 Redis key-value data structure server with t…   3                                       
wodby/redis                      Redis container image with orchestration        1                                       [OK]
tiredofit/redis                  Redis Server w/ Zabbix monitoring and S6 Ove…   1                                       [OK]
xetamus/redis-resource           forked redis-resource                           0                                       [OK]
$ 
```
使用搜索命令，Jane已经确定Redis Docker Image被称为`Redis`，并希望运行最新版本。因为Redis是一个数据库，Jane想在她继续工作的时候把它作为后台服务运行。

要完成这一步，在后台启动一个容器，运行一个基于官方图像的Redis实例。
Docker CLI有一个名为run的命令，它将基于Docker映像启动一个容器。结构是docker运行`<options> <image-name>`

默认情况下，Docker将在前台运行一个命令。要在后台运行，需要指定选项-d。

```bash
$ docker run -d redis
66a23eb0c3fd7ce1099f0eef043303eb286084a87e6047e851057d0ecc634ee0


$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS               NAMES
66a23eb0c3fd        redis               "docker-entrypoint.s…"   About a minute ago   Up About a minute   6379/tcp            zen_archimedes


`docker inspect <friendly-name|container-id>`命令提供了运行容器的详细信息，如IP地址等。

`docker logs <friendly-name|container-id>`将显示容器写入标准错误或标准输出的消息。

#静态映射端口
$ docker run -d --name redisHostPort -p 6379:6379 redis:latest
00d11bf6c9217aa43646c32779a29d62d854e90ae3cfe70e72e61016db49fb7c

#动态映射端口
$ docker run -d --name redisDynamic -p 6379 redis:latest
56a6612f70b1f35097da220339cc1ec4c3ae84137757e803aa59e41c61523a11

$ docker port redisDynamic 6379
0.0.0.0:32768

#已经启动了多个redis实例
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                     NAMES
56a6612f70b1        redis:latest        "docker-entrypoint.s…"   58 seconds ago      Up 57 seconds       0.0.0.0:32768->6379/tcp   redisDynamic
00d11bf6c921        redis:latest        "docker-entrypoint.s…"   2 minutes ago       Up 2 minutes        0.0.0.0:6379->6379/tcp    redisHostPort
66a23eb0c3fd        redis               "docker-entrypoint.s…"   5 minutes ago       Up 5 minutes        6379/tcp                  zen_archimedes
```
缺省情况下，主机端口映射为0.0.0.0，即所有IP地址。在定义端口映射时，可以指定一个特定的IP地址，例如`-p 127.0.0.1:6379:6379`
默认情况下，Docker将运行可用的最新版本。如果需要一个特定的版本，它可以被指定为一个标记，例如，version 3.2将被`docker run -d redis:3.2`。
由于这是Jane第一次使用Redis映像，它将被下载到Docker Host机器上。


让数据持久存储

```bash
$ docker run -d --name redisMapped -v /opt/docker/data/redis:/data redis
71e3cfca3344c9eaa4102761fad59d135c3233b56e960eebd5b650d72996936e
```
Docker允许您使用`$PWD`作为当前目录的占位符。

---
##  2. 运行web容器
Docker映像从一个基本映像开始。基本映像应该包括应用程序所需的平台依赖项，例如，安装JVM或CLR。
这个基本映像定义为Dockerfile中的一条指令。Docker映像是基于Dockerfile的内容构建的。Dockerfile是描述如何部署应用程序的说明列表。
在这个例子中，我们的基础图像是Nginx的Alpine版本。这提供了Linux Alpine发行版上配置的web服务器。

写一个网页
```bash
$ vim index.html
<h1>Hello World</h1>
```

创建dockerfile


```bash
FROM nginx:alpine
COPY . /usr/share/nginx/html
```
构建镜像

```bash
$ docker build -t webserver-image:v1 .
Sending build context to Docker daemon  3.072kB
Step 1/2 : FROM nginx:alpine
 ---> 513f9a9d8748
Step 2/2 : COPY . /usr/share/nginx/html
 ---> ae7287f132f3
Successfully built ae7287f132f3
Successfully tagged webserver-image:v1
$ docker build -t webserver-image:v1 .
Sending build context to Docker daemon  3.072kB
Step 1/2 : FROM nginx:alpine
 ---> 513f9a9d8748
Step 2/2 : COPY . /usr/share/nginx/html
 ---> Using cache
 ---> ae7287f132f3
Successfully built ae7287f132f3
Successfully tagged webserver-image:v1

$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
webserver-image     v1                  ae7287f132f3        15 seconds ago      22.9MB
```
通过镜像运行容器

```bash
$ docker run -d -p 80:80 webserver-image:v1
```
测试web

```bash
$ curl ip
<h1>Hello World</h1>
```
---
## 3. 编排镜像
所有Docker映像都从一个基本映像开始。基本映像是来自Docker 官方仓库用于启动容器的相同映像。除了图像名称，我们还可以包含图像标签，以指示我们想要的特定版本，默认情况下，这是最新的版本。
这些基本映像用作运行应用程序所需的附加更改的基础。例如，在这个场景中，在部署静态HTML文件之前，我们需要在系统上配置并运行NGINX。因此，我们想使用NGINX作为我们的基本映像。
Dockerfile是简单的文本文件

```bash
FROM nginx:1.11-alpine
```
定义了基本映像之后，我们需要运行各种命令来配置映像。有很多命令可以帮助实现这一点，主要的两个命令是`COPY`和`RUN`。
`RUN <command>`允许您像在命令提示符中那样执行任何命令，例如安装不同的应用程序包或运行构建命令。RUN的结果会持久化到映像中，因此不要在磁盘上留下任何不必要的或临时的文件，这一点很重要，因为这些文件将包含在映像中。
`COPY <src> <dest>`允许您将文件从包含Dockerfile的目录复制。

已经为您创建了一个新的`index.html`文件，我们想从我们的容器中提供该文件。在FROM命令后面的下一行，使用COPY命令将index.html复制到`/usr/share/nginx/html`目录中。

```bash
$ vim index.html
<h1>Hello World</h1>
```

```bash
FROM nginx:1.11-alpine
COPY index.html /usr/share/nginx/html/index.html
```
将我们的文件复制到映像中并下载了所有依赖项后，您需要定义需要访问哪个端口应用程序。
使用`EXPOSE <port>`命令可以告诉Docker应该打开哪些端口，可以绑定到哪些端口。您可以在一条命令中定义多个端口，例如`EXPOSE 80433`或`EXPOSE 7000-8000`

```bash
FROM nginx:1.11-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```
配置好Docker映像并定义了我们想要访问的端口后，现在我们需要定义启动应用程序的命令。
Dockerfile中的CMD行定义了启动容器时要运行的默认命令。如果命令需要参数，那么建议使用一个数组，例如`["cmd"， "-a"， "arga value"， "-b"， "argb-value"]`，这将被组合在一起，命令`cmd -a" arga value" -b argb-value`将被运行。

运行NGINX的命令为`NGINX -g daemon off`;将此设置为Dockerfile中的默认命令。

CMD的另一种方法是`ENTRYPOINT`。虽然CMD可以在容器启动时被重写，但`ENTRYPOINT`定义了一个命令，在容器启动时可以将参数传递给它。

在这个例子中，NGINX将是关闭-g守护进程的入口点;默认的命令。

```bash
FROM nginx:1.11-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

写完Dockerfile后，你需要使用docker构建将它转换成一个映像。build命令接受一个包含Dockerfile的目录，执行步骤并将映像存储在本地Docker引擎中。如果由于错误而失败，则构建将停止。

```bash
docker build -t my-nginx-image:latest .
docker images
```
使用来自build命令的ID结果或您分配给它的友好名称启动新构建映像的实例。
NGINX被设计为后台服务，所以你应该包含选项-d。要使web服务器可访问，使用`-p 80:80`将其绑定到端口80

```bash
$ docker run -d -p 80:80 my-nginx-image:latest

$ docker ps
CONTAINER ID        IMAGE                   COMMAND                  CREATED              STATUS              PORTS                         NAMES
34e0b44c067f        my-nginx-image:latest   "nginx -g 'daemon of…"   About a minute ago   Up About a minute   0.0.0.0:80->80/tcp, 443/tcp   gracious_ride

$ curl -i http://ip
HTTP/1.1 200 OK
Server: nginx/1.11.13
Date: Tue, 28 Sep 2021 08:17:44 GMT
Content-Type: text/html
Content-Length: 21
Last-Modified: Tue, 28 Sep 2021 08:11:49 GMT
Connection: keep-alive
ETag: "6152ce45-15"
Accept-Ranges: bytes

<h1>Hello World</h1>
```
---
##  4. 构建node.js镜像

### 4.1 dockerfile基础定义
正如我们在前一个场景中所描述的，所有映像都从一个基本映像开始，理想情况下，该映像尽可能接近您所需的配置。`Node.js`为每个发布版本提供了带有标签的预构建映像。
`Node:0.0`的图像为`Node:10-alpine`。这是一个基于 `Alpine-based`的构建，比官方形象更小和更流线型。
除了基本映像，我们还需要创建应用程序运行的基本目录。使用RUN <命令>，我们可以像从命令shell中运行一样执行命令，通过使用mkdir，我们可以创建目录.

我们可以使用`WORKDIR <目录>`定义一个工作目录，以确保所有未来的命令都是从相对于我们的应用程序的目录执行的。

在单独的行上设置`FROM <image>:<tag>、RUN <command>和WORKDIR <directory>`，以配置用于部署应用程序的基本环境。
Dockerfile内容：
```bash
FROM node:10-alpine

RUN mkdir -p /src/app

WORKDIR /src/app
```
### 4.2 npm install
在前面的集合中，我们配置了配置的基础以及希望如何部署应用程序。下一个阶段是安装运行应用程序所需的依赖项。对于Node.js，这意味着运行`NPM install`。
为了将构建时间保持在最小，Docker将在Dockerfile中缓存一行代码的执行结果，以便在将来的构建中使用。如果发生了更改，Docker将使当前行和以下所有行无效，以确保所有行都是最新的。

对于NPM，我们只希望在包中有东西时重新运行`NPM install`。Json文件已经改变。如果没有任何改变，那么我们可以使用缓存版本来加速部署。使用COPY包。我们可以使RUN npm install命令失效，如果包。Json文件已经改变。如果文件没有更改，那么缓存将不会失效，并且将使用npm install命令的缓存结果。

Dockerfile更新内容：
```bash
FROM node:10-alpine

RUN mkdir -p /src/app

WORKDIR /src/app

COPY package.json /src/app/package.json

RUN npm install
```
如果你不想使用缓存作为构建的一部分，那么设置选项`--no-cache=true`作为docker构建命令的一部分。

### 4.3 应用配置
在安装了依赖项之后，我们希望复制应用程序的其余源代码。拆分依赖项的安装并复制源代码使我们能够在需要时使用缓存。
如果我们在运行npm install之前复制我们的代码，那么它每次都会运行，因为我们的代码会发生变化。通过复制只是包。Json，我们可以确保缓存是无效的，只有当我们的包内容已经改变。

在Dockerfile中创建所需的步骤，以完成应用程序的部署。
我们可以使用copy复制Dockerfile所在的整个目录`<dest dir>`。

复制源代码之后，使用`EXPOSE <port>`定义应用程序需要访问的端口。

最后，需要启动应用程序。使用Node.js的一个巧妙技巧是使用`npm start`命令。这看起来在包里。Json文件，了解如何启动保存重复命令的应用程序。

```bash
FROM node:10-alpine

RUN mkdir -p /src/app

WORKDIR /src/app

COPY package.json /src/app/package.json

RUN npm install

COPY . /src/app

EXPOSE 3000

CMD [ "npm", "start" ]
```

### 4.4 构建并运行镜像

```bash
$ docker build -t my-nodejs-app .
$ docker run -d --name my-running-app -p 3000:3000 my-nodejs-app
```
您可以使用curl测试容器是否可访问。如果应用程序响应，那么您就知道一切都已正确启动。

```bash
$ curl http://docker:3000
<!DOCTYPE html><html><head><title>Express</title><link rel="stylesheet" href="/stylesheets/style.css"></head><body><h1>Express</h1><p>Welcome to Express</p></body></html>
```
### 4.5 运行添加环境变量
Docker映像应该设计成可以从一个环境传输到另一个环境，而不需要做任何更改或重新构建。通过遵循这个模式，您可以确信，如果它在一个环境(如登台)中工作，那么它也将在另一个环境(如生产环境)中工作。

使用Docker，可以在启动容器时定义环境变量。例如，对于Node.js应用程序，您应该在生产环境中运行时为NODE_ENV定义一个环境变量。

使用-e选项，可以将名称和值设置为`-e NODE_ENV=production`

```bash
$ docker run -d --name my-production-running-app -e NODE_ENV=production -p 3000:3000 my-nodejs-app
```
---
##  5. OnBuild优化Dockerfile

虽然Dockerfile是按从上到下的顺序执行的，但当该映像用作另一个映像的基础时，您可以触发一条指令在稍后的时间执行。

ONBUILD指令可以为镜像添加触发器。

当我们在一个Dockerfile文件中加上ONBUILD指令，该指令对利用该Dockerfile构建镜像（比如为A镜像）不会产生实质性影响。

但是当我们编写一个新的Dockerfile文件来基于A镜像构建一个镜像（比如为B镜像）时，这时构造A镜像的Dockerfile文件中的ONBUILD指令就生效了，在构建B镜像的过程中，首先会执行ONBUILD指令指定的指令，然后才会执行其它指令。

需要注意的是，如果是再利用B镜像构造新的镜像时，那个ONBUILD指令就无效了，也就是说只能再构建子镜像中执行，对孙子镜像构建无效。其实想想是合理的，因为在构建子镜像中已经执行了，如果孙子镜像构建还要执行，相当于重复执行，这就有问题了。

利用ONBUILD指令,实际上就是相当于创建一个模板镜像，后续可以根据该模板镜像创建特定的子镜像，需要在子镜像构建过程中执行的一些通用操作就可以在模板镜像对应的dockerfile文件中用ONBUILD指令指定。 从而减少dockerfile文件的重复内容编写。

下面是Node.js的`OnBuild Dockerfile`。与前面的场景不同，应用程序指定命令以`ONBUILD`作为前缀。
Dockerfile1:
```bash
FROM node:7
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
ONBUILD COPY package.json /usr/src/app/
ONBUILD RUN npm install
ONBUILD COPY . /usr/src/app
CMD [ "npm", "start" ]
```

```bash
docker build -t node:7-onbuild -f Dockerfile1
```

结果是，我们可以构建这个映像，但在将构建的映像用作基本映像之前，不会执行应用程序特定的命令。然后，它们将作为基本映像构建的一部分执行。

有了复制代码、安装依赖项和启动应用程序的所有逻辑后，在应用程序级别上需要定义的唯一方面就是要公开哪个端口。

创建`OnBuild`映像的好处是，我们的Dockerfile现在更简单，可以轻松地跨多个项目重用，而不必重新运行相同的步骤，以提高构建时间。
dockerfile2:
```bash
FROM node:7-onbuild
EXPOSE 3000
```
已经为您创建了上一步中的Dockerfile。基于`OnBuild docker`文件构建映像与之前相同。OnBuild命令将像在基础Dockerfile中一样执行。
总之，唯有 `ONBUILD` 是为了帮助别人定制自己而准备的。而不是为了构建当前镜像的。

```bash
docker build -t my-nodejs-app -f dockerfile2

docker run -d --name my-running-app -p 3000:3000 my-nodejs-app

curl http://ip:3000
```
---
##  6. 忽略文件`.dockerignore`

###  6.1 Docker Ignore
为了防止敏感文件或目录被错误地包含在映像中，您可以添加一个名为`.dockerignore`的文件。

Dockerfile将工作目录复制到Docker映像中。因此，这将包括潜在的敏感信息，如我们希望在映像外部管理的密码文件。

```bash
$ ls
Dockerfile  cmd.sh  passwords.txt

$ cat Dockerfile 
FROM alpine
ADD . /app
COPY cmd.sh /cmd.sh
CMD ["sh", "-c", "/cmd.sh"]

$ cat cmd.sh 
echo "Hello World"

$ cat passwords.txt
admin:admin


$ docker build -t password .
Sending build context to Docker daemon  4.096kB
Step 1/4 : FROM alpine
 ---> 3fd9065eaf02
Step 2/4 : ADD . /app
 ---> 8e7bc5dac978
Step 3/4 : COPY cmd.sh /cmd.sh
 ---> ec486638d561
Step 4/4 : CMD ["sh", "-c", "/cmd.sh"]
 ---> Running in fe4cba7a87b2
Removing intermediate container fe4cba7a87b2
 ---> 4c270e87d27c
Successfully built 4c270e87d27c
Successfully tagged password:latest

$ docker run password ls /app
Dockerfile
cmd.sh
passwords.txt
```
这将包括密码文件。

下面的命令将在`.dockerignore`文件中包含`password .txt`，并确保它不会意外地出现在容器中。dockerignore文件将存储在源代码管理中，并与团队共享，以确保每个人都是一致的。

```bash
echo passwords.txt >> .dockerignore
```
`.dockerignore`文件支持目录和正则表达式来定义限制，非常类似于`.gitignore`。这个文件还可以用来提高构建时间，我们将在下一步研究这个问题。

构建映像，因为Docker Ignore文件不应该包括密码文件。

```bash
$ docker build -t nopassword .
Sending build context to Docker daemon  4.096kB
Step 1/4 : FROM alpine
 ---> 3fd9065eaf02
Step 2/4 : ADD . /app
 ---> 36ee8b3bc4ee
Step 3/4 : COPY cmd.sh /cmd.sh
 ---> a4c8fc953352
Step 4/4 : CMD ["sh", "-c", "/cmd.sh"]
 ---> Running in 5b7774763eca
Removing intermediate container 5b7774763eca
 ---> b6b6eac92cce
Successfully built b6b6eac92cce
Successfully tagged nopassword:latest
$ docker run nopassword ls /app
Dockerfile
cmd.sh
```
如果您需要使用密码作为RUN命令的一部分，那么您需要复制、执行和删除文件作为单个RUN命令的一部分。只有Docker容器的最终状态被持久化到映像中。

###  6.2 Docker 构建安全上下文
`dockerignore`文件可以确保Docker映像中不包含敏感细节。但是，它们也可以用来提高映像的构建时间。

在环境中，已经创建了100M的临时文件。Dockerfile永远不会使用这个文件。当您执行构建命令时，Docker将整个路径内容发送给引擎，以便它计算要包含哪些文件。因此，发送100M文件是不需要的，并创建了一个较慢的构建。

您可以通过执行该命令看到100M的影响。

```bash
$ docker build -t large-file-context .
Sending build context to Docker daemon  104.9MB
Step 1/4 : FROM alpine
 ---> 3fd9065eaf02
Step 2/4 : ADD . /app
 ---> cb1e74c524af
Step 3/4 : COPY cmd.sh /cmd.sh
 ---> e3dbbbd57ddf
Step 4/4 : CMD ["sh", "-c", "/cmd.sh"]
 ---> Running in 5fcb5e771266
Removing intermediate container 5fcb5e771266
 ---> 7e398a079fb0
Successfully built 7e398a079fb0
Successfully tagged large-file-context:latest
```
在下一步中，我们将演示如何提高构建的性能。

明智的做法是忽略`.git`目录以及在映像中下载/构建的依赖项，比如`node_modules`。在Docker容器中运行的应用程序永远不会使用它们，只会增加构建过程的开销。

###  6.3 优化构建
以同样的方式，我们使用.dockerignore文件来排除敏感文件，我们可以使用它来排除我们不想在构建期间发送到Docker构建上下文的文件。

要加快构建速度，只需在忽略文件中包含大文件的文件名。

```bash
echo big-temp-file.img >> .dockerignore
```
当我们重建图像时，它将会快得多，因为它不需要复制100M文件。

```bash
$ docker build -t no-large-file-context .
Sending build context to Docker daemon  4.096kB
Step 1/4 : FROM alpine
 ---> 3fd9065eaf02
Step 2/4 : ADD . /app
 ---> Using cache
 ---> 4a1be3423c29
Step 3/4 : COPY cmd.sh /cmd.sh
 ---> Using cache
 ---> e30db2162cca
Step 4/4 : CMD ["sh", "-c", "/cmd.sh"]
 ---> Using cache
 ---> 4d4964ddbb00
Successfully built 4d4964ddbb00
Successfully tagged no-large-file-context:latest
```
当忽略`.git`这样的大目录时，这种优化会产生更大的影响。

---

##  7. 容器持久化数据
数据容器是唯一负责存储/管理数据的容器。
与其他容器一样，它们由主机系统管理。然而，当您执行docker ps命令时，它们不会运行。
要创建数据容器，我们首先要创建一个具有知名名称的容器以供将来参考。我们使用busybox作为基础，因为它体积小，重量轻，以防我们想要探索和移动容器到另一个主机。
在创建容器时，我们还提供了一个-v选项来定义其他容器读取/保存数据的位置。

```bash
$ docker create -v /config --name dataContainer busybox

```
容器就绪后，我们现在可以将文件从本地客户端目录复制到容器中。
下面的命令将config.conf文件复制到dataContainer和`config.conf`目录中。

```bash
$ docker cp config.conf dataContainer:/config/
```
现在我们的`Data Container`有了配置，我们可以在启动需要配置文件的依赖容器时引用该容器。

使用——`volumes-from <container>`选项，我们可以使用正在启动的容器中来自其他容器的挂载卷。在这种情况下，我们将启动一个Ubuntu容器，它引用了我们的数据容器。当我们列出config目录时，它将显示来自附加容器的文件。

```bash
$ docker run --volumes-from dataContainer ubuntu ls /config
config.conf
```
如果`/config`目录已经存在，那么`volumes-from`将被覆盖并成为所使用的目录。可以将多个卷映射到一个容器。

如果我们想将Data Container移动到另一台机器，那么我们可以将其导出到.tar文件。

```bash
$ docker export dataContainer > dataContainer.tar
```
命令`docker import dataContainer.tar`会将数据容器导入到docker中。

---
## 8. 容器之间的交流

连接到容器最常见的场景是应用程序连接到数据存储。创建链接时的关键方面是容器的名称。所有容器都有名称，但为了在处理链接时更容易一些，为所连接的源容器定义一个友好的名称是很重要的。

运行一个友好的名称为redis-server的redis服务器，我们将在下一步连接它。这将是源容器。

```bash
$ docker run -d --name redis-server redis
```
Redis是一个快速的、开源的键值数据存储。
要连接到源容器，在启动新容器时使用`--link <container-name|id>:<alias>`选项。容器名引用上一步中定义的源容器，而别名定义主机的友好名称。

通过设置别名，我们可以将应用程序的配置方式与基础设施的调用方式分开。这意味着应用程序配置在连接到其他环境时不需要更改。

在这个例子中，我们打开一个链接到`redis-server`的`Alpine`容器。我们已经将别名定义为redis。当一个链接被创建时，Docker将做两件事。

首先，Docker将基于链接到容器的环境变量设置一些环境变量。这些环境变量为您提供了一种通过已知名称引用端口和IP地址等信息的方法。

可以使用env命令输出所有环境变量。例如:

```bash
$ docker run --link redis-server:redis alpine env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=bae49bf11c01
REDIS_PORT=tcp://172.18.0.2:6379
REDIS_PORT_6379_TCP=tcp://172.18.0.2:6379
REDIS_PORT_6379_TCP_ADDR=172.18.0.2
REDIS_PORT_6379_TCP_PORT=6379
REDIS_PORT_6379_TCP_PROTO=tcp
REDIS_NAME=/angry_franklin/redis
REDIS_ENV_GOSU_VERSION=1.12
REDIS_ENV_REDIS_VERSION=6.2.5
REDIS_ENV_REDIS_DOWNLOAD_URL=http://download.redis.io/releases/redis-6.2.5.tar.gz
REDIS_ENV_REDIS_DOWNLOAD_SHA=4b9a75709a1b74b3785e20a6c158cab94cf52298aa381eea947a678a60d551ae
HOME=/root
```
通过创建链接，您可以以与在您的网络中运行的服务器相同的方式ping源容器。

```bash
$ docker run --link redis-server:redis alpine ping -c 1 redis
PING redis (172.18.0.2): 56 data bytes
64 bytes from 172.18.0.2: seq=0 ttl=64 time=0.202 ms

--- redis ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.202/0.202/0.202 ms
```
通过创建链接，应用程序可以以通常的方式与源容器进行连接和通信，而无需考虑两个服务都运行在容器中这一事实。

这是一个简单的node.js应用程序，它使用主机名redis连接到redis。

```bash
$ docker run -d -p 3000:3000 --link redis-server:redis katacoda/redis-node-docker-example
```
发送一个HTTP请求到应用程序将存储请求在Redis和返回一个计数。如果发出多个请求，就会看到计数器的递增，因为条目被持久化了。

```bash
$ curl ip:3000
This page was generated after talking to redis.

Application Build: 1

Total requests: 1

IP count: 
    ::ffff:172.17.0.33: 1
$ curl ip:3000
This page was generated after talking to redis.

Application Build: 1

Total requests: 2

IP count: 
    ::ffff:172.17.0.33: 2
```
以同样的方式，您可以将源容器连接到应用程序，也可以将它们连接到自己的CLI工具。

下面的命令将启动一个redis -cli工具的实例，并通过它的别名连接到redis服务器。

```bash
$ docker run -it --link redis-server:redis redis redis-cli -h redis
redis:6379> info
```
`KEYS *`命令将输出当前存储在源redis容器中的内容。

---
##  9. Docker 网络
### 9.1 创建网络
第一步是使用CLI创建网络。这个网络将允许我们附加多个容器，这些容器将能够发现彼此。在本例中，我们将从创建一个后端网络开始。所有连接到我们后端的容器都将在这个网络上。

```bash
$ docker network create backend-network
89109e8de51aee15171ac6ec7257af040aecc66906777acfbbe88a715dcdb9d4
```
当我们启动新的容器时，我们可以使用`--net`属性来分配它们应该连接到哪个网络。

```bash
$ docker run -d --name=redis --net=backend-network redis
```
###  9.2 连接网络
与使用链接不同，docker网络的行为类似于传统网络，节点可以附加/分离。

首先你会注意到Docker不再分配环境变量或更新容器的hosts文件。使用下面的两个命令，您会注意到它不再提到其他容器。

```bash
$ docker run --net=backend-network alpine env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=d566ff9c9a14
HOME=/root

$ docker run --net=backend-network alpine cat /etc/hosts
127.0.0.1       localhost
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
172.19.0.3      97c3a236a7e6
```
相反，容器可以通过Docker中的嵌入式DNS服务器进行通信。这个DNS服务器通过IP `127.0.0.11`分配给所有容器，并在`resolv.conf`文件中设置。

```bash
$ docker run --net=backend-network alpine cat /etc/resolv.conf
nameserver 127.0.0.11
options ndots:0
```
当容器试图通过众所周知的名称(如Redis)访问其他容器时，DNS服务器将返回正确的容器的IP地址。在这种情况下，Redis的完全限定名将是`Redis .backend-network`。

```bash
$ docker run --net=backend-network alpine ping -c1 redis
PING redis (172.19.0.2): 56 data bytes
64 bytes from 172.19.0.2: seq=0 ttl=64 time=0.324 ms

--- redis ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.324/0.324/0.324 ms
```

###  9.3 连接两个容器
Docker支持多个网络和容器同时连接到多个网络。

例如，让我们用Node.js应用程序创建一个单独的网络，它与我们现有的Redis实例通信。

第一个任务是以同样的方式创建一个新的网络。

```bash
$ docker network create frontend-network
37e9702dd8f695f515b988beddd1cf4d4f7b38447a4e4177d98fcf96231321b2
```
当使用connect命令时，可以将现有容器附加到网络上。

```bash
$ docker network connect frontend-network redis
```
当我们启动web服务器时，考虑到它连接到同一个网络，它将能够与我们的Redis实例通信。

```bash
$ docker run -d -p 3000:3000 --net=frontend-network katacoda/redis-node-docker-example
```

```bash
$ curl ping:3000
This page was generated after talking to redis.

Application Build: 1

Total requests: 1

IP count: 
    ::ffff:172.17.0.51: 1
$ curl ping:3000
This page was generated after talking to redis.

Application Build: 1

Total requests: 2

IP count: 
    ::ffff:172.17.0.51: 2
```
### 9.4 创建别名
使用docker网络时仍然支持链接，并提供了一种方法来定义容器名的别名。这将为容器提供一个额外的DNS条目名称和被发现的方式。当使用`--link`时，嵌入式DNS将保证本地化查找结果只在使用`--link`的容器上。

另一种方法是在将容器连接到网络时提供别名。
下面的命令将用db的别名将我们的Redis实例连接到前端网络。

```bash
docker network create frontend-network2
docker network connect --alias db frontend-network2 redis
```
当容器试图通过名称db访问服务时，他们将得到我们的Redis容器的IP地址。

```bash
$ docker run --net=frontend-network2 alpine ping -c1 db
PING db (172.21.0.2): 56 data bytes
64 bytes from 172.21.0.2: seq=0 ttl=64 time=0.170 ms

--- db ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.170/0.170/0.170 ms
```
###  9.5 断开容器连接
创建好网络后，我们可以使用CLI来探索细节。下面的命令将列出我们主机上的所有网络。  

```bash
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
89109e8de51a        backend-network     bridge              local
6fe697227a58        bridge              bridge              local
37e9702dd8f6        frontend-network    bridge              local
b0a9dbbb0bab        frontend-network2   bridge              local
fa054a9af353        host                host                local
f50397115ef2        none                null                local
```
然后，我们可以探索网络，查看连接的容器及其IP地址。

```bash
$ docker network inspect frontend-network
[
    {
        "Name": "frontend-network",
        "Id": "37e9702dd8f695f515b988beddd1cf4d4f7b38447a4e4177d98fcf96231321b2",
        "Created": "2021-09-28T12:52:03.799072129Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.20.0.0/16",
                    "Gateway": "172.20.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "80bb046b3ac46cd0efa7b66640e0eaf297f65d39ad080193758f6d19d10c6d3e": {
                "Name": "redis",
                "EndpointID": "a8fb389c6672f0ab173c39b273064922ea252d3fce5094d1864fb2b36cdfa25d",
                "MacAddress": "02:42:ac:14:00:02",
                "IPv4Address": "172.20.0.2/16",
                "IPv6Address": ""
            },
            "b28cbfb9b69e68d070f8fef5ddd2bbabb6e410ebeb0905b917dfd8eb103d85a3": {
                "Name": "inspiring_archimedes",
                "EndpointID": "80afb91170ab08def612373bf78be60609dbb173bb3d57b3abda7b578ff001cc",
                "MacAddress": "02:42:ac:14:00:03",
                "IPv4Address": "172.20.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```
下面的命令断开redis容器与前端网络的连接。

```bash
$ docker network disconnect frontend-network redis
```
---
## 10. 使用卷持久化存储
### 10.1 --volumes，-v
在启动容器时创建和分配Docker卷。数据卷允许将主机目录映射到容器，以便共享数据。

这种映射是双向的。它允许从容器内部访问存储在主机上的数据。这还意味着进程在容器内保存的数据会持久化到主机上。

这个例子将使用Redis作为一种持久化数据的方法。在下面启动一个Redis容器，并使用-v参数创建一个数据卷。它指定容器中保存到/data目录中的任何数据都应该持久化到主机的`/docker/redis-data`目录中。

```bash
 docker run  -v /docker/redis-data:/data  --name r1 -d redis redis-server --appendonly yes
```
我们可以使用下面的命令将数据输送到Redis实例中。

```bash
$ cat data | docker exec -i r1 redis-cli --pipe
All data transferred. Waiting for the last reply...
Last reply received from server.
errors: 0, replies: 1
```

Redis会将这些数据保存到磁盘。在主机上，我们可以调查应该包含Redis数据文件的映射直接。

```bash
$ ls /docker/redis-data
appendonly.aof
```
这个目录可以挂载到第二个容器。一种用法是让Docker容器对数据执行备份操作。

```bash
$  docker run  -v /docker/redis-data:/backup ubuntu ls /backup
appendonly.aof
```
### 10.2 --volumes-from
数据卷映射给主机有利于数据持久化。然而，要从另一个容器访问它们，您需要知道容易出错的确切路径。

另一种方法是使用`-volumes-from`。该参数将映射卷从源容器映射到正在启动的容器。

在这个例子中，我们将Redis容器的卷映射到Ubuntu容器。`/data`目录只存在于我们的Redis容器中，然而，因为`-volumes-from`,Ubuntu容器可以访问数据。

```bash
$  docker run --volumes-from r1 -it ubuntu ls /data
appendonly.aof
```
这允许我们访问来自其他容器的卷，而不必关心它们是如何在主机上持久化的。

###  10.3 只读卷
挂载卷使容器对目录具有完全的读和写访问权限。通过对挂载目录添加“ro”权限，可以对该目录设置只读权限。如果容器试图修改目录中的数据，则会出错。

```bash
$ docker run -v /docker/redis-data:/data:ro -it ubuntu rm -rf /data
rm: cannot remove '/data/appendonly.aof': Read-only file system
```
---
## 11. 管理日志
当你启动一个容器时，Docker将跟踪进程的`Standard Out`和`Standard Error`输出，并通过客户端使它们可用。
在后台，有一个名为Redis -server的Redis实例运行。通过使用Docker客户端，我们可以访问标准输出和标准错误输出

```bash
$ docker logs redis-server
```
默认情况下，Docker日志使用`JSON -file`记录器输出，这意味着输出存储在主机上的JSON文件中。这可能会导致大文件填满磁盘。因此，您可以更改日志驱动程序以移动到不同的目的地。

`Syslog`日志驱动程序将所有容器日志写到主机的中央Syslog日志中。syslog是一种广泛使用的消息记录标准。它允许生成消息的软件、存储消息的系统以及报告和分析消息的软件分离。

此日志驱动程序设计用于外部系统收集和聚合syslog日志。下面的命令将redis日志重定向到syslog

```bash
$ docker run -d --name redis-syslog --log-driver=syslog redis
```
如果你试图使用客户端查看日志，你会收到错误FATA[0000] "logs"命令只支持"json-file"日志驱动程序。

相反，您需要通过syslog流访问它们。

第三个选项是禁用容器上的日志记录。这对于在日志记录中非常冗长的容器特别有用。

当容器启动时，只需将`log-driver`设置为`none`。不会记录任何输出。

```bash
docker run -d --name redis-none --log-driver=none redis
```
inspect命令允许您识别特定容器的日志记录配置。下面的命令将为每个容器输出LogConfig部分。

```bash
$ docker inspect --format '{{ .HostConfig.LogConfig }}' redis-server
{json-file map[]}

$ docker inspect --format '{{ .HostConfig.LogConfig }}' redis-syslog
{syslog map[]}

$ docker inspect --format '{{ .HostConfig.LogConfig }}' redis-none
{none map[]}
```
---

##  12. 容器运行策略
Docker认为任何带有非零退出代码的容器都崩溃了。默认情况下，崩溃的容器将保持停止状态。

我们已经创建了一个特殊的容器，它输出一条消息，然后使用代码1退出，以模拟崩溃。

```bash
docker run -d --name restart-default scrapbook/docker-restart-example
```
如果列出所有的容器，包括stopped，您将看到容器已经崩溃

```bash
$ docker ps -a
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                     PORTS               NAMES
39ef0a052236        scrapbook/docker-restart-example   "/bin/sh -c ./launch…"   5 seconds ago       Exited (1) 2 seconds ago                       restart-default
```
而日志将输出我们的消息，这在现实生活中可能会提供帮助我们诊断问题的信息。

```bash
$ docker logs restart-default
Tue Sep 28 13:41:39 UTC 2021 Booting up...
```
根据您的场景，重新启动失败的进程可能会纠正这个问题。Docker可以在停止尝试之前自动重试启动Docker特定次数。
他的选项`--restart=on-failure`:#允许你说Docker应该重试多少次。在下面的示例中，Docker将在停止之前重新启动容器三次。

```bash
$ docker run -d --name restart-3 --restart=on-failure:3 scrapbook/docker-restart-example

$ docker logs restart-3
Tue Sep 28 13:42:44 UTC 2021 Booting up...
Tue Sep 28 13:42:46 UTC 2021 Booting up...
Tue Sep 28 13:42:50 UTC 2021 Booting up...
Tue Sep 28 13:42:53 UTC 2021 Booting up...
```
最后，Docker总是可以重新启动失败的容器，在这种情况下，Docker将一直尝试，直到容器被明确告知停止。

例如，当容器崩溃时，使用always标志自动重新启动容器

```bash
$ docker run -d --name restart-always --restart=always scrapbook/docker-restart-example

$ docker logs restart-always
```

---
## 13. 容器元数据与标签
当容器通过docker运行启动时，标签可以被附加到容器上。一个容器可以在任何时候有多个标签。

注意，在这个例子中，因为我们使用的标签是用于CLI，而不是一个自动化的工具，所以我们没有使用DNS表示法格式。

要添加单个标签，可以使用`l =<value>`选项。下面的示例为容器分配了一个名为`user`的带有ID的标签。这将允许我们查询与该特定用户相关的所有正在运行的容器。

```bash
docker run -l user=12345 -d redis
```
如果您正在添加多个标签，那么这些标签可以来自外部文件。文件的每一行都需要有一个标签，然后这些标签将被附加到正在运行的容器上。

这一行在文件中创建了两个标签，一个用于用户，另一个用于分配角色。

```bash
echo 'user=123461' >> labels && echo 'role=cache' >> labels
```
The `--label-file=<filename>` option will create a label for each line in the file.

```bash
 docker run --label-file=labels -d redis
```
标签镜像的工作方式与容器相同，但在构建镜像时在Dockerfile中设置。当容器启动时，镜像的标签将应用到容器实例。

在一个Dockerfile中，你可以使用label指令分配一个标签。在标签下面创建名为“剪贴簿”的供应商。

```bash
LABEL vendor=Katacoda
```
如果我们想要分配多个标签，可以使用下面的格式，每行都有一个标签，使用反斜杠("\")连接。注意，我们使用的是与第三方工具相关的DNS标记格式。

```bash
LABEL vendor=Katacoda \ 
com.katacoda.version=0.0.5 \
com.katacoda.build-date=2016-07-01T10:47:29Z \
com.katacoda.course=Docker
```
标签和元数据只有在您可以稍后查看/查询它们时才有用。查看特定容器或镜像的所有标签的第一种方法是使用`docker inspect`。

环境已经为您创建了一个名为`rd`的容器和一个名为`katacoda-label-example`的映像。

通过提供运行容器的友好名称或哈希id，您可以查询它的所有元数据。

```bash
docker inspect rd
```

使用`-f`选项，您可以过滤JSON响应，只针对我们感兴趣的标签部分。

```bash
$ docker inspect -f "{{json .Config.Labels }}" rd
{"com.katacoda.created":"automatically","com.katacoda.private-msg":"magic","user":"scrapbook"}
```
检查镜像的方法是一样的，但是JSON格式略有不同，将其命名为`ContainerConfig`而不是`Config`。

```bash
$ docker inspect -f "{{json .ContainerConfig.Labels }}" katacoda-label-example
{"com.katacoda.build-date":"2015-07-01T10:47:29Z","com.katacoda.course":"Docker","com.katacoda.private-msg":"HelloWorld","com.katacoda.version":"0.0.5","vendor":"Katacoda"}
```
这些标签将保留，即使镜像已被取消标记。当镜像未被标记时，它的名称将为`<none>.`


虽然检查单个容器和映像可以为您提供更多的上下文，但在运行数千个容器的生产中，限制对您感兴趣的容器的响应是很有用的。

`docker ps`命令允许您根据标签名称和值指定一个过滤器。例如，下面的查询将返回所有具有值katacoda的用户标签键的容器。

```bash
$ docker ps --filter "label=user=scrapbook"
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
0c0d9b5b90ed        redis               "docker-entrypoint.s…"   8 minutes ago       Up 8 minutes        6379/tcp            rd
```
基于构建镜像时使用的标签，可以对镜像应用相同的过滤方法。

```bash
$ docker images --filter "label=vendor=Katacoda"
REPOSITORY               TAG                 IMAGE ID            CREATED             SIZE
katacoda-label-example   latest              33a1689f8704        8 minutes ago       112MB
```
标签不仅适用于图像和容器，也适用于`Docker Daemon`本身。当您启动守护进程的实例时，可以为它分配标签，以帮助确定应该如何使用它，例如，它是开发服务器还是生产服务器，或者它是否更适合运行数据库等特定角色。

```bash
docker -d \
  -H unix:///var/run/docker.sock \
  --label com.katacoda.environment="production" \
  --label com.katacoda.storage="ssd"
```
---
##  14. 负载平衡的容器
###  14.1 NGINX Proxy
在这个场景中，我们希望运行一个NGINX服务，它可以在加载新容器时动态发现和更新它的负载平衡配置。我们已经创建了`nginx-proxy`。

`Nginx-proxy`接受HTTP请求，并根据请求主机名将请求代理到相应的容器。这对用户是透明的，不会产生任何额外的性能开销。

在启动代理容器时，需要配置三个键属性。

 - 第一种方法是使用`-p 80:80`将容器绑定到主机上的80端口。这确保了所有HTTP请求都由代理处理。
 - 第二步是挂载`docker.sock`文件。这是一个与运行在主机上的Docker守护进程的连接，允许容器通过API访问它的元数据。NGINX-proxy使用这个来监听事件，然后根据容器的IP地址更新NGINX配置。挂载文件的工作方式与使用`-v /var/run/docker.sock:/tmp/docker.sock:ro`的目录相同。指定:ro将访问限制为只读。
 - 最后，我们可以设置一个可选的`-e DEFAULTHOST=<domain>`。如果传入的请求没有生成任何指定的主机，则该容器将处理请求。这使您能够在一台机器上运行多个具有不同域的网站，并可返回到一个已知的网站。


使用下面的命令启动nginx-proxy。

```bash
docker run -d -p 80:80 -e DEFAULT_HOST=proxy.example -v /var/run/docker.sock:/tmp/docker.sock:ro --name nginx jwilder/nginx-proxy
```
：因为我们使用的是`DEFAULT_HOST`，所以任何传入的请求都将被定向到已经分配了HOST代理的容器。

您可以使用`curl http://ip`向web服务器发出请求。由于我们没有容器，它将返回一个503错误。

```bash
$ curl http://ip
<html>
<head><title>503 Service Temporarily Unavailable</title></head>
<body>
<center><h1>503 Service Temporarily Unavailable</h1></center>
<hr><center>nginx</center>
</body>
</html>
```
### 14.2 单机
`Nginx-proxy`现在正在监听Docker在启动/停止时引发的事件。一个名为`katacoda/docker-http-server`的示例网站已经创建，它将返回运行它的机器名。这允许我们测试我们的代理是否按照预期工作。它的内部是一个PHP和Apache2应用程序，侦听端口80。

为了让Nginx-proxy开始向容器发送请求，你需要指定`VIRTUAL_HOST`环境变量。这个变量定义了请求来自的域，并且应该由容器处理。

在这个场景中，我们将把我们的`HOST`设置为与`DEFAULT_HOST`匹配，这样它将接受所有请求。

```bash
 docker run -d -p 80 -e VIRTUAL_HOST=proxy.example katacoda/docker-http-server
```
有时，NGINX需要几秒钟的时间来重新加载，但如果我们使用`curl http://ip`执行一个请求到我们的代理，那么请求将由我们的容器处理。

```bash
$ curl http://ip
<h1>This request was processed by host: a6b180c03df3</h1>
```
### 14.2 集群
现在，我们已经成功地创建了一个容器来处理HTTP请求。如果我们用相同的`VIRTUAL_HOST`启动第二个容器，那么nginx-proxy将在一个循环负载平衡的场景中配置系统。这意味着第一个请求将发送到一个容器，第二个请求将发送到第二个容器，然后循环重复。您可以运行的节点数量没有限制。

使用与前面相同的命令启动第二个容器或者第三个

```bash
 docker run -d -p 80 -e VIRTUAL_HOST=proxy.example katacoda/docker-http-server
 docker run -d -p 80 -e VIRTUAL_HOST=proxy.example katacoda/docker-http-server
```
如果使用`curl http://ip`执行对代理的请求，则请求将由第一个容器处理。第二个HTTP请求将返回不同的机器名，这意味着它是由第二个容器处理的。

```bash
$ curl http://ip
<h1>This request was processed by host: ac2c0ef08655</h1>
$ curl http://ip
<h1>This request was processed by host: a6b180c03df3</h1>
```
当NGINX -proxy为我们自动创建和配置NGINX时，如果你对最终的配置感兴趣，你可以使用docker exec输出完整的配置文件，如下所示。

```bash
docker exec nginx cat /etc/nginx/conf.d/default.conf
```
关于何时重新加载配置的附加信息可以在使用

```bash
docker logs nginx
```
---
##  15. 编排docker-compose
Docker Compose是基于`docker-compose.yml`文件。该文件定义启动集群集所需的所有容器和设置。属性映射到您如何使用docker运行命令.
格式yaml：

```bash
container_name:
  property: value
    - or options
```
在这个场景中，我们有一个需要连接到Redis的`Node.js`应用程序。首先，我们需要定义`docker-compose.yml`文件来启动Node.js应用程序。

根据上面的格式，文件需要将容器命名为“`web`”，并将构建属性设置为当前目录。我们将在以后的步骤中介绍其他属性。

将下列yaml复制到编辑器中。这将定义一个名为web的容器，它基于当前目录的构建。

```bash
web:
  build: .
```
Docker Compose支持所有可以使用`Docker run`定义的属性。将两个容器链接在一起以指定links属性并列出所需连接。例如，下面将链接到相同文件中定义的redis源容器，并将相同的名称分配给别名。

```bash
  links:
    - redis
```
同样的格式用于端口等其他属性,有关选项的其他文档可在以下网址找到
[https://docs.docker.com/compose/compose-file/](https://docs.docker.com/compose/compose-file/)

更新我们的web容器，以暴露`3001`端口，并创建一个链接到我们的Redis容器。

在上一步中，我们使用当前目录中的`Dockerfile`作为容器的基础。在此步骤中，我们希望使用来自`Docker Hub`的现有映像作为第二个容器。

要找到第二个容器，只需在新行上使用与前面相同的格式。YAML格式非常灵活，可以在同一个文件中定义多个容器。

定义第二个名称为`redis`的容器，它使用镜像`redis`。按照`YAML`格式，容器的详细信息如下:

```bash
redis:
  image: redis:alpine
  volumes:
    - /var/redis/data:/data
```
使用创建的`docker-compose.yml`文件就绪后，您可以使用一个up命令启动所有应用程序。如果您想调出单个容器，那么您可以使用`<name>`。

参数`-d`表示在后台运行容器，类似于与`docker run`一起使用。

```bash
$ ls
Dockerfile  Makefile  docker-compose.yml  node_modules  package.json  server.js

$ cat Dockerfile 
FROM ocelotuproar/alpine-node:5.7.1-onbuild
EXPOSE 3000

$ cat docker-compose.yml 
web:
  build: .

  links:
    - redis

  ports:
    - "3000"
    - "8000"

redis:
  image: redis:alpine
  volumes:
    - /var/redis/data:/data
```


```bash
启动部署运行
$ docker-compose up -d

$ docker-compose ps
      Name                    Command               State                        Ports                      
------------------------------------------------------------------------------------------------------------
tutorial_redis_1   docker-entrypoint.sh redis ...   Up      6379/tcp                                        
tutorial_web_1     npm start                        Up      0.0.0.0:32769->3000/tcp, 0.0.0.0:32768->8000/tcp

#查看日志
$ docker-compose logs
```
由于Docker Compose理解如何启动应用程序容器，所以它还可以用于扩展正在运行的容器数量。`scale`选项允许指定服务，然后指定所需的实例数量。如果数量大于已经运行的实例，那么它将启动额外的容器。如果数量较少，那么它将停止不需要的容器。

使用该命令扩展正在运行的web容器的数量

```bash
$ docker-compose scale web=3
WARNING: The scale command is deprecated. Use the up command with the --scale flag instead.
Starting tutorial_web_1 ... done
Creating tutorial_web_2 ... done
Creating tutorial_web_3 ... done
```
你可以减少使用

```bash
$ docker-compose scale web=1
WARNING: The scale command is deprecated. Use the up command with the --scale flag instead.
Stopping and removing tutorial_web_2 ... done
Stopping and removing tutorial_web_3 ... done
```
与启动应用程序时一样，要停止一组容器，可以使用该命令

```bash
$ docker-compose stop
```
要删除所有容器，请使用此命令

```bash
$ docker-compose rm
```

---
## 16. docker stats统计信息
环境中有一个名为nginx的容器运行。你可以通过以下方法找到容器的统计信息:

```bash
$ docker stats nginx
CONTAINER ID        NAME                CPU %               MEM USAGE / LIMIT     MEM %               NET I/O             BLOCK I/O           PIDS
048931bbead9        nginx               0.12%               17.21MiB / 737.6MiB   2.33%               7.73kB / 484B       0B / 16.4kB         17
```
这将启动一个终端窗口，该窗口使用来自容器的实时数据来刷新自身。如果需要退出，请使用`CTRL+C`停止正在运行的进程。
内置的Docker允许你提供多个名称/id，并在一个窗口中显示它们的统计信息。

环境现在有三个连接的容器在运行。要查看所有这些容器的统计信息，可以使用管道和`xargs`。管道将一个命令的输出传递到另一个命令的输入，而xargs允许您将该输入作为参数提供给命令。

通过结合这两种方法，我们可以获取由`docker ps`提供的所有正在运行的容器的列表，并将它们用作`docker stats`的参数。这让我们对整个机器的容器有了一个概述。

```bash
$ docker ps -q | xargs docker stats
```
---
##  17. dockerfile多阶段构建创建优化docker镜像
多阶段特性允许一个Dockerfile包含多个阶段，以生成所需的、优化的Docker映像。

在此之前，这个问题是通过两个dockerfile解决的。一个文件将包含使用开发容器构建二进制文件和工件的步骤，第二个文件将针对生产进行优化，不包括开发工具。

通过在生产映像中删除开发工具，可以重新生成攻击面并改进部署时间。

首先部署一个示例Golang HTTP服务器。目前使用的是两阶段的Docker构建方法。这个场景将创建一个新的Dockerfile，允许使用单个命令构建映像。

```bash
git clone https://github.com/katacoda/golang-http-server.git
```
使用编辑器，创建一个多阶段`Dockerfile`。第一阶段使用`Golang SDK`构建二进制文件。第二阶段将生成的二进制文件复制到一个优化的Docker镜像中。

```bash
# First Stage
FROM golang:1.6-alpine

RUN mkdir /app
ADD . /app/
WORKDIR /app
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Second Stage
FROM alpine
EXPOSE 80
CMD ["/app"]

# Copy from first stage
COPY --from=0 /app/main /app
```
目前有一些关于改进语法的讨论，您可以参阅[https://github.com/docker/docker/pull/31257](https://github.com/docker/docker/pull/31257)

Dockerfile的新语法到位后，构建过程与前面相同。使用下面的build命令创建所需的Docker镜像。

```bash
docker build -f Dockerfile.multi -t golang-app .
```
结果将是两个镜像。一个是第一阶段使用的未标记的镜像，另一个是较小的镜像，也是我们的目标镜像。

如果你收到错误，`COPY --from=0 /build/out /app/ Unknown flag: from`，这意味着你正在运行一个没有多阶段支持的旧版本的Docker。本场景的步骤1升级当前Docker版本。

可以启动和部署镜像，而不需要进行任何更改。

```bash
$docker run -d -p 80:80 golang-app

$ curl localhost
<h1>This request was processed by host: 178cf19ec6e9</h1>
```

---
##  18. docker ps输出格式

```bash
$ docker run -d redis
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
1bf198e56506        redis               "docker-entrypoint.s…"   22 seconds ago      Up 18 seconds       6379/tcp            angry_northcutt

# --format方法
$ docker ps --format '{{.Names}} container is using {{.Image}} image'
angry_northcutt container is using redis image

$ docker ps --format 'table {{.Names}}\t{{.Image}}'
NAMES               IMAGE
angry_northcutt     redis
```
然而，format参数允许显示通过docker ps命令已经暴露的数据。如果您想包含额外的信息，比如容器的IP地址，那么数据需要通过`docker inspect`来获取。然后，format参数可以访问所有容器信息。下面是列出正在运行的容器的所有IP地址的示例。

```bash
$ docker ps -q | xargs docker inspect --format '{{ .Id }} - {{ .Name }} - {{ .NetworkSettings.IPAddress }}'
1bf198e565063b29b75341cf958536482d2e6ad605a8032d0572e2b1770ab924 - /angry_northcutt - 172.18.0.2
```
---
##  19. Docker非root特权配置
该环境当前运行的是Ubuntu 16.04，用户以root身份登录。第一步是创建一个没有这些root特权的新用户，这意味着他们将以更高的安全性运行，并且不能对系统进行关键更改。

`useradd` 命令将创建一个具有默认权限的用户。在终端上执行命令，添加一个名为`lowprivuser`的新用户。这个用户可以被称为任何名称。

```bash
$ useradd -m -d /home/lowprivuser -p $(openssl passwd -1 password) lowprivuser
```
使用'`sudo su` '，可以切换到以这个新的低权限用户运行。

```bash
$ sudo su lowprivuser
lowprivuser@host01:/root$
```
当作为该用户运行时，一些项会发生变化。例如，用户无法在某些位置(如根目录)创建或更改文件，

```bash
lowprivuser@host01:/root$ touch /root/blocked
touch: cannot touch '/root/blocked': Permission denied
```
户也无法访问Docker，因为之前这需要他们有根权限。

```bash
lowprivuser@host01:/root$ docker ps
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.40/containers/json: dial unix /var/run/docker.sock: connect: permission denied
```
在下一步中，我们将部署新的`Rootless`版本，并允许用户启动自己的容器。Docker提供了一个脚本，用于部署新的`Rootless`版本所需的组件。

使用`lowprivuser`命令执行脚本，安装组件。

```bash
lowprivuser@host01:/root$ curl -sSL https://get.docker.com/rootless | sh
# Installing stable version 20.10.8
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 58.1M  100 58.1M    0     0  55.4M      0  0:00:01  0:00:01 --:--:-- 55.5M
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 18.0M  100 18.0M    0     0  35.2M      0 --:--:-- --:--:-- --:--:-- 35.2M
+ PATH=/home/lowprivuser/bin:/root/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games /home/lowprivuser/bin/dockerd-rootless-setuptool.sh install
[INFO] systemd not detected, dockerd-rootless.sh needs to be started manually:

PATH=/home/lowprivuser/bin:/sbin:/usr/sbin:$PATH dockerd-rootless.sh 

[INFO] Creating CLI context "rootless"
Successfully created context "rootless"

[INFO] Make sure the following environment variables are set (or add them to ~/.bashrc):

# WARNING: systemd not found. You have to remove XDG_RUNTIME_DIR manually on every logout.
export XDG_RUNTIME_DIR=/home/lowprivuser/.docker/run
export PATH=/home/lowprivuser/bin:$PATH
export DOCKER_HOST=unix:///home/lowprivuser/.docker/run/docker.sock
```
完成这一步之后，继续下一步，设置用户环境并开始启动容器。

现在已经安装了 `rootless Docker`。可以使用以下脚本启动守护进程:

```bash
export XDG_RUNTIME_DIR=/tmp/docker-1001
export PATH=/home/lowprivuser/bin:$PATH
export DOCKER_HOST=unix:///tmp/docker-1001/docker.sock
mkdir -p $XDG_RUNTIME_DIR

/home/lowprivuser/bin/dockerd-rootless.sh --experimental --storage-driver vfs
```
这将在前台运行，并允许您查看来自rootless Docker守护进程的调试输出。

单击以下命令启动第二个终端窗口，以lowprivuser用户登录

```bash
sudo lowprivuser

```
要访问Docker，请设置以下环境变量。它指定了对id为1001的用户运行的Docker实例的连接，该连接应该与lowprivuser的id匹配。

```bash
export XDG_RUNTIME_DIR=/tmp/docker-1001
export PATH=/home/lowprivuser/bin:$PATH
export DOCKER_HOST=unix:///tmp/docker-1001/docker.sock
```
在下一步中，我们可以启动容器。

现在可以访问用户`1001`运行的Docker守护进程。
标准的Docker CLI命令的工作方式与此相同。下面的命令列出了为用户运行的所有容器，目前它应该返回一个空列表。

```bash
$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```
可以查看Daemon运行的细节:

```bash
docker info
docker run -it ubuntu bash
root@002495da35fe:/# id
uid=0(root) gid=0(root) groups=0(root)
```
容器内的用户仍然被报告为root。他们将能够安装包和修改Docker内部运行的部分系统。然而，如果它们设法逃脱，它们将无法干扰宿主。

在单独的终端窗口中，宿主机root用户可以查看哪些进程正在运行，哪些用户启动了它们。使用`ps aux`可以验证我们的新容器实例是由低特权用户管理和拥有的。

```bash
$ id; ps aux | grep lowprivuser
uid=0(root) gid=0(root) groups=0(root)
root     21016  0.0  0.2  52700  3940 pts/0    S    03:18   0:00 sudo su lowprivuser
root     21017  0.0  0.2  52280  3540 pts/0    S    03:18   0:00 su lowprivuser
lowpriv+ 21145  0.0  0.4 710816  6912 pts/0    Sl+  03:22   0:00 rootlesskit --net=vpnkit --mtu=1500 --slirp4netns-sandbox=auto --slirp4netns-seccomp=auto --disable-host-loopback --port-driver=builtin --copy-up=/etc --copy-up=/run --propagation=rslave /home/lowprivuser/bin/dockerd-rootless.sh --experimental --storage-driver vfs
lowpriv+ 21150  0.5  0.7 711712 12228 pts/0    Sl+  03:22   0:01 /proc/self/exe --net=vpnkit --mtu=1500 --slirp4netns-sandbox=auto --slirp4netns-seccomp=auto --disable-host-loopback --port-driver=builtin --copy-up=/etc --copy-up=/run --propagation=rslave /home/lowprivuser/bin/dockerd-rootless.sh --experimental --storage-driver vfs
lowpriv+ 21430  0.0  0.5 711432  8612 ?        Sl   03:26   0:00 /home/lowprivuser/bin/containerd-shim-runc-v2 -namespace moby -id 002495da35fe1431fd79e2dda1bf3447c7d4d9890220067324c9d64aa0f30e9f -address /tmp/docker-1001/docker/containerd/containerd.sock
root     21532  0.0  0.0  14224   920 pts/2    S+   03:27   0:00 grep --color=auto lowprivuser
```
系统现在运行Docker容器，不需要任何额外的权限，允许我们的系统以更高的安全性操作。

相关阅读：

 - [**docker 快速学习手册**](https://ghostwritten.blog.csdn.net/article/details/119462437)
 - [**docker 的冷门高效玩法**](https://ghostwritten.blog.csdn.net/article/details/120494295)
 - [**docker 命令使用大全**](https://ghostwritten.blog.csdn.net/article/details/105926041)


