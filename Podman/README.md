#  Podman Overview

![](https://img-blog.csdnimg.cn/0349876be0004ebc9ab43fd4ba8300cd.png)


##  1. 概述
[Podman](https://podman.io/)（全称 POD 管理器）是一款用于在 [Linux®](https://www.redhat.com/zh/topics/linux/what-is-linux) 系统上开发、管理和运行容器的开源工具。Podman 最初由红帽® 工程师联合开源社区一同开发，它可利用 `lipod` 库来管理整个容器生态系统。 

Podman 采用无守护进程的包容性架构，因此可以更安全、更简单地进行容器管理，再加上 [Buildah](https://www.redhat.com/zh/topics/containers/what-is-buildah) 和 [Skopeo](https://blog.csdn.net/xixihahalelehehe/article/details/127342981) 等与之配套的工具和功能，开发人员能够按照自身需求来量身定制容器环境。 它与[Docker](https://www.docker.com/)扮演相同的角色，并且在很大程度上与 Docker 兼容，提供几乎相同的命令。

## 2. 什么是 Podman？
我们发现以下视频和文章是很好的起点。

 - 在[Podman：下一代 Linux 容器工具](https://developers.redhat.com/articles/podman-next-generation-linux-container-tools)中，Doug Tidwell 解释了 Podman 是什么以及如何安装该工具、使用它构建映像、运行映像、将映像推送到容器注册表、将映像下载到非 Linux系统，并使用 Docker 运行映像。
 - [从 Docker 过渡到 Podman](https://developers.redhat.com/blog/2020/11/19/transitioning-from-docker-to-podman)是关于容器的最受欢迎的红帽开发人员文章之一，它使用真实示例向您展示如何安装Podman、使用其基本命令以及从 Docker 命令行界面 (CLI) 过渡到 Podman . 您还将了解如何使用 Podman 运行现有映像以及如何设置端口转发。
 - 在[Podman 的无根容器：基础知识](https://developers.redhat.com/blog/2020/09/25/rootless-containers-with-podman-the-basics)中，Prakhar Sethi 解释了使用容器和 Podman 的好处。本文介绍了无根容器并解释了它们的重要性，然后通过一个示例场景向您展示了如何在 Podman 中使用无根容器。

要获得一些实践，请参阅使用[容器工具部署容器](https://developers.redhat.com/courses/red-hat-enterprise-linux/deploy-containers-podman)，这是一个简短（仅 10 分钟）的课程，将教您如何部署和控制已定义的容器映像。

##  3. 使用 Podman 的多种方式
以下是在各种环境中使用它的一些资源：

 - [将您的应用程序交付到无根容器中的边缘和物联网设备](https://developers.redhat.com/blog/2021/02/03/deliver-your-applications-to-edge-and-iot-devices-in-rootless-containers)向您展示了如何使用systemd Podman 和[红帽 Ansible 自动化](https://developers.redhat.com/products/ansible/overview)来自动化并将软件作为容器推送到小型边缘和[物联网](https://developers.redhat.com/topics/iot)(IoT) 网关设备。
 - 使用 [Podman 构建应用程序映像企业 Linux](https://developers.redhat.com/products/rhel/overview)。
 - [Kubernetes](https://developers.redhat.com/topics/kubernetes)开发人员应该查看[使用 Podman 将开发环境迁移到生产环境](https://www.youtube.com/watch?v=0qtHXQ5KEO4)。该视频展示了如何将容器从桌面移动到生产Kubernetes。Podman 的[generate-kube](https://docs.podman.io/en/latest/markdown/podman-generate-kube.1.html)工具可以提供帮助。该视频首先使用 Podman 生成一个Kubernetes YAML 文件，然后介绍使用该 YAML 将环境从本地开发迁移到 OpenShift 生产所需的步骤。
 - [Podman：用于处理容器和 Pod 的 Linux 工具](https://www.youtube.com/watch?v=bJDI_QuXeCE)：本教程向您展示如何安装 Podman，使用它构建映像，使用 Podman 运行映像，将映像推送到容器注册表，然后将映像下载到非 Linux系统并使用 Docker 运行它。
 - [Podman 入门](https://www.youtube.com/watch?v=Za36qHbrf3g)：加入实习生 Cedric Clyburn，他将向您介绍 Podman 的基础知识。使用它来运行现有映像、端口转发和构建映像。
 - [使用最佳实践和 IBM Cloud Code Engine 容器化和部署您的 Node.js 应用程序](https://www.youtube.com/watch?v=V7nz32WFut0)：采用最佳实践，使用多阶段
   Dockerfile、ubi8/nodejs-14-minimal基本映像、Buildah、Podman 和安全容器注册表来容器化您的Node.js 应用程序。然后将您的应用程序容器部署到 IBM Cloud Code Engine，这是一个完全托管的 Knative[无服务器平台](https://developers.redhat.com/topics/serverless-architecture)，可运行您的容器化工作负载，包括 Web 应用程序、[微服务](https://developers.redhat.com/topics/microservices)、[事件驱动](https://developers.redhat.com/topics/event-driven)函数和批处理作业。

最后，下载 [Podman 基础备忘单](https://developers.redhat.com/cheat-sheets/podman-basics-old)，以获得更快、更轻松的 Podman 体验。

## 4. Podman 是如何管理容器的？
用户可以从命令行调用 Podman，以便从存储库拉取容器并运行它们。Podman 调用配置好的容器运行时来创建运行的容器。不过，由于没有专门的守护进程，Podman 使用 [systemd](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/chap-managing_services_with_systemd)（一种用于 Linux 操作系统的系统和服务管理器）来进行更新并让容器在后台保持运行。通过将 systemd 和 Podman 集成，您可以为容器生成控制单元，并在自动启用 systemd 的前提下运行它们。

用户可以在系统上管理自有的存储库，也可通过 systemd 单元来控制自有容器的自动启动和管理。允许用户管理自己的资源并使容器以无根方式运行，可以阻止诸如使 /var/lib/containers 目录可被写入等不良做法，或防范可能会导致应用暴露于额外安全问题的其他系统管理做法。这样也可确保每一用户具有单独的容器和镜像集合，并可在同一主机上同步使用 Podman，而不会彼此干扰。用户完成自己的工作时，可将变更推送到共有的镜像仓库，将他们的镜像共享给其他人。

Podman 也可部署 [RESTful API](https://www.redhat.com/zh/topics/api/what-is-a-rest-api)（REST API）来管理容器。REST 是表述性状态传递的英文缩写。REST API 是遵循 REST 架构规范的应用编程接口，支持与 RESTful Web 服务进行交互。借助 REST API，您可以从 cURL、Postman 和 Google 的 Advanced REST 客户端等许多平台调用 Podman。

## 5. Podman、Buildah 和 Skopeo
Podman 是一种模块化容器引擎，因此必须与 Buildah 和 Skopeo 等工具搭配使用才能构建和移动容器。使用 Buildah 时，您可以从头开始构建容器，也可将某个镜像用作起点来构建。Skopeo 可在不同类型的存储系统之间移动容器镜像，允许您在不同镜像仓库（例如 docker.io、quay.io 和您的内部镜像仓库）之间以及本地系统上不同类型的存储之间复制镜像。这种模块式的容器化工具有助于生成灵活的轻量型环境，减小开销并隔离您实现目标所需的功能。工具的体量越小、模块化程度越高，演进发展的速度也越快，而且每一工具也能专注于单一用途。 

我们可以把 Podman、Buildah 和 Skopeo 比喻成一套特殊的瑞士军刀，它们彼此互补，几乎能满足所有容器用例的需求。Podman 就是这套刀中最大的一把。 

Podman 和 Buildah 默认使用 [runC](https://github.com/opencontainers/runc#readme)（OCI 运行时）来启动容器。您可以构建和运行镜像，也可通过 runC 运行 docker 格式的镜像。Buildah 由 Go 语言编写，可读取运行时规范，配置 [Linux 内核](https://www.redhat.com/zh/topics/linux/what-is-the-linux-kernel)，最终创建并启动容器进程。在更改一些配置后，您也可以将 Podman 与 [crun](https://github.com/containers/crun#readme) 等其他工具搭配使用。

## 6. Podman 与Docker
[Docker](https://www.docker.com/) 是支持创建和使用 Linux 容器的一种容器化技术。Podman 和 Docker 的主要区别在于 Podman 采用无守护进程架构。Podman 容器一直是无根的，而 Docker 最近才将无根模式添加到其守护进程配置中。Docker 是用于创建和管理容器的一体化工具，而 Podman 以及 Buildah 和 Skopeo 等相关工具则更擅长承担某些方面的容器化工作，让您能够根据自己在云原生应用中的需求来进行自定义。 

Podman 具有替代 Docker 的强大实力，但两者也可搭配使用。用户可以将 Docker 别名设置为 Podman（alias docker=podman）或反之，在这两者之间轻松切换。此外，一个叫做 podman-docker 的 rpm 可以将"docker"置入系统应用 PATH，从 Docker 轻松切换过来，在需要"docker"命令时对这些环境调用 Podman。Podman 的 CLI 与 Docker 容器引擎类似，熟悉其中之一的用户也能快速上手使用另一个。 

一些开发人员会一起使用 Podman 和 Docker，在开发阶段使用 Docker，然后在运行时环境中将程序转移到 Podman，享受其更好的安全性。 

Podman 非常适合不使用 Kubernetes 或 OpenShift 容器平台来运行容器的开发人员。[CRI-O](https://cri-o.io/) 是一个用于 Kubernetes 容器编排系统（例如红帽 OpenShift® 容器平台）的社区推动的开源容器引擎。


## 7. 为什么选择 Podman？
Podman 改变了容器格局，它不仅提供比肩领先容器引擎的高性能功能，而且具有如今许多开发团队迫切需要的灵活性、可访问性和高安全性。Podman 可以帮助您：

- 管理容器镜像和完整的容器生命周期，包括运行、联网、检查和下线。
- 为无根容器和容器集运行和隔离资源。
- 支持 OCI 和 Docker 镜像，以及与 Docker 兼容的 CLI。
- 打造一个无守护进程的环境，提高安全性并减少闲置资源消耗。 
- 部署 REST API 来支持 Podman 的高级功能。
- 借助 [checkpoint/restore in userspace](https://criu.org/Main_Page)（CRIU），实施面向 Linux 容器的检查点/恢复功能。CRIU 可以冻结正在运行的容器，并将其内存内容和状态保存到磁盘，以便容器化工作负载能够更快地重新启动。
- 自动更新容器。Podman 会检测更新的容器是否无法启动，并自动回滚到上一个工作版本。这可以将应用的可靠性提升到新的水平。 

