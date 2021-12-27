---
title: 使用 Prometheus + Grafana + Spring Boot Actuator 监控应用
date: 2021/12/27 21:51:40
toc: true
categories:
- Spring Boot
tags:
- Prometheus
- Grafana
- DevOps
---
在企业级的应用中，监控往往至关重要，监控可以帮助我们预防故障，预测变化趋势，在达到阈值的时候报警，为排查生产问题提供更多的信息。如果我们不知道我们程序的运行情况，当线上系统出现了事故再去排查就需要花费更多的时间，如果能提前监控，就能早做准备，以免出了事故之后乱了手脚，当然也避免不了系统不产生一点事故，但是能减少系统事故的产生。同时也能看到系统问题，早做优化，避免更大的事故发生。

<!-- more --> 

## 1. Spring Boot Actuator

根据[官网](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)介绍，Spring Boot包含了很多附加功能帮助我们监控和管理我们的应用，可以使用HTTP或者JMX等方式通过端点(endpoint)获取应用的健康状态以及其他指标收集。

Spring Boot Actuator模块就是Spring Boot提供的集成了上面所述的监控和管理的功能。像Spring Boot其他模块一样开箱即用，非常方便，通过Actuator就可以使用HTTP或者JMX来监控我们的应用。

> JMX(Java Management Extensions)：Java平台的管理和监控接口，任何程序只要按JMX规范访问这个接口，就可以获取所有管理与监控信息。

下面简单介绍下Spring Boot Actuator是如何使用的，具体的使用方法见[官方文档](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)，官方的文档是永远值得相信的。

### 1.1 添加依赖

如果使用maven管理，则是：

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
</dependencies>

```

如果使用Gradle，则是下面这样的：

```
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
}
```

### 1.2 开启端点

Spring Boot中监控应用或者与应用交互都是通过端点(`endpoint`)进行的，Spring Boot提供了非常多的原生端点，比如`health`，可以帮助我们监控应用的监控状态(是否可用)，同时可以添加自定义的端点。每个端点都可以单独设置是否开启，并通过HTTP或者JMX暴露给外部系统。如果选择HTTP方式，则URL的前缀一般是`/actuator`，比如`health`的url地址就是`/actuator/health`。

默认情况下，除了`shutdown`（让系统优雅的关闭） ，其他端点默认是开启的。我们可以通过`management.endpoint.<id>.enabled`设置某个端口的状态，比如开启shutdown端口。

```properties
management.endpoint.shutdown.enabled=true
```

### 1.3 暴露端点

开启端点后还必须暴露端点给HTTP或者JMX才能正常使用，但是端口可能包含一些敏感的数据，所以Spring Boot的原生端口默认只支持HTTP或者JMX，比如`shutdown`端口默认只支持JMX，`health`端口即支持JMX，也支持HTTP。

| ID                 | JMX  | Web  |
| :----------------- | :--- | :--- |
| `auditevents`      | Yes  | No   |
| `beans`            | Yes  | No   |
| `caches`           | Yes  | No   |
| `conditions`       | Yes  | No   |
| `configprops`      | Yes  | No   |
| `env`              | Yes  | No   |
| `flyway`           | Yes  | No   |
| `health`           | Yes  | Yes  |
| `heapdump`         | N/A  | No   |
| `httptrace`        | Yes  | No   |
| `info`             | Yes  | No   |
| `integrationgraph` | Yes  | No   |
| `jolokia`          | N/A  | No   |
| `logfile`          | N/A  | No   |
| `loggers`          | Yes  | No   |
| `liquibase`        | Yes  | No   |
| `metrics`          | Yes  | No   |
| `mappings`         | Yes  | No   |
| `prometheus`       | N/A  | No   |
| `quartz`           | Yes  | No   |
| `scheduledtasks`   | Yes  | No   |
| `sessions`         | Yes  | No   |
| `shutdown`         | Yes  | No   |
| `startup`          | Yes  | No   |
| `threaddump`       | Yes  | No   |

如果要改变端口暴露的方式，使用`include`或者`exclude`属性，比如：

```properties
management.endpoints.jmx.exposure.include=*
management.endpoints.web.exposure.include=health,info,prometheus
```

到目前为止，Spring Boot Actuator就配置好了，除了上述所看到的端点的开启和暴露方式，还有HTTP，JMX，日志，指标(Metrics)，权限，HTTP追踪，进程监控等功能，如果想了解更多，可以去[官网](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)进一步学习。

## 2. Prometheus 

Prometheus，中文名普罗米修斯，是新一代的监控系统，与其他监控系统相比，具有易于管理，监控服务的内部运行状态，强大的数据模型，强大的查询语言PromQL，高效，可扩展，易于集成，可视化，开放性等众多功能。详细内容可见[官网](https://prometheus.io/)，此处不再详细介绍。

在Spring Boot中，原生支持了prometheus端口，只需要通过如下配置就可集成Prometheus暴露给HTTP。

```yaml
management:
  endpoints:
    web:
      exposure:
        include: "prometheus"
```

除了上述配置外，还需要配置metrics，因为如果没有这个参数，很多报表不能正常显示。(此处没有深入研究，道歉...)

```yaml
management:
  endpoints:
    web:
      exposure:
        include: "prometheus"
  metrics:
    tags:
      application: ${spring.application.name}
```

这样就把Prometheus的客户端配置好了，另外就还需要服务端，这里我们使用docker方式，首先需要配置文件`prometheus.yml`

```yaml
scrape_configs:
  # 任意写，建议英文，不要包含特殊字符
  - job_name: 'jobName'
    # 采集的间隔时间
    scrape_interval: 15s
    # 采集时的超时时间
    scrape_timeout: 10s
    # 采集路径
    metrics_path: '/actuator/prometheus'
    # 采集服务的地址，也就是我们应用的地址
    static_configs:
      - targets: ['localhost:8080']
```

创建`docker-compose.yml`，注意`prometheus.yml`与`docker-compose.yml`的相对路径，如果放在同样的目录下，volumes则为`- './prometheus.yml:/etc/prometheus/config.yml'`。

```yaml
version: '3.3'
services:
  prometheus:
    image: 'prom/prometheus:v2.14.0'
    ports:
      - '9090:9090'
    command: '--config.file=/etc/prometheus/config.yml'
    volumes:
      - './prometheus.yml:/etc/prometheus/config.yml'
```

然后直接使用命令`docker-compose up -d`启动即可，docker compose的使用另寻了解，此处不再详细介绍。

启动之后，在浏览器中访问`http://localhost:9090`

![2021-10-06-B7UuV1](https://image.ldbmcs.com/2021-10-06-B7UuV1.png)

然后，可以查看不同指标的监控数据，比如`jvm_memory_used_bytes`

![2021-10-06-caFBAX](https://image.ldbmcs.com/2021-10-06-caFBAX.png)

这样，我们就通过Prometheus已经可以看到Spring Boot不同指标的监控数据了，那么为什么还需要Grafana呢，不集成Grafana也是可以的，但是通过Grafana，我们可以更加方便快捷的可视化的查看监控数据，最终的成果如下图所述：

![2021-10-06-tJAxIH](https://image.ldbmcs.com/2021-10-06-tJAxIH.png)

如果感兴趣的话，继续往下看哟。

## 3. Grafana

### 3.1 介绍

Grafana是一个可视化面板，可以展示非常漂亮的图标和布局，支持Prometheus，SQL(MySQL，PostgreSQL)等作为数据源。

有如下特点：

1. 可视化：非常精美的各种组件可供选择，比如图表，文本，提醒事项，还有灵活的布局，可以自由配置你的可视化面板。
2. 数据源：目前支持Prometheus，Graphite，Loki，Elasticsearch，MySQL，PostgreSQL，Stackdriver和TestData DB等多种数据源。
3. 通知提醒：通过可视化的方式配置通知规则，在数据达到阈值时，将配置好的信息发送给指定管理员。
4. 混合数据源：在同一个图中混合不同的数据源，基于每个查询指定数据源。

### 3.2 安装

还是使用docker compose的方式安装，`docker-compose.yml`如下：

```yaml
version: '3.3'
services:
  grafana:
    image: 'grafana/grafana:6.5.0'
    ports:
      - '3000:3000'
```

此处可以与Prometheus合并到一个docker compose中，如果合并则是：

```yaml
version: '3.3'
services:
  prometheus:
    image: 'prom/prometheus:v2.14.0'
    ports:
      - '9090:9090'
    command: '--config.file=/etc/prometheus/config.yml'
    volumes:
      - './prometheus.yml:/etc/prometheus/config.yml'

  grafana:
    image: 'grafana/grafana:6.5.0'
    ports:
      - '3000:3000'
```

然后再通过命令`docker-compose up -d`启动，在浏览器中访问`http://localhost:3000`，并使用初始账号`admin:admin`登录。

![2021-10-06-VLU67p](https://image.ldbmcs.com/2021-10-06-VLU67p.png)

### 3.3 配置

#### 3.3.1 添加数据源

登录之后，选择添加数据源，选择Prometheus。

![2021-10-06-GIx6OD](https://image.ldbmcs.com/2021-10-06-GIx6OD.png)

输入数据源名称(任意)，Prometheus的url地址，然后点击添加保存。

![2021-10-06-tksEgE](https://image.ldbmcs.com/2021-10-06-tksEgE.png)

#### 3.3.2 创建仪表盘

下一步就是创建仪表盘，在这里有两个选择，其一是创建新的仪表盘，选择不同的组件，设置布局，还有一种方式是选择[grafana](https://grafana.com/grafana/dashboards)官方或者社区提供的仪表盘，而且他们的样式都十分精美，可以直接导入。这里我们选择导入仪表盘，因为我们是Java应用，重点关注的肯定是JVM相关的指标，所以我们搜索JVM，通过安装量进行排序。

![2021-10-06-gy4E1A](https://image.ldbmcs.com/2021-10-06-gy4E1A.png)

点击第一个，这个仪表盘包含了JVM，线程，CPU等指标，我们就导入这个，当然你也可以选择其他的仪表盘或者自建。

![2021-10-06-l8RyBT](https://image.ldbmcs.com/2021-10-06-l8RyBT.png)

在`Grafana.com Dashboard`处输入4701。

![2021-10-06-rQfZIA](https://image.ldbmcs.com/2021-10-06-rQfZIA.png)

选择数据源，点击导入。

![2021-10-06-wv5tLx](https://image.ldbmcs.com/2021-10-06-wv5tLx.png)

最终呈现的仪表盘就如下图：

![2021-10-06-QqsmVO](https://image.ldbmcs.com/2021-10-06-QqsmVO.png)

## 4. 总结

这篇主要从Spring Boot Actuator入手，介绍了Spring Boot应用监控的端点和暴露方式，接着就以端点Prometheus为例，介绍了Prometheus的基本概念和如何使用的，Spring Boot Actuator + Prometheus就已经能完成可视化监控应用了，但是Prometheus的可视化还是比较粗糙，这个时候Grafana就出场了，通过Grafana和Prometheus就可以实现完美的可视化仪表盘。

另外除了监控应用外，我们平时使用的还有数据库，那么我们如果通过Grafana和Prometheus监控数据库实例的相关指标呢，下一篇文章见。