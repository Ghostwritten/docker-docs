# Podman 部署私有镜像仓库
tags: registry
![](https://img-blog.csdnimg.cn/81136404287e48ae892c8282a0a82400.png)

[Podman](https://podman.io/)是一个无守护进程的开源 Linux 原生工具，旨在使用开放容器倡议 ( OCI )容器和容器映像轻松查找、运行、构建、共享和部署应用程序。主要是由`RedHat`推动改进。

关于了解 Podman 更多内容：
- [Podman 下一代 Linux 容器工具](https://blog.csdn.net/xixihahalelehehe/article/details/125618884)
- [Podman 入门指南](https://blog.csdn.net/xixihahalelehehe/article/details/121611523)

## 1. 安装 Podman 和 httpd-tools

```bash
yum install -y podman httpd-tools
```

## 2. 配置仓库存储位置
存储目录为 `/opt/registry/`

```bash
mkdir -p /opt/registry/{auth,certs,data}
```
- `Auth`子目录存储htpasswd用于身份验证的文件。
- `Certs`子目录存储仓库使用的证书验证。
- `Data`目录存储存储在仓库中的实际镜像。

如果你想单独挂载一块盘来存储数据可以利用`parted`命令

```bash
sudo parted -s -a optimal -- /dev/sdb mklabel gpt
sudo parted -s -a optimal -- /dev/sdb  mkpart primary 0% 100%
sudo parted -s -- /dev/sdb  align-check optimal 1
sudo pvcreate /dev/sdb1
sudo vgcreate vg0 /dev/sdb1
sudo lvcreate -n registry -l +100%FREE vg0
sudo mkfs.xfs /dev/vg0/registry
echo "/dev/vg0/registry /opt/registry/data xfs defaults 0 0" | sudo tee -a /etc/fstab
```
挂载验证
```bash
$ sudo mount -a
$ df -hT  /opt/registry/data
Filesystem             Type  Size  Used Avail Use% Mounted on
/dev/mapper/vg0-registry xfs   200G  1.5G  199G   1% /opt/registry/data

```

## 3. 生成访问仓库的凭据
### 3.1 htpasswd 用户名和密码
身份验证由一个简单的htpasswd文件和一个 SSL 密钥对提供

`htpasswd`将在该`/opt/registry/auth/`目录中创建一个名为 `Bcrypt Htpasswd` 的文件
```bash
htpasswd -bBc /opt/registry/auth/htpasswd registryuser  registryuserpassword
```
- b通过命令提供密码。
- B使用 Bcrypt 加密存储密码。
- c创建文件。
- 用户名为 registryuser。
- 密码是 registryuserpassword。

查看文件
```bash
$ tac /opt/registry/auth/htpasswd
registryuser:$2y$05$XciI1wfzkUETe7XazJfc/uftBnMQfYOV1jOnbV/QOXw/SXhmLsApK
```
### 3.2 TLS 密钥对
通过使用由可信机构（内部或外部）签名的密钥和证书或简单的自签名证书，仓库通过 TLS 得到保护。要使用自签名证书：

```bash
cat << EOF > ssl.conf
[ req ]
prompt             = no
distinguished_name = req_subj
x509_extensions    = x509_ext

[ req_subj ]
CN = Localhost

[ x509_ext ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
basicConstraints       = CA:true
subjectAltName         = @alternate_names

[ alternate_names ]
DNS.1 = localhost
IP.1  = 192.168.10.80
EOF

```

```bash
openssl req -config ssl.conf -new -x509 -nodes -sha256 -days 365 -newkey rsa:4096 -keyout /opt/registry/certs/domain.key -out /opt/registry/certs/domain.crt

openssl x509 -inform PEM -in /opt/registry/certs/domain.crt -out /opt/registry/certs/domain.cert
```
- `req`  OpenSSL 生成和处理证书请求。
- `-newkey`  OpenSSL 创建一个新的私钥和匹配的证书请求。
- `rsa:4096`  OpenSSL 生成一个 4096 位的 RSA 密钥。
- `-nodes`  OpenSSL 私钥没有密码要求。私钥不会被加密。
- `-sha256`  OpenSSL 使用 sha256 来签署请求。
- `-keyout`  OpenSSL 存储新密钥的名称和位置。
- `-x509`  OpenSSL 生成一个自签名证书。
- `-days`  OpenSSL 密钥对有效的天数。
- `-out`  OpenSSL 在哪里存储证书。

输入证书的相应选项。`CN=`值是您的主机的主机名。主机的主机名应该可由 DNS 或`/etc/hosts`文件解析。

```bash
$ ll /opt/registry/certs/
total 12
-rw-r--r-- 1 root root 1842 Nov 21 20:01 domain.cert
-rw-r--r-- 1 root root 1842 Nov 21 20:01 domain.crt
-rw------- 1 root root 3272 Nov 21 20:01 domain.key
```
将服务器证书、密钥和 CA 文件复制到 `podman`证书文件夹中。您必须首先创建适当的文件夹

```bash
mkdir -p /etc/containers/certs.d/192.168.10.80\:5000/
cp -r /opt/registry/certs/* /etc/containers/certs.d/192.168.10.80\:5000/
```


> 注意：如果仓库未使用 TLS 保护，则`/etc/containers/registries.conf`可能必须为仓库配置文件中的不安全设置。

该证书还必须得到您的主机和客户端的信任：

```bash
cp /opt/registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust
trust list | grep -i "<hostname>"
```
## 4. 启动容器

```bash
$ podman images
REPOSITORY                  TAG         IMAGE ID      CREATED     SIZE
docker.io/library/registry  latest      81c944c2288b  9 days ago  24.7 MB
```

```bash
podman run --name myregistry \
-p 5000:5000 \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/auth:/auth:z \
-e "REGISTRY_AUTH=htpasswd" \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
-v /opt/registry/certs:/certs:z \
-e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt" \
-e "REGISTRY_HTTP_TLS_KEY=/certs/domain.key" \
-e REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true \
-e REGISTRY_STORAGE_DELETE_ENABLED=true \
-d \
docker.io/library/registry:latest
```
选项的详细信息是：
- `--name myregistry`将容器命名为`myregistry`。
- `-p 5000:5000`将容器中的端口 5000 公开为主机上的端口 5000。
- `-v /opt/registry/data:/var/lib/registry:z`像 在具有正确 SELinux 上下文的容器中一样安装`/opt/registry/data` 在主机`/var/lib/registry`
- `-v /opt/registry/auth:/auth:z/opt/registry/auth`在主机上安装，就像`/auth` 在具有正确 SELinux 上下文的容器中一样。
- `-v opt/registry/certs:/certs:z`像 在具有正确 SELinux 上下文的容器中一样安装`/opt/registry/certs` 在主机上 。/certs
- `-e "REGISTRY_AUTH=htpasswd"` 使用bcrypt加密htpasswd文件进行身份验证。由容器的 `REGISTRY_AUTH_HTPASSWD_PATH` 环境变量设置的文件位置。
- `-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm"` 指定用于`htpasswd`.
- `-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd`使用容器中的 bcrypt 加密/auth/htpasswd 文件。
- `-e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt"`设置证书文件的路径。
- `-e "REGISTRY_HTTP_TLS_KEY=/certs/domain.key"`设置私钥路径。
- `-e REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true`为 schema1 清单提供向后兼容性。
- `-e REGISTRY_STORAGE_DELETE_ENABLED=true` 可以通过API 删除镜像
- `-d docker.io/library/registry:latest`是一个允许存储和分发镜像的仓库应用程序。

> 注意：如果防火墙在主机上运行，​​则需要允许暴露的端口 (5000)。

```bash
firewall-cmd --add-port=5000/tcp --zone=internal --permanent
firewall-cmd --add-port=5000/tcp --zone=public --permanent
firewall-cmd --reload
```
或者直接关闭

```bash
systemctl stop firewalld && systemctl disable firewalld
setenforce 0
```

##  5. 测试
### 5.1 登陆
```bash
docker login -u registryuser -p registryuserpassword 192.168.10.80:5000
Login Succeeded!
```
### 5.2 API访问
```bash
$ curl  -k -u "registryuser:registryuserpassword" https://192.168.10.80:5000/v2/_catalog
{"repositories":[]}
```
- [更多API 访问策略请参考这里](https://ghostwritten.blog.csdn.net/article/details/105926147)

### 5.3 镜像入库

从公共拉取`alpine:latest`镜像
```bash
$ podman pull alpine:latest
Resolved "alpine" as an alias (/etc/containers/registries.conf.d/000-shortnames.conf)
Trying to pull docker.io/library/alpine:latest...
Getting image source signatures
Copying blob ca7dd9ec2225 [--------------------------------------] 0.0b / 0.0b
Copying config bfe296a525 done
Writing manifest to image destination
Storing signatures
bfe296a525011f7eb76075d688c681ca4feaad5afe3b142b36e30f1a171dc99a
```
打标签
```bash
podman tag alpine:latest 192.168.10.80:5000/alpine:latest
```
推送入库

```bash
podman push 192.168.10.80:5000/alpine:latest
```

###  5.4 查询镜像信息
查询是否入库

```bash
$ curl  -k -u "registryuser:registryuserpassword" https://192.168.10.80:5000/v2/_catalog
{"repositories":["alpine"]}
```
查看镜像标签

```bash
$  curl  -k -u "registryuser:registryuserpassword" https://192.168.10.80:5000/v2/alpine/tags/list
{"name":"alpine","tags":["latest"]}
```
查看镜像 `manifests`

```bash
$ curl  -k -u "registryuser:registryuserpassword"https://192.168.10.80:5000/v2/alpine/manifests/latest
{
   "schemaVersion": 1,
   "name": "alpine",
   "tag": "latest",
   "architecture": "amd64",
   "fsLayers": [
      {
         "blobSum": "sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4"
      },
      {
         "blobSum": "sha256:60f8044dac9f779802600470f375c7ca7a8f7ad50e05b0ceb9e3b336fa5e7ad3"
      }
   ],
   "history": [
      {
         "v1Compatibility": "{\"architecture\":\"amd64\",\"config\":{\"Hostname\":\"\",\"Domainname\":\"\",\"User\":\"\",\"AttachStdin\":false,\"AttachStdout\":false,\"AttachStderr\":false,\"Tty\":false,\"OpenStdin\":false,\"StdinOnce\":false,\"Env\":[\"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"],\"Cmd\":[\"/bin/sh\"],\"Image\":\"sha256:18f412e359de0426344f4fe1151796e2d9dc121b01d737e953f043a10464d0b7\",\"Volumes\":null,\"WorkingDir\":\"\",\"Entrypoint\":null,\"OnBuild\":null,\"Labels\":null},\"container\":\"3cd2ce612b9119be9673860022420eee020f0a6d44e9072ca25196f4f0a4613d\",\"container_config\":{\"Hostname\":\"3cd2ce612b91\",\"Domainname\":\"\",\"User\":\"\",\"AttachStdin\":false,\"AttachStdout\":false,\"AttachStderr\":false,\"Tty\":false,\"OpenStdin\":false,\"StdinOnce\":false,\"Env\":[\"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"],\"Cmd\":[\"/bin/sh\",\"-c\",\"#(nop) \",\"CMD [\\\"/bin/sh\\\"]\"],\"Image\":\"sha256:18f412e359de0426344f4fe1151796e2d9dc121b01d737e953f043a10464d0b7\",\"Volumes\":null,\"WorkingDir\":\"\",\"Entrypoint\":null,\"OnBuild\":null,\"Labels\":{}},\"created\":\"2022-11-12T04:19:23.199716539Z\",\"docker_version\":\"20.10.12\",\"id\":\"260323e12fa2abcb1ff61576931037c6f8538afeb5ff82fa256670a20b384b6b\",\"os\":\"linux\",\"parent\":\"faa2cddd53c99ad978614b839a2a20a47f143a4d6ecb86bda576dfb3124c0cad\",\"throwaway\":true}"
      },
      {
         "v1Compatibility": "{\"id\":\"faa2cddd53c99ad978614b839a2a20a47f143a4d6ecb86bda576dfb3124c0cad\",\"created\":\"2022-11-12T04:19:23.05154209Z\",\"container_config\":{\"Cmd\":[\"/bin/sh -c #(nop) ADD file:ceeb6e8632fafc657116cbf3afbd522185a16963230b57881073dad22eb0e1a3 in / \"]}}"
      }
   ],
   "signatures": [
      {
         "header": {
            "jwk": {
               "crv": "P-256",
               "kid": "5BQE:5CXW:TWNN:OFV7:ZPNY:ARAG:ZJ7K:Z5GI:ZVQ3:SZYQ:2M3J:D7YG",
               "kty": "EC",
               "x": "-JvBdARI6NPMx8g6d1zyPzmSkkZ8rKIcxdz2BEonpzU",
               "y": "4OlY36zLCvLHXzMrb4w8W2TZSJdVc5ijM0Y9DieEkWY"
            },
            "alg": "ES256"
         },
         "signature": "ZL0HFyuq9G9cYsBzZZqMlwGK3aQMJHFKeQ2Dh8XByzGKtfoJCJ5kQY0W3yynzb3Mj9WYrzeabZwey-dZIHt_7Q",
         "protected": "eyJmb3JtYXRMZW5ndGgiOjIwODgsImZvcm1hdFRhaWwiOiJDbjAiLCJ0aW1lIjoiMjAyMi0xMS0yMVQxMjoyNjowM1oifQ"
      }
   ]
}
```

参考：
- [How to implement a simple personal/private Linux container image registry for internal use](https://www.redhat.com/sysadmin/simple-container-registry)
- [docker registry仓库私搭并配置证书](https://ghostwritten.blog.csdn.net/article/details/105926147)
