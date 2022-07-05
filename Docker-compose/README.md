#  Docker-compose overview


##  1. 简介
[docker-ompose](https://docs.docker.com/compose/) 是一个用于定义和运行多容器 Docker 应用程序的工具。使用 docker-compose，您可以使用 YAML 文件来配置应用程序的服务。然后，使用一个命令，您可以从您的配置中创建并启动所有服务。

docker-compose 适用于所有环境：生产、登台、开发、测试以及 CI 工作流程。

##  2. 使用步骤
用 docker-compose 基本上是一个三步过程：

 1. 使用 a 定义您的应用程序的环境，[Dockerfile](https://smoothies.com.cn/docker-docs/Docker/docker_dockerfile.html)以便可以在任何地方复制它。
 2. 定义构成您的应用程序的服务，[docker-compose.yml](https://docs.docker.com/compose/compose-file/) 以便它们可以在隔离环境中一起运行。
 3. 运行`docker compose up`，`Docker compose` 命令启动并运行您的整个应用程序。您也可以`docker-compose up`使用 docker-compose 二进制文件运行。

docker-compose.yml

```bash
version: "3.9"  # optional since v1.27.0
services:
  web:
    build: .
    ports:
      - "8000:5000"
    volumes:
      - .:/code
      - logvolume01:/var/log
    links:
      - redis
  redis:
    image: redis
volumes:
  logvolume01: {}
```

##  3. 生命周期
docker-compose 具有用于管理应用程序整个生命周期的命令：

 1. 启动、停止和重建服务
 2. 查看运行服务的状态
 3. 流式传输正在运行的服务的日志输出
 4. 在服务上运行一次性命令

## 4. 特色

docker-compose 使其有效的特点是：

 - **单个主机上的多个隔离环境**

docker-compose 使用项目名称将环境彼此隔离。您可以在几个不同的上下文中使用此项目名称：

在开发主机上，创建单个环境的多个副本，例如当您想要为项目的每个功能分支运行稳定副本时

 - 在 CI 服务器上，为了防止构建相互干扰，您可以将项目名称设置为唯一的构建号
 - 在共享主机或开发主机上，以防止可能使用相同服务名称的不同项目相互干扰
 - 默认项目名称是项目目录的基本名称。您可以使用 -p命令行选项或 `COMPOSE_PROJECT_NAME`环境变量设置自定义项目名称。

默认项目目录是 `docker-compose` 文件的基本目录。可以使用`--project-directory`命令行选项定义它的自定义值。

 - **创建容器时保留卷数据**

docker-compose 会保留您的服务使用的所有卷。运行时docker-compose up ，如果它找到以前运行的任何容器，它会将卷从旧容器复制到新容器。此过程可确保您在卷中创建的任何数据都不会丢失。

 - **仅重新创建已更改的容器**

docker-compose 缓存用于创建容器的配置。当您重新启动未更改的服务时，docker-compose 会重新使用现有容器。重复使用容器意味着您可以非常快速地更改您的环境。

 - **变量和在环境之间移动组合**

docker-compose 支持 docker-compose 文件中的变量。您可以使用这些变量为不同的环境或不同的用户定制您的组合。有关详细信息，请参阅[变量替换](https://docs.docker.com/compose/compose-file/compose-file-v3/#variable-substitution)。

[extends](https://docs.docker.com/compose/extends/)您可以使用该字段或通过创建多个 docker-compose 文件来扩展docker-compose 文件
