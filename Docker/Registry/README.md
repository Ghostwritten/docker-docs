#  Docker Registry Overview

## 1. 什么是 Docker registry ？
Docker registry  是命名 Docker镜像的 存储和分发系统。同一个image可能有多个不同的版本，由它们的标签标识。

Docker registry 被组织成 [Docker 存储库](https://www.aquasec.com/cloud-native-academy/container-security/image-repository/) ，其中存储库包含特定镜像的所有版本。仓库允许 Docker 用户在本地拉取镜像，以及将新镜像推送到仓库（在适用时给予足够的访问权限）。

默认情况下，[Docker](https://www.aquasec.com/cloud-native-academy/docker-container/docker-containers-vs-virtual-machines/) 引擎与 [Docker Hub](https://hub.docker.com/) 交互，Docker 的公共仓库实例。但是，可以在本地运行开源 Docker registry /分发版，以及称为 Docker Trusted Registry 的商业支持版本。网上还有其他公共登记处。

要从本地仓库中提取镜像，您可以运行类似于以下内容的命令：

```bash
docker pull my-registry:9000/foo/bar:2.1
docker pull foo/bar #默认latest
```


##  2. Docker Hub
DockerHub 是 Docker Inc. 的托管仓库解决方案。除了公共和私有存储库之外，它还提供自动构建、组织帐户以及与 Github 和 Bitbucket 等源控制解决方案的集成。

任何运行 Docker 的人都可以访问公共存储库，并且镜像名称包括组织/用户名。例如， 将从Jenkins 组织中提取docker pull jenkins/jenkins 带有标签的 Jenkins CI 服务器镜像 。latest 有成千上万的公共image可用。私有存储库限制对存储库创建者或其组织成员的访问。

DockerHub 支持官方存储库，其中包括经过安全性和最佳实践验证的image。这些不需要组织/用户名，例如 docker pull nginx 将提取 latest Nginx 负载均衡器的image。

如果 DockerHub 存储库链接到包含构建上下文（Dockerfile 和同一文件夹中的所有任何文件）的源代码控制存储库，则 DockerHub 可以执行自动镜像构建。源存储库中的提交将触发 DockerHub 中的构建。

如需进一步阅读，请参阅 Docker 文档： [配置自动化 Docker 构建](https://docs.docker.com/docker-hub/builds/) ›

DockerHub 还可以自动扫描私有存储库中的镜像以查找漏洞，生成一份报告，详细说明在每个镜像层中发现的漏洞，按严重性（严重、主要或次要）。

如需进一步阅读，请参阅 Docker 文档：  [Docker 安全扫描](https://docs.docker.com/engine/scan/) ›


##  3. Docker Hub 常见操作
使用 DockerHub 的常见操作包括：

 - **登录 DockerHub**：运行 `docker login` 将询问您的 DockerHub ID 和密码。
 - 在公共存储库中搜索image：使用 `docker search` 带有搜索词的命令在公共（包括官方）存储库中查找与该词匹配的所有image。
 - **拉取现有image**：使用 `docker pull` 并指定image名称。默认情况下，检索最新版本，但可以通过指定不同的image标签/版本来覆盖此行为。例如，要拉取 Ubuntu
   镜像的（旧）版本 14.04：

```bash
docker pull ubuntu:14.04
```

 - **推送本地镜像**：您可以通过运行 `docker push` 命令推送镜像。例如，要将（最新）本地版本的 `my-image` 推送到我的仓库：

```bash
docker push my-username/my-image
```

 - **创建一个新组织**：这必须通过浏览器完成。转到 Docker Hub ，单击 组织 ，然后单击 创建组织 并填写所需的数据。
 - **创建一个新的存储库**：这必须从浏览器中完成。转到 Docker Hub ，单击 Create 下拉菜单并选择 Create Repository。填写所需数据。您现在可以开始将image推送到此存储库。
 - **创建自动构建**：这必须从浏览器中完成。首先，通过导航到您的个人资料设置， 将您的 Github 或 Bitbucket 帐户链接到 Docker Hub  ，然后单击**Linked Accounts & Services**  。选择 公共和私人访问（强制）并授权。然后，单击“ 创建” 下拉菜单，选择 “创建自动构建 ”并选择要从中构建image的源存储库。

##  4. 私有 docker 仓库
在本地（组织内部）运行私有仓库的用例包括：

 1. 在隔离网络内分发image （不通过 Internet 发送image）；
 2. 创建更快的 CI/CD 管道 （从内部网络拉取和推送image），包括更快地部署到本地环境  ；
 3. 在大型机器集群上部署新镜像；
 4. 严格控制image的存储位置

运行私有镜像系统，尤其是当交付到生产依赖于它时，需要操作技能，例如确保可用性、日志记录和日志处理、监控和安全性。对 http 和整体网络通信的深入了解也很重要。

一些供应商提供自己的开源 Docker registry 扩展。这些可以帮助缓解上述一些运营问题：

 - [Docker Trusted Registry](https://docs.docker.com/registry/introduction/) 是 Docker Inc 的商业支持版本，通过复制、镜像审计、签名和安全扫描、与 LDAP 和 Active Directory 的集成提供高可用性。
 - [Harbor](https://goharbor.io/) 是一个 VMWare 开源产品，它还通过复制、镜像审计、与 LDAP 和 Active Directory 的集成来提供高可用性。
 - [GitLab Container Registry](https://docs.gitlab.com/ee/user/packages/container_registry/) 与 GitLab CI 的工作流程紧密集成，只需最少的设置。
 - [JFrog Artifactory](https://jfrog.com/artifactory/) 用于强大的工件管理（不仅是 Docker 镜像，还包括任何工件）。



## 5. 创建本地仓库
管理本地仓库安装所需的常见操作包括：

启动仓库：仓库本身是一个 Docker 镜像，需要使用 docker run . 例如，根据默认配置运行它，并将主机端口 5001 上的请求转发到容器端口 5000（注册中心将侦听的默认端口）：

```bash
docker run -d -p 5001:5000 --name  registry registry:2 
```

默认情况下，仓库数据保存为 Docker 卷。要指定主机上的特定存储位置（例如，SSD 或 SAN 文件系统），请使用绑定挂载选项：

```bash
-v <host location>:<container location>
```

`Automatically restart registry`：要在主机重新启动或仅仅因为仓库容器停止时保持仓库运行，只需将选项添加 --restart=always 到命令中。
停止仓库：停止仓库只是使用 docker stop  registry 命令停止正在运行的仓库容器的问题。要实际删除容器，还需要运行：

```bash
docker rm -v registry
```

请注意，开源 Docker registry 带有一组默认配置，用于**日志记录**、**存储**、**身份验证**、**中间件**、**报告**、**http**、**通知**、**健康检查**等。这些可以通过将特定环境变量传递给仓库启动命令来单独覆盖。例如，以下命令告诉仓库在容器的端口 5001 而不是默认端口 5000 上侦听请求。

```bash
docker run -d -e REGISTRY_HTTP_ADDR=0.0.0.0:5001 -p 5001:5001 \
--name  registry registry:2
```

另一种选择是使用YAML 文件 完全覆盖配置设置 。它还需要作为卷安装在容器上，例如：

```bash
docker run -d -p 5001:5000 -v config.yml:/etc/docker/registry/config.yml \
--name  registry registry:2
```

如需进一步阅读，请参阅 Docker 文档： [部署仓库服务器](https://docs.docker.com/registry/deploying/) ›和 [配置仓库](https://docs.docker.com/registry/configuration/) ›

todo:
* [ ] [How To Set Up a Private Docker Registry on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-private-docker-registry-on-ubuntu-18-04)

