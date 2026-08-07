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
| `ORG_DEPT_V` | 部门版本档案，`PK_VID` 是版本主键；业务表存部门主键时不要写版本主键 |
| `LCZJ_SUPPLIERDEDUCTION` | 供应商扣款单主表，`BILLNO`、`PK_DEPT`、`DEF1-5`、`CORIGCURRENCYID` |
| `LCZJ_SUPPLIERDEDUCTION_H` | 扣款单表体，`VBDEF1-20`、`CSOURCEBILLID/BID`、`REASON/MEMO`；来源字段常存来源单据主键 |
| `QC_REPORTBILL_B` | 质检报告表体，案例中合同号在 `VBDEF7` |
| `V_MATERIAL_PRICE_BJDJ` | 物料单价视图，`PK_MATERIAL`、`NQTORIGTAXPRICE`（含税单价） |
| `PO_ARRIVEORDER_B` | 到货表体，`PK_ARRIVEORDER_B`、`PK_MATERIAL`、`PK_ORDER`、`CSOURCEBID` |
| `PO_ORDER` | 采购订单主表，`PK_ORDER`、`VBILLCODE` |
| `PO_ORDER_B` | 采购订单表体，`NQTORIGTAXPRICE`、`VCONTRACTCODE` |
| `BD_PSNJOB` | 人员任职，`INDUTYDATE`、`ISMAINJOB`；取当前岗位用任职日期最新且主职记录 |
| `OM_POST` | 岗位，`PK_POST`、`POSTNAME` |

## 已验证字段语义

- `QC_REPORTBILL.PK_APPLYDEPT` 是报检部门主键；`PK_APPLYDEPT_V` 是部门版本主键；`PK_PUDEPT` 是物料所在车间部门。三者含义不同，写目标表前先确认目标字段存主档主键还是版本主键。
- 质检报告表没有物料名称列；取名称需用 `QC_REPORTBILL.PK_MATERIAL` 关联 `BD_MATERIAL_V`（按 `PK_MATERIAL` 分组取 `MAX(NAME)` 防重复）。
- 到货单主键（表头）与到货单表体主键不同：`PO_ARRIVEORDER.PK_ARRIVEORDER` 对 `PO_ARRIVEORDER_B.PK_ARRIVEORDER_B`。

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
