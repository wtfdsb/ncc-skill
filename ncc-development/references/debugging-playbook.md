# 排错手册

## 先收证据

| 症状 | 第一证据 |
|---|---|
| 页面空白 | 前端编译终端第一条 ERROR、Console 第一条业务错误 |
| 找不到活动名 | 请求 URL、Action XML、部署路径、class、服务启动日志 |
| 401 | Response 内容、Authorize XML、成功请求 Headers 对比 |
| 参照空 | Payload 条件、Response rows/total、等价 SQL |
| 有 rows 但列空 | Response 字段别名与 `columnConfig.code` |
| 保存类型不匹配 | 完整 payload、VO Java 类型、数据库列类型 |
| ORA-01400 | 报错列的 DDL 非空约束及新增默认数据来源 |
| 权限树无应用 | 应用/菜单有效记录、引用关系、组织类型、缓存 |

## 最小实验

一次只验证一个假设。例如参照无数据：先去掉所有可选过滤并保留 `dr`，确认基础查询有值；再逐个加回物料、部门和权限条件。不要同时改 SQL、前端字段名和权限。

## Network 阅读

1. URL 是否命中预期 Action；
2. HTTP 状态；
3. `busiParamJson` 反序列化后的字段；
4. `queryCondition` 主键值；
5. `defineItems` 与响应别名；
6. Response 的 `success`、`rows`、`page.total` 和业务消息。

## 重启边界

- 仅前端源代码且 dev server 热更新成功：通常强制刷新即可。
- Java class、Action/Authorize XML：部署后重启后端。
- 页面模板/应用菜单/权限：保存发布后可能需要清缓存、重新登录或服务重启。
- MCP 配置：完全退出并重启 Codex；旧任务可能仍持有旧工具快照，新任务用于最终验证。
