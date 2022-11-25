# Centos 7.9 harbor 部署镜像仓库
tags: registry
![](https://img-blog.csdnimg.cn/257145a26e7540fb84859725fbbcaba2.png)

##  1. 安装 docker
- [Docker 安装](https://blog.csdn.net/xixihahalelehehe/article/details/104293170)

### 1.1 配置 docker

```bash
$ cat /etc/docker/daemon.json 
{
   "exec-opts": ["native.cgroupdriver=systemd"],
   "log-driver": "json-file",
   "log-opts": {
   "max-size":  "100m"
    },
   "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
 }
```
启动 docker
```bash
systemctl start docker
```

##  2. 安装 docker-compose
下载最新版本：[https://github.com/docker/compose/releases](https://github.com/docker/compose/releases/)
```bash
 sudo curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
 sudo chmod +x /usr/local/bin/docker-compose	
 sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

```bash
$ docker-compose --version
Docker Compose version v2.12.2
```

## 3. 下载 harbor
下载最新harbor：[https://github.com/goharbor/harbor/releases](https://github.com/goharbor/harbor/releases)

```bash
sudo curl -L "https://github.com/goharbor/harbor/releases/download/v2.6.2/harbor-offline-installer-v2.6.2.tgz" -o harbor-offline-installer-v2.6.2.tgz


```

```bash
$ tar xzvf harbor-offline-installer-v2.6.2.tgz
harbor/harbor.v2.6.2.tar.gz
harbor/prepare
harbor/LICENSE
harbor/install.sh
harbor/common.sh
harbor/harbor.yml.tmpl

$ ls harbor
common.sh  harbor.v2.6.2.tar.gz  harbor.yml.tmpl  install.sh  LICENSE  prepare
```
## 4. 定制配置文件 harbor.yml

```bash
cp harbor.yml.tmpl harbor.yml
```

```bash
$ vim harbor.yml
hostname: harbor.fumai.com
http:
  port: 80
https:
  port: 443
  certificate: /data/cert/harbor.fumai.com.crt
  private_key: /data/cert/harbor.fumai.com.key
harbor_admin_password: Harbor12345
database:
  password: root123
  max_idle_conns: 100
  max_open_conns: 900
data_volume: /data
trivy:
  ignore_unfixed: false
  skip_update: false
  offline_scan: false
  security_check: vuln
  insecure: false
jobservice:
  max_job_workers: 10
notification:
  webhook_job_max_retry: 10
chart:
  absolute_url: disabled
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
_version: 2.6.0
proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - trivy
upload_purging:
  enabled: true
  age: 168h
  interval: 24h
  dryrun: false
cache:
  enabled: false
  expire_hours: 24
```

## 5. 配置证书
###  5.1 生成证书颁发机构证书
生成 CA 证书私钥ca.key
```bash
openssl genrsa -out ca.key 4096
```
#生成 CA 证书
```bash
openssl req -x509 -new -nodes -sha512 -days 3650 -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=harbor.fumai.com" -key ca.key -out ca.crt
```
### 5.2 生成服务器证书
生成私钥

```bash
openssl genrsa -out harbor.fumai.com.key 4096
```
生成证书签名请求 (CSR)

```bash
openssl req -sha512 -new -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=harbor.fumai.com"  -key harbor.fumai.com.key -out harbor.fumai.com.csr
```
生成 `x509 v3` 扩展文件

```bash
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=harbor.fumai.com
DNS.2=harbor.fumai
DNS.3=hostname
EOF
```
使用该`v3.ext`文件为您的 Harbor 主机生成证书

```bash
openssl x509 -req -sha512 -days 3650 -extfile v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in harbor.fumai.com.csr -out harbor.fumai.com.crt
```
### 5.3 向 Harbor 和 Docker 提供证书
将服务器证书和密钥复制到 Harbor 主机上的 certficates 文件夹中
```bash
mkdir -p /data/cert
cp harbor.fumai.com.crt /data/cert/
cp harbor.fumai.com.key /data/cert/
```
转换`harbor.fumai.com.crt`为`harbor.fumai.com.key.cert`，供 docker使用
```bash
openssl x509 -inform PEM -in harbor.fumai.com.crt -out harbor.fumai.com.cert
```
将服务器证书、密钥和 CA 文件复制到 Harbor 主机上的 `docker` 证书文件夹中。您必须首先创建适当的文件夹

```bash
mkdir -p /etc/docker/certs.d/harbor.fumai.com/
cp harbor.fumai.com.cert /etc/docker/certs.d/harbor.fumai.com/
cp harbor.fumai.com.key /etc/docker/certs.d/harbor.fumai.com/
cp ca.crt /etc/docker/certs.d/harbor.fumai.com/
```
配置生效

```bash
systemctl daemon-reload &&  systemctl restart docker
```

## 6. 部署 harbor
运行`prepare`脚本以启用 HTTPS
```bash
./prepare
```
输出：
```bash
prepare base dir is set to /root/harbor
Unable to find image 'goharbor/prepare:v2.6.2' locally
v2.6.2: Pulling from goharbor/prepare
d46c4d5563bc: Pulling fs layer
2014728b1023: Pulling fs layer
aab288eb9305: Pulling fs layer
f5624bd14a09: Waiting
d706af45859a: Waiting
758da3aa4679: Waiting
af6231a55025: Waiting
8c758607ff4a: Waiting
fb477479c0dd: Waiting
99767f301e98: Waiting
v2.6.2: Pulling from goharbor/prepare
d46c4d5563bc: Pull complete
2014728b1023: Pull complete
aab288eb9305: Pull complete
f5624bd14a09: Pull complete
d706af45859a: Pull complete
758da3aa4679: Pull complete
af6231a55025: Pull complete
8c758607ff4a: Pull complete
fb477479c0dd: Pull complete
99767f301e98: Pull complete
Digest: sha256:43e0c17257f4ebe982edd0fbf8e8f2081c81550769dc92ed06ed16e1641fc8a9
Status: Downloaded newer image for goharbor/prepare:v2.6.2
Generated configuration file: /config/portal/nginx.conf
Generated configuration file: /config/log/logrotate.conf
Generated configuration file: /config/log/rsyslog_docker.conf
Generated configuration file: /config/nginx/nginx.conf
Generated configuration file: /config/core/env
Generated configuration file: /config/core/app.conf
Generated configuration file: /config/registry/config.yml
Generated configuration file: /config/registryctl/env
Generated configuration file: /config/registryctl/config.yml
Generated configuration file: /config/db/env
Generated configuration file: /config/jobservice/env
Generated configuration file: /config/jobservice/config.yml
Generated and saved secret to file: /data/secret/keys/secretkey
Successfully called func: create_root_cert
Generated configuration file: /compose_location/docker-compose.yml
Clean up the input dir
```
启动

```bash
docker-compose up -d
```
查看容器状态

```bash
$ docker-compose ps
NAME                COMMAND                  SERVICE             STATUS              PORTS
harbor-core         "/harbor/entrypoint.…"   core                running (healthy)
harbor-db           "/docker-entrypoint.…"   postgresql          running (healthy)
harbor-jobservice   "/harbor/entrypoint.…"   jobservice          running (healthy)
harbor-log          "/bin/sh -c /usr/loc…"   log                 running (healthy)   127.0.0.1:1514->10514/tcp
harbor-portal       "nginx -g 'daemon of…"   portal              running (healthy)
nginx               "nginx -g 'daemon of…"   proxy               running (healthy)   0.0.0.0:80->8080/tcp, :::80->8080/tcp, 0.0.0.0:443->8443/tcp, :::443->8443/tcp
redis               "redis-server /etc/r…"   redis               running (healthy)
registry            "/home/harbor/entryp…"   registry            running (healthy)
registryctl         "/home/harbor/start.…"   registryctl         running (healthy)
```

## 7. 测试
命令行登陆

```bash
$  docker login harbor.fumai.com
Username: admin
Password: Harbor12345
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```
界面登陆
- `https://harbor.fumai.com`
- admin/Harbor12345
![](https://img-blog.csdnimg.cn/1832b220aa754cd18c504acc7686a560.png)
![](https://img-blog.csdnimg.cn/958692a1506f465bbf229bfd742824d7.png)

终于部署结束了，如果你想参考更多关于 harbor 内容，请参考：
- [harbor 初级部署入门指南](https://ghostwritten.blog.csdn.net/article/details/121381151)
- [官方 Harbor](https://goharbor.io/)
- [亨利笔记](https://cloud.tencent.com/developer/column/76096/tag-10649)
