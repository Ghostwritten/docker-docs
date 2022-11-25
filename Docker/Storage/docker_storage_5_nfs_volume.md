#  Docker NFS volume 创建与使用
tags: 存储
<!-- catalog: ~Docker NFS volume~ -->

![在这里插入图片描述](https://img-blog.csdnimg.cn/f28908e27ca741ab80460b9a9e66b2ae.png)


## 1. 简介
Docker 卷是为Docker 容器设置持久存储的首选机制。卷是安装在容器内的主机文件系统上的现有目录。它们可以从容器和主机系统访问。

Docker 还允许用户挂载通过 NFS 远程文件共享系统共享的目录。为此目的创建的卷使用 Docker 自己的 NFS 驱动程序，无需在主机系统上挂载 NFS 目录。

## 2. 创建 NFS Docker 卷

创建和管理 Docker 卷的最简单方法是使用docker volume命令及其子命令。

创建 NFS Docker 卷的语法包括两个选项。

 1. 该`--driver`选项定义了local卷驱动程序，它接受类似于[mount](https://blog.csdn.net/xixihahalelehehe/article/details/127347073) Linux 中的命令的选项。
 2. `--opt`多次调用该选项以提供有关卷的更多详细信息。

详细信息包括：

- volume type
- write mode
- 远程 NFS 服务器的 IP 或 Web 地址
- 服务器上共享目录的路径

```bash
docker volume create --driver local \
--opt type=nfs \
--opt o=addr=[ip-address],rw \
--opt device=:[path-to-directory] \
[volume-name]
```
下面的示例说明了如何创建一个名为`nfs-volume`. 该卷包含`/mnt/nfsdir`位于服务器上的目录，具有`rw`（读/写）权限。服务器的 IP 地址是`10.240.12.70`。

![在这里插入图片描述](https://img-blog.csdnimg.cn/7b5eecdaf2cf485c8c21e61507b501a9.png)
列出可用的 Docker 卷。

```bash
docker volume ls
```
![在这里插入图片描述](https://img-blog.csdnimg.cn/964e97eb9d474c4b8c60af0a94bfa6cf.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/a53029e71e664851ab81127c90a23fce.png)
## 3. 在容器中挂载 NFS
要将 NFS 卷挂载到容器中，请nfs-common在主机系统上安装软件包。


```bash
sudo apt update
sudo apt install nfs-common
```

> 注意：如果使用 YUM 或 RPM 进行包管理，则 NFS 客户端包称为`nfs-utils`

使用[docker run](https://blog.csdn.net/xixihahalelehehe/article/details/123378401) 命令启动容器。在该部分中指定 NFS 卷和安装点`--mount`。

```bash
docker run -d -it \
--name [container-name] \
--mount source=[volume-name],target=[mount-point]\
[image-name]
```
![在这里插入图片描述](https://img-blog.csdnimg.cn/9514e592f0fd43478ad88ebaa87d99bf.png)

```bash
docker inspect [container-name]
```
![在这里插入图片描述](https://img-blog.csdnimg.cn/eaa0534caf834249961aecfbaa5e1756.png)

```bash
docker exec -it [container-name] ls /mnt
```
##  4. Docker Compose 挂载 NFS 卷
如果您使用[Docker Compose](https://blog.csdn.net/xixihahalelehehe/article/details/108769857)来管理您的容器，请通过在 YML 文件中定义来挂载 NFS 卷。

创建 `docker-compose.yml` 文件。

```bash
version: "3.2"

services:
  [service-name]:
    image: [docker-image]
    ports:
      - "[port]:[port]"

    volumes:
      - type: volume
        source: [volume-name]
        target: /nfs
        volume:
          nocopy: true
volumes:
  [volume-name]:
    driver_opts:
      type: "nfs"
      o: "addr=[ip-address],nolock,soft,rw"
      device: ":[path-to-directory]"
```

> 注意：nolock和soft选项确保 Docker 在与 NFS 服务器的连接丢失时不会冻结( freeze)


参考：
- [NFS Docker Volumes: How to Create and Use](https://phoenixnap.com/kb/nfs-docker-volumes)
