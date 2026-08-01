# 质量异议上报案例（90HA0707）

此案例来自 EMS 设备管理模块，用于复用 NCC 开发方法，不可把字段关系或 `ems` 目录名盲目套用到其他模块。

## 已验证文件

| 用途 | 文件 |
|---|---|
| 主前端 | `<NCC_WORKSPACE>\<FRONTEND>\src\ems\qualityobjection\qualityobjection\main\index.js` |
| 质检报告参照前端 | `<NCC_WORKSPACE>\<FRONTEND>\src\ems\refer\qualityobjection\qcReportGridRef\index.js` |
| 上机单参照前端 | `<NCC_WORKSPACE>\<FRONTEND>\src\ems\refer\qualityobjection\sparepartReplaceOnGridRef\index.js` |
| 后端 Action | `<NCC_WORKSPACE>\ems\qualityobjection\src\client\nccloud\web\ems\qualityobjection\qualityobjection\action` |
| Action XML | `<NCC_WORKSPACE>\ems\qualityobjection\src\client\yyconfig\modules\ems\qualityobjection\qualityobjection\config\action\90HA0707_action.xml` |
| Authorize XML | `<NCC_WORKSPACE>\ems\qualityobjection\src\client\yyconfig\modules\ems\qualityobjection\qualityobjection\config\authorize\90HA0707_authorize.xml` |
| DDL | `<NCC_WORKSPACE>\ems\qualityobjection\script\dbcreate\ORACLE\00001\tb_qualityobjection.sql` |

## 已形成模式

- `pk_material` 用标准物料多版本参照，编码/名称/规格/型号/图号存快照。
- `pk_qcreport` 使用自定义表型参照；按车间、物料主键独立或组合过滤。
- 质检报告详情 Action 带出到货、供应商与检验主数量；异议数量校验为不大于报告数量。
- `pk_replaceon` 使用上机单参照，按物料主键过滤，带出上机编码、上机时间和领用时间。
- `internalcontact` 使用用户参照，详情 Action 通过用户关联人员档案读取手机号；没有手机号时阻止保存或提示更换联系人。
- 异议类型存枚举编码，查询区/表单/列表需分别配置显示。

## 关键经验

- 质检报告窗口的列名来自前端 `columnConfig`，值来自后端 `setExtraFields` 与子查询别名；任一不一致都会出现空列。
- 上机参照过滤必须传业务表实际使用的备件/物料主键；编码搜索不能替代主键关联。
- 联系人手机号不在用户表时，通过用户的人员档案外键查询，不能猜测手机号列。
- `TRANSTYPEPK` 的非空约束来自生成单据模型，新增必须获得交易类型上下文。
- Action 源码存在并不等于运行时可调用；XML、部署和重启缺一不可。
