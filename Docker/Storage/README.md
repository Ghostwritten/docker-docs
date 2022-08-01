# Docker Volume

![在这里插入图片描述](https://img-blog.csdnimg.cn/ed5ef84c1fc448d5acfa3d02757d206f.png#pic_center)

## 1. 简介
默认情况下，在容器内创建的所有文件都存储在可写容器层上。这意味着：

 - 当该容器不再存在时，数据不会持续存在，并且如果另一个进程需要数据，则可能很难将数据从容器中取出。
   容器的可写层与运行容器的主机紧密耦合。您无法轻松地将数据移动到其他地方。
 - 写入容器的可写层需要 存储驱动程序来管理文件系统。存储驱动程序提供了一个联合文件系统，使用 Linux
   内核。与使用直接写入主机文件系统的数据卷相比，这种额外的抽象会降低性能 。
 - Docker 有两个选项让容器在主机上存储文件，以便即使在容器停止后文件也能持久保存：`volumes`和 `bind mounts`。

Docker 还支持将文件存储在主机内存中的容器。此类文件不会持久保存。如果您在 Linux 上运行 Docker，则使用tmpfs mount将文件存储在主机的系统内存中。

挂载类型

 - `volumes`：由 Docker（/var/lib/docker/volumes/在 Linux 上）管理的主机文件系统的一部分中。非 Docker 进程不应修改文件系统的这一部分。卷是在 Docker 中持久化数据的最佳方式
 - `bind mounts`：可以存储在主机系统的任何位置。它们甚至可能是重要的系统文件或目录。Docker 主机或 Docker 容器上的非 Docker 进程可以随时修改它们。
 - `tmpfs mounts`：挂载仅存储在主机系统的内存中，永远不会写入主机系统的文件系统

![在这里插入图片描述](https://img-blog.csdnimg.cn/426664884f1142498c1efaee8caf6567.png)

##  2. 原理

在 linux 系统上，docker 将images, containers, volumes等相关的数据存储在`/var/lib/docker`下。
![在这里插入图片描述](https://img-blog.csdnimg.cn/66bd0ef34a584c5cacedae853ada7e54.png)
当我们运行`docker build`命令时，docker 会为 dockerfile 中的每条指令构建一层。这些图像层是只读层。当我们运行`docker run`命令时，docker 会构建容器层，它们是读写层。
![在这里插入图片描述](https://img-blog.csdnimg.cn/139dd00b11864310bf81a154b57097ab.png)
您可以在容器上创建新文件，例如下图中的temp.txt。您还可以修改容器上属于图像层的文件，例如下图中的app.py。执行此操作时，会在容器层上创建该文件的本地副本，并且更改仅存在于容器上——这称为 Copy-on-Write 机制。这很重要，因为多个容器和子图像使用相同的图像层。容器上的文件的生命周期与容器的生命周期一样长。当容器被销毁时，其上的文件/修改也会被销毁。为了持久化数据，我们可以使用我们在上一节中看到的卷映射技术。
![在这里插入图片描述](https://img-blog.csdnimg.cn/0a29b8992e77406cac9febdecd0f5bdf.png)
## 3. 命令

您可以使用`docker volume create`命令创建 docker 卷。此命令将在`/var/lib/docker/volumes`目录中创建一个卷。

```bash
docker volume create data_volume
docker volume ls
docker volume inspect data_volume
```
docker run命令时，您可以使用`-v`标志指定要使用的卷。这称为卷挂载。

```bash
docker run -v data_volume:/var/lib/postgres postgres
```
如果该卷不存在，docker 会为您创建一个。现在，即使容器被销毁，数据也会保留在卷中。

如果您想将数据放在 docker 主机上的特定位置或磁盘上已有数据，您也可以将此位置挂载到容器上。这称为绑定安装。

```bash
docker run -v /data/postgres:/var/lib/postgres postgres
```
![在这里插入图片描述](https://img-blog.csdnimg.cn/29aadb9d251f4c46ba15015e564e0cd1.png)
删除

```bash
docker volume rm data_volume
```


##  4. 应用

### 4.1 目录 bind mount

```bash
echo "<h1>Hello from Host</h1>" > ./target/index.html
docker run -it --rm --name nginx -p 8080:80 -v "$(pwd)"/target:/usr/share/nginx/html nginx
```
访问：`http://localhost:8080/`，您应该会看到“Hello from Host”


###  4.2 隐式创建 Docker volume

```bash
#创建demo-earthly卷挂载
docker run -it --rm --name nginx -p 8080:80 -v demo-earthly:/usr/share/nginx/html nginx
docker volume ls
ls /var/lib/docker/volumes/target/_data/demo-earthly
#查看卷内容
docker run -it --rm -v demo-earthly:/opt/demo-earthly ubuntu ls /opt/demo-earthly
```
![在这里插入图片描述](https://img-blog.csdnimg.cn/94819ff51ba74c8d962af9c8b5867397.png)
###  4.3 显式创建 Docker 卷

```bash
docker volume create --name demo-earthly  
```

###  4.4 从 Dockerfile 声明一个 Docker 卷
可以使用语句在 Dockerfile 中声明卷`VOLUME`

Dockerfile：
```bash
FROM nginx:latest

RUN echo "<h1>Hello from Volume</h1>" > /usr/share/nginx/html/index.html
VOLUME /usr/share/nginx/html
```
利用Dockerfile构建镜像

```bash
$ docker build -t demo-earthly .
$ docker run -p 8080:80  demo-earthly
$ docker volume ls
DRIVER              VOLUME NAME
local               20879e3f0bfaf0eed63cb7f37c4b9545084a703f888a230b8aedc2082c836281

$ docker volume inspect 20879e3f0bfaf0eed63cb7f37c4b9545084a703f888a230b8aedc2082c836281 
[
    {
        "CreatedAt": "2022-07-28T11:02:14+08:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/20879e3f0bfaf0eed63cb7f37c4b9545084a703f888a230b8aedc2082c836281/_data",
        "Name": "20879e3f0bfaf0eed63cb7f37c4b9545084a703f888a230b8aedc2082c836281",
        "Options": null,
        "Scope": "local"
    }
]


$ docker inspect -f '{{ .Mounts }}' amazing_carson 
[{volume 20879e3f0bfaf0eed63cb7f37c4b9545084a703f888a230b8aedc2082c836281 /var/lib/docker/volumes/20879e3f0bfaf0eed63cb7f37c4b9545084a703f888a230b8aedc2082c836281/_data /usr/share/nginx/html local  true }]

```
每次启动一个新容器时，都会创建另一个卷，内容为`/usr/share/nginx/html`.


###  4.5 另一种方式挂载 mount 参数
-v并且--volume是使用以下语法将卷安装到容器的最常见方法：

```bash
-v <name>:<destination>:<options>
```
该卷将以只读方式安装：

```bash
docker run -it -v demo-volume:/data:ro ubuntu
```
另一种方法-v是`--mount`选项添加到docker run命令中。--mount是 的更详细的对应物-v。
语法：

```bash
docker run --mount source=[volume_name],destination=[path_in_container] [docker_image]
```
示例

```bash
docker run -it --name=example --mount source=demo-volume,destination=/data ubuntu
```
###  4.6 使用配置卷 docker-compose
使用docker-compose命令在多个容器之间轻松共享数据更方便。


`docker-compose.yml` 目录挂载

```bash
version: "3.2"
services:
  web:
    image: nginx:latest
    ports:
      - 8080:80
    volumes:
      - ./target:/usr/share/nginx/html
```
`docker-compose.yml` 创建卷

```bash
version: "3.2"
services:
  web:
    image: nginx:latest
    ports:
      - 8080:80
    volumes:
      - html_files:/usr/share/nginx/html
  web1:
    image: nginx:latest
    ports:
      - 8081:80
    volumes:
      - html_files:/usr/share/nginx/html
 
volumes:
  html_files:
```
声明了一个名为并`html_files`在服务中使用它的卷。多个容器（web、web1）可以挂载同一个卷。

运行`docker-compose up`将创建一个名为`<project_name>_html_filesif` 它不存在的卷。然后运行`docker volume ls`以列出创建的两个卷，从项目名称开始。

您还可以在 docker-compose 文件之外管理容器，但您仍然需要在下面声明它们volumes并设置属性`external: true`。

```bash
version: "3.2"
services:
  web:
    image: nginx:latest
    ports:
      - 8080:80
    volumes:
      - html_files:/usr/share/nginx/html
 
volumes:
  html_files:
    external: true
```
如果你没有`html_files`，你可以使用`docker volume create html_files`来创建它。当你添加 时`external`，Docker 会找出卷是否存在；但如果没有，就会报错。

###  4.7 从共享卷在容器之间复制文件
创建容器并创建挂载卷

```bash
docker create volume demo-earthly
docker run -it --name=another-example --mount source=demo-volume,destination=/data ubuntu
root@ded392c589ea:/# touch /data/demo.txt
```
导航到数据卷目录并使用命令创建一个文件`touch demo.txt`。退出容器，然后启动一个`another-example-two`具有相同数据量的新容器：

```bash
docker run -it --name=another-example-two --mount source=demo-volume,destination=/data ubuntu
root@feef37293ea5:/# ls /data
```

参考：

 - [Manage data in Docker](https://docs.docker.com/storage/)
 - [Docker Storage](https://towardsdatascience.com/docker-storage-598e385f4efe)
 - [Understanding Docker Volumes](https://earthly.dev/blog/docker-volumes/)
 - [Guide to Docker Volumes](https://www.baeldung.com/ops/docker-volumes)


