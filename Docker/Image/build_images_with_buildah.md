# 构建镜像开源工具 buildah
tags: images
![在这里插入图片描述](https://img-blog.csdnimg.cn/ea898d04242948daab46a5770a6b2085.png)

## 1. 简介
[Buildah](https://buildah.io/) 是一种基于 Linux 的开源工具，用于构建与开放容器倡议 (OCI) 兼容的[容器](https://www.redhat.com/en/topics/containers/whats-a-linux-container)，这意味着容器也与[Docker](https://www.redhat.com/en/topics/containers/what-is-docker)和[Kubernetes](https://www.redhat.com/en/topics/containers/what-is-kubernetes)兼容。借助 `Buildah`，您可以使用自己喜欢的工具从现有基础镜像或使用空镜像从头开始创建高效的容器镜像。这是一种更灵活、更安全的构建容器镜像的方式。

`Buildah`由 `Daniel Walsh` 和他在 `Red Hat` 的团队于 2017 年创建。他们着手创建容器镜像的“`coreutils`”——一种可以与现有容器主机工具一起使用来构建 `OCI` 和 Docker 兼容容器镜像的工具。然后，这些镜像可以存储在[容器仓库](https://www.redhat.com/en/topics/cloud-native-apps/what-is-a-container-registry)中，并在多个[运行时环境](https://www.redhat.com/en/topics/cloud-native-apps/what-is-a-Java-runtime-environment)中使用。

## 2. 特点
- 使用或不使用 [Dockerfiles](https://blog.csdn.net/xixihahalelehehe/article/details/107517710)（包含用户可以调用以组装镜像的所有命令的文本文档）构建容器镜像 
- 从头开始或从现有容器镜像起点创建容器镜像；
- 不在镜像本身中包含构建工具，减少构建镜像的大小，提高安全性，并允许使用更少的资源更容易地传输 ；
- 与 `Dockerfiles` 兼容，允许从 Docker 轻松转换；
- 创建特定于用户的镜像，以便镜像可以按创建它们的用户进行排序；
- 检查、验证和修改镜像；
- 将容器和镜像从本地存储推送到公共或私有仓库或存储库；
- 从 [Docker Hub](https://hub.docker.com/) 推送或拉取镜像；
- 移除本地存储的容器镜像；
- 挂载和卸载工作容器的根文件系统；
- 使用容器根文件系统的更新内容作为新镜像的文件系统层。

## 3. Buildah 和 Podman
`Buildah` 和[Podman](https://podman.io/)都是互补的开源项目和命令行工具，使用并构建 OCI 镜像和容器。首先创建了 Buildah，Podman 使用与 Buildah 相同的代码进行构建。但是，Buildah 的命令比 Podman 的命令详细得多，允许对镜像进行更细粒度的控制并允许创建更精细的镜像层。Podman 的“构建”命令使用了 Buildah 功能的一个子集。 

Buildah 专注于构建容器镜像，复制在没有守护程序套接字组件的 Dockerfile 中找到的所有命令，而 Podman 专注于维护和修改容器中的这些镜像所需的东西。使用 Podman，您可以创建一个容器——使用 Buildah 提供容器镜像——然后使用熟悉的命令行界面 (CLI) 命令（如果您可以运行一个Docker CLI 中的命令，您可以在 Podman CLI 中运行相同的命令）。 

Podman 和 Buildah 的另一个不同之处是：Buildah 的容器主要是临时创建的，以允许将内容传输到正在创建的容器镜像中，而使用 Podman，用户创建传统容器，旨在使用和维护更长时间. Buildah 的容器用于短期目的，而 Podman 的容器用于长期目的。 

`Buildah` 和 `Podman` 各自创建的容器是互相看不到的。


## 4. 安装
### 4.1 CentOS

```bash
sudo yum -y install buildah
```
### 4.2 Ubuntu

```bash
# Ubuntu 20.10 and newer
sudo apt-get -y update
sudo apt-get -y install buildah
```
### 4.3 RHEL7

```bash
sudo subscription-manager repos --enable=rhel-7-server-extras-rpms
sudo yum -y install buildah
```
### 4.4 Fedora

```bash
sudo dnf -y install buildah
```
或者

```bash
$ sudo rpm-ostree install buildah
```

- [更多安装方式请参考这里](https://github.com/containers/buildah/blob/main/install.md)


## 5. 命令
| Command                                              | Description                                                                                          |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| [buildah-add(1)](/https://github.com/containers/buildah/blob/main/docs/buildah-add.1.md)               | 将文件、URL 或目录的内容添加到容器中。                                   |
| [buildah-build(1)](https://github.com/containers/buildah/blob/main/docs/buildah-build.1.md)           | 使用 Containerfiles 或 Dockerfiles 中的指令构建镜像。                               |
| [buildah-commit(1)](https://github.com/containers/buildah/blob/main/docs/buildah-commit.1.md)         | 从运行的容器创建镜像。                                                            |
| [buildah-config(1)](https://github.com/containers/buildah/blob/main/docs/buildah-config.1.md)         | 更新镜像配置设置。                                                                 |
| [buildah-containers(1)](https://github.com/containers/buildah/blob/main/docs/buildah-containers.1.md) | 列出工作容器及其基础镜像。                                                   |
| [buildah-copy(1)](https://github.com/containers/buildah/blob/main/docs/buildah-copy.1.md)             | 将文件、URL 或目录的内容复制到容器的工作目录中。              |
| [buildah-from(1)](https://github.com/containers/buildah/blob/main/docs/buildah-from.1.md)             | 从头开始或使用指定镜像作为起点创建一个新的工作容器。  |
| [buildah-images(1)](https://github.com/containers/buildah/blob/main/docs/buildah-images.1.md)         | 列出本地存储中的镜像。                                                                       |
| [buildah-info(1)](https://github.com/containers/buildah/blob/main/docs/buildah-info.1.md)             | 显示 Buildah 系统信息。                                                                  |
| [buildah-inspect(1)](https://github.com/containers/buildah/blob/main/docs/buildah-inspect.1.md)       | 检查容器或镜像的配置。                                                |
| [buildah-mount(1)](https://github.com/containers/buildah/blob/main/docs/buildah-mount.1.md)           | 挂载工作容器的根文件系统。                                                      |
| [buildah-pull(1)](https://github.com/containers/buildah/blob/main/docs/buildah-pull.1.md)             | 从指定位置拉取镜像。                                                           |
| [buildah-push(1)](https://github.com/containers/buildah/blob/main/docs/buildah-push.1.md)             | 将镜像从本地存储推送到其他地方。                                                       |
| [buildah-rename(1)](https://github.com/containers/buildah/blob/main/docs/buildah-rename.1.md)         | 重命名本地容器                                                                            |
| [buildah-rm(1)](https://github.com/containers/buildah/blob/main/docs/buildah-rm.1.md)                 | 删除一个或多个工作容器。                                                             |
| [buildah-rmi(1)](https://github.com/containers/buildah/blob/main/docs/buildah-rmi.1.md)               | 删除一个或多个镜像.                                                                          |
| [buildah-run(1)](https://github.com/containers/buildah/blob/main/docs/buildah-run.1.md)               | 在容器内运行命令。                                                               |
| [buildah-tag(1)](https://github.com/containers/buildah/blob/main/docs/buildah-tag.1.md)               | 为本地镜像添加一个额外的名称。                                                            |
| [buildah-umount(1)](https://github.com/containers/buildah/blob/main/docs/buildah-umount.1.md)         | 卸载工作容器的根文件系统。                                                      |
| [buildah-unshare(1)](https://github.com/containers/buildah/blob/main/docs/buildah-unshare.1.md)       | 在具有修改后的 ID 映射的用户命名空间中启动命令。                                      |
| [buildah-version(1)](https://github.com/containers/buildah/blob/main/docs/buildah-version.1.md)       | 显示 Buildah 版本信息                                                              |


## 6. 示例
配置别名
```bash
$ vim /root/.bashrc
alias p='podman'
alias b='buildah'
alias s='skopeo'
```

### 6.1 命令行构建一个 httpd 镜像

第一步是提取基本映像并创建工作容器

```bash
$ buildah from fedora
fedora-working-container

$ b ps
CONTAINER ID  BUILDER  IMAGE ID     IMAGE NAME                       CONTAINER NAME
89704476b76a     *     885d2b38b819 registry.fedoraproject.org/fe... fedora-working-container
```
将包添加到工作容器

```bash
buildah run fedora-working-container dnf install httpd -y
```
为Web服务器创建包含某些内容的工作目录：

```bash
mkdir demo-httpd && cd demo-httpd && echo 'sample container' > index.html
```
将本地文件复制到工作容器

```bash
buildah copy fedora-working-container index.html /var/www/html/index.html
```
定义容器入口点以启动应用程序

```bash
buildah config --entrypoint "/usr/sbin/httpd -DFOREGROUND" fedora-working-container
```
配置完成后，保存镜像：

```bash
buildah commit fedora-working-container fedora-myhttpd
```
列出本地镜像

```bash
$ buildah images
REPOSITORY                          TAG      IMAGE ID       CREATED          SIZE
localhost/fedora-myhttpd            latest   e1fb00a4662b   43 seconds ago   434 MB
```
现在可以使用podman在本地利用新生成的镜像运行容器：



```bash
podman run -tid fedora-myhttpd
```
测试

```bash
$ p exec -ti heuristic_solomon curl http://localhost
sample container
```
要将映像推送到本地Docker仓库，请执行以下操作：

```bash
#登陆仓库
$ buildah login -u registryuser -p registryuserpassword 192.168.10.80:5000
Login Succeeded!
#推送
$ buildah push  fedora-myhttpd docker://192.168.10.80:5000/testuser/fedora-myhttpd:latest
Getting image source signatures
Copying blob d4222651a196 done
Copying blob cc6656265656 done
Copying config e1fb00a466 done
Writing manifest to image destination
Storing signatures
```
也可以这样执行：

```bash
buildah push --creds registryuser:registryuserpassword fedora-myhttpd docker://192.168.10.80:5000/testuser/fedora-myhttpd:latest
```
`Skopeo`检查结果

```bash
$ skopeo inspect docker://192.168.10.80:5000/testuser/fedora-myhttpd:latest
```
###  6.2 Dockerfile 构建

```bash
$ mkdir fedora-http-server && cd fedora-http-server 
$ nano Dockerfile
```

```bash
# Base on the most recently released Fedora
FROM fedora:latest
MAINTAINER ipbabble email buildahboy@redhat.com # not a real email

# Install updates and httpd
RUN echo "Updating all fedora packages"; dnf -y update; dnf -y clean all
RUN echo "Installing httpd"; dnf -y install httpd && dnf -y clean all

# Expose the default httpd port 80
EXPOSE 80

# Run the httpd
CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
```
按`CTRL+X`退出，按`Y`保存，按`Enter`退出`nano`

构建

```bash
buildah bud -t fedora-http-server
```
运行容器

```bash
podman run -p 8080:80  -tid fedora-http-server
podman ps
```
测试访问

```bash
curl localhost:8080
```

### 6.3 构建镜像脚本（代替 Dockerfile）
- `build_buildah_upstream.sh`

```bash
#!/usr/bin/env bash
# build_buildah_upstream.sh 
#
ctr=$(buildah from fedora)
buildah config --env GOPATH=/root/buildah $ctr
buildah run $ctr /bin/sh -c 'dnf -y install --enablerepo=updates-testing \
     make \
     golang \
     bats \
     btrfs-progs-devel \
     device-mapper-devel \
     glib2-devel \
     gpgme-devel \
     libassuan-devel \
     libseccomp-devel \
     git \
     bzip2 \
     go-md2man \
     runc \
     fuse-overlayfs \
     fuse3 \
     containers-common; \
     mkdir -p /root/buildah; \
     git clone https://github.com/containers/buildah /root/buildah/src/github.com/containers/buildah; \
     cd /root/buildah/src/github.com/containers/buildah; \
     make; \
     make install; \
     rm -rf /root/buildah/*; \
     dnf -y remove bats git golang go-md2man make; \
     dnf clean all' 

buildah run $ctr -- sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' /etc/containers/storage.conf

buildah run $ctr /bin/sh -c 'mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers; touch /var/lib/shared/overlay-images/images.lock; touch /var/lib/shared/overlay-layers/layers.lock' 

buildah config --env _BUILDAH_STARTED_IN_USERNS="" --env BUILDAH_ISOLATION=chroot $ctr
buildah commit $ctr buildahupstream 
```
构建镜像：

```bash
chmod 755 build_buildah_upstream.sh
./build_buildah_upstream.sh
```
运行容器：

```bash
$ podman run buildahupstream buildah version
$ podman run buildahupstream bash -c "buildah from busybox; buildah images"
```

参考：
- [Building Images With Buildah](https://docs.oracle.com/en/operating-systems/oracle-linux/podman/podman-BuildingImagesWithBuildah.html#buildah-containers)
- [Building with Buildah: Dockerfiles, command line, or scripts](https://www.redhat.com/sysadmin/building-buildah)
