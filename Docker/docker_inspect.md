#  docker inspect --format 

Docker --format 参数提供了基于 Go模板 的日志格式化输出辅助功能，并提供了一些内置的增强函数。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200817185403190.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70#pic_center)
## 1. 什么是模板?
上图是大家熟悉的 MVC 框架（Model View Controller）： `Model（模型，通常在服务端）用于处理数据、View（视图，客户端代码）用于展现结果、Controller（控制器）`用于控制数据流，确保 M 和 V 的同步，即一旦 M 改变，V 也应该同步更新。
而对于 View 端的处理，在很多动态语言中是通过在静态 HTML 代码中插入动态数据来实现的。例如 JSP 的 <%=....=%> 和 PHP 的 <?php.....?> 语法。
由于最终展示给用户的信息大部分是静态不变的，只有少部分数据会根据用户的不同而动态生成。比如，对于 docker ls 的输出信息会根据附加参数的不同而不同，但其表头信息是固定的。所以，将静态信息固化为模板可以复用代码，提高展示效率。


## 2. Go模板常用语法
```bash
docker network inspect --format='{{/*查看容器的默认网关*/}}{{range .IPAM.Config}}{{.Gateway}}{{end}}' $INSTANCE_ID
```
## 3. 变量
### 3.1 系统变量 \{\{.\}\}
点号表示当前对象及上下文，和 Java、C++ 中的 this 类似。可以直接通过\{\{.\}\}获取当前对象。
另外，如果返回结果也是一个 Struct 对象（Json 中以花括号/大括号包含），则可以直接通过点号级联调用，获取子对象的指定属性值。

```bash
#可以通过级联调用直接读取子对象 State 的 Status 属性，以获取容器的状态信息：
docker inspect --format '{{/*读取容器状态*/}}{{.State.Status}}' $INSTANCE_ID   
```
**注意**： 如果需要获取的属性名称包含点号（比如下列示例数据）或者以数字开头，则不能直接通过级联调用获取信息。因为属性名称中的点号会被解析成级联信息，进而导致返回错误结果。即便使用引号将其包含也会提示语法格式错误。此时，需要通过 index 来读取指定属性信息。

```bash
"Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
```

```bash
# 直接级联调用会提示找不到数据：
docker inspect --format '{{.Options.com.docker.network.driver.mtu}}' bridge
<no value>
 
# 用引号括起来会提示语法错误：
docker inspect --format '{{.Options."com.docker.network.driver.mtu"}}' bridge
Template parsing error: template: :1: bad character U+0022 '"'
 
# 正确的用法，必须用 index 读取指定属性名称的属性值：
docker inspect --format '{{/*读取网络在hosts上的名称*/}}{{index .Options "com.docker.network.bridge.name"}}' bridge
docker0

```


实例：

```bash
[root@monitor1 ~]#  docker inspect -f '{{.Id}}' prometheus 
9094fdeb64edf75d52189e1b985d0926cf4e6d53880a8f09ab30fc2d6c8a0908
[root@monitor1 ~]# docker inspect -f '{{.State.Status}}' prometheus 
running
[root@monitor1 ~]# docker inspect -f '{{"status:"}}{{.State.Status}}' prometheus 
status:running
[root@monitor1 ~]# docker inspect -f '{{"status:"}}{{index .State.Status}}' prometheus 
status:running

```

### 3.2 自定义变量
可以在处理过程中设置自定义变量，然后结合自定义变量做更复杂的处理。 如果自定义变量的返回值是对象，则可以通过点号进一步级联访问其属性。比如 `{{$Myvar.Field1}}`。

```bash
# 结合变量的使用，对输出结果进行组装展现，以输出容器的所有绑定端口列表：
docker inspect --format '{{/*通过变量组合展示容器绑定端口列表*/}}已绑定端口列表：{{println}}{{range $p,$conf := .NetworkSettings.Ports}}{{$p}} -> {{(index $conf 0).HostPort}}{{println}}{{end}}' Web_web_1
 
# 示例输出信息
已绑定端口列表：
80/tcp -> 32770
8081/tcp -> 8081
```
### 3.3 遍历（循环）：range
格式：

```bash
{{range pipeline}}{{.}}{{end}}
{{range pipeline}}{{.}}{{else}}{{.}}{{end}}
```

range 用于遍历结构内返回值的所有数据。支持的类型包括 array, slice, map 和 channel。使用要点：
-  对应的值长度为 0 时，range 不会执行。
-  结构内部如要使用外部的变量，需要在前面加 引用，比如Var2。
-  range 也支持 else 操作。效果是：当返回值为空或长度为 0 时执行 else 内的内容。

 查看容器网络下已挂载的所有容器名称，如果没有挂载任何容器，则输出 "With No Containers"

```bash
        "NetworkSettings": {
            "Bridge": "",
            "SandboxID": "a4ae52dfb055599b4b582d4c91f5a38d297bbed30f3e1d698f1c199be572c1e3",
            "HairpinMode": false,
            "LinkLocalIPv6Address": "",
            "LinkLocalIPv6PrefixLen": 0,
            "Ports": {
                "9090/tcp": [
                    {
                        "HostIp": "0.0.0.0",
                        "HostPort": "9090"
                    }
                ]
            },
            "SandboxKey": "/var/run/docker/netns/a4ae52dfb055",
            "SecondaryIPAddresses": null,
            "SecondaryIPv6Addresses": null,
            "EndpointID": "16dbaea3aef149379a83673284c9adb843dab363246e6eb3255e40b149003580",
            "Gateway": "172.17.0.1",
            "GlobalIPv6Address": "",
            "GlobalIPv6PrefixLen": 0,
            "IPAddress": "172.17.0.2",
            "IPPrefixLen": 16,
            "IPv6Gateway": "",
            "MacAddress": "02:42:ac:11:00:02",
            "Networks": {
                "bridge": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": null,
                    "NetworkID": "2045baaf0ce3f404298a1a57035b6cc6c91ebd4ee05ce219b818f255c198b44b",
                    "EndpointID": "16dbaea3aef149379a83673284c9adb843dab363246e6eb3255e40b149003580",
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.2",
                    "IPPrefixLen": 16,
                    "IPv6Gateway": "",
                    "GlobalIPv6Address": "",
                    "GlobalIPv6PrefixLen": 0,
                    "MacAddress": "02:42:ac:11:00:02"
                }
            }
        }
    }
]
```

```bash
[root@monitor1 ~]#  docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' prometheus
172.17.0.2

[root@monitor1 ~]#  docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}} {{$p}} -> {{(index $conf 0).HostPort}} {{end}}' prometheus
 9090/tcp -> 9090 
 ```
 
## 4. index
如果返回结果是一个 map, slice, array 或 string，则可以使用 index 加索引序号（从零开始计数）来读取属性值。
```bash
[root@monitor1 ~]# docker inspect --format='{{(index (index .NetworkSettings.Ports "9090/tcp") 0).HostPort}}'  prometheus
9090

```


## 5. 判断：if … else … end
基本判断
### 5.1 not
   返回单一参数的布尔否定值，即返回输入参数的否定值。

示例:

```bash
# 如果容器的 restarting 设置为 false，则返回信息“容器没有配置重启策略”
docker inspect --format '{{if not .State.Restarting}}容器没有配置重启策略{{end}}' $(docker ps -q)
容器没有配置重启策略
```
### 5.2 or
-   \{\{or x y\}\}: 表示如果 x 为真返回 x，否则返回 y。
-   \{\{or x y z\}\}：后面跟多个参数时会逐一判断每个参数，并返回第一个非空的参数。如果都为 false，则返回最后一个参数。
-  除了 null（空）和 false 被识别为 false，其它值（字符串、数字、对象等）均被识别为 true。

示例:

```bash
[root@monitor1 ~]# docker inspect --format '{{or .State.Status .State.Restarting}}' $(docker ps -q)
running
```
## 6. 判断条件
判断语句通常需要结合判断条件一起使用，使用格式基本相同：

```bash
{{if 判断条件 .Var1 .Var2}}{{end}}
```

go模板支持如下判断方式：
1)  eq: 相等，即 arg1 == arg2。比较特殊的是，它支持多个参数进行与比较，此时，它会将第一个参数和其余参数依次比较，返回下式的结果：

```bash
{{if eq true .Var1 .Var2 .Var3}}{{end}}
```

效果等同于：

```bash
arg1==arg2 || arg1==arg3 || arg1==arg4 ...
2) ne: 不等，即 arg1 != arg2。
3) lt: 小于，即 arg1 < arg2。
4) le: 小于等于，即 arg1 <= arg2。
5) gt: 大于，即 arg1 > arg2。
6) ge: 大于等于，即 arg1 >= arg2。
```

## 7. 判断的使用

```bash
{{if pipeline}}{{end}}
{{if pipeline}}{{else}}{{if pipeline}}{{end}}{{end}}
{{if pipeline}}{{else if pipeline}}{{else}}{{end}}
```

```bash
# 输出所有已停止的容器名称：
docker inspect --format '{{if ne 0.0 .State.ExitCode}}{{.Name}}{{end}}' $(docker ps -aq)
docker inspect --format '{{if ne 0.0 .State.ExitCode}}{{.Name}}{{else}}该容器还在运行{{end}}' $(docker ps -aq)
docker inspect --format '{{if ne 0.0 .State.ExitCode}}{{.Name}}{{else if .}}该容器还在运行{{end}}' $(docker ps -aq)
 
# 输出所有已停止或配置了 Restarting 策略的容器名称
docker inspect --format '{{if ne 0.0 .State.ExitCode}}{{.Name}}{{else if eq .State.Restarting true}}容器{{.Name}}配置了Restarting策略.{{else}}{{end}}' $(docker ps -aq)
```
## 8. 打印信息
docker --format 默认调用 go语言的 print 函数对模板中的字符串进行输出。而 go语言还有另外 2 种相似的内置函数，对比说明如下：

 - `print`：  将传入的对象转换为字符串并写入到标准输出中。如果后跟多个参数，输出结果之间会自动填充空格进行分隔。
 - `println`:  功能和 print 类似，但会在结尾添加一个换行符。也可以直接使用 {{println}} 来换行。
 - `printf`:   与 shell 等环境一致，可配合占位符用于格式化输出。

```bash
docker inspect --format '{{.State.Pid}}{{.State.ExitCode}}' $INSTANCE_ID
240390
 
docker inspect --format '{{print .State.Pid .State.ExitCode}}' $INSTANCE_ID
24039 0
 
docker inspect --format '{{.State.Pid}}{{println " 从这换行"}}{{.State.ExitCode}}' $INSTANCE_ID
24039 从这换行
0
 
docker inspect --format '{{printf "Pid:%d ExitCode:%d" .State.Pid .State.ExitCode}}' $INSTANCE_ID
Pid:24039 ExitCode:0
```
## 9. 管道
管道 即 pipeline ，与 shell 中类似，可以是上下文的变量输出，也可以是函数通过管道传递的返回值。

```bash
{{.Con | markdown | addlinks}}
{{.Name | printf "%s"}}
```

```bash
$ docker inspect --format '{{len .Name}}' prometheus 
11


$ docker inspect nginx -f '{{json .State}}' | jq
{
  "Status": "running",
  "Running": true,
  "Paused": false,
  "Restarting": false,
  "OOMKilled": false,
  "Dead": false,
  "Pid": 23773,
  "ExitCode": 0,
  "Error": "",
  "StartedAt": "2021-08-04T09:27:06.018089509Z",
  "FinishedAt": "0001-01-01T00:00:00Z"
}

```

参考：

 - [What to Inspect When You're Inspecting](https://www.ctl.io/developers/blog/post/what-to-inspect-when-youre-inspecting)
 - [Docker格式化输出命令:"docker inspect --format" 学习笔记](https://www.cnblogs.com/kevingrace/p/6424476.html)
