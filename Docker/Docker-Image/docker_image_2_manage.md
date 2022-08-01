#  Docker 镜像管理

dockerhub官网：[https://hub.docker.com/](https://hub.docker.com/)
prometheus镜像为示例
## 1. 拉取 (docker pull)

```bash
$ docker search prom/prometheus #搜索镜像
```

```bash

$ docker pull prom/prometheus    #默认版本latest
$ docker pull docker.io/prom/prometheus   #默认版本latest
$ docker pull docker.io/prom/prometheus:2.3.1   # 指定版本
```

```bash
$ docker images #查看镜像列表
$ docker images -a  #<none>标签得镜像也能被展示
```

## 2. 查看配置信息 (docker inspect)

```bash
$ docker inspect prom/prometheus:latest
```

## 3. 修改tag (docker tag)

```bash
$ docker tag prom/prometheus:latest prom/prometheus:v1.0  #修改版本
$ docker tag prom/prometheus:latest docker.registry.localhost/prometheus:latest #修改仓库名，修改自己的私有仓库docker.registry.localhost（自定义）


```

## 4. 打包与解包 (docker save|load)
打包
```bash
$ docker save -o prometheus.tar prom/prometheus:latest #第一种方式打包
$ docker save > prometheus.tar prom/prometheus:latest  #第二种方式打包
$ docker save -o monitor.tar prom/prometheus:latest prom/alertmanager:latest # 多个镜像打包
$ docker save prom/prometheus:latest | gzip -> prometheus.tar.gz
```
解包

```bash
$ docker load -i prometheus.tar  #第一种方式解包
$ docker load < prometheus.tar  #第二种方式解包
```

## 5. 推送 (docker push)
#将本地的镜像推送至公共镜像源的自己仓库，一般区别官方镜像，为私人定制。ghostwritten为我的仓库名

```bash
$ docker push docker.io/ghostwritten/prometheus:latest  
```

将本地的镜像推送至本地搭建的私有仓库，一般为内网集群环境公用。搭建私有仓库请点击

```bash
$ docker push docker.registry.localhost/prometheus:latest  
$ docker push docker.registry.localhost/monitor/prometheus:latest  #加monitor tag方便区分镜像类型
```

## 6. 删除 (docker rmi)

```bash
$ docker rmi prom/prometheus:latest
$ docker rmi  -f prom/prometheus:latest  #-f 为强制删除
```

## 7. 构建（docker build）

docker build命令会根据Dockerfile文件及上下文构建新Docker镜像。构建上下文是指Dockerfile所在的本地路径或一个URL（Git仓库地址）。构建上下文环境会被递归处理，所以，构建所指定的路径还包括了子目录，而URL还包括了其中指定的子模块。
OPTIONS说明：

```bash
--build-arg=[] :设置镜像创建时的变量；

--cpu-shares :设置 cpu 使用权重；

--cpu-period :限制 CPU CFS周期；

--cpu-quota :限制 CPU CFS配额；

--cpuset-cpus :指定使用的CPU id；

--cpuset-mems :指定使用的内存 id；

--disable-content-trust :忽略校验，默认开启；

-f :指定要使用的Dockerfile路径；

--force-rm :设置镜像过程中删除中间容器；

--isolation :使用容器隔离技术；

--label=[] :设置镜像使用的元数据；

-m :设置内存最大值；

--memory-swap :设置Swap的最大值为内存+swap，"-1"表示不限swap；

--no-cache :创建镜像的过程不使用缓存；

--pull :尝试去更新镜像的新版本；

--quiet, -q :安静模式，成功后只输出镜像 ID；

--rm :设置镜像成功后删除中间容器；

--shm-size :设置/dev/shm的大小，默认值是64M；

--ulimit :Ulimit配置。

--tag, -t: 镜像的名字及标签，通常 name:tag 或者 name 格式；可以在一次构建中为一个镜像设置多个标签。

--network: 默认 default。在构建期间设置RUN指令的网络模式
```

常用命令
```bash
$ docker build .  #默认使用当前目录下Dockerfile
$ docker  build . -f centosdockerfile  #其他名称dockerfile，需要指定
$ docker build -f /path/to/a/Dockerfile . #递归目录下的dockerfile
$ docker build -t ghostwritten/app . #指定镜像名
$ docker build -t ghostwritten/app:1.0.2 -t ghostwritten/app:latest . #指定多个tag
#Dockerfile文件中的每条指令会被独立执行，并会创建一个新镜像，Docker 会重用已生成的中间镜像，以加速docker build的构建速度，也可以通过--cache-from指定
$ docker build -t ghostwritten/app --cache-from 31f630c65071 . 
$ docker build -t ghostwritten/app --no-cache . #不使用缓存
```
详细请参考[docker官网](https://docs.docker.com/engine/reference/commandline/build/)
