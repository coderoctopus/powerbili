# PowerBili
用于原样保存哔哩哔哩上的用户生成内容，不会对获取的json文件做出任何优化或更改。内容的优化和浏览会留给下一个软件（或脚本）处理。

[TOC]

# 支持的内容

## 视频

1. 评论（也支持其他评论区，详见下）
2. 分P信息
3. 统计信息（评论数、点赞数……）
4. 简介
5. tags

## 用户空间

1. 动态
2. 统计信息（播放量、点赞数……）
3. 收藏夹（WIP）

# 使用方法
todo

# 术语表
B站API中用到的英文术语非常混乱，为了便于交流与理解，列出了对应的YouTube名称以及个人推荐的用法供参考。

中文名|推荐英文名|B站英文名|YouTube英文名
-|-|-|-
弹幕（数）|danmaku|danmaku|N/A
评论[^注1]|comment|reply|comment
评论的回复|reply|reply|reply
P|episode|videos/p（？）|N/A
简介|description|desc/intro|description
动态|community|dynamic[^注2]|community
up主|uploader|up/upper[^注3]|uploader
收藏夹|playlist[^注4]|favorite/fav|playlist
被收藏（数）|favorite|favorite/collect[^注3]|N/A
播放数|views|view/play|views
[^注1]: 某些情况下评论和回复的总数会统称为评论数
[^注2]: dynamic这个词没有中文语境中“动态”的含义，完全就是误用。另外community（社区）是所有动态的统称，一条动态叫community post
[^注3]: 无话可说
[^注4]: 因为B站的收藏夹可以公开，也可以被别人播放，功能上更接近playlist

# 使用的API
这里给出的表格是我自己测试的结果，更详细的解释以及使用方法请参考[这里](https://github.com/SocialSisterYi/bilibili-API-collect/blob/master/comment/list.md)

## 视频
### 获取评论
https://api.bilibili.com/x/v2/reply?jsonp=jsonp&pn=1&type=1&oid=170001&sort=2&ps=49

### 获取评论的回复
https://api.bilibili.com/x/v2/reply/reply?jsonp=jsonp&pn=1&type=1&oid=170001&sort=2&ps=49&root=1796347201

`pn`：页码

`sort`：排序方式

`sort`值|排序方式|网页显示名称|旧版名称[^注5]
-|-|-|-
0|最新|按时间排序|默认排序
1|最热[^注6]|未使用|按赞同数
2|最热[^注6]|按热度排序|按回复数

[^注5]: 部分专题页面仍使用旧版评论区
[^注6]: 算法未知

`type`：哪种页面上的评论

`type`值|类型|备注
-|-|-
0|error|
1|视频（包括番剧、影视）|oid=av号，番剧和影视使用跳转前的av号
2|专题（blackboard/topic)|oid=url数字
3|非法值|未使用
4|专题（blackboard/topic）|url用的是随机字符串，oid仍为整数，应该是内部编号<br>不清楚为什么不沿用type=2
5|未知|可能是测试用的，除了oid=1之外都是“啥都木有”
6|小黑屋|oid=url数字
7|未知|可能和小黑屋有关
8|未知|可能是测试用的，除了oid=1之外都是“啥都木有”·
9|未知|
10|未知|
11|相簿动态|oid超级长
12|专栏|oid=cv号
13|未知|
14|音频|oid=au号
15|未知|可能和小黑屋有关
16|未知|视频？
17|文字动态|oid超级长
18|未知|
19|未知|
20|未知|
21|未知|
22|漫画|oid=mc号
...|...|...
33|课堂|oid=url数字

顺便一提，这几个type中有好几个oid=1的页面包含了b站程序员测试时留下的痕迹，顺便还能获得他们的uid（逃

### 获取基本信息
https://api.bilibili.com/x/web-interface/view?aid=170001

### 获取tag
https://api.bilibili.com/x/web-interface/view/detail/tag?aid=170001

### 获取简介
https://api.bilibili.com/x/web-interface/archive/desc?&aid=170001

### 获取分P信息
https://api.bilibili.com/x/player/pagelist?aid=170001

## 用户
### 获取收藏夹内容
https://api.bilibili.com/x/v3/fav/resource/list?media_id=976835796&pn=1&ps=20&keyword=&order=mtime&type=0&tid=0&platform=web&jsonp=jsonp

### 获取up主统计信息
https://api.bilibili.com/x/space/upstat?mid=2&jsonp=jsonp
https://api.bilibili.com/x/relation/stat?vmid=2&jsonp=jsonp