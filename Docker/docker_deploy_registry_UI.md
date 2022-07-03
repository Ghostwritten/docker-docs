#  docker 部署 registry UI


## 1. 创建 registry 仓库

```bash
$ docker run -d --restart=always --name registry -p 5000:5000 -v /storage/registry:/var/lib/registry registry：2.3.0
$ docker ps
```

## 2. 将镜像推入仓库

```bash
$ docker pull centos
$ docker tag  centos:latest 192.168.211.15:5000/centos:latest
$ docker push 192.168.211.15:5000/centos:latest
The push refers to a repository [192.168.211.15:5000/centos]
Get https://192.168.211.15:5000/v1/_ping: http: server gave HTTP response to HTTPS client
```

在推送镜像中出现错误，因为client与Registry交互默认将采用https访问，但我们在install Registry时并未配置指定任何tls相关的key和crt文件，https将无法访问。因此， 我们需要配置客户端的Insecure Registry选项（另一种解决方案需要配置Registry的证书）。

```bash
$ vim /etc/sysconfig/docker
OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false --insecure-registry 192.168.211.15:5000'
$ docker stop registry
$ systemctl restart docker
$ docker start registry
$ docker push 192.168.211.15:5000/centos:latest
$ $ curl  https://192.168.211.15:5000/v2/_catalog
{"repositories":["centos"]}   #获取镜像列表
```



## 3. 创建registry-web
Docker官方只提供了REST API，并没有给我们一个界面。 可以使用Portus来管理私有仓库， 同时可以使用简单的UI管理工具， Docker提供私有库“hyper/docker-registry-web”， 下载该镜像就可以使用了。

```bash
$ docker run -d -p 8080:8080 --name registry-web  --link registry -e REGISTRY_URL=http://registry:5000/v2  -e REGISTRY_NAME=localhost:5000        hyper/docker-registry-web
```
界面：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200717132621206.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)

参考：

 - [registry-web](https://hub.docker.com/r/hyper/docker-registry-web/)
