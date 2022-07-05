#  Podman Overview


[Podman](https://podman.io/)是一个构建容器的工具。它与[Docker](https://www.docker.com/)扮演相同的角色，并且在很大程度上与 Docker 兼容，提供几乎相同的命令。本文为开始使用 Podman 的开发人员和寻求更高级信息的开发人员提供了资源。

## 什么是 Podman？
我们发现以下视频和文章是很好的起点。

 - 在[Podman：下一代 Linux 容器工具](https://developers.redhat.com/articles/podman-next-generation-linux-container-tools)中，Doug Tidwell 解释了 Podman 是什么以及如何安装该工具、使用它构建映像、运行映像、将映像推送到容器注册表、将映像下载到非 Linux系统，并使用 Docker 运行映像。
 - [从 Docker 过渡到 Podman](https://developers.redhat.com/blog/2020/11/19/transitioning-from-docker-to-podman)是关于容器的最受欢迎的红帽开发人员文章之一，它使用真实示例向您展示如何安装Podman、使用其基本命令以及从 Docker 命令行界面 (CLI) 过渡到 Podman . 您还将了解如何使用 Podman 运行现有映像以及如何设置端口转发。
 - 在[Podman 的无根容器：基础知识](https://developers.redhat.com/blog/2020/09/25/rootless-containers-with-podman-the-basics)中，Prakhar Sethi 解释了使用容器和 Podman 的好处。本文介绍了无根容器并解释了它们的重要性，然后通过一个示例场景向您展示了如何在 Podman 中使用无根容器。

要获得一些实践，请参阅使用[容器工具部署容器](https://developers.redhat.com/courses/red-hat-enterprise-linux/deploy-containers-podman)，这是一个简短（仅 10 分钟）的课程，将教您如何部署和控制已定义的容器映像。

##  使用 Podman 的多种方式
以下是在各种环境中使用它的一些资源：

 - [将您的应用程序交付到无根容器中的边缘和物联网设备](https://developers.redhat.com/blog/2021/02/03/deliver-your-applications-to-edge-and-iot-devices-in-rootless-containers)向您展示了如何使用systemd Podman 和[红帽 Ansible 自动化](https://developers.redhat.com/products/ansible/overview)来自动化并将软件作为容器推送到小型边缘和[物联网](https://developers.redhat.com/topics/iot)(IoT) 网关设备。
 - 使用 [Podman 构建应用程序映像企业 Linux](https://developers.redhat.com/products/rhel/overview)。
 - [Kubernetes](https://developers.redhat.com/topics/kubernetes)开发人员应该查看[使用 Podman 将开发环境迁移到生产环境](https://www.youtube.com/watch?v=0qtHXQ5KEO4)。该视频展示了如何将容器从桌面移动到生产Kubernetes。Podman 的[generate-kube](https://docs.podman.io/en/latest/markdown/podman-generate-kube.1.html)工具可以提供帮助。该视频首先使用 Podman 生成一个Kubernetes YAML 文件，然后介绍使用该 YAML 将环境从本地开发迁移到 OpenShift 生产所需的步骤。
 - [Podman：用于处理容器和 Pod 的 Linux 工具](https://www.youtube.com/watch?v=bJDI_QuXeCE)：本教程向您展示如何安装 Podman，使用它构建映像，使用 Podman 运行映像，将映像推送到容器注册表，然后将映像下载到非 Linux系统并使用 Docker 运行它。
 - [Podman 入门](https://www.youtube.com/watch?v=Za36qHbrf3g)：加入实习生 Cedric Clyburn，他将向您介绍 Podman 的基础知识。使用它来运行现有映像、端口转发和构建映像。
 - [使用最佳实践和 IBM Cloud Code Engine 容器化和部署您的 Node.js 应用程序](https://www.youtube.com/watch?v=V7nz32WFut0)：采用最佳实践，使用多阶段
   Dockerfile、ubi8/nodejs-14-minimal基本映像、Buildah、Podman 和安全容器注册表来容器化您的Node.js 应用程序。然后将您的应用程序容器部署到 IBM Cloud Code Engine，这是一个完全托管的 Knative[无服务器平台](https://developers.redhat.com/topics/serverless-architecture)，可运行您的容器化工作负载，包括 Web 应用程序、[微服务](https://developers.redhat.com/topics/microservices)、[事件驱动](https://developers.redhat.com/topics/event-driven)函数和批处理作业。

最后，下载 [Podman 基础备忘单](https://developers.redhat.com/cheat-sheets/podman-basics-old)，以获得更快、更轻松的 Podman 体验。

