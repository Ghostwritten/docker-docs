#  Docker CI/CD Overiview

##  1. 前言

根据[2020 年 Jetbrains 开发人员调查](https://www.jetbrains.com/lp/devecosystem-2021/)，44% 的开发人员现在正在使用某种形式的 Docker 容器持续集成和部署。

Docker 已成为持续集成和持续部署的早期采用者。通过利用与 GIT 等源代码控制机制的正确集成，[Jenkins](https://www.jenkins.io/) 可以在开发人员每次提交代码时启动构建过程。此过程会生成一个新的 Docker 映像，该映像可在整个环境中立即可用。使用 Docker 镜像，团队可以快速构建、共享和部署他们的应用程序。

目的：根据开发/IT 需求，使用自助服务自动化工具自动配置环境/基础设施。

组织面临的挑战：

环境不可用
缺乏环境配置技能
环境配置的前置时间长

## 2. 什么是持续集成？

这是一种开发实践，开发人员每天多次将代码集成到共享存储库中，支持将新功能与现有代码集成。此集成代码还确保运行时环境中没有错误，使我们能够检查它对其他更改的反应。

用于持续集成的最流行工具是“Jenkins”，而 GIT 用于源代码控制存储库。Jenkins 可以从 GIT 存储库中提取最新的代码修订版并生成可以部署到服务器的构建。

## 3. 什么是持续交付？

持续交付是在任何给定时间将软件部署到任何环境的能力，包括二进制文件、配置和环境更改（如果有）。

## 4. 什么是持续部署？

持续部署是开发团队在短周期内发布软件的一种方法。开发人员所做的任何更改都会一直部署到生产环境。

## 5. 什么是 Docker？

Docker 是一个容器化平台，它将应用程序及其所有依赖项以 Container 的形式打包在一起，以确保应用程序在任何环境中都能无缝运行。

## 6. Docker 如何在 CI/CD 中提供帮助？

Docker 帮助开发人员在任何环境中构建他们的代码并测试他们的代码，以便在应用程序开发生命周期的早期捕获错误。Docker 有助于简化流程，节省构建时间，并允许开发人员并行运行测试。

Docker 可以与 GitHub 等源代码控制管理工具和 Jenkins 等集成工具集成。开发人员将代码提交到 GitHub，使用 Jenkins 创建映像测试自动触发构建的代码。可以将此镜像添加到 Docker 注册表中，以处理不同环境类型之间的不一致。

##  7. Docker Pipeline 阶段

 - `Build`：此阶段的 Docker 容器将具有构建所需的所有工具，例如 SDK，它还可以缓存我们应用所需的依赖项。
 - `Test`： Docker 在集成和功能测试方面非常有帮助，我们可以在开始集成或功能测试之前创建应用程序所需的数据库、身份等服务的容器。这种方法还为我们提供了并行化测试的能力，因为在尝试创建应用程序的两个实例进行测试时不会出现端口冲突等问题。它非常具有成本效益并减少了环境管理所需的工作量，因为不需要保持相关服务始终运行。最后，我们还可以在数据库中加载测试数据，以便我们的集成/功能测试运行，这节省了大量时间，因为我们之前在测试设置中加载数据。
 - `Deliver`：在这个阶段，我们可以设置 docker 镜像以拥有打包和交付所需的工具。例如，我们可以在 docker 容器中使用 docker 来将我们的工件打包为 docker 镜像。


todo:

 - [How to build a CI/CD pipeline with Docker](https://circleci.com/blog/build-cicd-piplines-using-docker/)
 - [Run your CI/CD jobs in Docker containers](https://docs.gitlab.com/ee/ci/docker/using_docker_images.html)
 - [Docker for your CI CD Pipeline](https://medium.com/kodeyoga/docker-for-your-ci-cd-pipeline-cfb4556792e5)
