---
title: 使用 Prometheus + Grafana 监控 MySQL
date: 2021/12/27 21:50:59
categories:
- MySQL
tags:
- Prometheus
- Grafana
- DevOps
---
在[上一篇](https://juejin.cn/post/7015949319425490952)文章中，我们介绍了Grafana和Prometheus的基本概念，以及如何监控Spring Boot应用。今天，这篇文章将要介绍如何通过Prometheus + Grafana 监控 MySQL，快速方便的查看连接数，锁，内存，网络等指标，通过这些指标我们能快速的发现mysql瓶颈，死锁等问题。

## 1. Prometheus

之前介绍过[Prometheus](https://prometheus.io/)是开源的监控系统，与其他监控系统相比，具有易于管理，监控服务的内部运行状态，强大的数据模型，强大的查询语言PromQL，高效，可扩展，易于集成，可视化，开放性等众多功能。

### 1.1 Exporter

所有可以向Prometheus提供监控样本数据的程序都可以被称为一个`Exporter`。而Exporter的一个实例称为target，如下所示，Prometheus通过轮询的方式定期从这些target中获取样本数据:

![](https://image.ldbmcs.com/2021-10-16-JOmTmD.jpg)

Exporter的来源也分为两种，分别是社区提供的，包含数据库（MySQL Exporter, Redis Exporter等），消息队列（ Kafka Exporter, RabbitMQ Exporter等），存储，HTTP服务，日志，监控服务等。另外就是用户自定义的Exporter，用户可以基于Prometheus提供的Client Library创建自己的Exporter程序。

### 1.2 MySQLD Exporter

Prometheus提供的`MySQLD Exporter`实现对MySQL数据库性能以及资源利用率的监控和度量。

这里我们采用docker compose的方式部署Exporter，`docker-compose.yml`：

```yaml
version: '3'
services:
  mysqlexporter:
    image: prom/mysqld-exporter
    ports:
      - "9104:9104"
    environment:
      - DATA_SOURCE_NAME=root:password@(mysql:3306)/database
```

运行命令`docker-compose up -d`启动Exporter。

### 1.3 配置`prometheus.yml`

除了需要启动MySQLD Exporter外，Prometheus的配置文件也需要修改下，在`prometheus.yml`文件中加入以下配置才会加入到监控中。

```yaml
- job_name: jobName
  static_configs:
  - targets:
    - localhost:9104
```

然后运行以下命名重启Prometheus：

```bash
docker-compose down
docker-compose up -d
```

然后，可以在浏览器中输入`http://127.0.01:9090/targets`，我们看到Tragets已经添加成功。

![](https://image.ldbmcs.com/2021-10-16-dqM8nR.png)

点击`Graph`可以看到监控的MySQL的指标：

![](https://image.ldbmcs.com/2021-10-16-IXUSxz.png)

下一步就是在Grafana中添加数据源，导入仪表盘模板。

## 2. Grafana

介绍以及安装Grafana在这里就不展开细说了，不清楚的可以看[上一篇文章](https://juejin.cn/post/7015949319425490952)，总体上说主要是安装grafana，创建数据源，引入仪表盘模板就完成了。我们直接从创建数据源开始。

### 2.1 创建数据源

首先，在浏览器中打开grafana的地址，点击添加数据源。

![](https://image.ldbmcs.com/2021-10-16-XrAoMT.png)

选择Prometheus。

![](https://image.ldbmcs.com/2021-10-16-I2zlcw.png)

输入数据源名称，数据源来源地址，点击添加。

![](https://image.ldbmcs.com/2021-10-16-DW6pb5.png)

### 2.2 创建仪表盘

点击左侧菜单栏的【创建】，点击【导入】,当然也可以在这里选择创建仪表盘，自己选择组件和自定义布局完成。

![](https://image.ldbmcs.com/2021-10-16-n3JndO.png)

这里需要填写我们需要导入的仪表盘组件，可以在浏览器中进入[Grafana仪表盘模板网站](https://grafana.com/grafana/dashboards/)，搜索MySQL。

![2021-10-16-OAVQ6Q](https://image.ldbmcs.com/2021-10-16-OAVQ6Q.png)

选择我们喜欢的一个模板，这里我们选择第一个，点击进入。

![2021-10-16-bGQldH](https://image.ldbmcs.com/2021-10-16-bGQldH.png)

复制仪表盘的id，这里是7362。

![2021-10-16-K8NTQ7](https://image.ldbmcs.com/2021-10-16-K8NTQ7.png)

然后会自动加载进入下个页面，输入仪表盘的名称，选择数据源，点击导入即成功创建仪表盘。

![2021-10-16-3kw738](https://image.ldbmcs.com/2021-10-16-3kw738.png)

最终呈现的仪表盘如下：

![2021-10-16-Uu7dK9](https://image.ldbmcs.com/2021-10-16-Uu7dK9.png)

## 3. 参考

1. [Exporter是什么](https://yunlzheng.gitbook.io/prometheus-book/part-ii-prometheus-jin-jie/exporter/what-is-prometheus-exporter)