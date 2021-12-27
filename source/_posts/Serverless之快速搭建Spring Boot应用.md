---
title: Serverless之快速搭建Spring Boot应用
date: 2021/12/27 22:18:31
toc: true
categories:
- Spring Boot
tags:
- Serverless
- DevOps
---
Serverless，也就是无服务器，什么是无服务器，和服务器有什么关系，为什么需要Serverless，怎么使用Serverless，这些问题将是本篇文章得到答案。在本篇文章中会简单介绍Serverless的基础概念和利用Serverless快速搭建Spring Boot应用。

## 1. 什么是无服务器 (Serverless) 

### 1.1 基础概念

现在正常的开发发布流程是首先编码，然后把代码打包成镜像，服务器拉取最新镜像重启更新，我们不仅需要编码，还需要考虑服务器的部署，应用日志，扩容，负载均衡等等，那么有没有什么新的架构能帮助我们省去运维，让开发只关心编码，测试，这就是Serverless。

<!-- more --> 

**Serverless（无服务器架构）指的是服务端逻辑由开发者实现，运行在无状态的计算容器中，由事件驱动， 服务器完全被第三方管理，而业务层面的状态则记录在数据库或存储资源中。**

用一句话说，就是让开发者只需要关注业务实现，不必要关心与业务无关的东西，比如考虑如何部署到云端，不需要关心扩容，不需要关心运维，这一切东西全部交给提供Serverless的云服务提供商。

与IaaS的区别是，在IaaS中，用户需要提前购买好服务器，并且在请求高的时候提高资源，在请求低的时候减少资源，在没有请求的时候，容器依然就绪等待请求。

Serverless不需要提前购买服务资源，只在需求时启动，在事件触发时分配资源，当没有事件触发时就会关闭容器，等待下一次触发。那么开发者需要做的就是用代码实现业务，然后把代码打包上传到云服务提供商就结束了，剩下的运维全部交给提供商。

### 1.2 优缺点

首先，我们看看Serverless有哪些缺点：

1. 冷启动。Serverless 也是在容器中运行应用的。当某个请求传入时，会首先检查是否有正在运行的容器，如果没有正在运行的容器，就会启动一个新的容器去运行应用，这个就是冷启动。既然需要启动新的容器，那么响应的时间就不会那么快。
2. 切换成本高。由于使用的是云服务商提供的服务，当我们需要更改服务商的时候，成本就会非常高，因为每一家的规范都不相同。
3. 不灵活。与方便对应的就是不灵活，因为我们所以的运维都交给了提供商，那么我们就不能控制服务器或者优化服务器达到我们的目的。

再来看看优点：

1. 提高开发效率，这个在前面已经说过多次，就不再赘述。
2. 降低运维成本，不需要管理服务器，只需要为运行时间付费即可。

### 1.3 适用场景

既然有这些优缺点，那么哪些场景适合使用Serverless呢？

1. 短暂，无状态的应用，可以接受冷启动的场景。
2. 不频繁但是可能请求激增的场景。

比如实时文件处理，数据ETL，无服务器移动后端，音视频分析等场景。

### 1.4 Serverless产品

1. AWS Lanmbda：支持文件处理，流处理，Web应用程序，IoT后端，移动后端。
2. Cloud Functions：支持与第三方服务及API集成，无服务器移动后端，服务器IoT后端，文件处理，视频和图片分析，情感分析。
3. 阿里云函数计算：具有丰富的触发器类型，支持多种编程语言，有非常便捷的开发工具进行调试部署，还有丰富的计算类型
4. 腾讯云 Serverless：拥有简化配置，方便运维，一站式开发等特点，支持基于云函数的命令行开发工具，传统应用框架的快速迁移等场景。

下面我们将使用阿里云的函数计算实际部署Spring Boot应用。

## 2. 快速搭建Spring Boot应用

阿里云的函数计算是事件驱动的全托管计算服务。使用函数计算，您无需采购与管理服务器等基础设施，只需编写并上传代码。函数计算为您准备好计算资源，弹性地、可靠地运行任务，并提供日志查询、性能监控和报警等功能。

### 2.1 开发流程

函数计算工作流程如下图所示：

![](https://image.ldbmcs.com/2021-10-28-Nql4DJ.jpg)

1. 开发者使用编程语言编码代码，目前函数计算支持的编程语言：Java，PHP，Go，Python，Node.js等语言。
2. 开发者上传代码到函数计算，可以通过函数计算控制台，Funcraft，Serverless Devs，API或SDK等方式上传代码。
3. 触发函数执行，因为Serverless是事件驱动，所以需要通过HTTP请求，OSS、API网关等方式触发。

### 2.2 快速部署

在这里我们通过Serverless Devs管理函数。

FC组件和ROS组件都是函数计算团队基于Serverless Devs为您提供的组件，FC组件和ROS组件是用于支持阿里云Serverless应用全生命周期的工具。该组件是Funcraft的进阶版本，和Funcraft的行为描述类似，Funcraft是通过资源配置文件template.yml协助您实现开发、构建、部署等操作的，FC组件和ROS组件则是通过资源配置文件即YAML文件，帮助您快速开发、构建、测试和将应用部署到函数计算。

#### 2.2.1 安装Serverless Devs

可以通过包管理器(npm，yarn)和脚本安装安装。这里我们通过npm安装：

```bash
npm install @serverless-devs/s -g
```

执行完成之后，通过命令`s -v`验证是否安装成功：

```bash
~ s -v
@serverless-devs/s: 2.0.92, darwin-x64, node-v12.18.3
```

#### 2.2.2 配置Serverless Devs

在使用前，我们需要先进行配置，在终端中执行`s config add`，根据提示输入`Account ID`、`Access Key Id`、`Secret Access Key`、 `aliasName` 即可。

```bash
~ s config add
? Please select a template: Alibaba Cloud (alibaba)
🧭 Refer to the document for alibaba key:  http://config.devsapp.net/account/alibaba
? AccountID 1831277402*****
? AccessKeyID LTAIkC5X*****
? AccessKeySecret ZMbINFFtAUlWPykcI51U******
? Please create alias for key pair. If not, please enter to skip default

    Alias: default
    AccountID: 1831277402******
    AccessKeyID: LTAIkC5X******
    AccessKeySecret: ZMbINFFtAUlWPykcI51U*******

Configuration successful
```

#### 2.2.3 创建Spring Boot项目

在目标目录下执行命令`s init devsapp/start-springboot -d projectName`初始化项目：

```bash
➜ Project s init devsapp/start-springboot -d serverlessSpringboot

🚀 Serverless Awesome: https://github.com/Serverless-Devs/package-awesome

✔ file decompression completed
? please select credential alias default

     _____            _            ______             _
    /  ___|          (_)           | ___ \           | |
    \ `--. _ __  _ __ _ _ __   __ _| |_/ / ___   ___ | |_
     `--. \ '_ \| '__| | '_ \ / _` | ___ \/ _ \ / _ \| __|
    /\__/ / |_) | |  | | | | | (_| | |_/ / (_) | (_) | |_
    \____/| .__/|_|  |_|_| |_|\__, \____/ \___/ \___/ \__|
          | |                  __/ |
          |_|                 |___/


    Welcome to the start-springboot application
     This application requires to open these services:
         FC : https://fc.console.aliyun.com/
         ACR: https://cr.console.aliyun.com/
     This application can help you quickly deploy the SpringBoot project:
         Full yaml configuration    : https://github.com/devsapp/sprintboot#%E5%AE%8C%E6%95%B4yaml
         SpringBoot development docs: https://spring.io/projects/spring-boot/
     This application homepage: https://github.com/devsapp/start-springboot


🏄‍ Thanks for using Serverless-Devs
👉 You could [cd /Users/dcs/Project/serverlessSpringboot] and enjoy your serverless journey!
🧭️ If you need help for this example, you can use [s -h] after you enter folder.
💞 Document ❤ Star：https://github.com/Serverless-Devs/Serverless-Devs
```

进入项目目录执行`s deploy`部署项目到函数计算，需要开通[NAS](https://nasnext.console.aliyun.com/introduction)，并创建通用型NAS文件系统。

> 阿里云函数计算支持与NAS无缝集成。这使您的函数可以像访问本地文件系统一样访问存储在其中一个NAS文件系统上的文件。您所要做的是在服务上配置NAS，其中包括NAS的地域、挂载点、分组等信息。配置成功后，该服务下的函数就可以像访问本地文件系统一样访问指定的NAS文件系统。

```bash
➜ serverlessSpringboot s deploy
[2021-10-30T21:18:13.963] [INFO ] [S-CLI] - Start ...
📎 Using web framework type: nas, If you want to deploy with container, you can [s cli fc-default set web-framework container] to switch.
[2021-10-30T21:18:14.222] [INFO ] [WEB-FRAMEWORK] - The configuration of the domain name is not detected, and a temporary domain name is generated.
[2021-10-30T21:18:16.653] [INFO ] [FC-DEPLOY] - Using region: cn-hangzhou
[2021-10-30T21:18:16.654] [INFO ] [FC-DEPLOY] - Using access alias: default
[2021-10-30T21:18:16.654] [INFO ] [FC-DEPLOY] - Using accessKeyID: ***********Udxi
[2021-10-30T21:18:16.654] [INFO ] [FC-DEPLOY] - Using accessKeySecret: ***********1BwC
📎 Using fc deploy type: sdk, If you want to deploy with pulumi, you can [s cli fc-default set deploy-type pulumi] to switch.
[2021-10-30T21:18:16.827] [INFO ] [FC-DEPLOY] - Checking Service web-springboot exists
[2021-10-30T21:18:17.105] [INFO ] [FC-DEPLOY] - Setting role: AliyunFCDefaultRole
[2021-10-30T21:18:17.152] [INFO ] [RAM] - Checking Role AliyunFCDefaultRole exists
[2021-10-30T21:18:17.447] [INFO ] [RAM] - Updating role: AliyunFCDefaultRole
[2021-10-30T21:18:17.561] [INFO ] [RAM] - Checking Plicy AliyunFCDefaultRolePolicy exists
[2021-10-30T21:18:17.721] [INFO ] [FC-DEPLOY] - Using logConfig: auto: fc will try to generate default sls project
[2021-10-30T21:18:17.892] [INFO ] [SLS] - Checking Project 1831277402525713-cn-hangzhou-logproject exists
[2021-10-30T21:18:18.122] [INFO ] [SLS] - Checking Logstore 1831277402525713-cn-hangzhou-logproject/fc-service-web-springboot-logstore exists
[2021-10-30T21:18:20.170] [INFO ] [SLS] - Checking Logstore index 1831277402525713-cn-hangzhou-logproject/fc-service-web-springboot-logstore exists
📎 Using fc deploy type: sdk, If you want to deploy with pulumi, you can [s cli fc-default set deploy-type pulumi] to switch.
[2021-10-30T21:18:20.233] [INFO ] [FC-DEPLOY] - Generated logConfig:
enableInstanceMetrics: true
enableRequestMetrics: true
logBeginRule: ~
logstore: fc-service-web-springboot-logstore
project: 1831277402525713-cn-hangzhou-logproject

[2021-10-30T21:18:20.234] [INFO ] [FC-DEPLOY] - Using vpcConfig: auto: fc will try to generate related vpc resources automatically
[2021-10-30T21:18:20.976] [INFO ] [VPC] - Getting vpc: fc-deploy-component-generated-vpc-cn-hangzhou
[2021-10-30T21:18:21.157] [INFO ] [VPC] - Getting vswitch: fc-deploy-component-generated-vswitch-cn-hangzhou
[2021-10-30T21:18:21.272] [INFO ] [VPC] - Getting securityGroup: fc-deploy-component-generated-securityGroup-cn-hangzhou
[2021-10-30T21:18:21.439] [INFO ] [FC-DEPLOY] - Generated vpcConfig:
securityGroupId: sg-bp16mj0j92jm506ind4g
vSwitchId: vsw-bp12p47aa34uzgsu7wic2
vpcId: vpc-bp1o9ew2j2mkrr8v5l3jz

[2021-10-30T21:18:21.440] [INFO ] [FC-DEPLOY] - Using nasConfig: auto: fc will try to generate related nas file system automatically
[2021-10-30T21:18:22.259] [INFO ] [FC-NAS] - Creating NasFileSystem: Alibaba-FcDeployComponent-DefaultNas-cn-hangzhou
[2021-10-30T21:18:22.566] [INFO ] [FC-NAS] - Creating MountTarget: 0cb1c4b180
[2021-10-30T21:18:25.241] [INFO ] [FC-NAS] - Nas mount target domain already created, waiting for status to be 'Active', now is Pending
[2021-10-30T21:18:27.505] [INFO ] [FC-NAS] - Nas mount target domain already created, waiting for status to be 'Active', now is Pending
[2021-10-30T21:18:29.736] [INFO ] [FC-NAS] - Nas mount target domain already created, waiting for status to be 'Active', now is Pending
[2021-10-30T21:18:31.853] [INFO ] [FC-NAS] - Nas mount target domain already created, waiting for status to be 'Active', now is Active
[2021-10-30T21:18:32.091] [INFO ] [FC-DEPLOY] - Using region: cn-hangzhou
[2021-10-30T21:18:32.091] [INFO ] [FC-DEPLOY] - Using access alias: default
[2021-10-30T21:18:32.091] [INFO ] [FC-DEPLOY] - Using accessKeyID: ***********Udxi
[2021-10-30T21:18:32.091] [INFO ] [FC-DEPLOY] - Using accessKeySecret: ***********1BwC
📎 Using fc deploy type: sdk, If you want to deploy with pulumi, you can [s cli fc-default set deploy-type pulumi] to switch.
[2021-10-30T21:18:32.106] [INFO ] [FC-DEPLOY] - Checking Service _FC_NAS_web-springboot-ensure-nas-dir-exist-service exists
[2021-10-30T21:18:32.178] [INFO ] [FC-DEPLOY] - Setting role: AliyunFCDefaultRole
[2021-10-30T21:18:32.184] [INFO ] [RAM] - Checking Role AliyunFCDefaultRole exists
[2021-10-30T21:18:32.367] [INFO ] [RAM] - Updating role: AliyunFCDefaultRole
[2021-10-30T21:18:32.468] [INFO ] [RAM] - Checking Plicy AliyunFCDefaultRolePolicy exists
[2021-10-30T21:18:32.602] [INFO ] [FC-DEPLOY] - Checking Function nas_dir_checker exists
✔ Make service _FC_NAS_web-springboot-ensure-nas-dir-exist-service success.
✔ Make function _FC_NAS_web-springboot-ensure-nas-dir-exist-service/nas_dir_checker success.
[2021-10-30T21:18:35.575] [INFO ] [FC-DEPLOY] - Checking Service _FC_NAS_web-springboot-ensure-nas-dir-exist-service exists
[2021-10-30T21:18:35.660] [INFO ] [FC-DEPLOY] - Checking Function nas_dir_checker exists

There is auto config in the service: _FC_NAS_web-springboot-ensure-nas-dir-exist-service
[2021-10-30T21:18:43.438] [INFO ] [FC-DEPLOY] - Using region: cn-hangzhou
[2021-10-30T21:18:43.439] [INFO ] [FC-DEPLOY] - Using access alias: default
[2021-10-30T21:18:43.439] [INFO ] [FC-DEPLOY] - Using accessKeyID: ***********Udxi
[2021-10-30T21:18:43.439] [INFO ] [FC-DEPLOY] - Using accessKeySecret: ***********1BwC
📎 Using fc deploy type: sdk, If you want to deploy with pulumi, you can [s cli fc-default set deploy-type pulumi] to switch.
[2021-10-30T21:18:43.454] [INFO ] [FC-DEPLOY] - Checking Service _FC_NAS_web-springboot exists
[2021-10-30T21:18:43.527] [INFO ] [FC-DEPLOY] - Setting role: AliyunFCDefaultRole
[2021-10-30T21:18:43.533] [INFO ] [RAM] - Checking Role AliyunFCDefaultRole exists
[2021-10-30T21:18:43.774] [INFO ] [RAM] - Updating role: AliyunFCDefaultRole
[2021-10-30T21:18:43.881] [INFO ] [RAM] - Checking Plicy AliyunFCDefaultRolePolicy exists
[2021-10-30T21:18:44.044] [INFO ] [FC-DEPLOY] - Checking Function nas_dir_checker exists
[2021-10-30T21:18:44.120] [INFO ] [FC-DEPLOY] - Checking Trigger httpTrigger exists
[2021-10-30T21:18:44.192] [INFO ] [FC-DEPLOY] - Checking Trigger httpTrigger exists
✔ Make service _FC_NAS_web-springboot success.
✔ Make function _FC_NAS_web-springboot/nas_dir_checker success.
✔ Make trigger _FC_NAS_web-springboot/nas_dir_checker/httpTrigger success.
[2021-10-30T21:18:47.007] [INFO ] [FC-DEPLOY] - Checking Service _FC_NAS_web-springboot exists
[2021-10-30T21:18:47.078] [INFO ] [FC-DEPLOY] - Checking Function nas_dir_checker exists
[2021-10-30T21:18:47.206] [INFO ] [FC-DEPLOY] - Checking Trigger httpTrigger exists

There is auto config in the service: _FC_NAS_web-springboot
[2021-10-30T21:18:47.389] [INFO ] [FC-DEPLOY] - Generated nasConfig:
groupId: 10003
mountPoints:
  - fcDir: /mnt/auto
    nasDir: /web-springboot
    serverAddr: 0cb1c4b180-ulm3.cn-hangzhou.nas.aliyuncs.com
userId: 10003

[2021-10-30T21:18:47.391] [INFO ] [FC-DEPLOY] - Checking Function springboot exists
[2021-10-30T21:18:47.504] [WARN ] [FC-DEPLOY] - Image registry.cn-hangzhou.aliyuncs.com/web-framework/java11:0.0.1 dose not exist locally.
Maybe you need to run 's build' first if it dose not exist remotely.
[2021-10-30T21:18:47.506] [INFO ] [FC-DEPLOY] - Checking Trigger web-springboot exists
[2021-10-30T21:18:47.576] [INFO ] [FC-DEPLOY] - Checking Trigger web-springboot exists
✔ Make service web-springboot success.
✔ Make function web-springboot/springboot success.
✔ Make trigger web-springboot/springboot/web-springboot success.
[2021-10-30T21:18:49.288] [INFO ] [FC-DEPLOY] - Checking Service web-springboot exists
[2021-10-30T21:18:49.359] [INFO ] [FC-DEPLOY] - Checking Function springboot exists
[2021-10-30T21:18:49.485] [INFO ] [FC-DEPLOY] - Checking Trigger web-springboot exists
[2021-10-30T21:18:49.669] [INFO ] [FC-DEPLOY] - Using customDomain: auto: fc will try to generate related custom domain resources automatically
✔ devsapp_domain.zip file decompression completed
✔ End of request
✔ Deployed.
✔ End of request
[2021-10-30T21:18:57.618] [INFO ] [FC-DEPLOY] - Generated auto custom domain: springboot.web-springboot.1831277402525713.cn-hangzhou.fc.devsapp.net
[2021-10-30T21:18:57.619] [INFO ] [FC-DEPLOY] - Creating custom domain: springboot.web-springboot.1831277402525713.cn-hangzhou.fc.devsapp.net
✔ devsapp_fc-domain.zip file decompression completed
[2021-10-30T21:18:58.878] [INFO ] [FC-DOMAIN] - Creating custom domain: springboot.web-springboot.1831277402525713.cn-hangzhou.fc.devsapp.net

There is auto config in the service: web-springboot

Tips for next step
======================
* Display information of the deployed resource: s info
* Display metrics: s metrics
* Display logs: s logs
* Invoke remote function: s invoke
* Remove Service: s remove service
* Remove Function: s remove function
* Remove Trigger: s remove trigger
* Remove CustomDomain: s remove domain



Reminder nas upload instruction: upload ./code/target/demo-0.0.1-SNAPSHOT.jar /mnt/auto/springboot/demo-0.0.1-SNAPSHOT.jar

Tips for next step
======================
* Invoke remote function: s invoke
✔ Upload done

Tips for next step
======================
* Invoke remote function: s invoke
✔ Try container acceleration
springboot:
  region:        cn-hangzhou
  serviceName:   web-springboot
  functionName:  springboot
  customDomains:
    - http://springboot.web-springboot.1831277402525713.cn-hangzhou.fc.devsapp.net
```

在浏览器中访问临时域名`http://springboot.web-springboot.1831277402525713.cn-hangzhou.fc.devsapp.net`，可以看到已经部署成功了。

![](https://image.ldbmcs.com/2021-10-30-nEZkrO.png)

#### 2.2.4 自定义域名

首先在阿里云函数计算控制台点击【域名管理】添加自定义域名。

![](https://image.ldbmcs.com/2021-10-30-AXGLzv.png)

输入域名，选择服务名称，函数名称，版本，点击确定。注意需要提前将域名备案并解析到页面的CNAME上。

![](https://image.ldbmcs.com/2021-10-30-vb8Nr2.png)

配置成功后就可以再浏览器中输入自定义域名验证是否配置成功。

![](https://image.ldbmcs.com/2021-10-30-X5emqL.png)

## 3. 总结

本文介绍了Serverless是什么，解决了什么问题以及通过Serverless Devs如何快速在阿里云函数计算平台上部署SpringBoot应用。