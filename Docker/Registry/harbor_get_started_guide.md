# harbor部署入门指南
tags: registry

 - [docker registry仓库搭建并配置证书](https://ghostwritten.blog.csdn.net/article/details/105926147)
 - [docker部署带有界面的registry仓库](https://ghostwritten.blog.csdn.net/article/details/107406198)
 - [harbor【1】初级部署入门指南](https://ghostwritten.blog.csdn.net/article/details/121381151)
 - [docker圣经](https://ghostwritten.blog.csdn.net/article/details/119462437)
 - [云原生圣经](https://ghostwritten.blog.csdn.net/article/details/108562082)

----------------
## 1. 什么是harbor
[Docker](https://www.docker.com/)有个形象的比喻叫集装箱，[kubernetes](https://kubernetes.io/)是舵手，而[Harbor](https://goharbor.io/)是港湾，其实是用来保存容器镜像的仓库，企业使用docker、kubernetes时，一般都需要个私有镜像仓库的，`Harbor`就是其中的佼佼者。官方的解释：harbor通过策略和基于角色的访问控制来保护工件，确保图像被扫描且没有漏洞，并将图像签名为受信任的。Harbor 是 CNCF 毕业的项目，可提供合规性、性能和互操作性，帮助您跨云原生计算平台（如 Kubernetes 和 Docker）一致且安全地管理工件。

特点：
安全
 - 安全和漏洞分析
 - 内容签名和验证

管理

 - 多租户
 - 可扩展的 API 和 Web UI
 -  跨多个注册中心复制，包括 Harbor
 - 身份集成和基于角色的访问控制

##  2. Harbor的架构  
![在这里插入图片描述](https://img-blog.csdnimg.cn/5f22f15f5fd44e938eefeebf27245a15.png?)

 - `Proxy`: `Harbor`的`registry`、`UI`、`token services`等组件，都处在一个反向代理后边。该代理将来自浏览器、`docker clients`的请求转发到后端服务上。
 - `Registry`: 负责存储`Docker`镜像，以及处理`Docker push/pull`请求。因为`Harbor`强制要求对镜像的访问做权限控制， 在每一次`push/pull`请求时，`Registry`会强制要求客户端从`token service`那里获得一个有效的`token`。

`Core services`: Harbor的核心功能，主要包括如下3个服务:

 - `UI`: 作为`Registry Webhook`, 以图像用户界面的方式辅助用户管理镜像。
 1 WebHook是在registry中配置的一种机制， 当registry中镜像发生改变时，就可以通知到Harbor的`webhook endpoint`。Harbor使用`webhook`来更新日志、初始化同步job等。
 2 `Token service`会根据该用户在一个工程中的角色，为每一次的push/pull请求分配对应的token。假如相应的请求并没有包含token的话，`registry`会将该请求重定向到`token service`。
 3 `Database` 用于存放工程元数据、用户数据、角色数据、同步策略以及镜像元数据。
 - `Job services`: 主要用于镜像复制，本地镜像可以被同步到远程Harbor实例上。
 - `Log`: 负责收集其他模块的日志到一个地方。

##  准备条件
###  Harbor 安装条件
[harbor 安装条件](https://goharbor.io/docs/2.4.0/install-config/installation-prereqs/)
###  docker安装
[docker安装](https://docs.docker.com/engine/install/ubuntu/#installation-methods)
### docker-compose安装
[docker-compose安装](https://ghostwritten.blog.csdn.net/article/details/108769857)

[官方harbor 安装](https://goharbor.io/docs/2.4.0/install-config/download-installer/)

##  3. Harbor http ip部署
### 3.1 harbor安装
```bash
$ tar xzvf harbor-online-installer-v2.3.4.tgz 
harbor/prepare
harbor/LICENSE
harbor/install.sh
harbor/common.sh
harbor/harbor.yml.tmpl
$ ls
harbor  harbor-online-installer-v2.3.4.tgz
$ cd harbor/
harbor/$ ls
common.sh  harbor.yml.tmpl  install.sh  LICENSE  prepare
```

> 如果我们 尝试重新安装的话，一定要保持harbor目录最初解压的样子，当然如果我们重新安装不修改数据目录，应该也要将其删除：`rm -r
> /data/*`

```bash
$ cp harbor.yml.tmpl harbor.yml
$ vim harbor.yml
$ cat harbor.yml|grep -v '#' |grep -v '^$'
hostname: 192.168.211.70
http:
  port: 80
harbor_admin_password: 123456
database:
  password: root123
  max_idle_conns: 100
  max_open_conns: 900
data_volume: /data
trivy:
  ignore_unfixed: false
  skip_update: false
  insecure: false
jobservice:
  max_job_workers: 10
notification:
  webhook_job_max_retry: 10
chart:
  absolute_url: disabled
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
_version: 2.3.0
proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - trivy
```
我修改如下：

 - hostname为本机的ip地址：192.168.211.70
 - 注释掉了https部分的相关配置


> 也许你在配置文件`harbor.yaml`有改密码的冲动，但在注释中的解释说我们应该在登陆界面ui去修改它，因此，如果配置文件修改了admin的登陆密码为：123456，也许会报错，不管怎么说，我遇到了，也许是我的浏览器缓存问题。或者部署机器的杂质问题。

```bash
$ ./prepare 
prepare base dir is set to /root/harbor/harbor1/harbor
WARNING:root:WARNING: HTTP protocol is insecure. Harbor will deprecate http protocol in the future. Please make sure to upgrade to https
Generated configuration file: /config/portal/nginx.conf
Generated configuration file: /config/log/logrotate.conf
Generated configuration file: /config/log/rsyslog_docker.conf
Generated configuration file: /config/nginx/nginx.conf
Generated configuration file: /config/core/env
Generated configuration file: /config/core/app.conf
Generated configuration file: /config/registry/config.yml
Generated configuration file: /config/registryctl/env
Generated configuration file: /config/registryctl/config.yml
Generated configuration file: /config/db/env
Generated configuration file: /config/jobservice/env
Generated configuration file: /config/jobservice/config.yml
Generated and saved secret to file: /data/secret/keys/secretkey
Successfully called func: create_root_cert
Generated configuration file: /compose_location/docker-compose.yml
Clean up the input dir

#会在/data目录生成一些配置和数据。
$ ls /data/
ca_download  database  job_logs  redis  registry  secret
```
由于我们部署的是非安全的harbor，我们不要忘了对docker的配置做一些修改。添加`insecure-registries`参数。

```bash
$ cat /etc/docker/daemon.json 
{
   "exec-opts": ["native.cgroupdriver=systemd"],
   "log-driver": "json-file",
   "log-opts": {
   "max-size":  "100m"
    },
   "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
   "insecure-registries": [
       "192.168.211.70"
  ]
 }
```
然后部署安装，如果第一次可能因为拉取镜像有点慢，但往后部署也就几秒钟的时间。

```bash
$ ./install.sh 

[Step 0]: checking if docker is installed ...

Note: docker version: 20.10.10

[Step 1]: checking docker-compose is installed ...

Note: docker-compose version: 2.1.1


[Step 2]: preparing environment ...

[Step 3]: preparing harbor configs ...
prepare base dir is set to /root/harbor/harbor1/harbor
WARNING:root:WARNING: HTTP protocol is insecure. Harbor will deprecate http protocol in the future. Please make sure to upgrade to https
Clearing the configuration file: /config/nginx/nginx.conf
Clearing the configuration file: /config/core/app.conf
Clearing the configuration file: /config/core/env
Clearing the configuration file: /config/portal/nginx.conf
Clearing the configuration file: /config/registryctl/config.yml
Clearing the configuration file: /config/registryctl/env
Clearing the configuration file: /config/registry/passwd
Clearing the configuration file: /config/registry/config.yml
Clearing the configuration file: /config/log/rsyslog_docker.conf
Clearing the configuration file: /config/log/logrotate.conf
Clearing the configuration file: /config/jobservice/config.yml
Clearing the configuration file: /config/jobservice/env
Clearing the configuration file: /config/db/env
Generated configuration file: /config/portal/nginx.conf
Generated configuration file: /config/log/logrotate.conf
Generated configuration file: /config/log/rsyslog_docker.conf
Generated configuration file: /config/nginx/nginx.conf
Generated configuration file: /config/core/env
Generated configuration file: /config/core/app.conf
Generated configuration file: /config/registry/config.yml
Generated configuration file: /config/registryctl/env
Generated configuration file: /config/registryctl/config.yml
Generated configuration file: /config/db/env
Generated configuration file: /config/jobservice/env
Generated configuration file: /config/jobservice/config.yml
loaded secret from file: /data/secret/keys/secretkey
Generated configuration file: /compose_location/docker-compose.yml
Clean up the input dir



[Step 4]: starting Harbor ...
[+] Running 10/10
 ⠿ Network harbor_harbor        Created                                                                                                                                                                                                                0.1s
 ⠿ Container harbor-log         Started                                                                                                                                                                                                                2.2s
 ⠿ Container registry           Started                                                                                                                                                                                                                5.5s
 ⠿ Container harbor-portal      Started                                                                                                                                                                                                                6.1s
 ⠿ Container registryctl        Started                                                                                                                                                                                                                8.2s
 ⠿ Container redis              Started                                                                                                                                                                                                                8.7s
 ⠿ Container harbor-db          Started                                                                                                                                                                                                                6.5s
 ⠿ Container harbor-core        Started                                                                                                                                                                                                               10.1s
 ⠿ Container nginx              Started                                                                                                                                                                                                               12.4s
 ⠿ Container harbor-jobservice  Started                                                                                                                                                                                                               13.4s
✔ ----Harbor has been installed and started successfully.----

$ docker ps
CONTAINER ID   IMAGE                                COMMAND                  CREATED          STATUS                    PORTS                                         NAMES
aace64158bb9   goharbor/nginx-photon:v2.3.4         "nginx -g 'daemon of…"   20 minutes ago   Up 20 minutes (healthy)   0.0.0.0:80->8080/tcp, 0.0.0.0:443->8443/tcp   nginx
2fb44007a910   goharbor/harbor-jobservice:v2.3.4    "/harbor/entrypoint.…"   21 minutes ago   Up 20 minutes (healthy)                                                 harbor-jobservice
07e9c7fc4789   goharbor/harbor-core:v2.3.4          "/harbor/entrypoint.…"   21 minutes ago   Up 20 minutes (healthy)                                                 harbor-core
6a530d9902f0   goharbor/redis-photon:v2.3.4         "redis-server /etc/r…"   21 minutes ago   Up 20 minutes (healthy)                                                 redis
857e8929f318   goharbor/registry-photon:v2.3.4      "/home/harbor/entryp…"   21 minutes ago   Up 20 minutes (healthy)                                                 registry
a6f1e3951798   goharbor/harbor-registryctl:v2.3.4   "/home/harbor/start.…"   21 minutes ago   Up 20 minutes (healthy)                                                 registryctl
044a0dbe8f0f   goharbor/harbor-db:v2.3.4            "/docker-entrypoint.…"   21 minutes ago   Up 20 minutes (healthy)                                                 harbor-db
3a111e636acd   goharbor/harbor-portal:v2.3.4        "nginx -g 'daemon of…"   21 minutes ago   Up 20 minutes (healthy)                                                 harbor-portal
da038195ace4   goharbor/harbor-log:v2.3.4           "/bin/sh -c /usr/loc…"   21 minutes ago   Up 20 minutes (healthy)   127.0.0.1:1514->10514/tcp                     harbor-log

$ docker-compose ps
NAME                COMMAND                  SERVICE             STATUS              PORTS
harbor-core         "/harbor/entrypoint.…"   core                running (healthy)   
harbor-db           "/docker-entrypoint.…"   postgresql          running (healthy)   
harbor-jobservice   "/harbor/entrypoint.…"   jobservice          running (healthy)   
harbor-log          "/bin/sh -c /usr/loc…"   log                 running (healthy)   127.0.0.1:1514->10514/tcp
harbor-portal       "nginx -g 'daemon of…"   portal              running (healthy)   
nginx               "nginx -g 'daemon of…"   proxy               running (healthy)   0.0.0.0:80->8080/tcp, 0.0.0.0:443->8443/tcp
redis               "redis-server /etc/r…"   redis               running (healthy)   
registry            "/home/harbor/entryp…"   registry            running (healthy)   
registryctl         "/home/harbor/start.…"   registryctl         running (healthy)   
```
Harbor安装结束，我们验证一下。

###  3.2 测试结果
#### 3.2.1 仓库登陆

```bash
$ docker login 192.168.211.70
Authenticating with existing credentials...
Stored credentials invalid or expired
Username (admin): admin
Password: 隐藏输入（Harbor12345）
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```
####  4.2.2 界面登陆
界面登陆用户密码：`admin/Harbor12345`
![在这里插入图片描述](https://img-blog.csdnimg.cn/a7a7d5549a1f40d0b65e0b7be063d534.png?)

####  4.2.3 修改密码
现在我们把admin的初始密码`Harbor12345`改为`123456`，试一试。

![在这里插入图片描述](https://img-blog.csdnimg.cn/9d2bc5be0121467fb47e3492396e08eb.png?)
**发现原来admin密码的设置要支持大小写字符并且有数字**。
![修改harbor密码](https://img-blog.csdnimg.cn/5a0b26bd78b4463ebb89e67d0bfcd0fd.png?)
那么我们把`admin`的密码改为`Ghost12345`
![在这里插入图片描述](https://img-blog.csdnimg.cn/f14ae54830004ff1af12939af2afdcc9.png?)
修改成功，并且退出重新登陆成功了（图略）。
当然，我们的仓库登陆密码也会随之变化。

```bash
$ docker login 192.168.211.70
Authenticating with existing credentials...
Stored credentials invalid or expired
Username (admin): 
Password: 隐藏输入（Ghost12345）
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```
#### 4.2.4 推送镜像
我们要把镜像推送到仓库，那么镜像名要遵守恰当的格式

```bash
docker push 仓库名/项目名/镜像名:标签
```
我们的仓库名是`192.168.211.70`,项目名当前默认是`library`，当然我们可以根据自己的需求在界面创建一个新的项目名。例如base
![在这里插入图片描述](https://img-blog.csdnimg.cn/9af19670e1904bd0bfb7c4227d86cf5b.png?)
然后给一个镜像打一个标签。推送到仓库。

```bash
$ docker tag busybox:latest 192.168.211.70/base/busybox:latest
$ docker push 192.168.211.70/base/busybox:latest
The push refers to repository [192.168.211.70/base/busybox]
cfd97936a580: Pushed 
latest: digest: sha256:febcf61cd6e1ac9628f6ac14fa40836d16f3c6ddef3b303ff0321606e55ddd0b size: 527
```
界面我们也能看到推送进来的镜像。
![在这里插入图片描述](https://img-blog.csdnimg.cn/f4003f76b7ea4ae9b868dc6a8c0538c6.png?)
#### 4.2.5 拉取镜像  
我们换到另一台机器尝试一下拉取这个镜像，要怎么做呢？修改`/etc/docker/daemon.json` 添加`insecure-registries`参数是最为关键的一步。

```bash
$  vim /etc/docker/daemon.json 
{
   "exec-opts": ["native.cgroupdriver=systemd"],
   "log-driver": "json-file",
   "log-opts": {
   "max-size":  "100m"
    },
   "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
    "insecure-registries": [
       "192.168.211.70"
  ]
 }

$ systemctl daemon-reload && systemctl restart docker

#拉取成功
$ docker pull 192.168.211.70/base/busybox:latest
latest: Pulling from base/busybox
24fb2886d6f6: Pull complete 
Digest: sha256:febcf61cd6e1ac9628f6ac14fa40836d16f3c6ddef3b303ff0321606e55ddd0b
Status: Downloaded newer image for 192.168.211.70/base/busybox:latest
192.168.211.70/base/busybox:latest
```




 [配置 Harbor YML 文件](https://goharbor.io/docs/2.4.0/install-config/configure-yml-file/)


![在这里插入图片描述](https://img-blog.csdnimg.cn/b223471adbd54a3b8b1721bd52943829.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBAZ2hvc3R3cml0dGVu,size_20,color_FFFFFF,t_70,g_se,x_16)

##  4. Harbor http 域名部署
### 4.1 清理杂质
```bash
$ docker-compose down
[+] Running 10/10
 ⠿ Container harbor-jobservice  Removed                                                                                                                                                                                                               10.5s
 ⠿ Container registryctl        Removed                                                                                                                                                                                                               10.5s
 ⠿ Container nginx              Removed                                                                                                                                                                                                                0.5s
 ⠿ Container harbor-portal      Removed                                                                                                                                                                                                                0.4s
 ⠿ Container harbor-core        Removed                                                                                                                                                                                                               10.5s
 ⠿ Container redis              Removed                                                                                                                                                                                                                1.0s
 ⠿ Container harbor-db          Removed                                                                                                                                                                                                                0.9s
 ⠿ Container registry           Removed                                                                                                                                                                                                               11.1s
 ⠿ Container harbor-log         Removed                                                                                                                                                                                                               10.7s
 ⠿ Network harbor_harbor        Removed 

$ rm -rf /data/*
$ rm -rf common          
```
浏览器界面清理缓存
### 4.2 修改配置
a. `harbor.yaml`配置文件只修改了`hostname`参数

```bash
hostname: ghost.harbor.com
```
b. 
```bash
$ echo "192.168.211.70 ghost.harbor.com" >> /etc/hosts

$ nslookup ghost.harbor.com
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
Name:	ghost.harbor.com
Address: 192.168.211.70
```
c.
docker配置文件`/etc/docker/daemon.json` 参数`insecure-registries` 由`192.168.211.70`修改为`ghost.harbor.com`

```bash
$ cat /etc/docker/daemon.json 
{
   "exec-opts": ["native.cgroupdriver=systemd"],
   "log-driver": "json-file",
   "log-opts": {
   "max-size":  "100m"
    },
   "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
   "insecure-registries": [
       "ghost.harbor.com"
  ]
 }
```

并重启docker
```bash
systemctl daemon-reload && systemctl restart docker
```

### 4.3 harbor安装

```bash
$ ./prepare 
$ ./install.sh 
$ docker ps
$ docker-compose ps
```
### 4.3 测试结果
####  4.3.1 仓库登陆
```bash
$ docker login ghost.harbor.com
Username: admin
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```
####  4.3.2 界面登陆
本机windows配置
```bash
C:\Windows\System32\drivers\etc\hosts
192.168.211.70 ghost.harbor.com
```
访问：`http://ghost.harbor.com`
用户名/密码：`admin`/`Harbor12345`

登陆成功
![在这里插入图片描述](https://img-blog.csdnimg.cn/ef4e6398233b4a69be3fb4921c2db283.png?)
####  4.3.3 镜像推送

```bash
$ docker tag busybox:latest ghost.harbor.com/library/busybox:latest

$ docker push ghost.harbor.com/library/busybox:latest
The push refers to repository [ghost.harbor.com/library/busybox]
cfd97936a580: Pushed 
latest: digest: sha256:febcf61cd6e1ac9628f6ac14fa40836d16f3c6ddef3b303ff0321606e55ddd0b size: 527
```
Harbor http域名访问的部署结束。

----

##  5. Harbor https ip访问部署
默认情况下，Harbor 不附带证书。可以在没有安全性的情况下部署 Harbor，以便您可以通过 HTTP 连接到它。但是，仅在没有连接到外部 Internet 的气隙测试或开发环境中才可接受使用 HTTP。在公有环境中使用 HTTP 会使您面临中间人攻击。在生产环境中，始终使用 HTTPS。如果您启用 `Content Trust with Notary` 以正确签署所有图像，则必须使用 HTTPS。

要配置 HTTPS，您必须创建 SSL 证书。您可以使用受信任的第三方 CA 签署的证书，也可以使用自签名证书。本节介绍如何使用 [OpenSSL](https://www.openssl.org/)创建 CA，以及如何使用您的 CA 签署服务器证书和客户端证书。您可以使用其他 CA 提供商，例如 [Let's Encrypt](https://letsencrypt.org/)。

以下过程假设您的 Harbor 注册表的主机名是`192.168.211.70`，并且其 DNS 记录指向您运行 Harbor 的主机。
### 5.1 清理杂质
```bash
$ docker-compose down
[+] Running 10/10
 ⠿ Container harbor-jobservice  Removed                                                                                                                                                                                                               10.5s
 ⠿ Container registryctl        Removed                                                                                                                                                                                                               10.5s
 ⠿ Container nginx              Removed                                                                                                                                                                                                                0.5s
 ⠿ Container harbor-portal      Removed                                                                                                                                                                                                                0.4s
 ⠿ Container harbor-core        Removed                                                                                                                                                                                                               10.5s
 ⠿ Container redis              Removed                                                                                                                                                                                                                1.0s
 ⠿ Container harbor-db          Removed                                                                                                                                                                                                                0.9s
 ⠿ Container registry           Removed                                                                                                                                                                                                               11.1s
 ⠿ Container harbor-log         Removed                                                                                                                                                                                                               10.7s
 ⠿ Network harbor_harbor        Removed 

$ rm -rf /data/*
$ rm -rf common          
```
### 5.2 修改配置

#### 5.2.1 harbor.yaml
 `harbor.yaml`配置文件修改`hostname`参数并配置了https相关参数

```bash
$ cat harbor.yml|grep -v '#' | grep -v '^$'
hostname: 192.168.211.70 
http:
  port: 80
https:
  port: 443
  certificate: /data/cert/192.168.211.70.crt
  private_key: /data/cert/192.168.211.70.key
harbor_admin_password: Harbor12345
database:
  password: root123
  max_idle_conns: 100
  max_open_conns: 900
data_volume: /data
trivy:
  ignore_unfixed: false
  skip_update: false
  insecure: false
jobservice:
  max_job_workers: 10
notification:
  webhook_job_max_retry: 10
chart:
  absolute_url: disabled
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
_version: 2.3.0
proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - trivy
```
#### 5.2.2 /etc/docker/daemon.json
docker配置文件`/etc/docker/daemon.json` 参数`insecure-registries` 要把它去掉。

```bash
$ cat /etc/docker/daemon.json 
{
   "exec-opts": ["native.cgroupdriver=systemd"],
   "log-driver": "json-file",
   "log-opts": {
   "max-size":  "100m"
    },
   "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
 }
```

并重启docker
```bash
systemctl daemon-reload && systemctl restart docker
```
####  5.2.3 生成证书颁发机构证书
在生产环境中，您应该从 CA 获取证书。在测试或开发环境中，您可以生成自己的 CA。要生成 CA 证书，请运行以下命令。
生成 CA 证书私钥
```bash
$ openssl genrsa -out ca.key 4096
Generating RSA private key, 4096 bit long modulus (2 primes)
..............++++
.................................++++
e is 65537 (0x010001)
```
生成 CA 证书
调整`-subj`选项中的值以反映您的组织。如果使用 `FQDN` 连接 `Harbor` 主机，则必须将其指定为公用名 ( CN) 属性。

```bash
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=192.168.211.70" \
 -key ca.key \
 -out ca.crt
```
####  5.2.4 生成服务器证书
证书通常包含一个.crt文件和一个.key文件，例如，`192.168.211.70.crt`和`192.168.211.70.key`.
**生成私钥**

```bash
openssl genrsa -out 192.168.211.70.key 4096
```
**生成证书签名请求 (CSR)**
调整`-subj`选项中的值以反映您的组织。如果使用 FQDN 连接 Harbor 主机，则必须将其指定为公用名 ( CN) 属性并在密钥和 CSR 文件名中使用它。

```bash
openssl req -sha512 -new \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=192.168.211.70" \
    -key 192.168.211.70.key \
    -out 192.168.211.70.csr
```
**生成 x509 v3 扩展文件**
无论您是使用 FQDN 还是 IP 地址连接到您的 Harbor 主机，您都必须创建此文件，以便为您的 Harbor 主机生成符合主题备用名称 (SAN) 和 x509 v3 的证书扩展要求。替换DNS条目以反映您的域。

**使用该`extfile.cnf`文件为您的 Harbor 主机生成证书**
将192.168.211.70CRS 和 CRT 文件名中的 替换为 Harbor 主机名
```bash
echo subjectAltName = IP:192.168.211.70 > extfile.cnf
```
```bash
openssl x509 -req -sha512 -days 3650 \
    -extfile extfile.cnf \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in 192.168.211.70.csr \
    -out 192.168.211.70.crt
```

#### 5.2.5 向 Harbor 和 Docker 提供证书
生成后`ca.crt`，`192.168.211.70.crt`和`192.168.211.70.key`文件，必须将它们提供给Harbor and  Docker，和重新配置harbor使用它们。
**a. 将服务器证书和密钥复制到 Harbor 主机上的 certficates 文件夹中**

```bash
mkdir /data/cert
cp 192.168.211.70.crt /data/cert/
cp 192.168.211.70.key /data/cert/
```
**b. 转换192.168.211.70.crt为192.168.211.70.cert，供 Docker 使用**
Docker 守护进程将.crt文件解释为 CA 证书，将.cert文件解释为客户端证书。

```bash
openssl x509 -inform PEM -in 192.168.211.70.crt -out 192.168.211.70.cert
```
**c. 将服务器证书、密钥和 CA 文件复制到 Harbor 主机上的 Docker 证书文件夹中。您必须首先创建适当的文件夹。**

```bash
mkdir -p /etc/docker/certs.d/192.168.211.70/
cp 192.168.211.70.cert /etc/docker/certs.d/192.168.211.70/
cp 192.168.211.70.key /etc/docker/certs.d/192.168.211.70/
cp ca.crt /etc/docker/certs.d/192.168.211.70/
```
如果您将默认nginx端口 443映射到其他端口，请创建文件夹`/etc/docker/certs.d/192.168.211.70:port`或`/etc/docker/certs.d/harbor_IP:port`。
**d. 重启docker**

```bash
systemctl daemon-reload && systemctl restart docker
```
#### 5.2.6 操作系统级别信任证书
e. **当 Docker 守护程序在某些操作系统上运行时，您可能需要在操作系统级别信任证书**。
例如，运行以下命令
**ubuntu**
```bash
$ cp 192.168.211.70.crt /usr/local/share/ca-certificates/192.168.211.70.crt 
$ update-ca-certificates
Updating certificates in /etc/ssl/certs...
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```
**Red Hat (CentOS etc)**:

```bash
$ cp yourdomain.com.crt /etc/pki/ca-trust/source/anchors/yourdomain.com.crt
$ update-ca-trust
```

### 5.3 部署或重新配置 Harbor
如果您尚未部署 Harbor，请参阅 [配置 Harbor YML 文件](https://goharbor.io/docs/2.4.0/install-config/configure-yml-file/)以获取有关如何通过在 中指定`hostname`和`https`属性来配置 Harbor 以使用证书的信息`harbor.yml`。

如果您已经使用 HTTP 部署了 Harbor 并希望将其重新配置为使用 HTTPS，请执行以下步骤。
**a. 运行prepare脚本以启用 HTTPS**

```bash
./prepare
```
**b. 如果 Harbor 正在运行，请停止并删除现有实例**

您的图像数据保留在文件系统中，因此不会丢失任何数据。

```bash
docker-compose down -v
```

**c. 重启**

```bash
docker-compose up -d
```
### 5.4 测试结果
####  5.4.1 仓库登陆

```bash
$ docker login 192.168.211.70
Authenticating with existing credentials...
Stored credentials invalid or expired
Username (admin): admin
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

####  5.4.2 界面登陆
https://192.168.211.70
用户密码：admin/Harbor12345
![在这里插入图片描述](https://img-blog.csdnimg.cn/cfc4bbcdfcbd477296b3d48e9e4bbfcc.png?)
#### 5.4.3 推送镜像

```bash
$ docker push 192.168.211.70/library/alpine:v1.0 
The push refers to repository [192.168.211.70/library/alpine]
e2eb06d8af82: Pushed 
v1.0: digest: sha256:69704ef328d05a9f806b6b8502915e6a0a4faa4d72018dc42343f511490daf8a size: 528
```
####  5.4.4 拉取镜像
我们换到另一台机器尝试一下拉取这个镜像，需要什么配置呢，不需要什么，只需连通即可。

```bash
$ cat /etc/docker/daemon.json 
{
   "exec-opts": ["native.cgroupdriver=systemd"],
   "log-driver": "json-file",
   "log-opts": {
   "max-size":  "100m"
    },
   "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
 }
```

```bash
$ docker pull 192.168.211.70/library/alpine:v1.0
v1.0: Pulling from library/alpine
a0d0a0d46f8b: Pull complete 
Digest: sha256:69704ef328d05a9f806b6b8502915e6a0a4faa4d72018dc42343f511490daf8a
Status: Downloaded newer image for 192.168.211.70/library/alpine:v1.0
192.168.211.70/library/alpine:v1.0
```
harbor https ip访问部署成功结束

-----
##  6 Harbor https 域名访问部署
### 6.1 清理杂质
```bash
$ docker-compose down
[+] Running 10/10
 ⠿ Container harbor-jobservice  Removed                                                                                                                                                                                                               10.5s
 ⠿ Container registryctl        Removed                                                                                                                                                                                                               10.5s
 ⠿ Container nginx              Removed                                                                                                                                                                                                                0.5s
 ⠿ Container harbor-portal      Removed                                                                                                                                                                                                                0.4s
 ⠿ Container harbor-core        Removed                                                                                                                                                                                                               10.5s
 ⠿ Container redis              Removed                                                                                                                                                                                                                1.0s
 ⠿ Container harbor-db          Removed                                                                                                                                                                                                                0.9s
 ⠿ Container registry           Removed                                                                                                                                                                                                               11.1s
 ⠿ Container harbor-log         Removed                                                                                                                                                                                                               10.7s
 ⠿ Network harbor_harbor        Removed 

$ rm -rf /data/*
$ rm -rf common         
$ rm -rf /etc/docker/certs.d/* 
```
### 6.2 修改配置

#### 6.2.1 harbor.yaml
 `harbor.yaml`配置文件修改`hostname`参数并重新配置了https相关参数

```bash
$ cat harbor.yml|grep -v '#' | grep -v '^$'
hostname: ghost.harbor.com
http:
  port: 80
https:
  port: 443
  certificate: /data/cert/ghost.harbor.com.crt
  private_key: /data/cert/ghost.harbor.com.key
harbor_admin_password: Harbor12345
database:
  password: root123
  max_idle_conns: 100
  max_open_conns: 900
data_volume: /data
trivy:
  ignore_unfixed: false
  skip_update: false
  insecure: false
jobservice:
  max_job_workers: 10
notification:
  webhook_job_max_retry: 10
chart:
  absolute_url: disabled
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
_version: 2.3.0
proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - trivy
```
#### 6.2.2 /etc/docker/daemon.json
如下：

```bash
$ cat /etc/docker/daemon.json 
{
   "exec-opts": ["native.cgroupdriver=systemd"],
   "log-driver": "json-file",
   "log-opts": {
   "max-size":  "100m"
    },
   "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
 }
```

并重启docker
```bash
systemctl daemon-reload && systemctl restart docker
```
### 6.3 配置证书
####  6.3.1  生成证书颁发机构证书
```bash
#生成 CA 证书私钥
$ openssl genrsa -out ca.key 4096

#生成 CA 证书
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=ghost.harbor.com" \
 -key ca.key \
 -out ca.crt
```
####  6.3.2 生成服务器证书
```bash
#生成私钥
openssl genrsa -out ghost.harbor.com.key 4096

#生成证书签名请求 (CSR)
openssl req -sha512 -new \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=ghost.harbor.com" \
    -key ghost.harbor.com.key \
    -out ghost.harbor.com.csr

#生成 x509 v3 扩展文件**
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=ghost.harbor.com
DNS.2=ghost.harbor
DNS.3=hostname
EOF


#使用该v3.ext文件为您的 Harbor 主机生成证书
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in ghost.harbor.com.csr \
    -out ghost.harbor.com.crt
```

#### 6.3.4 向 Harbor 和 Docker 提供证书



```bash
#a. 将服务器证书和密钥复制到 Harbor 主机上的 certficates 文件夹中**
mkdir /data/cert
cp ghost.harbor.com.crt /data/cert/
cp ghost.harbor.com.key /data/cert/

#b. 转换ghost.harbor.com.crt为ghost.harbor.com.cert，供 Docker 使用**
openssl x509 -inform PEM -in ghost.harbor.com.crt -out ghost.harbor.com.cert

#**c. 将服务器证书、密钥和 CA 文件复制到 Harbor 主机上的 Docker 证书文件夹中。您必须首先创建适当的文件夹。**
mkdir -p /etc/docker/certs.d/ghost.harbor.com/
cp ghost.harbor.com.cert /etc/docker/certs.d/ghost.harbor.com/
cp ghost.harbor.com.key /etc/docker/certs.d/ghost.harbor.com/
cp ca.crt /etc/docker/certs.d/ghost.harbor.com/
```

> 如果您将默认nginx端口443映射到其他端口，请创建文件夹`/etc/docker/certs.d/ghost.harbor.com:port`或`/etc/docker/certs.d/harbor_IP:port`。

重启docker
```bash

systemctl daemon-reload && systemctl restart docker
```
#### 6.3.5 操作系统级别信任证书
e. **当 Docker 守护程序在某些操作系统上运行时，您可能需要在操作系统级别信任证书**。

**ubuntu**
```bash
$ cp ghost.harbor.com.crt /usr/local/share/ca-certificates/ghost.harbor.com.crt 
$ update-ca-certificates
Updating certificates in /etc/ssl/certs...
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```
**Red Hat (CentOS etc)**:

```bash
$ cp ghost.harbor.com.crt /etc/pki/ca-trust/source/anchors/ghost.harbor.com.crt
$ update-ca-trust
```

### 6.4 部署或重新配置 Harbor
如果您尚未部署 Harbor，请参阅 [配置 Harbor YML 文件](https://goharbor.io/docs/2.4.0/install-config/configure-yml-file/)以获取有关如何通过在 中指定`hostname`和`https`属性来配置 Harbor 以使用证书的信息`harbor.yml`。

如果您已经使用 HTTP 部署了 Harbor 并希望将其重新配置为使用 HTTPS，请执行以下步骤。
**a. 运行prepare脚本以启用 HTTPS**

```bash
./prepare
```
**b. 如果 Harbor 正在运行，请停止并删除现有实例**

您的图像数据保留在文件系统中，因此不会丢失任何数据。

```bash
docker-compose down -v
```

**c. 重启**

```bash
docker-compose up -d
```

### 6.5 测试
####  6.5.1 仓库登陆

```bash
$ docker login ghost.harbor.com
Authenticating with existing credentials...
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

####  6.5.2 界面登陆
![在这里插入图片描述](https://img-blog.csdnimg.cn/348d588802ca4ea1917ef48e778838c2.png?)
####  6.5.3 推送镜像

```bash
$ docker push ghost.harbor.com/library/busybox:latest 
The push refers to repository [ghost.harbor.com/library/busybox]
cfd97936a580: Pushed 
latest: digest: sha256:febcf61cd6e1ac9628f6ac14fa40836d16f3c6ddef3b303ff0321606e55ddd0b size: 527
```
####  6.5.4 拉取镜像
我们换到另一台机器`192.168.211.71`尝试一下拉取这个镜像，需要什么配置呢，
`/etc/docker/daemon.json`配置如下：
```bash
$ cat /etc/docker/daemon.json 
{
   "exec-opts": ["native.cgroupdriver=systemd"],
   "log-driver": "json-file",
   "log-opts": {
   "max-size":  "100m"
    },
   "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
 }
```
配置`/etc/hosts`

```bash
192.168.211.70 ghost.harbor.com
```

> 如果没有配置hosts可能会报这样的错 $ docker pull
> ghost.harbor.com/library/busybox:latest Error response from daemon:
> Get https://ghost.harbor.com/v2/: `x509: certificate has expire`d or is
> not yet valid 当然，也有可能是两台机器的时间没有同步，需要配置`ntp`

 另外要配置docker证书

```bash
mkdir -p /etc/docker/certs.d/ghost.harbor.com/
scp root@192.168.211.70:/etc/docker/certs.d/ghost.harbor.com/ghost.harbor.com.cert /etc/docker/certs.d/ghost.harbor.com/
scp root@192.168.211.70:/etc/docker/certs.d/ghost.harbor.com/ghost.harbor.com.key /etc/docker/certs.d/ghost.harbor.com/
scp root@192.168.211.70:/etc/docker/certs.d/ghost.harbor.com/ca.crt /etc/docker/certs.d/ghost.harbor.com/
```

> 如果没有证书将会这样报错 
> $ docker pull ghost.harbor.com/library/busybox:latest
> Error response from daemon: Get https://ghost.harbor.com/v2/: x509:
> `certificate signed by unknown authority`

最后，经历重重险阻，成功了。
```bash
docker pull ghost.harbor.com/library/busybox:latest
latest: Pulling from library/busybox
Digest: sha256:febcf61cd6e1ac9628f6ac14fa40836d16f3c6ddef3b303ff0321606e55ddd0b
Status: Downloaded newer image for ghost.harbor.com/library/busybox:latest
ghost.harbor.com/library/busybox:latest

```
harbor https ip访问部署成功结束

浏览器界面清理缓存

参考：

- [多种模式部署](https://goharbor.io/docs/2.4.0/install-config/run-installer-script/)
- [配置 Harbor 组件之间的内部 TLS 通信](https://goharbor.io/docs/2.4.0/install-config/configure-internal-tls/)
- [Harbor 安装故障排除](https://goharbor.io/docs/2.4.0/install-config/troubleshoot-installation/)
- [重新配置 Harbor 并管理 Harbor 生命周期](https://goharbor.io/docs/2.4.0/install-config/reconfigure-manage-lifecycle/)
- [自定义 Harbor 令牌服务](https://goharbor.io/docs/2.4.0/install-config/customize-token-service/)

