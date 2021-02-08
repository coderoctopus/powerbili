# PowerBili
用于原样保存哔哩哔哩上的UGC（用户生成内容）

# 支持的内容
1. 评论（支持几乎所有评论区，详见下）
2. 视频统计数据

# 使用的API
## https://api.bilibili.com/x/v2/reply?jsonp=jsonp&pn=1&type=1&oid=170001&sort=2&ps=49
## https://api.bilibili.com/x/v2/reply/reply?jsonp=jsonp&pn=1&type=1&oid=170001&sort=2&ps=49&root=1796347201

`pn`是页码，每页固定显示20条评论。

`sort`是排序方式

`sort`值|排序方式|网页显示名称|旧版名称*
-|-
0|最新|按时间排序|默认排序
1|最热**|未使用|按赞同数
2|最热**|按热度排序|按回复数

*部分专题页面仍使用旧版评论区。

**算法未知。

`type`代表是哪种页面上的评论

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

## https://api.bilibili.com/x/web-interface/archive/stat?aid=170001
## https://api.bilibili.com/x/web-interface/archive/stat?bvid=BV17x411w7KC

self-explanatory
