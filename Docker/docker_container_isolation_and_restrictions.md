#   Docker 容器隔离与限制

Cgroups 就是 Linux 内核中用来为进程设置资源限制的一个重要功能。 有意思的是，Google 的工程师在 2006 年发起这项特性的时候，曾将它命名为“进程容 器”（process container）。实际上，在 Google 内部，“容器”这个术语长期以来都被用于 形容被 Cgroups 限制过的进程组。后来 Google 的工程师们说，他们的 KVM 虚拟机也运行在 Borg 所管理的“容器”里，其实也是运行在 Cgroups“容器”当中。
这和我们今天说的 Docker 容器差别很大。 Linux Cgroups 的全称是 Linux Control Group。它最主要的作用，就是限制一个进程组能 够使用的资源上限，包括 CPU、内存、磁盘、网络带宽等等。 此外，Cgroups 还能够对进程进行优先级设置、审计，以及将进程挂起和恢复等操作。

在今天 的分享中，我只和你重点探讨它与容器关系最紧密的“限制”能力，并通过一组实践来带你认识 一下 Cgroups。
 在 Linux 中，Cgroups 给用户暴露出来的操作接口是文件系统，即它以文件和目录的方式组织 在操作系统的 /sys/fs/cgroup 路径下。
```bash
$ mount -t cgroup 
cpuset on /sys/fs/cgroup/cpuset type cgroup (rw,nosuid,nodev,noexec,relatime,cpuset)
cpu on /sys/fs/cgroup/cpu type cgroup (rw,nosuid,nodev,noexec,relatime,cpu)
cpuacct on /sys/fs/cgroup/cpuacct type cgroup (rw,nosuid,nodev,noexec,relatime,cpuacct)
blkio on /sys/fs/cgroup/blkio type cgroup (rw,nosuid,nodev,noexec,relatime,blkio)
memory on /sys/fs/cgroup/memory type cgroup (rw,nosuid,nodev,noexec,relatime,memory)
...
```

它的输出结果，是一系列文件系统目录。如果你在自己的机器上没有看到这些目录，那你就需要 自己去挂载 Cgroups，具体做法可以自行 Google。 可以看到，在 /sys/fs/cgroup 下面有很多诸如 cpuset、cpu、 memory 这样的子目录，也叫 子系统。这些都是我这台机器当前可以被 Cgroups 进行限制的资源种类。而在子系统对应的资 源种类下，你就可以看到该类资源具体可以被限制的方法。比如，对 CPU 子系统来说，我们就 可以看到如下几个配置文件，这个指令是：

```bash
$ ls /sys/fs/cgroup/cpu
cgroup.clone_children cpu.cfs_period_us cpu.rt_period_us  cpu.shares notify_on_release
cgroup.procs      cpu.cfs_quota_us  cpu.rt_runtime_us cpu.stat  tasks
```

两个参数需要组合使用，可以用来限制进程在长度为 cfs_period 的一段时间内，只 能被分配到总量为 cfs_quota 的 CPU 时间。 而这样的配置文件又如何使用呢？ 你需要在对应的子系统下面创建一个目录，比如，我们现在进入 /sys/fs/cgroup/cpu 目录下：

```bash
root@ubuntu:/sys/fs/cgroup/cpu$ mkdir container
root@ubuntu:/sys/fs/cgroup/cpu$ ls container/
cgroup.clone_children cpu.cfs_period_us cpu.rt_period_us  cpu.shares notify_on_release
cgroup.procs      cpu.cfs_quota_us  cpu.rt_runtime_us cpu.stat  tasks
```

这个目录就称为一个“控制组”。你会发现，操作系统会在你新创建的 container 目录下，自 动生成该子系统对应的资源限制文件。 现在，我们在后台执行这样一条脚本：

```bash
$ while : ; do : ; done &
[1] 226
```

显然，它执行了一个死循环，可以把计算机的 CPU 吃到 100%，根据它的输出，我们可以看到 这个脚本在后台运行的进程号（PID）是 226。 这样，我们可以用 top 指令来确认一下 CPU 有没有被打满：
$ top
%Cpu0 :100.0 us, 0.0 sy, 0.0 ni, 0.0 id, 0.0 wa, 0.0 hi, 0.0 si, 0.0 st
在输出里可以看到，CPU 的使用率已经 100% 了（%Cpu0 :100.0 us）。 而此时，我们可以通过查看 container 目录下的文件，看到 container 控制组里的 CPU quota 还没有任何限制（即：-1），CPU period 则是默认的 100 ms（100000 us）：

```bash
$ cat /sys/fs/cgroup/cpu/container/cpu.cfs_quota_us 
-1
$ cat /sys/fs/cgroup/cpu/container/cpu.cfs_period_us 
100000
```

接下来，我们可以通过修改这些文件的内容来设置限制。
比如，向 container 组里的 cfs_quota 文件写入 20 ms（20000 us）：

```bash
$ echo 20000 > /sys/fs/cgroup/cpu/container/cpu.cfs_quota_us
```

结合前面的介绍，你应该能明白这个操作的含义，它意味着在每 100 ms 的时间里，被该控制组 限制的进程只能使用 20 ms 的 CPU 时间，也就是说这个进程只能使用到 20% 的 CPU 带宽。 接下来，我们把被限制的进程的 PID 写入 container 组里的 tasks 文件，上面的设置就会对该 进程生效了：

```bash
$ echo 226 > /sys/fs/cgroup/cpu/container/tasks 
```

我们可以用 top 指令查看一下：

```bash
$ top
%Cpu0 : 20.3 us, 0.0 sy, 0.0 ni, 79.7 id, 0.0 wa, 0.0 hi, 0.0 si, 0.0 st
```

可以看到，计算机的 CPU 使用率立刻降到了 20%（%Cpu0 : 20.3 us）。 除 CPU 子系统外，Cgroups 的每一项子系统都有其独有的资源限制能力，比如：
 blkio，为 块 设 备 设 定 I/O 限 制，一般用于磁盘等设备； 
cpuset，为进程分配单独的 CPU 核和对应的内存节点；
 memory，为进程设定内存使用的限制。
 Linux Cgroups 的设计还是比较易用的，简单粗暴地理解呢，它就是一个子系统目录加上一组 资源限制文件的组合。而对于 Docker 等 Linux 容器项目来说，它们只需要在每个子系统下 面，为每个容器创建一个控制组（即创建一个新目录），然后在启动容器进程之后，把这个进程 的 PID 填写到对应控制组的 tasks 文件中就可以了。 而至于在这些控制组下面的资源文件里填上什么值，就靠用户执行 docker run 时的参数指定 了，比如这样一条命令：

```bash
$ docker run -it --cpu-period=100000 --cpu-quota=20000 ubuntu /bin/bash
```

在启动这个容器后，我们可以通过查看 Cgroups 文件系统下，CPU 子系统中，“docker”这 个控制组里的资源限制文件的内容来确认：

```bash
$ cat /sys/fs/cgroup/cpu/docker/5d5c9f67d/cpu.cfs_period_us
100000
 $ cat /sys/fs/cgroup/cpu/docker/5d5c9f67d/cpu.cfs_quota_us 
20000
```

这就意味着这个 Docker 容器，只能使用到 20% 的 CPU 带宽。

参考：

 - [白话容器基础（二）：隔离与限制](https://time.geekbang.org/column/article/14653)
