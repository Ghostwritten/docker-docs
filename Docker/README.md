#  Docker Overview
@[toc]

---

##  1. Docker 简介

[Docker](https://www.docker.com/) 是一个用于开发、发布和运行应用程序的开放平台。Docker 使您能够将应用程序与基础架构分离，以便您可以快速交付软件。使用 Docker，您可以像管理应用程序一样管理基础设施。通过利用 Docker 快速交付、测试和部署代码的方法，您可以显着减少编写代码和在生产环境中运行之间的延迟。
## 2. Docker 起源
Docker 最初是 dotCloud 公司创始人 [Solomon Hykes](https://github.com/shykes) 在法国期间发起的一个公司内部项目，它是基于 dotCloud 公司多年云服务技术的一次革新，并于 [2013 年 3 月以 Apache 2.0 授权协议开源](https://en.wikipedia.org/wiki/Docker_%28software%29)，主要项目代码在 [GitHub](https://github.com/moby/moby) 上进行维护。Docker 项目后来还加入了 Linux 基金会，并成立推动 [开放容器联盟（OCI）](https://opencontainers.org/)。

## 3. Docker 开源

Docker 自开源后受到广泛的关注和讨论，至今其 [GitHub](https://github.com/moby/moby) 项目 已经超过 6 万 3 千个星标和一万多个 fork。甚至由于 Docker 项目的火爆，在 2013 年底，[dotCloud 公司决定改名为 Docker](https://www.docker.com/blog/dotcloud-is-becoming-docker-inc/)。Docker 最初是在 Ubuntu 12.04 上开发实现的；`Red Hat` 则从 RHEL 6.5 开始对 Docker 进行支持；`Google` 也在其 PaaS 产品中广泛应用 `Docker`。

## 4. Docker 平台
Docker 提供了在称为容器的松散隔离环境中打包和运行应用程序的能力。隔离和安全性允许您在给定主机上同时运行多个容器。容器是轻量级的，包含运行应用程序所需的一切，因此您无需依赖主机上当前安装的内容。您可以在工作时轻松共享容器，并确保与您共享的每个人都获得以相同方式工作的同一个容器。

Docker 提供工具和平台来管理容器的生命周期：

 - 使用容器开发您的应用程序及其支持组件。
 - 容器成为分发和测试应用程序的单元。
 - 准备就绪后，将应用程序部署到生产环境中，作为容器或编排的服务。无论您的生产环境是本地数据中心、云提供商还是两者的混合，这都是一样的。


##  5. Docker 特性

**快速、一致地交付您的应用程序**

Docker 通过允许开发人员使用提供应用程序和服务的本地容器在标准化环境中工作来简化开发生命周期。容器非常适合持续集成和持续交付 (CI/CD) 工作流程。

考虑以下示例场景：

 - 您的开发人员在本地编写代码并使用 Docker 容器与同事分享他们的工作。
 - 他们使用 Docker 将他们的应用程序推送到测试环境中并执行自动化和手动测试。
 - 当开发者发现bug时，可以在开发环境中修复，重新部署到测试环境中进行测试和验证。
 - 测试完成后，将修复程序提供给客户就像将更新的镜像推送到生产环境一样简单。

**响应式部署和扩展**

Docker 基于容器的平台允许高度可移植的工作负载。Docker 容器可以在开发人员的本地笔记本电脑、数据中心的物理或虚拟机、云提供商或混合环境中运行。

Docker 的可移植性和轻量级特性还使得动态管理工作负载、根据业务需求近乎实时地扩展或拆除应用程序和服务变得容易。

**在相同硬件上运行更多工作负载**

Docker 是轻量级和快速的。它为基于管理程序的虚拟机提供了一种可行且经济高效的替代方案，因此您可以使用更多计算容量来实现业务目标。Docker 非常适合高密度环境以及需要用更少资源完成更多工作的中小型部署。


##  6. Docker 架构
Docker 使用客户端-服务器架构。Docker客户端与 Docker守护进程对话，后者负责构建、运行和分发 Docker 容器的繁重工作。Docker 客户端和守护程序可以 在同一系统上运行，或者您可以将 Docker 客户端连接到远程 Docker 守护程序。Docker 客户端和守护程序使用 `REST API`，通过 UNIX 套接字或网络接口进行通信。另一个 Docker 客户端是 `Docker Compose`，它允许您使用由一组容器组成的应用程序。

![在这里插入图片描述](https://img-blog.csdnimg.cn/bb803a1134744f128cfcbd036949c37f.png)

## 7. Docker 守护进程
Docker 守护程序 ( dockerd) 侦听 Docker API 请求并管理 Docker 对象，例如image、container、network和volume。守护进程还可以与其他守护进程通信以管理 Docker 服务。

## 8. Docker 客户端
Docker 客户端 ( docker client) 是许多 Docker 用户与 Docker 交互的主要方式。当您使用诸如`docker run`之类的命令时，客户端会将这些命令发送到`dockerd`执行它们。该docker命令使用 `Docker API`。Docker 客户端可以与多个守护进程通信。

## 9. Docker 桌面
`Docker Desktop` 是一个易于安装的应用程序，适用于您的 Mac 或 Windows 环境，使您能够构建和共享容器化应用程序和微服务。Docker Desktop 包括 `Docker 守护程序` ( dockerd)、`Docker 客户端` ( docker)、`Docker Compose`、`Docker Content Trust`、`Kubernetes` 和 `Credential Helper`。有关更多信息，请参阅[Docker 桌面](https://docs.docker.com/desktop/)。


##  10. Docker 仓库
Docker仓库存储 Docker 镜像。[Docker Hub](https://hub.docker.com/) 是一个任何人都可以使用的公共仓库，并且 Docker 默认配置为在 [Docker Hub](https://hub.docker.com/) 上查找镜像。您甚至可以运行自己的私有仓库。

当您使用`docker pull` or `docker run`命令时，将从您配置的仓库中提取所需的镜像。当您使用该`docker push`命令时，您的镜像会被推送到您配置的仓库中。


##  11. Docker 镜像
镜像是一个只读模板，其中包含创建 Docker 容器的说明。通常，一个镜像基于另一个镜像，并带有一些额外的自定义。例如，您可以基于该镜像构建一个镜像`ubuntu` ，但安装 `Apache Web` 服务器和您的应用程序，以及使您的应用程序运行所需的配置详细信息。

您可以创建自己的镜像，也可以只使用其他人创建并在仓库中发布的镜像。要构建您自己的镜像，您需要使用简单的语法创建一个`Dockerfile` ，用于定义创建和运行镜像所需的步骤。`Dockerfile` 中的每条指令都会在镜像中创建一个层。当您更改 Dockerfile 并重建镜像时，仅重建那些已更改的层。与其他虚拟化技术相比，这是使镜像如此轻量、小巧和快速的部分原因。

##  12. Docker 容器
容器是图像的可运行实例。您可以使用 `Docker API` 或 `CLI` 创建、启动、停止、移动或删除容器。您可以将容器连接到一个或多个网络，将存储附加到它，甚至可以根据其当前状态创建新镜像。

默认情况下，一个容器与其他容器及其主机的隔离相对较好。您可以控制容器的网络、存储或其他底层子系统与其他容器或主机的隔离程度。

容器由其镜像以及您在创建或启动它时提供给它的任何配置选项定义。当容器被移除时，任何未存储在持久存储中的状态更改都会消失。

示例`docker run`命令
以下命令运行一个ubuntu容器，以交互方式附加到您的本地命令行会话，然后运行/bin/bash​​.

```bash
 docker run -i -t ubuntu /bin/bash
```
当您运行此命令时，会发生以下情况（假设您使用的是默认仓库配置）：

 1. 如果您在本地没有ubuntu镜像，Docker 会从您配置的仓库中提取它，就像您`docker pull ubuntu`手动运行一样。
 2. Docker 会创建一个新容器，就像您`docker container create` 手动运行命令一样。
 3. Docker 为容器分配一个读写文件系统，作为它的最后一层。这允许正在运行的容器在其本地文件系统中创建或修改文件和目录。
 4. Docker 创建了一个网络接口来将容器连接到默认网络，因为您没有指定任何网络选项。这包括为容器分配 IP
   地址。默认情况下，容器可以使用主机的网络连接连接到外部网络。
 5. Docker 启动容器并执行/bin/bash. 因为容器以交互方式运行并附加到您的终端（由于`-i and -t` 标志），所以您可以在输出记录到终端时使用键盘提供输入。
 6. 当您键入`exit`终止`/bin/bash`命令时，容器会停止但不会被删除。您可以重新启动或删除它。


## 13. Docker 底层技术

Docker 使用 Google 公司推出的 [Go 语言](https://golang.google.cn/) 进行开发实现，基于 Linux 内核的 [cgroup](https://zh.wikipedia.org/wiki/Cgroups)，[namespace](https://en.wikipedia.org/wiki/Linux_namespaces)，以及 [OverlayFS](https://docs.docker.com/storage/storagedriver/overlayfs-driver/) 类的 [Union FS](https://en.wikipedia.org/wiki/Union_mount) 等技术，对进程进行封装隔离，属于 [操作系统层面的虚拟化技术](https://en.wikipedia.org/wiki/OS-level_virtualization)。由于隔离的进程独立于宿主和其它的隔离的进程，因此也称其为容器。最初实现是基于 [LXC](https://linuxcontainers.org/lxc/introduction/)，从 0.7 版本以后开始去除 LXC，转而使用自行开发的 [libcontainer](https://github.com/docker-archive/libcontainer)，从 1.11 版本开始，则进一步演进为使用 [runC](https://github.com/opencontainers/runc) 和 [containerd](https://github.com/containerd/containerd)。


