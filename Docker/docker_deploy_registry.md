#  docker registry 仓库搭建并配置证书

## 1. 仓库简介

Docker Registry，它是所有仓库（包括共有和私有）以及工作流的中央Registry

 - Repositories（仓库）可以被标记为喜欢或者像书签一样标记起来。
 - 用户可以在仓库下评论。
 - 私有仓库和共有仓库类似，不同之处在于前者不会在搜索结果中显示，也没有访问它的权限。只有用户设置为合作者才能访问私有仓库。
 - 成功推送之后配置webhooks。
 
## 2. Docker Registry角色
Docker Registry有三个角色，分别是`index`、`registry`和`registry client`。

### 2.1 Index
index 负责并维护有关用户帐户、镜像的校验以及公共命名空间的信息。它使用以下组件维护这些信息：

 - Web UI
 - 元数据存储
 - 认证服务
 - 符号化

这也分解了较长的URL，以方便使用和验证用户存储库。

### 2.2 Registry
`registry`是镜像和图表的仓库。然而，它没有一个本地数据库，也不提供用户的身份认证，由S3、云文件和本地文件系统提供数据库支持。此外，通过`Index Auth service`的`Token`方式进行身份认证。Registries可以有不同的类型。现在让我们来分析其中的几种类型：

 - `Sponsor Registry`：第三方的registry，供客户和Docker社区使用。
 - `Mirror Registry`：第三方的registry，只让客户使用。
 - `Vendor Registry`：由发布Docker镜像的供应商提供的registry。
 - `Private Registry`：通过设有防火墙和额外的安全层的私有实体提供的registry。

### 2.3 Registry Client

Docker充当registry客户端来负责维护推送和拉取的任务，以及客户端的授权。



## 3. registry部署
### 3.1 拉取镜像
```csharp
docker pull registry
```

报错`net/http: TLS handshake timeout`

修改docker配置,使用国内镜像 daocloud镜像加速器

```csharp
$ vim /etc/docker/daemon.json
{"registry-mirrors": ["http://d1d9aef0.m.daocloud.io"]}

$ systemctl restart docker
$ docker pull registry
```
### 3.2 运行容器创建registry仓库

```csharp
$ docker run -d --restart=always --name registry -p 5000:5000 -v /storage/registry:/var/lib/registry registry：2.3.0
$ docker ps
```

### 3.3 将镜像推入仓库

```csharp
$ docker pull centos
$ docker tag  centos:latest 192.168.211.15:5000/centos:latest
$ docker push 192.168.211.15:5000/centos:latest
The push refers to a repository [192.168.211.15:5000/centos]
Get https://192.168.211.15:5000/v1/_ping: http: server gave HTTP response to HTTPS client
```

在推送镜像中出现错误，因为client与Registry交互默认将采用https访问，但我们在install Registry时并未配置指定任何tls相关的key和crt文件，https将无法访问。因此， 我们需要配置客户端的Insecure Registry选项（另一种解决方案需要配置Registry的证书）。

```csharp
$ vim /etc/sysconfig/docker
OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false --insecure-registry 192.168.211.15:5000'
$ docker stop registry
$ systemctl restart docker
$ docker start registry
$ docker push 192.168.211.15:5000/centos:latest
$ $ curl  https://192.168.211.15:5000/v2/_catalog
{"repositories":["centos"]}   #获取镜像列表
```

### 3.4 配置Docker Registry签名证书
在Docker Registry主机中生成OpenSSL的自签名证书：

```csharp
cat << EOF > ssl.conf
[ req ]
prompt             = no
distinguished_name = req_subj
x509_extensions    = x509_ext

[ req_subj ]
CN = Localhost

[ x509_ext ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
basicConstraints       = CA:true
subjectAltName         = @alternate_names

[ alternate_names ]
DNS.1 = localhost
IP.1  = 192.168.211.15
EOF
```

```csharp
$ openssl req -config ssl.conf -new -x509 -nodes -sha256 -days 365 -newkey rsa:4096 -keyout /certs/server-key.pem -out /certs/server-crt.pem
```

### 3.5 使签名证书生效

Docker Registry所在本机操作：
证书生成好了，客户端现在就不需要 `--insecure-registry` 了 

```csharp
$ vim /etc/sysconfig/docker
OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false'
$ mkdir -p  /etc/docker/certs.d/192.168.211.15:5000/
$ cp /certs/server-crt.pem /etc/docker/certs.d/192.168.211.15\:5000/
$ systemctl restart docker
```

客户端操作：

```csharp
$ mkdir -p  /etc/docker/certs.d/192.168.211.15:5000/
$ scp /certs/server-crt.pem root@192.168.211.16:/etc/docker/certs.d/192.168.211.15:5000/
$ systemctl restart docker
```
### 3.6 配置Docker Registry用户认证
为了相对安全，可以给仓库加上基本的身份认证。使用 [htpasswd](https://httpd.apache.org/docs/current/programs/htpasswd.html) 创建用户：

```csharp
$ htpasswd -Bbn testuser testpassword > /auth/htpasswd
$ cat /auth/htpasswd
testuser:$2y$05$MO4iv425uurfqY2Y/X71TuNTUPu4Vrn.oNE4NxRTjsPTTU6QywiwG
```
或者借用镜像命令创建用户

```csharp
$ sudo sh -c "docker run --entrypoint htpasswd registry:2.3.0 -Bbn testuser testpassword > /auth/htpasswd"
or
$ docker run --entrypoint htpasswd registry:2.3.0 -Bbn testuser testpassword > auth/htpasswd
```


### 3.7 部署带有证书与用户认证的registry仓库

```csharp
docker run -d \
    -p 5000:5000 \
    --name registry \
    --restart=always \
    -v /var/lib/registry:/var/lib/registry \
    -v /auth:/auth \
    -v /certs:/certs \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server-crt.pem \
    -e REGISTRY_HTTP_TLS_KEY=/certs/server-key.pem \
    -e REGISTRY_AUTH=htpasswd \
    -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
    -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
    registry:2.3.0
```

### 3.8 登录测试

```csharp
$ docker login -u testuser -p testpassword 192.168.211.15:5000
Login Succeeded
```
命令行访问仓库：

```csharp
$ curl  -k -u "testuser:testpassword" https://192.168.211.15:5000/v2/_catalog
{"repositories":[]}
$ docker push 192.168.211.15:5000/centos:latest
$ curl  -k -u "testuser:testpassword" https://192.168.211.15:5000/v2/_catalog
{"repositories":["centos"]}   #获取镜像列表
$ curl  -k -u "testuser:testpassword" https://192.168.211.15:5000/v2/centos/tags/list
{"name":"centos","tags":["latest"]} #查询镜像是否存在以及标签列表
```

参考：

 - [Docker Registry](https://docs.docker.com/registry/)
 - [registry 镜像](https://hub.docker.com/_/registry)
 - [Deploy a registry server](https://docs.docker.com/registry/deploying/)
 - [Configuring a registry](https://docs.docker.com/registry/configuration/)
 - [Docker Registry私有仓库介绍与部署章](https://www.jianshu.com/p/07041223df66)

