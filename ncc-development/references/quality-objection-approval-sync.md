# 质量异议审批自动生成供应商扣款单（已验证案例）

案例：质量异议上报审批通过后自动生成供应商扣款单。字段映射来自实际项目验证，复用时必须重新核对表结构、页面模板和目标字段，不能把 `ems` 模块的目录或字段关系盲目套用到其他模块。

## 代码位置

| 层 | 文件 |
|---|---|
| 审批动作 | `<NCC_WORKSPACE>\ems\qualityobjection\src\public\nc\bs\pub\action\N_ZLYYSB_APPROVE.java` |
| 生成规则 | `<NCC_WORKSPACE>\ems\qualityobjection\src\public\nc\bs\ems\qualityobjection\approve\action\rule\WriteSupplierDeductionAfterApproveRule.java` |
| 服务实现 | `<NCC_WORKSPACE>\ems\qualityobjection\src\private\nc\impl\ems\qualityobjection\qualityobjection\QualityobjectionServiceImpl.java` |
| 参考旧实现 | `<NCC_WORKSPACE>\qc\qc\src\private\nc\bs\qc\c004\approve\action\rule\WriteGYSKKDAfterRule.java` |

## 已验证字段映射

### 表头 `LCZJ_SUPPLIERDEDUCTION`

| 字段 | 来源 |
|---|---|
| `pk_supplier` | 质量异议 `pk_supplier` |
| `pk_org` / `pk_org_v` | 质量异议组织 |
| `def3` | `4`（扣款处理方式） |
| `corigcurrencyid` | 人民币主键（环境相关，须只读查询确认） |
| `def1` | 到货单号 |
| `def2` / `pk_psndoc` | 采购员（`po_arriveorder.pk_pupsndoc`） |
| `def4` | 采购订单号 |
| `def5` | 合同号 |
| `pk_dept` | `QC_REPORTBILL.PK_APPLYDEPT`（报检部门主键） |

### 表体 `LCZJ_SUPPLIERDEDUCTION_H`

| 字段 | 来源 |
|---|---|
| `vbdef1` | 含税单价 |
| `vbdef2` | 到货单表体主键 |
| `vbdef3` | 采购订单号 |
| `vbdef4` | 数量 |
| `vbdef5` | `4`（与表头 `def3` 一致） |
| `vbdef6` | 采购员 |
| `vbdef7` | 处理意见 |
| `vbdef8` | 到货单主键 |
| `vbdef10` | 合同号 |
| `vbdef12` | 物料编码 |
| `vbdef14` | 物资总价值（数量 × 单价） |
| `vbdef15` | 供应商主键 |
| `vbdef16` | 来源单据主键（追溯 + 防重复） |
| `vbdef17` | 物料主键 |
| `vbdef18` | 单价 |
| `vbdef19` | 数量 |
| `vbdef20` | 金额 |
| `csourcebillid` | 到货单主键 |
| `csourcebillbid` | 到货单表体主键 |
| `reason` / `memo` | 来源单据文本字段 |

## 单价来源

- 视图 `V_MATERIAL_PRICE_BJDJ`：`NQTORIGTAXPRICE`（单价）、`PK_MATERIAL`（物料主键）。
- 采购链路：来源单据 `PK_ARRIVALBILL` → `PO_ARRIVEORDER` → `PO_ARRIVEORDER_B`（按 `PK_MATERIAL`）→ `PO_ORDER`（`PK_ORDER`）→ `PO_ORDER_B`（`CSOURCEBID`；`NQTORIGTAXPRICE`、`VCONTRACTCODE`）。

## 关键坑

1. **生成时机**：不能先调规则再让流程改状态。规则在审批状态未变成 1 时拿到的 VO 是空壳，数据库也还是 `-1`；应在流程动作完成后调用，规则内再做数据库状态兜底。
2. **SQL 兜底回载**：审批动作的 SQL 回载必须包含规则需要的列，并按 `IRowSet` 实际下标赋值；少一列就等于规则拿不到字段。
3. **防重复**：生成前按表体来源字段检查是否已存在，存在则跳过。
4. **部门来源**：业务部门取来源单据关联质检报告后的 `PK_APPLYDEPT`；不要用质量异议自己的部门字段，也不要写入 `PK_APPLYDEPT_V`（版本主键）。缺失时记录警告，不猜部门。
5. **收回不清数据**：`UNSAVE` 流程不能直接保存流程返回的 VO（字段可能被清空）；先按原主键重新加载完整 VO，只改审批状态再更新。
6. **PFlow 动作名**：`PFlow` 动作类可能精确匹配 `SAVE/UNSAVE`，列表按钮可能传业务动作别名，表现为“操作成功但状态不变”。先确认前端实际传的 `actionName`，修正按钮/动作映射；不要在 PFlow 里放宽判断绕过。
7. **JNDI 报错**：`xxx is not found in jndi please deploy it` 表示模块服务未部署，不是规则代码错误；需部署接口、实现和 UPM，再重启。

## 部署检查

- 源文件编码必须与编译参数一致（GBK/UTF-8），不要混用。
- 编译产物部署到运行环境 `modules\<MODULE>\META-INF\classes\...`；用 `javap` 验证 class 包含预期方法/字符串。
- 服务启动时间必须晚于部署时间，否则加载的是旧 class；重启后用日志或反编译确认。
