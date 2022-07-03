#  Docker 容器应用总是丢包如何分析？

##  1. 回顾
容器化后的应用程序，问题分析结合：

 - cgroups 会影响容器应用的运行；
 - iptables 中的 NAT，会影响容器的网络性能；
 - 叠加文件系统，会影响应用的 I/O 性能等。


就以最常用的反向代理服务器 Nginx 为例，学习丢包的分析方法

所谓丢包，是指在网络数据的收发过程中，由于种种原因，数据包还没传输到应用程序中，就被丢弃了。这些被丢弃包的数量，除以总的传输包数，也就是我们常说的丢包率。丢包率是网络性能中最核心的指标之一。

##  2. 案例准备

 - Ubuntu 18.04 两台
 - 机器配置：2 CPU，8GB 内存
 - 预先安装 docker、curl、hping3 等工具，如 apt install docker.io curl hping3。


![在这里插入图片描述](https://img-blog.csdnimg.cn/7a258ae9692045febab9443e37a504dd.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)

##  3. 案例分析
在终端一中执行下面的命令，启动 Nginx 应用，并在 80 端口监听。如果一切正常，你应该可以看到如下的输出：

```bash
$ docker run --name nginx --hostname nginx --privileged -p 80:80 -itd feisky/nginx:drop
dae0202cc27e5082b282a6aeeb1398fcec423c642e63322da2a97b9ebd7538e0


$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                NAMES
dae0202cc27e        feisky/nginx:drop   "/start.sh"         4 minutes ago       Up 4 minutes        0.0.0.0:80->80/tcp   nginx
```


接着，我们切换到终端二中，执行下面的 hping3 命令，进一步验证 Nginx 是不是真的可以正常访问了。注意，这里我没有使用 ping，是因为 ping 基于 ICMP 协议，而 Nginx 使用的是 TCP 协议。


```bash
# -c表示发送10个请求，-S表示使用TCP SYN，-p指定端口为80
$ hping3 -c 10 -S -p 80 192.168.0.30
HPING 192.168.0.30 (eth0 192.168.0.30): S set, 40 headers + 0 data bytes
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=3 win=5120 rtt=7.5 ms
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=4 win=5120 rtt=7.4 ms
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=5 win=5120 rtt=3.3 ms
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=7 win=5120 rtt=3.0 ms
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=6 win=5120 rtt=3027.2 ms

--- 192.168.0.30 hping statistic ---
10 packets transmitted, 5 packets received, 50% packet loss
round-trip min/avg/max = 3.0/609.7/3027.2 ms
```
从 hping3 的输出中，我们可以发现，发送了 10 个请求包，却只收到了 5 个回复，50% 的包都丢了。再观察每个请求的 RTT 可以发现，RTT 也有非常大的波动变化，小的时候只有 3ms，而大的时候则有 3s。根据这些输出，我们基本能判断，已经发生了丢包现象。可以猜测，3s 的 RTT ，很可能是因为丢包后重传导致的。那到底是哪里发生了丢包呢？

在这里，为了帮你理解网络丢包的原理，我画了一张图，你可以保存并打印出来使用：

![在这里插入图片描述](https://img-blog.csdnimg.cn/3d8bd7b6ea114aec8ccbcb10b29b7314.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)
从图中你可以看出，可能发生丢包的位置，实际上贯穿了整个网络协议栈。换句话说，全程都有丢包的可能。比如我们从下往上看：

 - 在两台 VM 连接之间，可能会发生传输失败的错误，比如网络拥塞、线路错误等；
 - 在网卡收包后，环形缓冲区可能会因为溢出而丢包；
 - 在链路层，可能会因为网络帧校验失败、QoS 等而丢包；
 - 在 IP 层，可能会因为路由失败、组包大小超过 MTU 等而丢包；
 - 在传输层，可能会因为端口未监听、资源占用超过内核限制等而丢包；
 - 在套接字层，可能会因为套接字缓冲区溢出而丢包；
 - 在应用层，可能会因为应用程序异常而丢包；
 - 此外，如果配置了 iptables 规则，这些网络包也可能因为 iptables 过滤规则而丢包。

现在我们切换回终端一，执行下面的命令，进入容器的终端中：

```bash
$ docker exec -it nginx bash
root@nginx:/#
```
么， 接下来，我们就可以从协议栈中，逐层排查丢包问题。


###  3.1 链路层

首先，来看最底下的链路层。当缓冲区溢出等原因导致网卡丢包时，Linux 会在网卡收发数据的统计信息中，记录下收发错误的次数。你可以通过 ethtool 或者 netstat ，来查看网卡的丢包记录。比如，可以在容器中执行下面的命令，查看丢包情况：


```bash
root@nginx:/# netstat -i
Kernel Interface table
Iface      MTU    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg
eth0       100       31      0      0 0             8      0      0      0 BMRU
lo       65536        0      0      0 0             0      0      0      0 LRU
```
输出中的 RX-OK、RX-ERR、RX-DRP、RX-OVR ，分别表示接收时的总包数、总错误数、进入 Ring Buffer 后因其他原因（如内存不足）导致的丢包数以及 Ring Buffer 溢出导致的丢包数。


TX-OK、TX-ERR、TX-DRP、TX-OVR 也代表类似的含义，只不过是指发送时对应的各个指标。

注意，由于 Docker 容器的虚拟网卡，实际上是一对 veth pair，一端接入容器中用作 eth0，另一端在主机中接入 docker0 网桥中。veth 驱动并没有实现网络统计的功能，所以使用 ethtool -S 命令，无法得到网卡收发数据的汇总信息。

从这个输出中，我们没有发现任何错误，说明容器的虚拟网卡没有丢包。不过要注意，如果用 tc 等工具配置了 QoS，那么 tc 规则导致的丢包，就不会包含在网卡的统计信息中。所以接下来，我们还要检查一下 eth0 上是否配置了 tc 规则，并查看有没有丢包。我们继续容器终端中，执行下面的 tc 命令，不过这次注意添加 -s 选项，以输出统计信息：


```bash
root@nginx:/# tc -s qdisc show dev eth0
qdisc netem 800d: root refcnt 2 limit 1000 loss 30%
 Sent 432 bytes 8 pkt (dropped 4, overlimits 0 requeues 0)
 backlog 0b 0p requeues 0
```
从 tc 的输出中可以看到， eth0 上面配置了一个网络模拟排队规则（qdisc netem），并且配置了丢包率为 30%（loss 30%）。再看后面的统计信息，发送了 8 个包，但是丢了 4 个。看来，应该就是这里，导致 Nginx 回复的响应包，被 netem 模块给丢了。既然发现了问题，解决方法也就很简单了，直接删掉 netem 模块就可以了。我们可以继续在容器终端中，执行下面的命令，删除 tc 中的 netem 模块：


```bash
root@nginx:/# tc qdisc del dev eth0 root netem loss 30%
```
删除后，问题到底解决了没？我们切换到终端二中，重新执行刚才的 hping3 命令，看看现在还有没有问题：


```bash
$ hping3 -c 10 -S -p 80 192.168.0.30
HPING 192.168.0.30 (eth0 192.168.0.30): S set, 40 headers + 0 data bytes
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=0 win=5120 rtt=7.9 ms
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=2 win=5120 rtt=1003.8 ms
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=5 win=5120 rtt=7.6 ms
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=6 win=5120 rtt=7.4 ms
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=9 win=5120 rtt=3.0 ms

--- 192.168.0.30 hping statistic ---
10 packets transmitted, 5 packets received, 50% packet loss
round-trip min/avg/max = 3.0/205.9/1003.8 ms
```
不幸的是，从 hping3 的输出中，我们可以看到，跟前面现象一样，还是 50% 的丢包；RTT 的波动也仍旧很大，从 3ms 到 1s。显然，问题还是没解决，丢包还在继续发生。不过，既然链路层已经排查完了，我们就继续向上层分析，看看网络层和传输层有没有问题。

### 3.2 网络层和传输层

在网络层和传输层中，引发丢包的因素非常多。不过，其实想确认是否丢包，是非常简单的事，因为 Linux 已经为我们提供了各个协议的收发汇总情况。我们继续在容器终端中，执行下面的 netstat -s 命令，就可以看到协议的收发汇总，以及错误信息了：


```bash
root@nginx:/# netstat -s
Ip:
    Forwarding: 1          //开启转发
    31 total packets received    //总收包数
    0 forwarded            //转发包数
    0 incoming packets discarded  //接收丢包数
    25 incoming packets delivered  //接收的数据包数
    15 requests sent out      //发出的数据包数
Icmp:
    0 ICMP messages received    //收到的ICMP包数
    0 input ICMP message failed    //收到ICMP失败数
    ICMP input histogram:
    0 ICMP messages sent      //ICMP发送数
    0 ICMP messages failed      //ICMP失败数
    ICMP output histogram:
Tcp:
    0 active connection openings  //主动连接数
    0 passive connection openings  //被动连接数
    11 failed connection attempts  //失败连接尝试数
    0 connection resets received  //接收的连接重置数
    0 connections established    //建立连接数
    25 segments received      //已接收报文数
    21 segments sent out      //已发送报文数
    4 segments retransmitted    //重传报文数
    0 bad segments received      //错误报文数
    0 resets sent          //发出的连接重置数
Udp:
    0 packets received
    ...
TcpExt:
    11 resets received for embryonic SYN_RECV sockets  //半连接重置数
    0 packet headers predicted
    TCPTimeouts: 7    //超时数
    TCPSynRetrans: 4  //SYN重传数
  ...
```
netstat 汇总了 IP、ICMP、TCP、UDP 等各种协议的收发统计信息。不过，我们的目的是排查丢包问题，所以这里主要观察的是错误数、丢包数以及重传数。根据上面的输出，你可以看到，只有 TCP 协议发生了丢包和重传，分别是：

 - 11 次连接失败重试（11 failed connection attempts）
 - 4 次重传（4 segments retransmitted）
 - 11 次半连接重置（11 resets received for embryonic SYN_RECV sockets）
 - 4 次 SYN 重传（TCPSynRetrans）
 - 7 次超时（TCPTimeouts）

这个结果告诉我们，TCP 协议有多次超时和失败重试，并且主要错误是半连接重置。换句话说，主要的失败，都是三次握手失败。不过，虽然在这儿看到了这么多失败，但具体失败的根源还是无法确定。所以，我们还需要继续顺着协议栈来分析。


###  3.3 iptables

首先我们要知道，除了网络层和传输层的各种协议，iptables 和内核的连接跟踪机制也可能会导致丢包。所以，这也是发生丢包问题时，我们必须要排查的一个因素。

我们先来看看连接跟踪，要确认是不是连接跟踪导致的问题，其实只需要对比当前的连接跟踪数和最大连接跟踪数即可。不过，由于连接跟踪在 Linux 内核中是全局的（不属于网络命名空间），我们需要退出容器终端，回到主机中来查看。你可以在容器终端中，执行 exit ；然后执行下面的命令，查看连接跟踪数：


```bash
# 容器终端中执行exit
root@nginx:/# exit
exit

# 主机终端中查询内核配置
$ sysctl net.netfilter.nf_conntrack_max
net.netfilter.nf_conntrack_max = 262144
$ sysctl net.netfilter.nf_conntrack_count
net.netfilter.nf_conntrack_count = 182
```
从这儿你可以看到，连接跟踪数只有 182，而最大连接跟踪数则是 262144。显然，这里的丢包，不可能是连接跟踪导致的。接着，再来看 iptables。回顾一下 iptables 的原理，**它基于 Netfilter 框架，通过一系列的规则，对网络数据包进行过滤（如防火墙）和修改（如 NAT）**。


些 iptables 规则，统一管理在一系列的表中，**包括 filter（用于过滤）、nat（用于 NAT）、mangle（用于修改分组数据） 和 raw（用于原始数据包）等**。而每张表又可以包括一系列的链，用于对 iptables 规则进行分组管理。

对于丢包问题来说，最大的可能就是被 filter 表中的规则给丢弃了。要弄清楚这一点，就需要我们确认，那些目标为 DROP 和 REJECT 等会弃包的规则，有没有被执行到。


你可以把所有的 iptables 规则列出来，根据收发包的特点，跟 iptables 规则进行匹配。不过显然，如果 iptables 规则比较多，这样做的效率就会很低。当然，更简单的方法，就是直接查询 DROP 和 REJECT 等规则的统计信息，看看是否为 0。如果统计值不是 0 ，再把相关的规则拎出来进行分析。

我们可以通过 iptables -nvL 命令，查看各条规则的统计信息。比如，你可以执行下面的 docker exec 命令，进入容器终端；然后再执行下面的 iptables 命令，就可以看到 filter 表的统计数据了：


```bash
# 在主机中执行
$ docker exec -it nginx bash

# 在容器中执行
root@nginx:/# iptables -t filter -nvL
Chain INPUT (policy ACCEPT 25 packets, 1000 bytes)
 pkts bytes target     prot opt in     out     source               destination
    6   240 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            statistic mode random probability 0.29999999981

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 15 packets, 660 bytes)
 pkts bytes target     prot opt in     out     source               destination
    6   264 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            statistic mode random probability 0.29999999981
```

从 iptables 的输出中，你可以看到，**两条 DROP 规则的统计数值不是 0，它们分别在 INPUT 和 OUTPUT 链中。这两条规则实际上是一样的，指的是使用 statistic 模块，进行随机 30% 的丢包。**再观察一下它们的匹配规则。**0.0.0.0/0 表示匹配所有的源 IP 和目的 IP，也就是会对所有包都进行随机 30% 的丢包。**看起来，这应该就是导致部分丢包的“罪魁祸首”了。既然找出了原因，接下来的优化就比较简单了。比如，把这两条规则直接删除就可以了。我们可以在容器终端中，执行下面的两条 iptables 命令，删除这两条 DROP 规则：


```bash
root@nginx:/# iptables -t filter -D INPUT -m statistic --mode random --probability 0.30 -j DROP
root@nginx:/# iptables -t filter -D OUTPUT -m statistic --mode random --probability 0.30 -j DROP
```
删除后，问题是否就被解决了呢？我们可以切换到终端二中，重新执行刚才的 hping3 命令，看看现在是否正常：


```bash
$ hping3 -c 10 -S -p 80 192.168.0.30
HPING 192.168.0.30 (eth0 192.168.0.30): S set, 40 headers + 0 data bytes
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=0 win=5120 rtt=11.9 ms
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=1 win=5120 rtt=7.8 ms
...
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=9 win=5120 rtt=15.0 ms

--- 192.168.0.30 hping statistic ---
10 packets transmitted, 10 packets received, 0% packet loss
round-trip min/avg/max = 3.3/7.9/15.0 ms
```
这次输出你可以看到，现在已经没有丢包了，并且延迟的波动变化也很小。看来，丢包问题应该已经解决了。

不过，到目前为止，我们一直使用的 hping3 工具，只能验证案例 Nginx 的 80 端口处于正常监听状态，却还没有访问 Nginx 的 HTTP 服务。所以，不要匆忙下结论结束这次优化，我们还需要进一步确认，Nginx 能不能正常响应 HTTP 请求。

我们继续在终端二中，执行如下的 curl 命令，检查 Nginx 对 HTTP 请求的响应：


```bash
$ curl --max-time 3 http://192.168.0.30
curl: (28) Operation timed out after 3000 milliseconds with 0 bytes received
```
从 curl 的输出中，你可以发现，这次连接超时了。可是，刚才我们明明用 hping3 验证了端口正常，现在却发现 HTTP 连接超时，是不是因为 Nginx 突然异常退出了呢？不妨再次运行 hping3 来确认一下：


```bash
$ hping3 -c 3 -S -p 80 192.168.0.30
HPING 192.168.0.30 (eth0 192.168.0.30): S set, 40 headers + 0 data bytes
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=0 win=5120 rtt=7.8 ms
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=1 win=5120 rtt=7.7 ms
len=44 ip=192.168.0.30 ttl=63 DF id=0 sport=80 flags=SA seq=2 win=5120 rtt=3.6 ms

--- 192.168.0.30 hping statistic ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 3.6/6.4/7.8 ms
```
奇怪，hping3 的结果显示，Nginx 的 80 端口确确实实还是正常状态。这该如何是好呢？别忘了，我们还有个大杀器——抓包操作。看来有必要抓包看看了。

###  3.4 tcpdump

接下来，我们切换回终端一，在容器终端中，执行下面的 tcpdump 命令，抓取 80 端口的包：


```bash
root@nginx:/# tcpdump -i eth0 -nn port 80
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes   
```
然后，切换到终端二中，再次执行前面的 curl 命令：


```bash
$ curl --max-time 3 http://192.168.0.30/
curl: (28) Operation timed out after 3000 milliseconds with 0 bytes received
```
等到 curl 命令结束后，再次切换回终端一，查看 tcpdump 的输出：


```bash
14:40:00.589235 IP 10.255.255.5.39058 > 172.17.0.2.80: Flags [S], seq 332257715, win 29200, options [mss 1418,sackOK,TS val 486800541 ecr 0,nop,wscale 7], length 0
14:40:00.589277 IP 172.17.0.2.80 > 10.255.255.5.39058: Flags [S.], seq 1630206251, ack 332257716, win 4880, options [mss 256,sackOK,TS val 2509376001 ecr 486800541,nop,wscale 7], length 0
14:40:00.589894 IP 10.255.255.5.39058 > 172.17.0.2.80: Flags [.], ack 1, win 229, options [nop,nop,TS val 486800541 ecr 2509376001], length 0
14:40:03.589352 IP 10.255.255.5.39058 > 172.17.0.2.80: Flags [F.], seq 76, ack 1, win 229, options [nop,nop,TS val 486803541 ecr 2509376001], length 0
14:40:03.589417 IP 172.17.0.2.80 > 10.255.255.5.39058: Flags [.], ack 1, win 40, options [nop,nop,TS val 2509379001 ecr 486800541,nop,nop,sack 1 {76:77}], length 0
```
经过这么一系列的操作，从 tcpdump 的输出中，我们就可以看到：

 - 前三个包是正常的 TCP 三次握手，这没问题；
 - 但第四个包却是在 3 秒以后了，并且还是客户端（VM2）发送过来的 FIN 包，也就说明，客户端的连接关闭了。


我想，根据 curl 设置的 3 秒超时选项，你应该能猜到，这是因为 curl 命令超时后退出了。我把这一过程，用 TCP 交互的流程图（实际上来自 Wireshark 的 Flow Graph）来表示，你可以更清楚地看到上面这个问题：

![在这里插入图片描述](https://img-blog.csdnimg.cn/c0b514bc81854e19a5c5ccfa4b249af0.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70)
这里比较奇怪的是，我们并没有抓取到 curl 发来的 HTTP GET 请求。那么，究竟是网卡丢包了，还是客户端压根儿就没发过来呢？我们可以重新执行 netstat -i 命令，确认一下网卡有没有丢包问题：


```bash
root@nginx:/# netstat -i
Kernel Interface table
Iface      MTU    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg
eth0       100      157      0    344 0            94      0      0      0 BMRU
lo       65536        0      0      0 0             0      0      0      0 LRU
```
还是那句话，遇到搞不懂的现象，不妨先去查查工具和方法的原理。我们可以对比一下这两个工具：

 - hping3 实际上只发送了 SYN 包；
 - 而 curl 在发送 SYN 包后，还会发送 HTTP GET 请求。


HTTP GET ，本质上也是一个 TCP 包，但跟 SYN 包相比，它还携带了 `HTTP GET` 的数据。那么，通过这个对比，你应该想到了，这可能是 MTU 配置错误导致的。为什么呢？

其实，仔细观察上面 netstat 的输出界面，第二列正是每个网卡的 MTU 值。eth0 的 MTU 只有 100，而以太网的 MTU 默认值是 1500，这个 100 就显得太小了。

当然，MTU 问题是很好解决的，把它改成 1500 就可以了。我们继续在容器终端中，执行下面的命令，把容器 eth0 的 MTU 改成 1500：


```bash
root@nginx:/# ifconfig eth0 mtu 1500
```
修改完成后，再切换到终端二中，再次执行 curl 命令，确认问题是否真的解决了：

```bash
$ curl --max-time 3 http://192.168.0.30/
<!DOCTYPE html>
<html>
...
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
非常不容易呀，这次终于看到了熟悉的 Nginx 响应，说明丢包的问题终于彻底解决了。

来自：

 - [服务器总是时不时丢包，我该怎么办？（下）](https://time.geekbang.org/column/article/85688)
