#  docker 镜像源

## 1. 镜像源

```bash
网易：http://hub-mirror.c.163.com
中科大镜像地址：http://mirrors.ustc.edu.cn/
中科大github地址：https://github.com/ustclug/mirrorrequest
Azure中国镜像地址：http://mirror.azure.cn/
Azure中国github地址：https://github.com/Azure/container-service-for-azure-china
DockerHub镜像仓库: https://hub.docker.com/ 
阿里云镜像仓库： https://cr.console.aliyun.com 
google镜像仓库： https://console.cloud.google.com/gcr/images/google-containers/GLOBAL （如果你本地可以翻墙的话是可以连上去的 ）
coreos镜像仓库： https://quay.io/repository/ 
RedHat镜像仓库： https://access.redhat.com/containers

```

## 2. 私人阿里镜像加速器
这里采用了阿里云的镜像加速器（需要阿里云账号进行登录），地址：阿里云 -> 容器镜像服务 -> 镜像工具 -> 镜像加速器。
![在这里插入图片描述](https://img-blog.csdnimg.cn/6bf48bc4ce7f4d50b5d6f7dc928debd3.png)


```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://ckdhnbk9.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

##  3. 国内镜像源
部分国外镜像仓库无法访问，但国内有对应镜像源，可以从以下镜像源拉取到本地然后重改tag即可： Azure Container Registry(ACR)

###  3.1 dockerhub (docker.io)
```bash
#dockerhub(docker.io)
#格式 
dockerhub.azk8s.cn/<repo-name>/<image-name>:<version>
#原镜像地址示例，我们可能平时拉dockerhub镜像是直接docker pull nginx:1.15.但是docker client会帮你翻译成#docker pull docker.io/library/nginx:1.15
docker.io/library/nginx:1.15
#国内拉取示例
dockerhub.azk8s.cn/library/nginx:1.15
```
###  3.2 gcr.io 

```bash
#gcr.io 
#格式
gcr.azk8s.cn/<repo-name>/<image-name>:<version> 
#原镜像地址示例
gcr.io/google-containers/pause:3.1
#国内拉取示例
gcr.azk8s.cn/google_containers/pause:3.1
```
###  3.3 quay.io

```bash
#quay.io
#格式
quay.azk8s.cn/<repo-name>/<image-name>:<version>
#原镜像地址示例
quay.io/coreos/etcd:v3.2.28
#国内拉取示例
quay.azk8s.cn/coreos/etcd:v3.2.28
```
### 3.4 k8s.gcr.io
```bash
#k8s.gcr.io
#格式
gcr.azk8s.cn/google_containers/<repo-name>/<image-name>:<version>
#原镜像地址示例
k8s.gcr.io/pause-amd64:3.1
#国内拉取示例
gcr.azk8s.cn/google_containers/pause:3.1


#原镜像格式
k8s.gcr.io/pause:3.1
#改为以下格式
googlecontainersmirrors/pause:3.1
```

### 3.5 阿里云的google 镜像源

```bash
#原镜像格式
k8s.gcr.io/pause:3.1
#改为以下格式
registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1
```

###  3.6 定制命令拉取镜像
或使用azk8spull，只有50行命令的小脚本，就可以从dockerhub、gcr.io、quay.io直接拉取镜像：

```bash
#download azk8spull
curl -Lo /usr/local/bin/azk8spull https://github.com/xuxinkun/littleTools/releases/download/v1.0.0/azk8spull
chmod +x /usr/local/bin/azk8spull
​
#直接拉取镜像
azk8spull k8s.gcr.io/pause:3.1
azk8spull quay.io/coreos/etcd:v3.2.28
​
#查看拉取的镜像
# docker images
REPOSITORY                                                        TAG                 IMAGE ID            CREATED             SIZE
k8s.gcr.io/etcd                                                   v3.2.28             b2756210eeab        3 months ago        247MB
k8s.gcr.io/pause                                                  3.1
```


 - [google镜像](https://console.cloud.google.com/gcr/images/)

