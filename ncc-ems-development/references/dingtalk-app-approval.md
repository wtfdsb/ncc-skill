# DingTalk App 备件报废审批接口

适用：钉钉/掌上龙成 App 通过 REST 调用 NCC 审批中心，完成备件报废（及备件修复）审批、图片校验与字段返回。重点记录“审批节点中文名称 stageName”的解析与传出方式。

## 定位

| 对象 | 位置 |
|---|---|
| App 后端 REST | `D:\nccproject\ems\appinterface\src\public\nccloud\api\ems\appinterface\riawf\DingdingServiceResources.java` |
| 类注解 | `@Path("ems/riawf/webservice")`，继承 `BaseResource` |
| 工作流动作 | `nc.itf.uap.pf.IPFMobileAppServiceFacade`（`NCLocator.getInstance().lookup(...)`） |
| App 前端页面 | 运行时 `pages/spareParts/sparePartsProcessBF/processDetails`，源码不在 NCC 常规目录，需单独定位 |

先读文件确认当前行号，不要依赖本文的旧行号。

## 报废字段-阶段-附件目录映射

| 阶段 | 字段1 | 字段2 | 附件目录1 | 附件目录2 |
|---|---|---|---|---|
| 制单人 | def7 | def8 | bfwz | bfsw |
| 专家组 | def9 | def10 | zjzqrwztp | zjzqrswtp |
| 工段长 | def25 | def26 | qrwztp | qrswtp |

附件实体存在 `sm_pub_filesystem`，`def*` 字段本身只是模板/展示入口，实际文件以 `filepath = billPk + 后缀` 为前缀存储。校验必须要求真实文件：`nvl(dr,0)=0 and isfolder='n' and isdoc='z' and filepath like billPk||suffix||'%'`。

## 报废相关接口

| 接口 | 用途 |
|---|---|
| `/getBJBFTaskBill` | 获取备件报废待办详情，返回 def7/8/9/10/25/26 图片 URL，并传出 `stageName` |
| `/doAppBJBFAction` | 备件报废审批动作（doAgree/doBack/doDisAgree/doReassign/doReject/doAddApprover） |
| `/getFilds` | 返回可展示/可上传字段列表（BJSCRAP 分支：photoList=`bjphoto,def7,def8,def9,def10,def25,def26`，uploadList=`def7,def8,def9,def10,def25,def26`） |
| `/updateScrap` | 保存报废审批图片，写回 def9/10/25/26 |

备件修复对应 `/getBJXFTaskBill`、`/doAppBJXFAction`，不在报废需求内。

## 审批节点中文名称 stageName 解析

参考 `N_BJSCRAP_APPROVE.java` 的 `getCurrentApprovalStage`，App 端做简化版：查当前用户在指定单据上的第一条未处理待办，把 `activitydefid` 经 `EMS_SCRAPFLOW` 自定义档案翻译成中文节点名。

SQL（已核实可用）：

```sql
select distinct cfg.name
  from pub_workflownote pw
  join pub_wf_task pbt on pw.pk_wf_task = pbt.pk_wf_task
  left join (select bd.code, bd.name
               from bd_defdoc bd
               join bd_defdoclist bdl on bd.pk_defdoclist = bdl.pk_defdoclist
              where bdl.code = 'EMS_SCRAPFLOW' and bd.pk_group = ?
                and nvl(bd.dr, 0) = 0 and nvl(bdl.dr, 0) = 0) cfg
    on cfg.code = pbt.activitydefid
 where pw.billid = ?
   and pw.checkman = ?
   and pw.dealdate is null
   and pw.ischeck = 'N'
```

参数顺序：`pk_group`（`InvocationInfoProxy.getInstance().getGroupId()`）、`billId`、`userId`。

处理规则：

- 同一用户多条待办：`ResultSetProcessor` 里 `return resultSet.next() ? resultSet.getString(1) : null`，只取第一条。
- 查不到/未配置映射：`stageName = null`。
- 判空后再 `trim()`，避免 NPE：`stageName = result == null ? null : result.toString().trim()`。
- `BaseDAO` 用 `try/catch/finally`，`finally` 里 `dao.close()`；查询异常与关闭异常都吞掉并保持 `stageName = null`，不得影响原接口业务。
- 传出：在返回 `parent`/`data` 的 Map 里 `map.put("stageName", stageName)`，保持原有 `code/msg/data` 逻辑不变。

## doAppBJBFAction 内部结构

`doAppBJBFAction` 按 `actioncode` 分支处理：

- `doAddApprover` 加签
- `doAgree` 批准（内部先按 `taskid` 解析 stage 做图片校验，再调 `getService().doAgree(pk_group, userId, taskid, note, null)`）
- `doBack` 收回
- `doDisAgree` 不批准
- `doReassign` 转办
- `doReject` 驳回

注意：`doAgree` 分支里的旧 stage 查询是“按 taskid 校验图片用”，与“按当前用户待办解析 stageName 并传出”是两件事，不要混用。新需求在 `doAppBJBFAction` 内解析当前用户待办节点名并传出，不新增 `@Path`，不修改入参 `JSONString` 和返回结构。

## 响应与约束

- 统一 `resultMap` 返回 `code/msg/data`，用 `NCCRestUtils.toJSONString(resultMap)`。
- 不修改 `@POST/@Path`、不修改入参 `JSONString`、保持原返回结构；只允许在既有对象里补充字段（如 `stageName`）。
- 不写 App 前端、Vue、页面按钮显隐逻辑；按钮是否显示由前端既有规则与后端返回字段共同决定。

## App 前端教训（processDetails）

- 页面可上传字段曾写死为 `def9/def10`，未包含 `def25/def26`，导致工段长图片只有标签没有“+”上传按钮。
- 该页面不调用 `/getFilds`，所以只改 `/getFilds` 无法让按钮出现。
- 后端 `/getBJBFTaskBill` 已返回 `def25/def26`，但前端仍只给 `def9/def10` 生成上传组件。
- 结论：需要在前端上传字段判断里加入 `def25/def26`，且上传保存 payload 支持 `def25/def26` 并继续调用 `/updateScrap`。

## 相关文件

- 图片校验与双 React 页面、补丁打包：`approval-picture-workflow.md`
- 后端 `.do` Action 与 XML 注册：`backend-actions.md`
