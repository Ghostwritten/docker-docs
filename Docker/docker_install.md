# 2. docker 安装


## 1. centos 安装 docker

yum-utils提供了yum-config-manager 效用，并device-mapper-persistent-data和lvm2由需要 devicemapper存储驱动程序
```bash
yum install -y yum-utils  device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```
可选：启用边缘和测试存储库。这些存储库包含在docker.repo上面的文件中，但默认情况下处于禁用状态。您可以将它们与稳定的存储库一起启用。

```bash
sudo yum-config-manager --enable docker-ce-edge
sudo yum-config-manager --enable docker-ce-test
```
禁用

```bash
$ sudo yum-config-manager --disable docker-ce-edge
```


按版本号排序结果

```bash
$ yum list docker-ce --showduplicates | sort -r
$ sudo yum -y install docker-ce
$ sudo systemctl start docke
$ sudo docker run hello-world
```
卸载Docker包：

```bash
$ sudo yum remove docker-ce
```

不会自动删除主机上的图像，容器，卷或自定义配置文件。删除所有图像，容器和卷：

```bash
$ sudo rm -rf /var/lib/docker
```

## 2. docker 1.13 安装
导入安装源:
  

```bash
rpm --import "https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e"
```

  如果没有响应使用：pgp.mit.edu 或keyserver.ubuntu.com

```bash
  yum-config-manager --add-repo https://packages.docker.com/1.13/yum/repo/main/centos/7
```

安装：

```bash
  yum makecache fast
  yum install -y docker-engine
```

注意：安装其他cs版本

```bash
  yum list docker-engine.x86_64  --showduplicates |sort -r
  yum installdocker-engine-<version>
```

## 3. docker 17.09.0-ce 安装

```bash
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
 rpm -ivh epel-release-latest-7.noarch.rpm

wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-17.09.0.ce-1.el7.centos.x86_64.rpm
yum -y install  docker-engine-selinux
yum -y remove  selinux-policy-targeted-3.13.1-192.0.5.el7_5.6.noarch
yum -y install  docker-engine-selinux

yum -y install container-selinux-2.68-1.el7.noarch.rpm
yumdownloader --resolve container-selinux
```

## 4. oracle 7.4 安装 docker

```bash
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
 rpm -ivh epel-release-latest-7.noarch.rpm
yum -y install  docker-engine-selinux
yum -y remove  selinux-policy-targeted-3.13.1-192.0.5.el7_5.6.noarch
yum -y install  docker-engine-selinux
yum -y install container-selinux-2.68-1.el7.noarch.rpm
yumdownloader --resolve container-selinux
yum -y install docker-ce
```

参考：

 - [安装 docker](https://docs.docker.com/install/)
 - [下载 docker ](https://download.docker.com/)
