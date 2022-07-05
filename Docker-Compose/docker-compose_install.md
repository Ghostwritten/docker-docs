#  docker-compose 安装

## 1. 安装
Linux
Linux 上我们可以从 Github 上下载它的二进制包来使用，最新发行的版本地址：[https://github.com/docker/compose/releases](https://github.com/docker/compose/releases/)。


运行以下命令以下载 Docker Compose 的当前稳定版本：

```bash
$ sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

要安装其他版本的 Compose，请替换 1.24.1。

将可执行权限应用于二进制文件：

```bash
$ sudo chmod +x /usr/local/bin/docker-compose
```

创建软链：

```bash
$ sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

测试是否安装成功：

```bash
$ docker-compose --version
cker-compose version 1.24.1, build 4667896b
```

## 2. 命令
```bash
docker-compose up -d nginx                     构建建启动nignx容器
docker-compose exec nginx bash            登录到nginx容器中
docker-compose down                              删除所有nginx容器,镜像
docker-compose ps                                   显示所有容器
docker-compose restart nginx                   重新启动nginx容器
docker-compose run --no-deps --rm php-fpm php -v  在php-fpm中不启动关联容器，并容器执行php -v 执行完成后删除容器
docker-compose build nginx                     构建镜像 。        
docker-compose build --no-cache nginx   不带缓存的构建。
docker-compose logs  nginx                     查看nginx的日志 
docker-compose logs -f nginx                   查看nginx的实时日志
 
docker-compose config  -q                        验证（docker-compose.yml）文件配置，当配置正确时，不输出任何内容，当文件配置错误，输出错误信息。 
docker-compose events --json nginx       以json的形式输出nginx的docker日志
docker-compose pause nginx                 暂停nignx容器
docker-compose unpause nginx             恢复ningx容器
docker-compose rm nginx                       删除容器（删除前必须关闭容器）
docker-compose stop nginx                    停止nignx容器
docker-compose start nginx                    启动nignx容器
```
