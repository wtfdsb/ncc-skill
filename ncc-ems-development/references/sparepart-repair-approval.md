# 备件修复审批流程（已验证案例，90HA0605 / bjxfrw）

案例：备件修复任务单审批改为 `修复人 → 设备分包人 → 工段长 → 专家组`，每级审批强制上传对应照片。字段映射经数据库+源码双重核对。复用时重新核对，不要套用到备件报废。

## 最终字段映射（主表 ems_sparepartrepairtask）

| 阶段 | 字段 | 附件后缀 | 备注 |
|---|---|---|---|
| 修复人照片 | `bjphoto` | `billId`（空后缀） | `sqys()` 已校验+保存，审批类勿重复加 |
| 设备分包人照片 | `def10` | `sbfbrtp` | |
| 工段长照片 | `def11` | `gdzztp` | 同时校验 `gdz_value` 非空 |
| 专家组照片 | `def12` | `zjzztp` | |
| 旧工段长照片 | `def7` | `gdztp` | 停用：不返回/不保存/不校验，列与历史附件保留 |
| 旧机电车间主任照片 | `def8` | `zrtp` | 停用同上 |
| 设备分包人用户主键 | `def9` | — | 非照片，禁止挪作照片 |
| 工段长用户主键 | `spgdz` | — | |
| 专家组用户主键 | `spzjz` | — | 可能逗号/中文分号分隔，用 split+trim 精确匹配，勿 contains |
| 工段长工值 | `gdz_value` | — | 保留 |
| 厂长最终价 | `cz_value` | — | 保留 |

- `def7/def8` VARCHAR2(2000)；`def9/def10/def11/def12` VARCHAR2(101)，每级一张照片 101 够用。
- 照片存在必须查 `sm_pub_filesystem`，不能只看表头字段非空。

## 代码位置与改动

| 文件（相对项目根） | 关键改动 |
|---|---|
| `ems/appinterface/src/public/nccloud/api/ems/appinterface/riawf/DingdingServiceResources.java` | App REST：`getBJXFTaskBill` 返回 bjphoto/def10/def11/def12 及 `parent.stageName`；`doAppBJXFAction` 按节点校验照片（仅 doAgree）；`updateBjxf` 保存 def10/11/12；`getFilds` 增加 BJXF 分支；新增 `hasRepairPhoto`/`getRepairApprovalStageByTaskId` |
| `ems/sparepartrepairtask/src/public/nc/bs/pub/action/N_bjxfrw_APPROVE.java` | Web 审批：`procFlowBacth()` 前按 EMS_REPAIRFLOW 校验三级照片；删除机电车间主任校验；待办查询加 `nvl(pw.dr,0)=0` |
| `ems/sparepartrepairtask/src/private/nc/impl/ems/sparepartrepairtask/sparepartrepairtask/SparepartrepairtaskServiceImpl.java` | `sqys()` 改查 `sm_pub_filesystem` 真实附件，不再只信前端 `photo` |
| `hbwork/src/ems/sparepartrepairtask/sparepartrepairtask/main/index.js` | bjphoto/def10/def11/def12 上传/查看渲染 |
| `hbwork/src/ems/sparepartrepairtask/sparepartrepairtaskp/main/index.js` | 审批页同四级照片渲染，替换 def7/def8 语义 |

未改：BMF、VO、数据库结构；`def8` 列与历史 zrtp 附件；报废代码；`N_BJXF_APPROVE`（属备件修复台账 BJXF，非任务审批 bjxfrw）。

## 节点识别（EMS_REPAIRFLOW）

- 自定义档案 `EMS_REPAIRFLOW`：`activitydefid → 设备分包人/工段长/专家组`。
- App：`getRepairApprovalStageByTaskId(taskid)` 查当前 activitydefid。
- Web：按 `billid + checkman + dealdate is null + ischeck='N'` 查当前待办，再映射。
- `stageName` 是当前有效未处理节点（未提交/已结束为 null），不是上一或下一节点。
- 映射缺失或同一用户命中多个不同阶段待办 → 阻止审批并提示。

## 附件校验

`hasRepairPhoto(billId, suffix)`：
```sql
select 1 from sm_pub_filesystem
where nvl(dr,0)=0 and isfolder='n' and isdoc='z'
  and filepath like ?  -- billId+suffix+'%'
```
- billId/suffix 先判空并做字母数字下划线格式校验；参数化查询。
- 查询空或 size=0 视为未上传。
- 只在 doAgree/审批通过校验；doBack/doDisAgree/doReassign/doReject 不校验照片。

## 关键坑

1. 修复与报废字段不同，勿复用报废 `def25/def26`、`qrwztp`、`zjzqrwztp` 等映射。
2. `def9` 是设备分包人用户主键，源码 `sparepartrepairtask.setDef9(subcontractor)` 写入；禁止做照片。
3. 旧 bug：zrtp 查询误用 `isHaveFileSql` 而非 `isHaveFileJdcjSql`；删除机电主任校验时一并移除。
4. `updateBjxf`：def10/11/12 仅在参数非空时更新；gdzValue/czValue 仅在 JSON 存在且非空时更新，否则覆盖成 NULL。
5. `doAppBJXFAction` 修复人分支不能 suffix=null 调 `hasRepairPhoto`；修复人照片由 `sqys()` 保证。
6. 待办查询必须加 `nvl(pw.dr,0)=0`，否则匹配已删除流程记录。
7. `moveRepairPhoto` 要校验 billId 主键格式并核对任务/用户归属。
8. 子表为空时报“任务单详情数据异常”；测试单必须带 ≥1 条有效子表（`ems_sparepartrepairtaskb.pk_task`→主表）。
9. `repairSure()` 禁止修复人=设备分包人；造单走业务服务生成完整主子表后再把四级人员统一改为测试账号。
10. 前端源码在 `hbwork`；若存在多份工作区副本，先确认实际构建入口再改。

## 部署清单（仿真/补丁）

后端 class（放 `replacement/hotwebs/nccloud/WEB-INF/classes/`）：
- `nccloud/api/ems/appinterface/riawf/DingdingServiceResources.class` + 内部类 `$1…$N`
- `nc/bs/pub/action/N_bjxfrw_APPROVE.class`
- `nc/impl/.../SparepartrepairtaskServiceImpl.class`（改 sqys 时）

前端构建产物（勿直接复制 src）：
- `replacement/hotwebs/resources/ems/sparepartrepairtask/...`
- `replacement/hotwebs/nccloud/resources/ems/sparepartrepairtask/...`

## 单账号测试

- 四级人员字段 `repairuser/def9/spgdz/spzjz` 全指向测试账号的用户主键；表内存主键非字符串。
- 测试矩阵要点：修复人无照片失败；设备分包人/工段长/专家组无照片失败；工段长 `gdz_value` 空失败；机电车间主任不再校验；退回/驳回/转办不校验；Web/App 一致。