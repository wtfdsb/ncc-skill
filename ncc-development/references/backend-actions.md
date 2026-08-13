# 后端 Action

## 一个 `.do` 请求的完整链路

```text
前端 URL
→ Action name（斜杠转换为点号）
→ action XML
→ Java clazz
→ 编译 class/JAR
→ 部署 yyconfig
→ authorize XML
→ 服务重启加载
```

例如请求 `/nccloud/ems/x/QueryThingAction.do` 通常对应 Action 名 `ems.x.QueryThingAction`。名称、大小写、包路径必须逐字符一致。

## 新增 Action 检查单

1. Java 类继承项目相邻 Action 使用的基类，并匹配方法签名。
2. 请求 DTO 与前端 payload 一致；确认 `pk`、Map 或自定义 DTO 的实际解析方式。
3. 返回字段名称与前端读取字段一致。
4. 在 `config/action/*.xml` 注册 `<name>` 与 `<clazz>`。
5. 在 `config/authorize/*.xml` 加入相同 Action 名。
6. 编译并部署 class/JAR；把 yyconfig 同步到服务实际加载目录。
7. 重启后端，再通过 Network 验证。

## 错误判别

- “找不到活动名”：Action 配置未加载、路径错误、XML 非法、class 未部署或服务未重启；不是普通 token 问题。
- HTTP 401 且响应包含找不到处理类：仍优先检查 ActionResource 链路。
- `Request unauthorized`：Action 已被路由但鉴权不通过时，比较同应用成功请求的认证信息及 authorize 配置。
- `argument type mismatch`：检查 VO 字段 Java 类型、前端传值形态及转换器；用 payload 定位具体字段。

## SQL 实现

先验证真实表关系和一对多情况。详情 Action 若可能返回多行，必须定义选择规则；不能依赖数据库“第一行”。优先使用参数化查询 API，限制返回列与行数。
