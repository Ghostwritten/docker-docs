#  Docker 高级操作


## 1. 容器的进程
```bash
$ docker run -d --name=db redis:alpine

$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
e2edc005ea6e        redis:alpine        "docker-entrypoint.s…"   31 seconds ago      Up 30 seconds       6379/tcp            db

#Docker容器启动一个名为redis-server的进程。在主机上，我们可以看到所有正在运行的进程，包括由Docker启动的进程。
$ ps aux | grep redis-server
999       1099  0.3  1.1  29156 11316 ?        Ssl  08:50   0:00 redis-server *:6379

docker top db
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
999                 1099                1083                0                   08:50               ?                   00:00:00            redis-server *:6379

#将列出所有子进程。
$ pstree -c -p -A $(pgrep dockerd)
dockerd(679)-+-docker-containe(717)-+-docker-containe(1083)-+-redis-server(1099)-+-{bio_aof_fsync}(1134)
             |                      |                       |                    |-{bio_close_file}(1133)
             |                      |                       |                    |-{bio_lazy_free}(1135)
             |                      |                       |                    `-{jemalloc_bg_thd}(1136)
             |                      |                       |-{docker-containe}(1084)
             |                      |                       |-{docker-containe}(1085)
             |                      |                       |-{docker-containe}(1086)
             |                      |                       |-{docker-containe}(1087)
             |                      |                       |-{docker-containe}(1088)
             |                      |                       `-{docker-containe}(1089)
             |                      |-{docker-containe}(718)
             |                      |-{docker-containe}(719)
             |                      |-{docker-containe}(720)
             |                      |-{docker-containe}(721)
             |                      |-{docker-containe}(728)
             |                      |-{docker-containe}(757)
             |                      |-{docker-containe}(758)
             |                      `-{docker-containe}(766)
             |-{dockerd}(704)
             |-{dockerd}(705)
             |-{dockerd}(706)
             |-{dockerd}(713)
             |-{dockerd}(714)
             |-{dockerd}(715)
             |-{dockerd}(716)
             |-{dockerd}(734)
             `-{dockerd}(1047)




$ DBPID=$(pgrep redis-server)
$ echo Redis is $DBPID
Redis is 1099
$ ls /proc
1     13   17   214  28   4    56   66   754        bus          filesystems  kpagecount    partitions     thread-self
10    130  170  215  29   473  57   67   8          cgroups      fs           kpageflags    sched_debug    timer_list
1083  131  18   22   3    475  58   674  844        cmdline      interrupts   loadavg       schedstat      timer_stats
1099  132  19   220  30   483  59   679  85         consoles     iomem        locks         scsi           tty
11    133  2    228  306  485  592  68   858        cpuinfo      ioports      mdstat        self           uptime
1172  134  20   23   309  5    6    698  86         crypto       irq          meminfo       slabinfo       version
12    135  200  235  31   52   60   7    87         devices      kallsyms     misc          softirqs       version_signature
124   14   203  24   32   53   61   707  9          diskstats    kcore        modules       stat           vmallocinfo
125   141  205  25   33   530  62   717  951        dma          keys         mounts        swaps          vmstat
126   15   21   26   34   54   63   72   957        driver       key-users    mtrr          sys            zoneinfo
127   16   210  264  35   540  64   725  acpi       execdomains  kmsg         net           sysrq-trigger
129   169  213  27   36   55   65   750  buddyinfo  fb           kpagecgroup  pagetypeinfo  sysvipc


#每个进程都在不同的文件中定义了自己的配置和安全设置
$ ls /proc/$DBPID
attr        cmdline          environ  io         mem         ns             pagemap      schedstat  stat     timers
autogroup   comm             exe      limits     mountinfo   numa_maps      personality  sessionid  statm    uid_map
auxv        coredump_filter  fd       loginuid   mounts      oom_adj        projid_map   setgroups  status   wchan
cgroup      cpuset           fdinfo   map_files  mountstats  oom_score      root         smaps      syscall
clear_refs  cwd              gid_map  maps       net         oom_score_adj  sched        stack      task

#例如，您可以查看和更新为该流程定义的环境变量
$ cat /proc/$DBPID/environ
*:6379

$ docker exec -it db env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=e2edc005ea6e
TERM=xterm
REDIS_VERSION=6.2.5
REDIS_DOWNLOAD_URL=http://download.redis.io/releases/redis-6.2.5.tar.gz
REDIS_DOWNLOAD_SHA=4b9a75709a1b74b3785e20a6c158cab94cf52298aa381eea947a678a60d551ae
HOME=/root


```
## 2. 命名空间
容器的基本组成部分之一是名称空间。名称空间的概念是限制进程可以看到和访问系统的某些部分，比如其他网络接口或进程。

当容器启动时，容器运行时(如Docker)将为进程创建新的命名空间。通过在它自己的Pid命名空间中运行进程，它将看起来像系统上的唯一进程。

可用的命名空间有:
Mount (mnt)

Process ID (pid)

Network (net)

Interprocess Communication (ipc)

UTS (hostnames)

User ID (user)

Control group (cgroup)

在不使用Docker等运行时的情况下，进程仍然可以在自己的命名空间内运行。一个可以提供帮助的工具是`unshare`。

```bash
$ unshare --help

Usage:
 unshare [options] <program> [<argument>...]

Run a program with some namespaces unshared from the parent.

Options:
 -m, --mount[=<file>]      unshare mounts namespace
 -u, --uts[=<file>]        unshare UTS namespace (hostname etc)
 -i, --ipc[=<file>]        unshare System V IPC namespace
 -n, --net[=<file>]        unshare network namespace
 -p, --pid[=<file>]        unshare pid namespace
 -U, --user[=<file>]       unshare user namespace
 -f, --fork                fork before launching <program>
     --mount-proc[=<dir>]  mount proc filesystem first (implies --mount)
 -r, --map-root-user       map current user to root (implies --user)
     --propagation slave|shared|private|unchanged
                           modify mount propagation in mount namespace
 -s, --setgroups allow|deny  control the setgroups syscall in user namespaces

 -h, --help     display this help and exit
 -V, --version  output version information and exit
```

使用`unshare`，可以启动进程并让它创建一个新的名称空间，比如Pid。通过从主机取消Pid名称空间的共享，看起来bash提示符是唯一运行的进程：

```bash
$ sudo unshare --fork --pid --mount-proc bash
$ ps
  PID TTY          TIME CMD
    1 pts/0    00:00:00 bash
    9 pts/0    00:00:00 ps
$ exit
exit
```

名称空间是磁盘上的索引节点位置。这允许进程`shared/reused`相同的名称空间，从而允许它们进行查看和交互。

```bash
#列出容器所有的名称空间
$ ls -lha /proc/$DBPID/ns/
total 0
dr-x--x--x 2 999 packer 0 Sep 27 08:50 .
dr-xr-xr-x 9 999 packer 0 Sep 27 08:50 ..
lrwxrwxrwx 1 999 packer 0 Sep 27 09:04 cgroup -> cgroup:[4026531835]
lrwxrwxrwx 1 999 packer 0 Sep 27 08:52 ipc -> ipc:[4026532157]
lrwxrwxrwx 1 999 packer 0 Sep 27 08:52 mnt -> mnt:[4026532155]
lrwxrwxrwx 1 999 packer 0 Sep 27 08:50 net -> net:[4026532160]
lrwxrwxrwx 1 999 packer 0 Sep 27 08:52 pid -> pid:[4026532158]
lrwxrwxrwx 1 999 packer 0 Sep 27 08:52 user -> user:[4026531837]
lrwxrwxrwx 1 999 packer 0 Sep 27 08:52 uts -> uts:[4026532156]
```
另一个工具`nsenter`用于将进程附加到现有的命名空间。对调试有用。

```bash
$ nsenter --target $DBPID --mount --uts --ipc --net --pid ps aux
PID   USER     TIME  COMMAND
    1 redis     0:02 redis-server *:6379
   16 root      0:00 ps aux
```
在Docker中，可以使用语法`container:<container-name>`共享这些名称空间。例如，下面的命令将nginx连接到DB命名空间。

```bash
$ docker run -d --name=web --net=container:db nginx:alpine
WEBPID=$(pgrep nginx | tail -n1)
$ echo nginx is $WEBPID
$ cat /proc/$WEBPID/cgroup
11:hugetlb:/docker/42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1
10:perf_event:/docker/42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1
9:cpu,cpuacct:/docker/42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1
8:cpuset:/docker/42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1
7:freezer:/docker/42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1
6:memory:/docker/42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1
5:pids:/docker/42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1
4:devices:/docker/42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1
3:net_cls,net_prio:/docker/42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1
2:blkio:/docker/42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1
1:name=systemd:/docker/42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1
```
虽然网络已被共享，但它仍将作为名称空间列出。

```bash
$ ls -lha /proc/$WEBPID/ns/
total 0
dr-x--x--x 2 systemd-network systemd-journal 0 Sep 27 09:10 .
dr-xr-xr-x 9 systemd-network systemd-journal 0 Sep 27 09:07 ..
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 cgroup -> cgroup:[4026531835]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 ipc -> ipc:[4026532225]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 mnt -> mnt:[4026532223]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 net -> net:[4026532160]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 pid -> pid:[4026532226]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 user -> user:[4026531837]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 uts -> uts:[4026532224]
```
但是，这两个进程的网络名称空间指向相同的位置。

```bash
$ ls -lha /proc/$WEBPID/ns/ | grep net
dr-x--x--x 2 systemd-network systemd-journal 0 Sep 27 09:10 .
dr-xr-xr-x 9 systemd-network systemd-journal 0 Sep 27 09:07 ..
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 cgroup -> cgroup:[4026531835]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 ipc -> ipc:[4026532225]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 mnt -> mnt:[4026532223]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 net -> net:[4026532160]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 pid -> pid:[4026532226]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 user -> user:[4026531837]
lrwxrwxrwx 1 systemd-network systemd-journal 0 Sep 27 09:10 uts -> uts:[4026532224]
$ ls -lha /proc/$DBPID/ns/ | grep net
lrwxrwxrwx 1 999 packer 0 Sep 27 08:50 net -> net:[4026532160]
```
##  3. chroot
容器进程的一个重要部分是能够拥有独立于主机的不同文件。这就是我们如何基于不同的操作系统在我们的系统上运行不同的Docker映像。

Chroot允许进程在父操作系统的不同根目录下启动。这允许不同的文件出现在根目录中。

##  4. cgroups
CGroups限制了进程可以消耗的资源数量。这些cgroup是在/proc目录中的特定文件中定义的值。
需要查看映射关系，使用命令:

```bash
$ cat /proc/$DBPID/cgroup
11:hugetlb:/docker/e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0
10:perf_event:/docker/e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0
9:cpu,cpuacct:/docker/e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0
8:cpuset:/docker/e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0
7:freezer:/docker/e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0
6:memory:/docker/e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0
5:pids:/docker/e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0
4:devices:/docker/e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0
3:net_cls,net_prio:/docker/e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0
2:blkio:/docker/e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0
1:name=systemd:/docker/e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0
```
这些被映射到磁盘上的其他cgroup目录:

```bash
$ ls /sys/fs/cgroup/
blkio  cpuacct      cpuset   freezer  memory   net_cls,net_prio  perf_event  systemd
cpu    cpu,cpuacct  devices  hugetlb  net_cls  net_prio          pids
```
### 4.1 进程的CPU统计信息
CPU统计数据和使用情况也存储在一个文件中!

```bash
$ cat /sys/fs/cgroup/cpu,cpuacct/docker/$DBID/cpuacct.stat
user 139
system 144
```
这里还定义了CPU共享限制。

```bash
$ cat /sys/fs/cgroup/cpu,cpuacct/docker/$DBID/cpu.shares
1024
```
### 4.2 进程的内存配置
所有用于容器内存配置的Docker cgroups都存储在:

```bash
$ ls /sys/fs/cgroup/memory/docker/
42e8d3ecb8137817669b58fd33c2b6e133bae8237513c7ed8af0a49a936248d1  memory.kmem.usage_in_bytes
cgroup.clone_children                                             memory.limit_in_bytes
cgroup.event_control                                              memory.max_usage_in_bytes
cgroup.procs                                                      memory.move_charge_at_immigrate
e2edc005ea6ef33fededdb8f7b58162665c81552a29a2ea777b8b9d05bd393d0  memory.numa_stat
memory.failcnt                                                    memory.oom_control
memory.force_empty                                                memory.pressure_level
memory.kmem.failcnt                                               memory.soft_limit_in_bytes
memory.kmem.limit_in_bytes                                        memory.stat
memory.kmem.max_usage_in_bytes                                    memory.swappiness
memory.kmem.slabinfo                                              memory.usage_in_bytes
memory.kmem.tcp.failcnt                                           memory.use_hierarchy
memory.kmem.tcp.limit_in_bytes                                    notify_on_release
memory.kmem.tcp.max_usage_in_bytes                                tasks
memory.kmem.tcp.usage_in_bytes
```
### 4.3 如何配置cgroups?

Docker的属性之一是控制内存限制的能力。这是通过cgroup设置完成的。
默认情况下，容器对内存没有限制。我们可以通过`docker stats`命令查看。

```bash
$ docker stats db --no-stream
CONTAINER ID        NAME                CPU %               MEM USAGE / LIMIT     MEM %               NET I/O             BLOCK I/O           PIDS
e2edc005ea6e        db                  0.17%               6.754MiB / 992.1MiB   0.68%               1.3kB / 0B          0B / 0B             5
```
内存引号存储在一个名为`memory.limit_in_bytes`

通过写入文件，我们可以改变进程的限制

```bash
$ echo 8000000 > /sys/fs/cgroup/memory/docker/$DBID/memory.limit_in_bytes
```
如果将文件读回去，您将注意到它已被转换为7999488。

```bash
$ cat /sys/fs/cgroup/memory/docker/$DBID/memory.limit_in_bytes
7999488
```
当再次检查Docker Stats时，进程的内存限制现在是7.629M

```bash
$ docker stats db --no-stream
CONTAINER ID        NAME                CPU %               MEM USAGE / LIMIT     MEM %               NET I/O             BLOCK I/O           PIDS
e2edc005ea6e        db                  0.19%               6.176MiB / 992.1MiB   0.62%               1.3kB / 0B          61.4kB / 0B         5
```
## 5. Seccomp / AppArmor
Linux中的所有操作都是通过系统调用来完成的。内核有330个系统调用，执行读取文件、关闭句柄和检查访问权限等操作。所有应用程序都使用这些系统调用的组合来执行所需的操作。

`AppArmor`是一个应用程序定义的配置文件，它描述了进程可以访问系统的哪些部分。

可以通过以下方式查看分配给进程的当前AppArmor配置文件

```bash
$ cat /proc/$DBPID/attr/current
docker-default (enforce)
```
Docker的默认`AppArmor`配置文件是`docker-default (enforce)`

在Docker 1.13之前，它将AppArmor配置文件存储在`/etc/ AppArmor.d/Docker-default`(在Docker启动时被覆盖，因此用户无法修改它。在v1.13之后，Docker现在在`tmpfs`中生成`Docker -default`，使用`apparmor_parser`将其加载到内核中，然后删除该文件

该模板可在[https://github.com/moby/moby/blob/a575b0b1384b2ba89b79cbd7e770fbeb616758b3/profiles/apparmor/template.go](https://github.com/moby/moby/blob/a575b0b1384b2ba89b79cbd7e770fbeb616758b3/profiles/apparmor/template.go)

Seccomp提供了限制系统调用的能力，阻止诸如安装内核模块或更改文件权限等方面。

Docker默认允许的调用可以在[https://github.com/moby/moby/blob/a575b0b1384b2ba89b79cbd7e770fbeb616758b3/profiles/seccomp/default.json](https://github.com/moby/moby/blob/a575b0b1384b2ba89b79cbd7e770fbeb616758b3/profiles/seccomp/default.json)

当分配给进程时，它意味着进程将被限制在能力系统调用的子集。如果它试图调用一个被阻塞的系统调用将收到错误“操作不允许”。

`SecComp`的状态也在一个文件中定义。

```bash
$ cat /proc/$DBPID/status
Name:   redis-server
State:  S (sleeping)
Tgid:   1099
Ngid:   0
Pid:    1099
PPid:   1083
TracerPid:      0
Uid:    999     999     999     999
Gid:    1000    1000    1000    1000
FDSize: 64
Groups: 1000 1000 
NStgid: 1099    1
NSpid:  1099    1
NSpgid: 1099    1
NSsid:  1099    1
VmPeak:    29156 kB
VmSize:    29156 kB
VmLck:         0 kB
VmPin:         0 kB
VmHWM:     11316 kB
VmRSS:      7032 kB
VmData:    23204 kB
VmStk:       132 kB
VmExe:      1672 kB
VmLib:      1656 kB
VmPTE:        56 kB
VmPMD:        12 kB
VmSwap:     4324 kB
HugetlbPages:          0 kB
Threads:        5
SigQ:   0/3824
SigPnd: 0000000000000000
ShdPnd: 0000000000000000
SigBlk: 0000000000000000
SigIgn: 0000000000001001
SigCgt: 00000000000044ea
CapInh: 00000000a80425fb
CapPrm: 0000000000000000
CapEff: 0000000000000000
CapBnd: 00000000a80425fb
CapAmb: 0000000000000000
Seccomp:        2
Cpus_allowed:   3
Cpus_allowed_list:      0-1
Mems_allowed:   00000000,00000001
Mems_allowed_list:      0
voluntary_ctxt_switches:        24583
nonvoluntary_ctxt_switches:     507
```

```bash
$ cat /proc/$DBPID/status | grep Seccomp
Seccomp:        2
```
标志位含义为:0:关闭。1:严格。2:过滤

##  6. Capabilities
`Capabilities`是关于进程或用户有权做什么的分组。这些功能可能包括多个系统调用或操作，例如更改系统时间或主机名。

状态文件还包含了`Capabilities`标志。一个进程可以丢弃尽可能多的capability，以确保其安全。

```bash
$ cat /proc/$DBPID/status | grep ^Cap
CapInh: 00000000a80425fb
CapPrm: 0000000000000000
CapEff: 0000000000000000
CapBnd: 00000000a80425fb
CapAmb: 0000000000000000
```
标志被存储为一个可以用capsh解码的位掩码

```bash
$ capsh --decode=00000000a80425fb
0x00000000a80425fb=cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap
```

##  7. 容器镜像

容器映像是一个包含tar文件的tar文件。每个tar文件都是一个层。一旦所有tar文件被提取到相同的位置，那么您就拥有了容器的文件系统。

这可以通过Docker进行探索。把这些image放到本地系统上。

```bash
$ docker pull redis:3.2.11-alpine
3.2.11-alpine: Pulling from library/redis
ff3a5c916c92: Pull complete 
aae70a2e6027: Pull complete 
87c655da471c: Pull complete 
bc3141806bdc: Pull complete 
53616fb426d9: Pull complete 
9791c5883c6a: Pull complete 
Digest: sha256:ebf1948b84dcaaa0f8a2849cce6f2548edb8862e2829e3e7d9e4cd5a324fb3b7
Status: Downloaded newer image for redis:3.2.11-alpine
```
将images导出为原始tar格式。

```bash
docker save redis:3.2.11-alpine > redis.tar
```

```bash
$ tar -xvf redis.tar
46a2fed8167f5d523f9a9c07f17a7cd151412fed437272b517ee4e46587e5557/
46a2fed8167f5d523f9a9c07f17a7cd151412fed437272b517ee4e46587e5557/VERSION
46a2fed8167f5d523f9a9c07f17a7cd151412fed437272b517ee4e46587e5557/json
46a2fed8167f5d523f9a9c07f17a7cd151412fed437272b517ee4e46587e5557/layer.tar
498654318d0999ce36c7b90901ed8bd8cb63d86837cb101ea1ec9bb092f44e59/
498654318d0999ce36c7b90901ed8bd8cb63d86837cb101ea1ec9bb092f44e59/VERSION
498654318d0999ce36c7b90901ed8bd8cb63d86837cb101ea1ec9bb092f44e59/json
498654318d0999ce36c7b90901ed8bd8cb63d86837cb101ea1ec9bb092f44e59/layer.tar
ad01e7adb4e23f63a0a1a1d258c165d852768fb2e4cc2d9d5e71698e9672093c/
ad01e7adb4e23f63a0a1a1d258c165d852768fb2e4cc2d9d5e71698e9672093c/VERSION
ad01e7adb4e23f63a0a1a1d258c165d852768fb2e4cc2d9d5e71698e9672093c/json
ad01e7adb4e23f63a0a1a1d258c165d852768fb2e4cc2d9d5e71698e9672093c/layer.tar
ca0b6709748d024a67c502558ea88dc8a1f8a858d380f5ddafa1504126a3b018.json
da2a73e79c2ccb87834d7ce3e43d274a750177fe6527ea3f8492d08d3bb0123c/
da2a73e79c2ccb87834d7ce3e43d274a750177fe6527ea3f8492d08d3bb0123c/VERSION
da2a73e79c2ccb87834d7ce3e43d274a750177fe6527ea3f8492d08d3bb0123c/json
da2a73e79c2ccb87834d7ce3e43d274a750177fe6527ea3f8492d08d3bb0123c/layer.tar
db1a23fc1daa8135a1c6c695f7b416a0ac0eb1d8ca873928385a3edaba6ac9a3/
db1a23fc1daa8135a1c6c695f7b416a0ac0eb1d8ca873928385a3edaba6ac9a3/VERSION
db1a23fc1daa8135a1c6c695f7b416a0ac0eb1d8ca873928385a3edaba6ac9a3/json
db1a23fc1daa8135a1c6c695f7b416a0ac0eb1d8ca873928385a3edaba6ac9a3/layer.tar
f07352aa34c241692cae1ce60ade187857d0bffa3a31390867038d46b1e7739c/
f07352aa34c241692cae1ce60ade187857d0bffa3a31390867038d46b1e7739c/VERSION
f07352aa34c241692cae1ce60ade187857d0bffa3a31390867038d46b1e7739c/json
f07352aa34c241692cae1ce60ade187857d0bffa3a31390867038d46b1e7739c/layer.tar
manifest.json
repositories
```
所有的tar层文件现在都是可见的。

```bash
$ ls
46a2fed8167f5d523f9a9c07f17a7cd151412fed437272b517ee4e46587e5557
498654318d0999ce36c7b90901ed8bd8cb63d86837cb101ea1ec9bb092f44e59
ad01e7adb4e23f63a0a1a1d258c165d852768fb2e4cc2d9d5e71698e9672093c
ca0b6709748d024a67c502558ea88dc8a1f8a858d380f5ddafa1504126a3b018.json
da2a73e79c2ccb87834d7ce3e43d274a750177fe6527ea3f8492d08d3bb0123c
db1a23fc1daa8135a1c6c695f7b416a0ac0eb1d8ca873928385a3edaba6ac9a3
f07352aa34c241692cae1ce60ade187857d0bffa3a31390867038d46b1e7739c
manifest.json
redis.tar
repositories
```
images还包含关于images的元数据，如版本信息和标记名称.

```bash
$ cat repositories
{"redis":{"3.2.11-alpine":"46a2fed8167f5d523f9a9c07f17a7cd151412fed437272b517ee4e46587e5557"}}

$ cat manifest.json
[{"Config":"ca0b6709748d024a67c502558ea88dc8a1f8a858d380f5ddafa1504126a3b018.json","RepoTags":["redis:3.2.11-alpine"],"Layers":["498654318d0999ce36c7b90901ed8bd8cb63d86837cb101ea1ec9bb092f44e59/layer.tar","ad01e7adb4e23f63a0a1a1d258c165d852768fb2e4cc2d9d5e71698e9672093c/layer.tar","da2a73e79c2ccb87834d7ce3e43d274a750177fe6527ea3f8492d08d3bb0123c/layer.tar","db1a23fc1daa8135a1c6c695f7b416a0ac0eb1d8ca873928385a3edaba6ac9a3/layer.tar","f07352aa34c241692cae1ce60ade187857d0bffa3a31390867038d46b1e7739c/layer.tar","46a2fed8167f5d523f9a9c07f17a7cd151412fed437272b517ee4e46587e5557/layer.tar"]}]
```

tar中文件

```bash
$ tar -xvf da2a73e79c2ccb87834d7ce3e43d274a750177fe6527ea3f8492d08d3bb0123c/layer.tar
etc/
etc/apk/
etc/apk/world
lib/
lib/apk/
lib/apk/db/
lib/apk/db/installed
lib/apk/db/lock
lib/apk/db/scripts.tar
lib/apk/db/triggers
sbin/
sbin/su-exec
var/
var/cache/
var/cache/misc/
```
##  8. 创建空镜像
由于images只是一个tar文件，可以使用下面的命令创建空images

```bash
$ tar cv --files-from /dev/null | docker import - empty
sha256:ba14edd8949ad44677f1955e37b9a35f9978d2a687b3f8ab86711811d46e2c53
```
通过导入tar，将创建额外的元数据。

```bash
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
empty               latest              ba14edd8949a        24 seconds ago      0B
redis               3.2.11-alpine       ca0b6709748d        3 years ago         20.7MB
```
但是，由于容器不包含任何内容，所以它不能启动进程。

##  9. 不使用Dockerfile创建镜像

可以扩展前面导入Tar文件的想法，从零开始创建整个映像。
首先，我们将使用BusyBox作为基础。这将为我们提供基本的linux命令。它被定义为rootfs。rootfs是……
Docker提供了一个脚本来下载BusyBox rootfs
[https://github.com/moby/moby/blob/a575b0b1384b2ba89b79cbd7e770fbeb616758b3/contrib/mkimage/busybox-static](https://github.com/moby/moby/blob/a575b0b1384b2ba89b79cbd7e770fbeb616758b3/contrib/mkimage/busybox-static)

```bash
$ curl -LO https://raw.githubusercontent.com/moby/moby/a575b0b1384b2ba89b79cbd7e770fbeb616758b3/contrib/mkimage/busybox-static && chmod +x busybox-static
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   782  100   782    0     0   2177      0 --:--:-- --:--:-- --:--:--  2184
$ 

$ ./busybox-static busybox
```
运行该脚本将下载rootfs和主二进制文件。

```bash
$ ls -lha busybox
total 20K
drwxr-xr-x  5 root root 4.0K Sep 27 09:43 .
drwx------ 15 root root 4.0K Sep 27 09:43 ..
drwxr-xr-x  2 root root 4.0K Sep 27 09:43 bin
drwxr-xr-x  2 root root 4.0K Sep 27 09:43 sbin
drwxr-xr-x  4 root root 4.0K Sep 27 09:43 usr
```
默认的Busybox rootfs不包含任何版本信息，所以让我们创建一个文件。

```bash
$ echo KatacodaPrivateBuild > busybox/release
```
与前面一样，该目录可以转换为tar，并自动导入到Docker中作为映像。


```bash
$ tar -C busybox -c . | docker import - busybox
sha256:73b25a6703da535db5cbc43073c2920b60f5f8a76db17de093e851f1a2d5f69c
```
现在可以将其作为容器启动。

```c
$ docker run busybox cat /release
KatacodaPrivateBuild
```
