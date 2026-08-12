# 自定义参照与自动带出

## 标准结构

```text
表单字段 pk_x
→ initMeta 指定前端 refcode
→ 参照 index.js 指定列和 queryGridUrl
→ queryCondition 传主键过滤条件
→ 后端 DefaultGridRefAction 返回 RefMeta
→ 选择后事件读取 refpk/refcode/refname/values
→ 必要时调用详情 Action
→ setFormItemsValue 写入快照字段
```

## 后端 RefMeta

核对：

- `setPkField` 是真实主键；
- `setCodeField/setNameField` 是窗口显示字段；
- `setExtraFields` 包含前端列和选择后需要的扩展字段；
- 表名或子查询给每列稳定别名；
- `getExtraSql` 中的条件字段与前端 payload 完全一致；
- 每个业务表都处理 `nvl(dr,0)=0`；
- 一对多关联不会产生错误重复行。

## 过滤

过滤条件可以独立可选时，后端仅在值非空时拼接。前端传主键而不是编码。观察 Network 中 `busiParamJson.queryCondition`，确认实际值不是空字符串、`~` 或错误字段。

参照返回空的诊断顺序：

1. 在数据库用 payload 中同一主键执行等价 SELECT；
2. 检查主键来自哪个参照版本；
3. 检查关联列、`dr`、组织/数据权限过滤；
4. 检查后端响应 `rows/total`；
5. 若 rows 有值但窗口空，比较 `columnConfig.code` 与响应字段别名。

## 自动带出

只在参照结果稳定携带字段时直接读取 `value.values`。跨表信息、手机号、供应商或复杂关联使用详情 Action，避免把大量关联塞进参照查询。

清空参照时同步清空其派生字段。异步返回前确认上游选择仍是请求发出时的主键，避免旧请求覆盖新选择。

## 性能

不要一次加载全表。传分页参数、支持关键词检索，并为高选择性过滤列检查索引。1 分钟级参照响应不正常；先通过执行计划或等价 SQL 定位全表扫描/错误连接，再调整。
