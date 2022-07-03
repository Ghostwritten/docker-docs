# docker + makefile =CI Pipeline

##  1. 简单的docker&makefile

### 1.1  编辑 dockerfile
```bash
$ cat Dockerfile
FROM busybox
CMD ["date"]
```


### 1.2 编辑 Makefile

```bash
build:
    docker build -t benhall/docker-make-example .

run:
    docker run benhall/docker-make-example
    
default: build test
```
### 1.3 执行 make

```bash
#通过dockerfile构建容器
$ make
docker build -t benhall/docker-make-example .
Sending build context to Docker daemon  116.7kB
Step 1/2 : FROM busybox
latest: Pulling from library/busybox
24fb2886d6f6: Pull complete 
Digest: sha256:f7ca5a32c10d51aeda3b4d01c61c6061f497893d7f6628b92f822f7117182a57
Status: Downloaded newer image for busybox:latest
 ---> 16ea53ea7c65
Step 2/2 : CMD ["date"]
 ---> Running in 26d6f36ad3b4
Removing intermediate container 26d6f36ad3b4
 ---> 339b5a708dce
Successfully built 339b5a708dce
Successfully tagged benhall/docker-make-example:latest

#查看构建效果
$ docker images |grep benha
benhall/docker-make-example   latest      339b5a708dce   2 minutes ago    1.24MB

#运行容器
$ make run
docker run benhall/docker-make-example
Mon Sep 27 08:36:15 UTC 2021
$ docker ps |grep ben
$ docker ps -a |grep ben
c8cf9f9b7090   benhall/docker-make-example   "date"                   14 seconds ago   Exited (0) 13 seconds ago             amazing_buck

#一次性构建部署
$ make build run
docker build -t benhall/docker-make-example .
Sending build context to Docker daemon  116.7kB
Step 1/2 : FROM busybox
 ---> 16ea53ea7c65
Step 2/2 : CMD ["date"]
 ---> Using cache
 ---> 339b5a708dce
Successfully built 339b5a708dce
Successfully tagged benhall/docker-make-example:latest
docker run benhall/docker-make-example
Mon Sep 27 08:38:11 UTC 2021

```


-----

我希望我所有的项目都能像这样工作：

```bash
git pull && make test && make build && make deploy
```

## 2. docker & Makefile 实战
项目：[https://github.com/Ghostwritten/dockerbuild](https://github.com/Ghostwritten/dockerbuild)

### 2.1 编写 Makefile
```bash
版权作者说明
# --------------------------------------------------------------------
# Copyright (c) 2019 LINKIT, The Netherlands. All Rights Reserved.
# Author(s): Anthony Potappel
# 
# This software may be modified and distributed under the terms of the
# MIT license. See the LICENSE file for details.
# --------------------------------------------------------------------

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
#条件赋值 ( ?= ) 如果变量未定义，则使用符号中的值定义变量。如果该变量已经赋值，则该赋值语句无效。
PWD ?= pwd_unknown

# PROJECT_NAME defaults to name of the current directory.
# should not to be changed if you follow GitOps operating procedures.
PROJECT_NAME = $(notdir $(PWD))

# Note. If you change this, you also need to update docker-compose.yml.
# only useful in a setting with multiple services/ makefiles.
#简单赋值 ( := ) 编程语言中常规理解的赋值方式，只对当前语句的变量有效。
SERVICE_TARGET := main

# if vars not set specifially: try default to environment, else fixed value.
# strip to ensure spaces are removed in future editorial mistakes.
# tested to work consistently on popular Linux flavors and Mac.
ifeq ($(user),)
# USER retrieved from env, UID from shell.
HOST_USER ?= $(strip $(if $(USER),$(USER),nodummy))
HOST_UID ?= $(strip $(if $(shell id -u),$(shell id -u),4000))
else
# allow override by adding user= and/ or uid=  (lowercase!).
# uid= defaults to 0 if user= set (i.e. root).
HOST_USER = $(user)
HOST_UID = $(strip $(if $(uid),$(uid),0))
endif

THIS_FILE := $(lastword $(MAKEFILE_LIST))
CMD_ARGUMENTS ?= $(cmd)

# export such that its passed to shell functions for Docker to pick up.
export PROJECT_NAME
export HOST_USER
export HOST_UID

# all our targets are phony (no files to check).
.PHONY: shell help build rebuild service login test clean prune

# suppress makes own output
#.SILENT:

# shell is the first target. So instead of: make shell cmd="whoami", we can type: make cmd="whoami".
# more examples: make shell cmd="whoami && env", make shell cmd="echo hello container space".
# leave the double quotes to prevent commands overflowing in makefile (things like && would break)
# special chars: '',"",|,&&,||,*,^,[], should all work. Except "$" and "`", if someone knows how, please let me know!).
# escaping (\) does work on most chars, except double quotes (if someone knows how, please let me know)
# i.e. works on most cases. For everything else perhaps more useful to upload a script and execute that.
shell:
ifeq ($(CMD_ARGUMENTS),)
	# no command is given, default to shell
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) run --rm $(SERVICE_TARGET) sh
else
	# run the command
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) run --rm $(SERVICE_TARGET) sh -c "$(CMD_ARGUMENTS)"
endif

# Regular Makefile part for buildpypi itself
help:
	@echo ''
	@echo 'Usage: make [TARGET] [EXTRA_ARGUMENTS]'
	@echo 'Targets:'
	@echo '  build    	build docker --image-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  rebuild  	rebuild docker --image-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  test     	test docker --container-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  service   	run as service --container-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  login   	run as service and login --container-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  clean    	remove docker --image-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  prune    	shortcut for docker system prune -af. Cleanup inactive containers and cache.'
	@echo '  shell      run docker --container-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo ''
	@echo 'Extra arguments:'
	@echo 'cmd=:	make cmd="whoami"'
	@echo '# user= and uid= allows to override current user. Might require additional privileges.'
	@echo 'user=:	make shell user=root (no need to set uid=0)'
	@echo 'uid=:	make shell user=dummy uid=4000 (defaults to 0 if user= set)'

rebuild:
	# force a rebuild by passing --no-cache
	docker-compose build --no-cache $(SERVICE_TARGET)

service:
	# run as a (background) service
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) up -d $(SERVICE_TARGET)

login: service
	# run as a service and attach to it
	docker exec -it $(PROJECT_NAME)_$(HOST_UID) sh

build:
	# only build the container. Note, docker does this also if you apply other targets.
	docker-compose build $(SERVICE_TARGET)

clean:
	# remove created images
	@docker-compose -p $(PROJECT_NAME)_$(HOST_UID) down --remove-orphans --rmi all 2>/dev/null \
	&& echo 'Image(s) for "$(PROJECT_NAME):$(HOST_USER)" removed.' \
	|| echo 'Image(s) for "$(PROJECT_NAME):$(HOST_USER)" already removed.'

prune:
	# clean all that is not actively used
	docker system prune -af

test:
	# here it is useful to add your own customised tests
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) run --rm $(SERVICE_TARGET) sh -c '\
		echo "I am `whoami`. My uid is `id -u`." && echo "Docker runs!"' \
	&& echo success
```



###  2.2 处理 UID

未配置 UserID (UID) 时，Docker 会将容器默认为用户 root。当您开始处理生产系统时，需要练习正确配置用户。你可以在[Dockers 的最佳实践](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)列表上阅读它，来自 [K8s 的这篇文章](https://kubernetes.io/blog/2018/07/18/11-ways-not-to-get-hacked/#8-run-containers-as-a-non-root-user)也很好地涵盖了它。

当您在 Mac 上本地运行测试时，root 会映射到您自己的用户，因此一切正常。生产平台——应该——被配置为用户隔离，但这并不总是默认的。例如，如果您在 Linux 系统上运行测试（没有重新映射），您可能会偶然发现 Docker 生成的文件[归 root 所有的问题](https://medium.com/redbubble/running-a-docker-container-as-a-non-root-user-7d2e00f8ee15)。

当您在一个系统上有多个用户时，您也会遇到问题。即使您不共享一个系统，运行并行测试也同样需要分离。而且，如果没有正确的 UID 设置，您甚至如何传递凭据（例如，通过将卷链接为 ~/.ssh 和 ~/.aws）？后者是处理基础设施部署时的常见模式。
如果你开始成为一个更密集的 `docker-consumer`，你的团队会成长并且事情会变得复杂，最终你会想要或需要在你的所有项目中嵌入 UID 分离。

幸运的是，尽早配置 UID 是（相对）容易的。虽然我花了一些练习才能获得良好的设置，但我现在有一个模板（假设使用 Makefile）自动完成所有操作，成本几乎为零。
以下是要使用的[docker-compose文件](https://gist.githubusercontent.com/anthonypotappel/b26b1981bac3e9afed793464176d1cfa/raw/3690c9afb44741a58733f477584cec4cac09c39e/docker-compose.yml)的副本：

```bash
version: '3.4'
services:
  main:
    # Makefile fills PROJECT_NAME to current directory name.
    # add UID to allow multiple users run this in parallel
    container_name: ${PROJECT_NAME}_${HOST_UID:-4000}
    hostname: ${PROJECT_NAME}
    # These variables are passed into the container.
    environment:
      - UID=${HOST_UID:-4000}
    # Run with user priviliges by default.
    user: ${HOST_USER:-nodummy}
    image: ${PROJECT_NAME}:${HOST_USER:-nodummy}
    build:
      context: .
      # Build for current user.
      target: user
      dockerfile: Dockerfile
      # These variables are passed to Dockerfile.
      args:
        - HOST_UID=${HOST_UID:-4000}
        - HOST_USER=${HOST_USER:-nodummy}
    # Run container as a service. Replace with something useful.
    command: ["tail", "-f", "/dev/null"]
    # Copy current (git-) project into container.
    volumes:
      - ${PWD:-.}:/home/${HOST_USER}/${PROJECT_NAME}
```


默认变量的一种写法

```bash
${HOST_USER:-nodummy} 
${HOST_UID:-4000}
```

这会从您的运行时复制变量，如果不存在，则分别默认为“`nodummy`”和“`4000`”。如果您不喜欢默认值，请执行以下操作：

```bash
${HOST_USER:?You forgot to set HOST_USER in .env!}
${HOST_UID:?You forgot to set HOST_UID in .env!}
```
注意“HOST_”前缀。我避免直接​​使用 USER 和 UID。不保证这些变量在运行时可用。USER 通常在 shell 中可用，但 UID 主要是 Docker 不会获取的环境变量。拥有单独的命名方案可以防止意外，并允许灵活配置自动化管道。
Dockerfile内容如下：

```bash
FROM alpine as base

RUN apk update \
    && apk add --no-cache \
        bash

FROM scratch as user
COPY --from=base . .

ARG HOST_UID=${HOST_UID:-4000}
ARG HOST_USER=${HOST_USER:-nodummy}

RUN [ "${HOST_USER}" == "root" ] || \
    (adduser -h /home/${HOST_USER} -D -u ${HOST_UID} ${HOST_USER} \
    && chown -R "${HOST_UID}:${HOST_UID}" /home/${HOST_USER})

USER ${HOST_USER}
WORKDIR /home/${HOST_USER}
```
在这里，我们构建了一个小型（只有 10MB，微服务 FTW！）Alpine 容器，添加了 bash 以供娱乐和练习。我们应用所谓的[分阶段构建](https://docs.docker.com/develop/develop-images/multistage-build/)的概念来保持基础镜像（可重用构建组件）与用户镜像（为特定运行准备的镜像）分离。

使用 Makefile 时，所有变量都会自动设置。这个 Dockerfile 在没有 Makefile 的情况下也能正常工作，但用户仍然可以在自己的运行时或单独的[env-file](https://docs.docker.com/compose/env-file/) 中配置变量.

如果您处于开发模式，您可能会遇到某些障碍，需要您以 root 用户身份进行故障排除。

```bash
make shell user=root
```
### 2.3 执行 make
```bash
# download our files
git clone https://github.com/LINKIT-Group/dockerbuild
# enter directory
cd dockerbuild
# build, test and run a command
make build test shell cmd="whoami"
# my favorite for container exploration
make shell
# shell-target is the default (first item), so this also works: 
make cmd="whoami"
make cmd="ls /"
# force a rebuild, test and cleanup
make rebuild test clean
```
### 2.4 开发小技巧

 - 运行容器最好加上--rm
 - 我们还可以加其他目标任务，比如将镜像推送到仓库。

参考：

 - [如何学习Makefile](https://ghostwritten.blog.csdn.net/article/details/120429427)
 - [docker & Makefile实战](https://github.com/Ghostwritten/dockerbuild)
