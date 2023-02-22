# 原理

## 一、简介

### 1、了解 Docker 的前生 LXC
LXC 为 Linux Container 的简写。可以提供轻量级的虚拟化，以便隔离进程和资源，而且不需要提供指令解释机制以及全虚拟化的其他复杂性。相当于 C++ 中的 NameSpace。容器有效地将由单个操作系统管理的资源划分到孤立的组中，以更好地在孤立的组之间平衡有冲突的资源使用需求。

与传统虚拟化技术相比，它的优势在于：

 1. 与宿主机使用同一个内核，性能损耗小；
 2. 不需要指令级模拟；
 3. 不需要即时(Just-in-time)编译；
 4. 容器可以在 CPU 核心的本地运行指令，不需要任何专门的解释机制；
 5. 避免了准虚拟化和系统调用替换中的复杂性；
 6. 轻量级隔离，在隔离的同时还提供共享机制，以实现容器与宿主机的资源共享。

**总结：Linux Container 是一种轻量级的虚拟化的手段。**

Linux Container 提供了在单一可控主机节点上支持多个相互隔离的server container 同时执行的机制。Linux Container 有点像 chroot，提供了一个拥有自己进程和网络空间的虚拟环境，但又有别于虚拟机，因为 lxc 是一种操作系统层次上的资源的虚拟化。

### 2、LXC 与 docker 什么关系？
docker 并不是 LXC 替代品，docker 底层使用了 LXC 来实现，LXC 将 linux 进程沙盒化，使得进程之间相互隔离，并且能够课哦内阁制各进程的资源分配。

在 LXC 的基础之上，docker 提供了一系列更强大的功能。

### 3、什么是 docker
docker 是一个开源的应用容器引擎，基于 `go` 语言开发并遵循了 `apache2.0` 协议开源。

docker 可以让开发者打包他们的应用以及依赖包到一个轻量级、可移植的容器中，然后发布到任何流行的 linux 服务器，也可以实现虚拟化。

容器是完全使用沙箱机制，相互之间不会有任何接口（类 iphone 的 app），并且容器开销极其低。

### 4、docker 官方文档
[https://docs.docker.com/](https://docs.docker.com/)
### 5、为什么docker越来越受欢迎
官方话语：容器化越来越受欢迎，因为容器是：

```bash
灵活：即使是最复杂的应用也可以集装箱化。
轻量级：容器利用并共享主机内核。
可互换：您可以即时部署更新和升级。
便携式：您可以在本地构建，部署到云，并在任何地方运行。
可扩展：您可以增加并自动分发容器副本。
可堆叠：您可以垂直和即时堆叠服务。
```
**镜像和容器（contalners）**
通过镜像启动一个容器，一个镜像是一个可执行的包，其中包括运行应用程序所需要的所有内容包含代码，运行时间，库、环境变量、和配置文件。容器是镜像的运行实例，当被运行时有镜像状态和用户进程，可以使用 docker ps 查看。

**容器和虚拟机**

容器时在 linux 上本机运行，并与其他容器共享主机的内核，它运行的一个独立的进程，不占用其他任何可执行文件的内存，非常轻量。

虚拟机运行的是一个完成的操作系统，通过虚拟机管理程序对主机资源进行虚拟访问，相比之下需要的资源更多。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200317164822581.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)
### 6、docker 版本
Docker Community Edition（CE）社区版
Enterprise Edition(EE) 商业版
### 7、docker 和 openstack 对比
![在这里插入图片描述](https://img-blog.csdnimg.cn/2020031716532830.png)

### 8、容器在内核中支持 2 种重要技术

docker 本质就是宿主机的一个进程，docker 是通过 `namespace` 实现资源隔离，通过 `cgroup` 实现资源限制，通过写时复制技术（`copy-on-write`）实现了高效的文件操作（类似虚拟机的磁盘比如分配 500g 并不是实际占用物理磁盘500g）
#### 1.namespaces 名称空间

linux namespace是提供资源隔离的方案

 - 系统可为进程分配不同的namespace
 - 进程隔离，资源隔离

![在这里插入图片描述](https://img-blog.csdnimg.cn/0a2107337ea34514b8ff2c794f87656f.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_20,color_FFFFFF,t_70,g_se,x_16)
![在这里插入图片描述](https://img-blog.csdnimg.cn/62076ac577ef48ed8c531bd4213b5676.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_20,color_FFFFFF,t_70,g_se,x_16)



![在这里插入图片描述](https://img-blog.csdnimg.cn/20200317165513621.png)
#### 2.control Group 控制组

cgroup 的特点是：

 - cgroup 的 api 以一个伪文件系统的实现方式，用户的程序可以通过文件系统实现 cgroup 的组件管理
 - cgroup 的组件管理操作单元可以细粒度到线程级别，另外用户可以创建和销毁 cgroup，从而实现资源载分配和再利用
 - 所有资源管理的功能都以子系统的方式实现，接口统一子任务创建之初与其父任务处于同一个 cgroup 的控制组

四大功能：

 - 资源限制：可以对任务使用的资源总额进行限制
 - 优先级分配：通过分配的 cpu 时间片数量以及磁盘 IO 带宽大小，实际上相当于控制了任务运行优先级
 - 资源统计：可以统计系统的资源使用量，如 cpu 时长，内存用量等
 - 任务控制：cgroup 可以对任务执行挂起、恢复等操作
### 9、了解 docker 三个重要概念
#### 1.image 镜像

docker 镜像就是一个只读模板，比如，一个镜像可以包含一个完整的 centos，里面仅安装 apache 或用户的其他应用，镜像可以用来创建 docker 容器，另外 docker 提供了一个很简单的机制来创建镜像或者更新现有的镜像，用户甚至可以直接从其他人那里下周一个已经做好的镜像来直接使用

#### 2.container 容器

docker 利用容器来运行应用，容器是从镜像创建的运行实例，它可以被启动，开始、停止、删除、每个容器都是互相隔离的，保证安全的平台，可以吧容器看做是要给简易版的 linux 环境（包括 root 用户权限、镜像空间、用户空间和网络空间等）和运行再其中的应用程序

#### 3.repostory 仓库

仓库是集中存储镜像文件的沧桑，registry 是仓库主从服务器，实际上参考注册服务器上存放着多个仓库，每个仓库中又包含了多个镜像，每个镜像有不同的标签（tag）

仓库分为两种，公有参考，和私有仓库，最大的公开仓库是 `docker Hub`，存放了数量庞大的镜像供用户下载，国内的 docker pool，这里仓库的概念与 Git 类似，`registry` 可以理解为 github 这样的托管服务。

### 10、docker 的主要用途
官方就是 Bulid 、ship、run any app/any where，编译、装载、运行、任何 app/在任意地放都能运行。

就是实现了应用的封装、部署、运行的生命周期管理只要在 glibc 的环境下，都可以运行。

运维生成环境中：docker 化。

 - 发布服务不用担心服务器的运行环境，所有的服务器都是自动分配 docker，
 - 自动部署，自动安装，自动运行
 - 再不用担心其他服务引擎的磁盘问题，cpu 问题，系统问题了
 - 资源利用更出色
 - 自动迁移，可以制作镜像，迁移使用自定义的镜像即可迁移，不会出现什么问题
 - 管理更加方便了
### 11、docker 改变了什么

```bash
面向产品：产品交付
面向开发：简化环境配置
面向测试：多版本测试
面向运维：环境一致性
面向架构：自动化扩容（微服务）
```

## 二、docker 架构
### 1、总体架构
![在这里插入图片描述](https://img-blog.csdnimg.cn/2020031717023073.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)

 - distribution 负责与 docker registry 交互，上传洗澡镜像以及 v2 registry 有关的源数据
 - registry 负责 docker registry 有关的身份认证、镜像查找、镜像验证以及管理
 - registry mirror 等交互操作
 - image 负责与镜像源数据有关的存储、查找，镜像层的索引、查找以及镜像 tar 包有关的导入、导出操作
 - reference 负责存储本地所有镜像的 repository 和 tag 名，并维护与镜像 id 之间的映射关系
 - layer 模块负责与镜像层和容器层源数据有关的增删改查，并负责将镜像层的增删改查映射到实际存储镜像层文件的 graphdriver 模块
 - graghdriver 是所有与容器镜像相关操作的执行者

### 2、docker 架构 2
如果觉得上面架构图比较乱可以看这个架构：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200317170652961.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)
从上图不难看出，用户是使用 `Docker Client` 与 `Docker Daemon` 建立通信，并发送请求给后者。

而 `Docker Daemon` 作为 Docker 架构中的主体部分，首先提供 `Server` 的功能使其可以接受 `Docker Client` 的请求；而后 `Engine` 执行 Docker 内部的一系列工作，每一项工作都是以一个 `Job` 的形式的存在。

Job 的运行过程中，当需要容器镜像时，则从 `Docker Registry` 中下载镜像，并通过镜像管理驱动 `graphdriver` 将下载镜像以 `Graph` 的形式存储；当需要为 Docker 创建网络环境时，通过网络管理驱动 `networkdriver` 创建并配置 Docker 容器网络环境；当需要限制 Docker 容器运行资源或执行用户指令等操作时，则通过 `execdriver` 来完成。

而 `libcontainer` 是一项独立的容器管理包，`networkdriver` 以及 `execdriver` 都是通过 `libcontainer` 来实现具体对容器进行的操作。当执行完运行容器的命令后，一个实际的 Docker 容器就处于运行状态，该容器拥有独立的文件系统，独立并且安全的运行环境等。
### 3、docker 架构 3
再来看看另外一个架构，这个个架构就简单清晰指明了 `server/client` 交互，容器和镜像、数据之间的一些联系。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200317170945947.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)
这个架构图更加清晰了架构

`docker daemon` 就是 docker 的守护进程即 `server` 端，可以是远程的，也可以是本地的，这个不是 `C/S` 架构吗，客户端 `Docker client` 是通过 `rest api` 进行通信。

docker cli 用来管理容器和镜像，客户端提供一个只读镜像，然后通过镜像可以创建多个容器，这些容器可以只是一个 `RFS`（`Root file system`根文件系统），也可以是一个包含了用户应用的 RFS，容器再 docker client 中只是要给进程，两个进程之间互不可见。

用户不能与 server 直接交互，但可以通过与容器这个桥梁来交互，由于是操作系统级别的虚拟技术，中间的损耗几乎可以不计。

## 三、docker 架构 2 各个模块的功能
主要的模块有：`Docker Client`、`Docker Daemon`、`Docker Registry`、`Graph`、`Driver`、`libcontainer` 以及 `Docker container`。

### 1、docker client
`docker client` 是 docker 架构中用户用来和 `docker daemon` 建立通信的客户端，用户使用的可执行文件为 docker，通过 docker 命令行工具可以发起众多管理 container 的请求。

docker client 可以通过一下三种方式和 docker daemon 建立通信：

 - tcp://host:port
 - unix:path_to_socket
 - fd://socketfd。

docker client 可以通过设置命令行 **flag 参数的形式设置安全传输层协议**(TLS)的有关参数，保证传输的安全性。

`docker client` 发送容器管理请求后，由 `docker daemon` 接受并处理请求，当 docker client 接收到返回的请求相应并简单处理后，docker client 一次完整的生命周期就结束了，当需要继续发送容器管理请求时，用户必须再次通过 docker 可以执行文件创建 docker client。

### 2、docker daemon
docker daemon 是 docker 架构中一个常驻在后台的系统进程，功能是：接收处理 docker client 发送的请求。该守护进程在后台启动一个 `server`，server 负载接受 docker client 发送的请求；接受请求后，server 通过路由与分发调度，找到相应的 `handler` 来执行请求。

docker daemon 启动所使用的可执行文件也为 docker，与 docker client 启动所使用的可执行文件 docker 相同，在 docker 命令执行时，通过传入的参数来判别 docker daemon 与 docker client。

docker daemon 的架构可以分为：`docker server、engine、job`。

### 3、docker server
docker server 在 docker 架构中时专门服务于 docker client 的 server，该 server 的功能时：接受并调度分发 docker client 发送的请求，架构图如下：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200317172041595.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)
 在 Docker 的启动过程中，通过包 `gorilla/mux`（golang 的类库解析），创建了一个 `mux.Router`，提供请求的路由功能。在 Golang 中，`gorilla/mux` 是一个强大的 URL 路由器以及调度分发器。该 mux.Router 中添加了众多的路由项，每一个路由项由**HTTP请求方法（PUT、POST、GET或DELETE）、URL、Handler** 三部分组成。

若 Docker Client 通过 HTTP 的形式访问 Docker Daemon，创建完 mux.Router 之后，Docker 将 Server 的监听地址以及 mux.Router 作为参数，创建一个 `httpSrv=http.Server{}`，最终执行 `httpSrv.Serve()` 为请求服务。

在 Server 的服务过程中，Server 在 listener 上接受 Docker Client 的访问请求，并创建一个全新的 `goroutine` 来服务该请求。在 goroutine 中，首先读取请求内容，然后做解析工作，接着找到相应的路由项，随后调用相应的 Handler 来处理该请求，最后 Handler 处理完请求之后回复该请求。

需要注意的是：Docker Server 的运行在 Docker 的启动过程中，是靠一个名为 `serveapi` 的 job 的运行来完成的。原则上，Docker Server 的运行是众多 job 中的一个，但是为了强调 Docker Server 的重要性以及为后续 job 服务的重要特性，将该 serveapi 的 job 单独抽离出来分析，理解为 Docker Server。

### 4、engine
Engine 是 Docker 架构中的运行引擎，同时也 Docker 运行的**核心模块**。它扮演 Docker container 存储仓库的角色，并且通过执行 job 的方式来操纵管理这些容器。

在 Engine 数据结构的设计与实现过程中，有一个 handler 对象。该 handler 对象存储的都是关于众多特定 job 的 handler 处理访问。举例说明，Engine 的 handler 对象中有一项为：`{“create”: daemon.ContainerCreate}`，则说明当名为 create 的 job 在运行时，执行的是 `daemon.ContainerCreate` 的 `handler` 。

### 5、job
一个 Job 可以认为是 Docker 架构中 Engine 内部最基本的工作执行单元。Docker 可以做的每一项工作，都可以抽象为一个 job。例如：在容器内部运行一个进程，这是一个 job；创建一个新的容器，这是一个 job，从 Internet 上下载一个文档，这是一个 job；包括之前在 Docker Server 部分说过的，创建 Server 服务于 HTTP 的 API，这也是一个 job，等等。

Job 的设计者，把 Job 设计得与 Unix 进程相仿。比如说：Job 有一个名称，有参数，有环境变量，有标准的输入输出，有错误处理，有返回状态等。

### 6、docker registry
Docker Registry 是一个存储容器镜像的仓库。而容器镜像是在容器被创建时，被加载用来初始化容器的文件架构与目录。

在 Docker 的运行过程中，`Docker Daemon` 会与 `Docker Registry` 通信，并实现搜索镜像、下载镜像、上传镜像三个功能，这三个功能对应的 job 名称分别为 `search` ， `pull` 与 `push` 。

其中，在 Docker 架构中，Docker 可以使用公有的 Docker Registry ，即大家熟知的 `Docker Hub`，如此一来，Docker 获取容器镜像文件时，必须通过互联网访问 Docker Hub；同时 Docker 也允许用户构建本地私有的 Docker Registry，这样可以保证容器镜像的获取在内网完成。

### 7、Graph
**Graph 在 Docker 架构中扮演已下载容器镜像的保管者，以及已下载容器镜像之间关系的记录者。**一方面，Graph 存储着本地具有版本信息的文件系统镜像，另一方面也通过 GraphDB 记录着所有文件系统镜像彼此之间的关系。
Graph 的架构如下：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200317172452571.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)
其中，`GraphDB` 是一个构建在 `SQLite` 之上的小型图数据库，实现了节点的命名以及节点之间关联关系的记录。它仅仅实现了大多数图数据库所拥有的一个小的子集，但是提供了简单的接口表示节点之间的关系。

同时在 Graph 的本地目录中，关于每一个的容器镜像，具体存储的信息有：**该容器镜像的元数据，容器镜像的大小信息，以及该容器镜像所代表的具体 rootfs**。

### 8、driver
**Driver 是 Docker 架构中的驱动模块。**通过 Driver 驱动，Docker 可以实现对 Docker 容器执行环境的定制。由于 Docker 运行的生命周期中，并非用户所有的操作都是针对 Docker 容器的管理，另外还有关于 Docker 运行信息的获取，Graph 的存储与记录等。因此，为了将 Docker 容器的管理从 Docker Daemon 内部业务逻辑中区分开来，设计了 Driver 层驱动来接管所有这部分请求。

在 Docker Driver 的实现中，可以分为以下三类驱动：

 - graphdriver
 - networkdriver
 - execdriver

**graphdriver 主要用于完成容器镜像的管理，包括存储与获取**。即当用户需要下载指定的容器镜像时，graphdriver 将容器镜像存储在本地的指定目录；同时当用户需要使用指定的容器镜像来创建容器的 rootfs 时，graphdriver 从本地镜像存储目录中获取指定的容器镜像。

在 graphdriver 的初始化过程之前，有 4 种文件系统或类文件系统在其内部注册，它们分别是 `aufs`、`btrfs`、`vfs` 和 `devmapper`。而 Docker 在初始化之时，通过获取系统环境变量 DOCKER_DRIVER 来提取所使用 driver 的指定类型。**而之后所有的 graph 操作，都使用该 driver 来执行**。

graphdriver 的架构如下：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200317172750819.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)

`networkdriver` 的用途是完成 Docker 容器网络环境的配置，其中包括 Docker 启动时为 Docker 环境创建网桥；Docker 容器创建时为其创建专属虚拟网卡设备；以及为 Docker 容器分配 IP、端口并与宿主机做端口映射，设置容器防火墙策略等。networkdriver 的架构如下：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200317172839131.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)
`execdriver` 作为 Docker 容器的执行驱动，**负责创建容器运行命名空间，负责容器资源使用的统计与限制，负责容器内部进程的真正运行等**。在 execdriver 的实现过程中，原先可以使用 LXC 驱动调用 LXC 的接口，来操纵容器的配置以及生命周期，而现在 execdriver 默认使用 `native` 驱动，不依赖于 LXC。

具体体现在 Daemon 启动过程中加载的 `ExecDriverflag` 参数，该参数在配置文件已经被设为 native 。这可以认为是 Docker 在 1.2 版本上一个很大的改变，或者说 Docker 实现跨平台的一个先兆。execdriver 架构如下：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200317173014383.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)
### 9、libcontainer
libcontainer 是 Docker 架构中一个使用 Go 语言设计实现的库，**设计初衷是希望该库可以不依靠任何依赖，直接访问内核中与容器相关的 API。**

正是由于 libcontainer 的存在，Docker 可以直接调用 libcontainer，而最终操纵容器的 `namespace、cgroups、apparmor`、**网络设备以及防火墙规则**等。这一系列操作的完成都不需要依赖LXC或者其他包。libcontainer架构如下![在这里插入图片描述](https://img-blog.csdnimg.cn/20200317173128272.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)
另外，`libcontainer` 提供了一整套标准的接口来满足上层对容器管理的需求。或者说，libcontainer 屏蔽了 Docker 上层对容器的直接管理。又由于 libcontainer 使用 Go 这种跨平台的语言开发实现，且本身又可以被上层多种不同的编程语言访问，因此很难说，未来的 Docker 就一定会紧紧地和 Linux 捆绑在一起。而于此同时，Microsoft 在其著名云计算平台 Azure 中，也添加了对 Docker 的支持，可见 Docker 的开放程度与业界的火热度。

暂不谈 Docker，由于 libcontainer 的功能以及其本身与系统的松耦合特性，很有可能会在其他以容器为原型的平台出现，同时也很有可能催生出云计算领域全新的项目。

### 10、docker container
`Docker container`（Docker容器）是 Docker 架构中服务交付的最终体现形式。

Docker 按照用户的需求与指令，订制相应的 Docker 容器：

 - 用户通过指定容器镜像，使得Docker容器可以自定义 rootfs 等文件系统；
 - 用户通过指定计算资源的配额，使得 Docker 容器使用指定的计算资源；
 - 用户通过配置网络及其安全策略，使得 Docker 容器拥有独立且安全的网络环境；
 - 用户通过指定运行的命令，使得 Docker 容器执行指定的工作。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200317173736319.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)

参考：
 - [docker万字详解](https://mp.weixin.qq.com/s?__biz=MzI1NDY0MTkzNQ==&mid=2247486863&idx=1&sn=d9f2ca6f86676d66620aa45bda9419c6&chksm=e9c35fefdeb4d6f9f4177a34ae869af0add428771e96342a5b61f820ee0cb441a2cf29d40b69&mpshare=1&scene=1&srcid=&sharer_sharetime=1572922732474&sharer_shareid=9e1d0f93025303e47ff2523f5ebf4078&key=f0016e59e9d353a1c927b16e68d48059a300cbef2c22f98539f21d35cd4f02682061bbff091ac0994ee23eae8b33fe793435e69f3356d2eec110f385761c1a9dbd5af380dbcd4f081f90dab52ea22963&ascene=1&uin=MjkwMDAzNTYzOQ==&devicetype=Windows%2010&version=62080079&lang=zh_CN&exportkey=AQGe90GjUFenNwIsZupLDE8=&pass_ticket=/7kx/uLmOCunzqxvArllKJ4VTeFnTz2XWXHdCJH5qlN3b9hHf/QFeHUYilXet1kJ)
