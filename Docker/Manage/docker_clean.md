#  docker 资源清理


## 1. 查看 docker 占用资源


```bash
docker container ls    #默认只列出正在运行的容器，-a 选项会列出包括停止的所有容器。
docker image l   s# 列出镜像信息，-a 选项会列出 intermediate 镜像(就是其它镜像依赖的层)。
docker volume ls #列出数据卷。
docker network ls #列出 network。
docker info #显示系统级别的信息，比如容器和镜像的数量等。
```
## 2. 清理
删除镜像

```bash
sudo docker rmi <Image Name>
```

删除容器

```bash
sudo docker rm <Container Name>
```

删除所有镜像

```bash
sudo docker rmi -a
```

删除所有容器

```bash
sudo docker rm -a
```

另外，容器的数据卷(volume)也是占用磁盘空间，可以通过以下命令删除失效的volume:

```bash
sudo docker volume rm $(docker volume ls -qf dangling=true)
```

当然，最暴力的方式是删除Docker存储镜像，容器与数据卷的目录(/var/lib/docker)
谨慎使用！！！:

```bash
sudo service docker stop
sudo rm -rf /var/lib/docker
sudo service docker start
```

只删除那些未被使用的资源

```bash
docker system prune
```

安全起见，这个命令默认不会删除那些未被任何容器引用的数据卷，如果需要同时删除这些数据卷，
你需要显式的指定 --volumns 参数。比如你可能想要执行下面的命令：

```bash
docker system prune --all --force --volumns
```

 `<none>` 镜像。这表示旧的镜像已经不再被引用了，此时它们就变成了 `dangling images`

```bash
docker container prune # 删除所有退出状态的容器
docker volume prune # 删除未被使用的数据卷
docker network prune #清理没有再被任何容器引用的networks
docker network prune --filter "until=24h" #清理没有被引用的、创建超过24小时的networks
docker image prune # 删除 dangling 或所有未被使用的镜像
docker image prune -a #清除所有没有容器引用的镜像
docker image prune -a --filter "until=24h" # 只清除超过创建时间超过24小时的镜像
```
