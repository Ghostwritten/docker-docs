#  Docker 配置 DNS

## 1. docker配置DNS方法
docker容器配置dns解析地址，我知道的有以下几种办法（优先级从高到低）：
 1. 启动的时候加--dns=IP_ADDRESS；
 2. 守护进程启动参数中添加DOCKER_OPTS="--dns 8.8.8.8" ；
 3. 在/etc/docker/deamon.json中添加dns信息（与守护进程参数会冲突不能同时添加。）；
 4. 使用宿主机的/etc/resolv.conf文件；

## 2. 默认DNS配置
怎样为Docker提供的每一个容器进行主机名和DNS配置，而不必建立自定义镜像并将主机名写 到里面？它的诀窍是覆盖三个至关重要的在/etc下的容器内的虚拟文件，那几个文件可以写入 新的信息。你可以在容器内部运行mount看到这个：

```bash
$ mount
...
/dev/disk/by-uuid/1fec...ebdf on /etc/hostname type ext4 ...
/dev/disk/by-uuid/1fec...ebdf on /etc/hosts type ext4 ...
/dev/disk/by-uuid/1fec...ebdf on /etc/resolv.conf type ext4 ...
...
```

## 3. 启动时配置dns参数
| Options                            | Description                                                                         |
|------------------------------------|-------------------------------------------------------------------------------------|
| -h HOSTNAME or --hostname=HOSTNAME | 在该容器启动时，将HOSTNAME设置到容器内的/etc/hosts, /etc/hostname, /bin/bash提示中。                    |
| --link=CONTAINER_NAME or ID:ALIAS  | 在该容器启动时，将ALIAS和CONTAINER_NAME/ID对应的容器IP添加到/etc/hosts. 如果 CONTAINER_NAME/ID有多个IP地址 ？ |
| --dns=IP_ADDRESS...                | 在该容器启动时，将nameserver IP_ADDRESS添加到容器内的/etc/resolv.conf中。可以配置多个。                      |
| --dns-search=DOMAIN...             | 在该容器启动时，将DOMAIN添加到容器内/etc/resolv.conf的dns search列表中。可以配置多个。                         |
| --dns-opt=OPTION...                | 在该容器启动时，将OPTION添加到容器内/etc/resolv.conf中的options选项中，可以配置多个                            |

如果docker run时不含`--dns=IP_ADDRESS`..., `--dns-search=DOMAIN`..., or `--dns-opt=OPTION`...参数，docker daemon会将copy本主机的`/etc/resolv.conf`，然后对该copy进行处理（将那些/etc/resolv.conf中ping不通的nameserver项给抛弃）,处理完成后留下的部分就作为该容器内部的/etc/resolv.conf。因此，如果你想利用宿主机中的/etc/resolv.conf配置的nameserver进行域名解析，那么你需要宿主机中该dns service配置一个宿主机内容器能ping通的IP。
如果宿主机的/etc/resolv.conf内容发生改变，docker daemon有一个对应的file change notifier会watch到这一变化，然后根据容器状态采取对应的措施： 

 - 如果容器状态为stopped，则立刻根据宿主机的/etc/resolv.conf内容更新容器内的/etc/resolv.conf.
 - 如果容器状态为running，则容器内的/etc/resolv.conf将不会改变，直到该容器状态变为stopped.
 - 如果容器启动后修改过容器内的/etc/resolv.conf，则不会对该容器进行处理，否则可能会丢失已经完成的修改，无论该容器为什么状态。
 - 如果容器启动时，用了--dns, --dns-search, or --dns-opt选项，其启动时已经修改了宿主机的/etc/resolv.conf过滤后的内容，因此docker daemon永远不会更新这种容器的/etc/resolv.conf。

> 注意: docker daemon监控宿主机/etc/resolv.conf的这个file change notifier的实现是依赖linux内核的inotify特性，而inotfy特性不兼容overlay fs，因此使用overlay fs driver的docker deamon将无法使用该/etc/resolv.conf自动更新的功能。、

```bash
 $ sudo docker run --hostname 'myhost' -it centos
 [root@myhost /]# cat /etc/hosts
 172.17.0.7    myhost

 $  sudo docker run -it --dns=192.168.5.1  centos
 [root@6a38049c9052 /]# cat /etc/resolv.conf
 nameserver 192.168.5.1

 $  sudo docker run -it --dns-search=www.domain.com  centos
 [root@ae0e9e99596f /]# cat /etc/resolv.conf
 nameserver 192.168.4.1
 search www.mydomain.com
```

## 4. daemon.json配置DNS格式

```bash
root@node-7:~# cat /etc/docker/daemon.json
{
  "data-root": "/data/docker",
  "dns": ["172.18.0.52", "172.18.0.70", "183.XX.XX.XX"],
  "dns-search": ["fiibeacon.local"],
  "hosts": ["unix:///var/run/docker.sock", "tcp://172.18.0.141:2375"],
  "storage-driver": "overlay2"
}
```
参考：

 - [docker高级网络配置](http://www.dockerinfo.net/%E9%AB%98%E7%BA%A7%E7%BD%91%E7%BB%9C%E9%85%8D%E7%BD%AE)
 - [docker container DNS配置介绍和源码分析](https://cloud.tencent.com/developer/article/1096388)
