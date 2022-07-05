#  Docker 镜像 overview

## 1. 什么是 Docker 镜像？
[Docker](https://www.techtarget.com/searchitoperations/definition/Docker) 镜像是用于在 Docker [容器](https://www.techtarget.com/searchitoperations/definition/container-containerization-or-container-based-virtualization)中执行代码的文件。Docker  镜像充当构建 Docker容器的一组指令，就像模板一样。使用 Docker 时，Docker 镜像也可以作为起点。 镜像相当于虚拟机 (VM) 环境中的快照。

Docker 用于在容器中创建、运行和部署应用程序。Docker  镜像包含应用程序运行所需的应用程序代码、库、工具、依赖项和其他文件。当用户运行一个镜像时，它可以成为一个容器的一个或多个实例。

Docker 镜像有多个层，每一层都源自上一层，但又有所不同。这些层[加速了 Docker 构建](https://www.techtarget.com/searchitoperations/tip/Optimize-Docker-images-for-improved-efficiency-and-security)，同时提高了可重用性并减少了磁盘使用。图像层也是只读文件。创建容器后，在不可更改的图像之上添加一个可写层，允许用户进行更改。

对 Docker  镜像和容器中的磁盘空间的引用可能会令人困惑。区分大小和虚拟大小很重要。大小是指容器的可写层使用的磁盘空间，而虚拟大小是指容器和可写层使用的磁盘空间。 镜像的只读层可以在从同一 镜像启动的任何容器之间共享。

## 2. Docker 镜像 demo
Docker 镜像包含运行容器化应用程序所需的一切，包括代码、[配置文件](https://www.techtarget.com/searchitoperations/definition/configuration-file)、环境变量、库和运行时。当镜像部署到 Docker 环境时，它可以作为 Docker 容器执行。d[ocker run](https://www.theserverside.com/blog/Coffee-Talk-Java-News-Stories-and-Opinions/Docker-run-vs-docker-compose-Whats-the-difference?_ga=2.17602992.885136467.1657029399-900056396.1656003084&_gl=1*9khqu9*_ga*OTAwMDU2Mzk2LjE2NTYwMDMwODQ.*_ga_TQKE4GS5P9*MTY1NzAzMTY3My4zLjEuMTY1NzAzMTc3My4w) 命令从一个特定的镜像创建一个容器。

Docker 镜像是可重用的资产——可部署在任何主机上。开发人员可以从一个项目中获取静态图像层并在另一个项目中使用它们。这节省了用户时间，因为他们不必从头开始重新创建图像。

## 3. Docker 容器与 Docker 镜像
Docker 容器是用于应用程序开发的虚拟化运行时环境。它用于创建、运行和部署与底层硬件隔离的应用程序。一个 Docker 容器可以使用一台机器，共享其内核并虚拟化操作系统以运行更多独立的进程。因此，Docker 容器是轻量级的。

Docker  镜像就像其他类型的 VM 环境中的快照。它是 Docker 容器在特定时间点的记录。Docker 镜像也是不可变的。虽然它们无法更改，但可以复制、共享或删除它们。该功能对于测试新软件或配置很有用，因为无论发生什么，图像都保持不变。

容器需要一个可运行的镜像才能存在。容器依赖于镜像，因为它们用于构建运行时环境并且是运行应用程序所必需的。

##  4. Docker 镜像剖析
一个 Docker 镜像有很多层，每个镜像都包含配置容器环境所需的一切——系统库、工具、依赖项和其他文件。图像的一些部分包括：

 - `Base image`：用户可以使用 build 命令完全从头开始构建第一层。
 - `Parent image`：作为基础镜像的替代方案，父镜像可以是 Docker 镜像中的第一层。它是一个重复使用的图像，作为所有其他层的基础。
 - `Layers`：层被添加到基础镜像中，使用代码使其能够在容器中运行。Docker 映像的每一层都可以在 /var/lib/docker/aufs/diff 下查看，或者通过命令行界面 (CLI) 中的 Docker history
   命令查看。Docker 的默认状态是显示所有顶层镜像，包括存储库、标签和文件大小。中间层被缓存，使顶层更容易查看。Docker 具有处理镜像层内容管理的存储驱动器。
 - `Container layer`：一个 Docker 镜像不仅会创建一个新的容器，还会创建一个可写或容器层。该层托管对正在运行的容器所做的更改，并存储新写入和删除的文件，以及对现有文件的更改。该层还用于自定义容器。
 - `Docker manifest`：Docker 映像的这一部分是一个附加文件。它使用JSON格式来描述图像，使用图像标签和数字签名等信息。
