+++
title="使用Github Actions + Docker 部署Spring Boot应用"
date="2021-12-27 21:49:16"
tags=["Spring Boot","Github Actions","Docker"]
+++

当前，如果我们手动部署Spring Boot应用，一般都是在本地打成jar包，然后在通过ftp上传到服务器，再重启应用。这样部署实在太过麻烦，如果能把代码直接提交到代码库，自动跑测试，测试通过去部署应用，也就是持续集成，这样就能省太多的时间去创造更好的产品。

<!-- more --> 

当前的持续集成服务主要有：最早支持Github项目的Travis CI，腾讯的Coding和大名鼎鼎的Jenkins。

[Github Actions](https://docs.github.com/cn/actions)是Github提供的持续集成和持续部署服务。

## 1. 工作流程workflow

### 1.1 创建workflow文件

Github Actions顾名思义，肯定是先选择你的Github项目，并且找到Actions功能，如图：

![](https://image.ldbmcs.com/2021-09-24-jE9hyN.png)

在这个页面，我们可以看到官方建议的工作流，还有部署到不同平台和不同语言的非常多的模板供我们选择，这里我们先看官方默认的配置，其他的再熟悉了流程之后可以慢慢研究。

![2021-09-24-1G1Bks](https://image.ldbmcs.com/2021-09-24-1G1Bks.png)

当我们点击了创建工作流后，会在当前仓库`.github/workflows`目录下创建一个yml格式的文件，这个就是我们工作流的配置文件，在这里我们可以定义触发规则，编译阶段，部署阶段等每一步需要做的事情。

![2021-09-24-Shldap](https://image.ldbmcs.com/2021-09-24-Shldap.png)

在这个配置文件中的基本字段：

1. `name`： workflow的名称

2. `on`：触发规则。比如push，pr等特定事件或者定时执行或发生外部的事件时执行，比如创建分支等，更多可以参考[触发工作流程的事件](https://docs.github.com/cn/actions/reference/events-that-trigger-workflows)。

3. `jobs.*.runs-on`:指定job运行的虚拟机环境，比如ubuntu-latest。

4. `jobs.*.steps`:指定每个job的运行步骤，比如指定jdk版本，编译打包等阶段。

5. `jobs.*.steps.run`:该步骤运行的命令或者 action。

   每个 step 可以依次执行一个或多个命令（action），比如 `mvn package`和ssh-deploy。

在[Github Marketplace](https://github.com/marketplace?category=&query=&type=actions&verification=)中提供了非常非常多的Actions，比如ssh，ftp等，可以非常方便的直接拿来使用。

注意，一个仓库可以有多个workflow文件，命名随意，GitHub 只要发现`.github/workflows`目录里面有`.yml`文件，就会自动运行该文件。

### 1.2 环境变量

在Github项目里找到Settings中的Secrets，并点击创建密钥，如图所示：

![2021-09-24-jOfqf1](https://image.ldbmcs.com/2021-09-24-jOfqf1.png)

GitHub 设置适用于工作流程运行中每个步骤的默认环境变量，环境变量区分大小写，在操作或步骤中运行的命令可以创建、读取和修改环境变量。

### 1.3 创建自定义Runner

在上文的配置文件中提到有`jobs.*.runs-on`字段，是指官方提供的虚拟机环境，也就是我们的job是在官方提供的服务器上运行的，那么能不能添加我们的服务器呢，答案是肯定的。

我们可以将服务器添加到单个仓库中。如果要将自托管的运行器添加到用户仓库，您必须是仓库所有者。对于组织仓库，您必须是组织所有者或拥有该仓库管理员的权限。

在Github项目的主页面上，点击Settings中的Actions。

![2021-09-24-k2MRWP](https://image.ldbmcs.com/2021-09-24-k2MRWP.png)

在右上角点击添加自己托管的runner。

![2021-09-24-z5K1S0](https://image.ldbmcs.com/2021-09-24-z5K1S0.png)

我们可以看到根据不同的操作系统都提供了对应的下载，配置和使用方法，根据步骤操作完就可以在列表上看到我们自定义的runner。

## 2. 使用Github Actions + Docker部署Spring Boot应用

### 2.1 创建workflow文件

```yaml
name: Deploy with docker

on:
  push:
    # 分支
    branches: [ master ]
  pull_request:
    branches: [ master ]

jobs:
  compile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up JDK 11
        uses: actions/setup-java@v2
        with:
          java-version: '11'
          distribution: 'adopt'
      # maven缓存，不加的话每次都会去重新拉取，会影响速度   
      - name: Dependies Cache
        uses: actions/cache@v2
        with:
          path: ~/.m2/repository
          key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
          restore-keys: |
            ${{ runner.os }}-maven-
      # 编译打包      
      - name: Build with Maven
        run: mvn package -Dmaven.test.skip=true
      # 登录Docker Hub  
      - name: Login to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_ACCESS_TOKEN }}
      - name: Set up Docker Buildx
        id: buildx
        uses: docker/setup-buildx-action@v1
      # build 镜像并push到中央仓库中  
      - name: Build and push
        id: docker_build
        uses: docker/build-push-action@v2
        with:
          context: ./
          file: ./Dockerfile
          push: true
          tags: ${{ secrets.DOCKER_HUB_USERNAME }}/imageName:latest
      # push后，用ssh连接服务器执行脚本    
      - name: SSH
        uses: fifsky/ssh-action@master
        with:
          command: |
            sh start.sh
          host: ${{ secrets.HOST }}
          user: ${{ secrets.USER }}
          key: ${{ secrets.PRIVATE_KEY}}
```

### 2.2 配置环境变量

![2021-09-24-7xO49X](https://image.ldbmcs.com/2021-09-24-7xO49X.png)

#### 2.2.1 Docker Hub 项目配置

如果在Github Actions中使用Docker，可以参考[官方文档](https://docs.docker.com/ci-cd/github-actions/)。这里介绍了如何创建Docker项目，创建流水线，优化流水线，推送镜像版本等内容。

在示例项目中，主要使用到下面2个配置项：

1. DOCKER_HUB_USERNAME：账号的用户名

2. DOCKER_HUB_ACCESS_TOKEN：授权的Token，在[用户设置](https://hub.docker.com/settings/security)中创建Token。

   ![2021-09-24-droVZL](https://image.ldbmcs.com/2021-09-24-droVZL.png)

这里除了使用Docker的方式外，也可以使用ftp的Actions上传jar包到服务器的指定目录，然后直接通过`jar -jar app.jar`运行。

#### 2.2.2 配置ssh

ssh相关的配置项，主要是HOST，USER，私钥PRIVATE_KEY，Host和用户不必多说，看下私钥是如何生成的：

```bash
[root@host ~]$ ssh-keygen  <== 建立密钥对
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): <== 按 Enter
Created directory '/root/.ssh'.
Enter passphrase (empty for no passphrase): <== 输入密钥锁码，或直接按 Enter 留空
Enter same passphrase again: <== 再输入一遍密钥锁码
Your identification has been saved in /root/.ssh/id_rsa. <== 私钥
Your public key has been saved in /root/.ssh/id_rsa.pub. <== 公钥
The key fingerprint is:
0f:d3:e7:1a:1c:bd:5c:03:f1:19:f1:22:df:9b:cc:08 root@host
```

创建好公钥和私钥之后，还需要把公钥放在服务器的`authorized_keys`中，这样才能正确的连接上。

```bash
[root@host ~]$ cd .ssh
[root@host .ssh]$ cat id_rsa.pub >> authorized_keys
```

> 为什么需要ssh？
>
> 我们连接服务器一般有2种方式，一种是通过密码登录，但是密码会被破解，非常不安全，那么就可以用ssh登录。
>
> ssh一般有一对公钥和私钥，连接的时候服务器的步骤：
>
> 1. 客户端通过公钥向服务器发起请求。
> 2. 服务器会验证客户端发送的公钥是否在本地的公钥列表中，如果不在就拒绝连接，如果在列表中，就会通过公钥加密随机字符串，然后发送给客户端。
> 3. 客户端通过私钥解密之后，发送给服务器，服务器验证解密后的字符串是否匹配，如果匹配则连接成功。

### 2.3 create Dockerfile

既然使用Docker的方式，那么首先就需要在项目根目录下创建Dockerfile文件，然后通过Dockerfile创建镜像。

```dockerfile
# 该镜像需要依赖的基础镜像
FROM fabric8/java-alpine-openjdk11-jre
# 调整时区
RUN rm -f /etc/localtime \
&& ln -sv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
&& echo "Asia/Shanghai" > /etc/timezone
# 将当前目录下的jar包复制到docker容器的/目录下
ADD target/app.jar /app/app.jar
# 指定docker容器启动时运行jar包
ENTRYPOINT ["java", "-jar","app/app.jar"]
```

这里基础镜像选择了alpine版本，因为它的体积非常小，几乎都可以忽略不计，另外还有Distroless或Busybox可以选择。

除了这种已经集成了jdk的基础镜像，也可以在纯净的alpine镜像上去安装jdk，这样的体积也会非常小，在推送镜像和拉取镜像上速度都会非常快。

> 更多参考：云原生实验室的[Alpine vs Distroless vs Busybox](https://fuckcloudnative.io/posts/alpine-vs-distroless-vs-busybox/)

这样，在我们提交代码到github的时候，流水线就会根据Dockerfile文件创建镜像，然后推送镜像，在流水线配置中如下：

```yaml
# build 镜像并push到中央仓库中  
- name: Build and push
	id: docker_build
  uses: docker/build-push-action@v2
  with:
  context: ./
  file: ./Dockerfile
  push: true
  tags: ${{ secrets.DOCKER_HUB_USERNAME }}/imageName:latest
```

### 2.4 pull image && restart container

通过上面的配置，我们已经可以成功的把镜像推送到Docker Hub的中央仓库中，那么下一步就是需要我们去服务器中拉取最新的镜像，然后关闭之前的容器，基于最新的镜像启动新的容器。

```bash
# push后，用ssh连接服务器执行脚本    
- name: SSH
  uses: fifsky/ssh-action@master
  with:
  command: |
  	sh start.sh
  host: ${{ secrets.HOST }}
  user: ${{ secrets.USER }}
  key: ${{ secrets.PRIVATE_KEY}}
```

所以，我们通过ssh连接服务器执行重启的脚本。

```bash
#!/bin/bash
docker pull username/app:latest
docker rm -f containerName||true&&docker run  --name=appName -d -p 8080:8080 username/app:latest
docker image prune -af
```

到此为止，我们就可以实现持续集成，不用手动的去上传jar包，然后执行各种命名。

## 3. 参考

- [GitHub Actions 入门教程](http://www.ruanyifeng.com/blog/2019/09/getting-started-with-github-actions.html)
- [官网](https://docs.github.com/cn/actions)