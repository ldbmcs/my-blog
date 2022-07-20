+++
title="你还在用JWT做身份认证嘛？"
date="2021-12-27 22:30:01"
tags=["JWT","鉴权"]
+++

>
翻译自：[JSON Web Tokens (JWT) are Dangerous for User Sessions—Here’s a Solution](https://redis.com/blog/json-web-tokens-jwt-are-dangerous-for-user-sessions/)

有时候，人们采用旨在解决狭义问题的技术，并开始广泛运用这项技术。这些问题可能看起来类似，但是使用独特的技术来解决一般的问题，可能会造成意想不到的后果。举个栗子，手里拿个锤子，看谁都是钉子，jwt就是这样一种技术。

<!-- more --> 

![](https://image.ldbmcs.com/ZXCI8K.jpg)

来源：[Stop using JWT for sessions](http://cryto.net/~joepie91/blog/2016/06/13/stop-using-jwt-for-sessions/)

![](https://image.ldbmcs.com/QDWi2g.jpg)

来源：[Why JWTs Are Bad for Authentication](https://www.youtube.com/watch?v=GdJ0wFi1Jyo)
—[Randall Degges](https://www.linkedin.com/in/rdegges/), Head of Developer Advocacy, Okta.]

![5itISa](https://image.ldbmcs.com/5itISa.jpg)

来源：[JWT should not be default for your sessions](https://evertpot.com/jwt-is-a-bad-default/)

![ilMt0s](https://image.ldbmcs.com/ilMt0s.jpg)

有很多像Okta这样的中小企业的深入文章和视频，谈论使用JWT的潜在风险和低效。然而这些警告被营销人员，YouTubers，博客作者，课程作者和其他有意或者无意推广它的人所掩盖。

如果你看了许多这样的视频和文章，他们都只是谈论了jwt带来的好处，却忽略了不足之处。更加具体点，他们只是谈论了如何使用JWT，但是并没有讨论jwt在实际生产环境中带来的额外的复杂性。他们也从来没有把它和现有的经历过风雨的技术进行比较，无法真正权衡利弊。

也许正式这个完美的，有价值的，友好的名字导致了jwt的流行，json(很受欢迎)，web，token(无状态)使人们认为jwt非常适合身份验证。

因此，我认为这是一个通过营销击败了工程师和安全专家的案例。但是，这也不是坏事，因为在Hacker
News经常会有关于JWT的冗长和激烈的辩论（请看[这里](https://news.ycombinator.com/item?id=21783303)
,[这里](https://news.ycombinator.com/item?id=27136539)和[这里](https://news.ycombinator.com/item?id=24352360)），所以拯救它还是有希望的。

如果你想一下，这些持续不断的辩论本身就应该是一个危险的信号，因为你永远不应该看到这样的辩论。特别是在安全领域，安全领域应该是永远安全的，在这其中任何一种技术都应该是安全的，或者它并不是安全领域的技术。

在任何情况下，在这篇博客中，我将只关注使用JWT的潜在风险，并谈论一个已经过了10年的经过数次战斗的解决方案。

为了方便理解，当我在谈到JWT时，我的意思是“无状态的JWT”，这也是JWT流行的首要原因，也是首先考虑使用JWT的最大原因。此外，我还在下面的参考资料部分列出了其他文章，这些文章深入介绍了JWT的本质。

在我们理解为什么JWT不安全之前，让我们首先通过一个示例去了解JWT是如何工作的。

## 1. 示例

让我们想像一下，比如你正在使用Twitter，你需要经历登录，写推文，点赞推文，转发推文，在这其中一共有4个操作，对于每一步操作，你都需要经过身份验证和授权，然后才能执行特定的操作。

下面是如果使用传统的方法的流程。

### 1.1 传统的方法

1. 通过账号和密码登录。
    1. 服务器首先对用户进行身份验证
    2. 然后，服务会创建一个用户的session token(会话的令牌)
       ，然后将token和用户信息一起存储在某个数据库中。（注意：token是一个无法识别的长字符串，也称为不透明字符串，如下所示：fsaf12312dfsdf364351312srw12312312dasd1et3423r）
2. 然后，服务器将你的token发送给移动端或者web端。
    1. 然后，token会被存储在cookie或者应用程序的本地存储中。
3.

接着，假设你编写并提交了一个Twitter，然后应用程序会将Token（通过Cookie或者header）和Twitter一起发送给服务器，以便服务器可以识别你是谁。但是，Token只是一个随机的字符串，那么服务器如何通过Token就知道你是谁呢？

4. 当服务器接收到了从前端传递过来的Token之后，它并不知道是哪个用户。因此，服务器会将Token发送到数据库中去检索以获取实际用户信息（如UserId）。
5. 如果Token对应的用户存在，而且被允许执行指定操作（比如发Twitter），则服务器允许他们执行改操作。
6. 最终，服务器会告诉前端这条推文已经被发送。

![fPD374](https://image.ldbmcs.com/fPD374.jpg)

### 1.2 传统方法最主要的问题

传统的方法最主要的问题是上述第4步骤非常慢，因为用户做的每一个操作都需要重复的去数据库查询用户的实际信息。因此，每次API调用都会导致至少2次数据库的连接(4，5)，这个可能会降低应用的响应时间。

**解决这个问题的2个办法**：

1. 通过某种方式完全取消数据库查找用户（比如4）
2. 通过额外的更快的数据库去查找用户，这样额外的查找就无关重要了。

**方法1：取消第4步，在数据库中查找用户**

这里有不同的办法可以实现：

1. 可以把用户状态缓存在服务器的内存中，但是会在进行服务器扩展时导致问题，因为用户的状态只保留在一个特定的服务器中。
2. 使用“sticky sessions”，可以告诉负载均衡器将同一个token的流量始终定向到特定的服务器，即使在向上扩展之后也是如此。但是这样在服务器缩减时，将失去缩减服务器中保存的所有用户状态。
3. 第三种选择就是JWT，接下来让我们看看JWT是如何实现的。

### 1.3 通过JWT解决数据库查询问题

如果当JWT被用作会话时，可以试图通过JWT来完全消除数据库查询来解决传统方法的主要问题。

**主要思想就是把用户的用户存储在session token本身上**。将实际用户信息存储在token上来代替某个长的随机字符串，为了安全，我们使用只有服务器知道的秘钥对token的一部分内容进行签名加密。

因此，即时客户端和服务器都可以看到Token的用户信息部分，但是第二部分，即签名部分，也只能由服务器验证。

在下面中，Token的粉红色部分包含payload（用户信息）并且客户端和服务端都能看到。

但是蓝色部分是使用秘钥，header和payload本身进行签名的，因此，如果客户端篡改了payload（比如模拟一个其他不同的用户），签名也就会被改变，并且在服务器端不能进行身份验证。

![FESrGS](https://image.ldbmcs.com/FESrGS.jpg)

下面是使用JWT的流程：

1. 通过账号和密码登录。
    1. 服务器通过在数据库查询用户进行身份验证。
    2. 然后，服务器通过用户信息和秘钥创建一个JWT Session Token（不涉及数据库）。
2. 然后，服务器将你的JWT Token发送给前端应用，对于以后的活动，服务器可以只通过JWT Token来标识客户，而不是每次都需要查询数据库进行身份验证。
    1. 一个JWT Token类似：`<header>.<payload>.<signature>`
3. 接着，你编写和提交一个twitter，当你点击发送时，随着你的Twitter文本一起，你的应用也会发送当前用户的JWT Token（从Cookie或者Header），以便服务器能标识你是哪个用户。但是，仅仅通过JWT
   Token，服务器怎么知道你是谁呢，因为Token的一部分已经包含了用户信息。
4. 所以当服务器接收到JWT Token时，会首先通过秘钥去校验签名部分，并从payload部分获取用户信息，从而减少数据库查询。
5. 如果签名通过，则允许执行该操作。
6. 最终，服务器会告诉前端这条推文已经被发送。

接下来，对于用户的每项操作，服务器只需要验证签名部分，从而获取用户信息，然后让用户执行该操作，从而完全跳过数据库的查询。

![uHcW7G](https://image.ldbmcs.com/uHcW7G.jpg)

**Token过期**

但是，关于JWT Token，还有一件额外和非常重要的事情需要了解，那就是使用过期时间来自动过期，一般设置5到30分钟。但是，正因为是JWT自有的功能，所以你不能轻松的撤销、变更无效或者更新，这个才是问题的症结所在。

## 2. 为什么JWT在用户身份验证中存在风险呢？

**JWT最大的问题就是Token的撤销问题。**从创建Token到Token过期，服务器都没有简单的方法可以失效它。

下面是一些存在风险的案例。

1. **退出登录，但是并没有真正退出。**

   想象一下，你在发完Twitter之后从Twitter上退出登录，你可能会觉得已经从服务器中退出登录了，但是这并不是真的。因为JWT是自我管理过期时间的，它会一直有效到过期为止，这可能是5分钟或者30分钟，或者存在于Token的一部分的设置的任何持续时间。所以，在这个时间段，如果有人获取到这个Token的访问权限，那么他可以继续使用这个Token，直到过期为止。

2. **屏蔽用户，但是并没有立刻屏蔽。**

   想象一下，你是Twitter或者某个用户正在使用的在线游戏的管理者，如果你想快速的屏蔽某个用户防止不滥用系统，那是不行的。和第一点原因是一样的，即使你屏蔽了这个用户，他还是继续拥有服务器的访问权限直到Token过期。

3. **数据不会实时更新。**

   继续想象一下，假设用户之前是管理员，但是被降级为只有较少权限的常规用户。同样的，操作并不会立即生效，该用户还是继续是管理员，直到Token过期。

4. JWT通常都没有进行加密，这样会导致任何能够执行中间人攻击并且嗅探JWT的人现在都能拥有你的身份验证凭据。因为只需在服务器和客户端的连接上完成MITM攻击，所以获取身份验证凭据就变得非常简单了。

## 3. 其他的复杂度和注意事项

### 3.1 库和规范的问题

人们发现，许多实现JWT的库多年来都存在许多安全问题，甚至该规范本身也存在许多问题，即使是推广JWT的AUTH本身也有很多问题[看这里](https://insomniasec.com/blog/auth0-jwt-validation-bypass)
。

### 3.2 Token的长度

在许多真实的复杂的应用中，他们可能需要存储一大堆的信息，如果将其存在JWT Token中可能会超过URL的长度或者Cookie的长度从而导致各种问题，另外还会在每个请求上发送大量的数据。

### 3.3 维护状态（用于限流，白名单等）

在许多真实的应用中，服务器必须维护用户的IP并且跟踪API以进行限流和IP白名单。因此无论如何都需要使用速度极快的数据库，如果认为你的应用可以通过JWT以某种方式变得无状态是不现实的。

### 3.4 建议的解决方案

一种流行的解决方案是在数据库中存储一个“已失效的Token”的列表，并且每次调用时再从数据中检查该列表，如果当前的Token在已失效的Token列表中，那就阻止用户进行下一步的操作。这样，每次请求都需要对数据库进行额外的查询，以检查Token是否已经失效，也就完全失去了使用JWT的目的（减少数据库的查询）。

### 3.5 底线

尽管JWT确实减少了数据库的查询，但是在这样做的同时引入了安全问题和其他的复杂度。安全始终是二元的，要么是安全的，要么是不安全的。因此，将JWT用于用户Session是非常危险的。

### 3.6 在哪里可以使用JWT

在后端进行服务器到服务器(或者微服务到微服务)通信的情况下，一个服务可能会生成一个JWT Token，将其发送到另外一个服务器用于授权的目的，以及其他的小场景，比如重置密码。在这些场景中，你可以将JWT Token作为**一次性的短期的**
令牌进行发送，已验证用户的信息。

## 4. 如果不能使用JWT，还能有其他的方案嘛

**解决方案就是不将JWT用于会话的目的，取而代之的是使用传统的，经过多次考验的更有效率的办法。**就是使用查找速度非常快(亚毫秒级)的数据库，至于额外的数据库调用则无关紧要，这个就是选项2。

**选项2：快速查找，使其调用无关紧要(一个经过数次考验的解决方案)**

有没有哪种速度非常快的数据库，可以在亚毫秒内响应数百万个请求？

当然，它就是Redis，一个每天为数十亿用户提供服务的数据库，数以千计的公司使用Redis的目的就是为了能快速响应用户请求。

而且Redis Enterprise是Redis OSS的增强版本，它提供99.999%的可用性，可以服务数万亿的请求。它可以作为私有云上的免费软件使用，也可以在排名前3位的云服务提供商的的云中使用。

更重要的是Redis Enterprise现在已经从仅仅是一个缓存数据库发展成为一个成熟的多模型数据库，其模块生态系统与核心Redis一起在本地运行。例如，您可以使用RedisJSON(比市场领先者快10倍)
，基本上拥有一个类似MongoDB的实时数据库，或者使用RediSearch模块(速度快4-100倍)，像Algolia一样实现实时全文搜索。

如果您简单地使用Redis作为Token存储，并使用其他一些数据库作为主数据库，那么您的体系结构将是下面这样的。需要注意的是，Redis Enterprise提供了四种类型的缓存：Cache-aside (Lazy-loading)
、Write-Back、Write-through和Read-Replica，而Redis OSS只提供一种(Cache-aside)。

请注意，闪电符号表示的是闪电般的快速速度，蜗牛符号表明速度很慢。

![yKHVKm](https://image.ldbmcs.com/yKHVKm.jpg)

如前所述，您还可以使用Redis作为整个数据层的主数据库。那么在这个场景中，您的体系结构变得简单得多，另外，一切都变得非常迅速。

![hCHLdf](https://image.ldbmcs.com/hCHLdf.jpg)

**是否具有扩展性呢？**

当然，公司不仅将Redis用作独立数据库，还将其用作地理上分布的数据库集群。

## 5. 参考资料

1. [Stop using JWT for sessions](http://cryto.net/~joepie91/blog/2016/06/13/stop-using-jwt-for-sessions/)
2. [JWT should not be your default for sessions](https://evertpot.com/jwt-is-a-bad-default/)
3. [Why JWTs Are Bad for Authentication – Randall Degges (Head of Dev Relations, Okta)](https://www.youtube.com/watch?v=GdJ0wFi1Jyo)
4. [Stop using JWT for sessions, part 2: Why your solution doesn’t work](http://cryto.net/~joepie91/blog/2016/06/19/stop-using-jwt-for-sessions-part-2-why-your-solution-doesnt-work/)
5. [Thomas H. Ptacek on Hacker News](https://news.ycombinator.com/item?id=13866883)
6. [My experience with JSON Web Token](https://x-team.com/blog/my-experience-with-json-web-tokens/)
7. [Authentication on the Web (Sessions, Cookies, JWT, localStorage, and more)](https://youtu.be/2PPSXonhIck)
8. [Thomas H. Ptacek’s blog](https://flaked.sockpuppet.org/about/)