# 数据库地图与验证方法

以下是当前质量异议案例中已从代码或查询确认过的对象。用于定位，不代表其他环境结构完全相同。

| 对象 | 关键字段/用途 |
|---|---|
| `EMS_QUALITYOBJECTION` | 质量异议主表，`PK_QUALITYOBJECTION` 主键 |
| `QC_REPORTBILL` | 质检报告，`PK_REPORTBILL`、`VBILLCODE`、`NCHECKNUM`、`PK_PUDEPT` |
| `QC_APPLYBILL_S` | 质检申请/来源关联，案例通过 `PK_APPLYBILL` 与报告关联 |
| `PO_ARRIVEORDER` | 到货主表，`PK_ARRIVEORDER`、`DBILLDATE`、`PK_SUPPLIER` |
| `BD_MATERIAL_V` | 物料多版本视图，编码、名称、规格、型号等以实际列为准 |
| `PU_GRAPHPAPER` | 图纸档案，`PK_MATERIAL`、`VBILLCODE`；物料表 `GRAPHID` 是否可用需按数据验证 |
| `EMS_SPAREPARTREPLACE` | 备件更换主表，`PK_REPLACE`、部门等 |
| `EMS_SPAREPARTREPLACEON` | 上机记录，`PK_REPLACEON`、`ONCODE`、`ONDATE`、`PK_SPAREPART` |
| `EMS_SPAREPARTSRECEIVERECORD` | 领用记录，案例通过上机记录来源字段关联并取 `RECEIVE_TIME` |
| `SM_USER` | 用户，关联人员档案字段 `PK_PSNDOC` |
| `BD_PSNDOC` | 人员档案，手机号字段以当前环境列定义为准 |
| `ORG_DEPT` | 部门/车间名称，常用 `PK_DEPT` 关联 |

## 验证关系

1. 用 `USER_TAB_COLUMNS` 确认列名、类型、长度。
2. 分别查询两表样本主键和外键，确认值域相同。
3. 用内连接统计匹配数，再用左连接检查孤儿记录。
4. 统计一个主键对应几条记录，确认一对一或一对多。
5. 加入双方 `dr` 条件后重新统计。
6. 用页面 payload 中的真实主键验证等价 SQL。

## Oracle 注意事项

- 未提交 DML 只在当前会话可见；DDL 通常隐式提交。
- `ROWNUM` 与排序组合时需要子查询保证先排序再截取。
- `COUNT(column)` 不统计 NULL；验证“字段是不是 0”应同时查值分布，不能只看 count。
- `CHAR(20)` 可能带空格，连接异常时检查 `TRIM`，但不要先用函数掩盖错误关联。
- NCC 通常使用逻辑删除 `dr=0/NULL`，需按现有模块惯例处理。
