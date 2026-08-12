# 质量异议上报案例（90HA0707）

此案例用于复用架构，不可把字段关系盲目套用到其他模块。

## 已验证文件

| 用途 | 文件 |
|---|---|
| 主前端 | `D:\nccproject\hbwork\src\ems\qualityobjection\qualityobjection\main\index.js` |
| 质检报告参照前端 | `D:\nccproject\hbwork\src\ems\refer\qualityobjection\qcReportGridRef\index.js` |
| 上机单参照前端 | `D:\nccproject\hbwork\src\ems\refer\qualityobjection\sparepartReplaceOnGridRef\index.js` |
| 后端 Action | `D:\nccproject\ems\qualityobjection\src\client\nccloud\web\ems\qualityobjection\qualityobjection\action` |
| Action XML | `D:\nccproject\ems\qualityobjection\src\client\yyconfig\modules\ems\qualityobjection\qualityobjection\config\action\90HA0707_action.xml` |
| Authorize XML | `D:\nccproject\ems\qualityobjection\src\client\yyconfig\modules\ems\qualityobjection\qualityobjection\config\authorize\90HA0707_authorize.xml` |
| DDL | `D:\nccproject\ems\qualityobjection\script\dbcreate\ORACLE\00001\tb_qualityobjection.sql` |

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

## 后续已验证扩展

- 质检报告窗口“部门”显示物料所在车间：`QC_REPORTBILL.PK_PUDEPT → ORG_DEPT.PK_DEPT`；不要误用 `PK_APPLYDEPT_V`。
- 质检报告表没有 `MATERIALNAME`，取物料名称需关联 `BD_MATERIAL_V` 子查询（`MAX(NAME)` 按 `PK_MATERIAL` 分组）。
- 选择质检报告带出合同号：`QC_REPORTBILL_B.VBDEF7` → 质量异议 `def1`；更换/清空质检报告时清旧值。
- 联系人按 `BD_PSNJOB` 最新 `INDUTYDATE` 且 `ISMAINJOB='Y'` 去重，每人一行，再过滤“工段长/车间主任”岗位。
- 异议描述、原因分析、损失情况在 `initMeta` 强制 `itemtype='textarea'`、`rows=2`，页面模板再配整行布局。
- 导出报“根据上机单无法获取到参照信息”：Excel 单据定义 XML 中自定义参照类型字段（`qc_reportbill`、`pd_wkg_mar`、`sparepartreplaceon`）且 `<basdoc>` 为空，改为 `String` 类型。
- 审批自动生成供应商扣款单的完整字段映射与坑位见 [quality-objection-approval-sync.md](quality-objection-approval-sync.md)。
