# 备件报废审批图片校验 —— 完整案例复盘

> 案例来源：备件报废审批流程优化（制单人 → 工段长 → 专家组，单据类型 `BJSCRAP`），2026-08-10 ~ 08-13，工作目录 `D:\nccproject`。
> 本文是完整案例复盘；可复用模式见 [approval-picture-workflow.md](approval-picture-workflow.md) 与 [dingtalk-app-approval.md](dingtalk-app-approval.md)。

## 1. 需求演进与字段映射反复（本案例最大教训）

原始需求：制单人、工段长、专家组三级各必须上传照片；表头增加工段长/专家组图片字段；后台校验必传；前端 `index.js`（参考 505 行附近），后端 `N_BJSCRAP_APPROVE.java`（332 行附近写死，要求改成不写死）。

字段归属经历了两次大转向：

| 阶段 | 初版方案（v2.0 文档） | 最终确定 |
|---|---|---|
| 制单人 | def7/def8（bfwz/bfsw） | def7/def8（bfwz/bfsw）不变 |
| 工段长 | def9/def10（qrwztp/qrswtp） | def25/def26（qrwztp/qrswtp） |
| 专家组 | def25/def26（zjzqrwztp/zjzqrswtp） | def9/def10（zjzqrwztp/zjzqrswtp） |

教训：

- **字段编码的归属由历史数据决定，不是由“哪个字段空着”决定。** 用户历史上一直用 def9/def10 存专家组照片，因此专家组最终保留 def9/def10，工段长改用空字段 def25/def26。
- **对调字段编码时，附件目录后缀保持不变**（工段长仍是 qrwztp/qrswtp，专家组仍是 zjzqrwztp/zjzqrswtp），否则历史附件不可见。
- 实施前先把“字段编码 ↔ 显示名 ↔ 阶段 ↔ 附件后缀”四者的契约写死并让需求方确认，中途改动会带来前端、后端、模板、补丁的多处返工。

## 2. 最终契约

| 阶段 | 字段1 | 字段2 | 附件目录1 | 附件目录2 |
|---|---|---|---|---|
| 制单人 | def7 | def8 | bfwz | bfsw |
| 专家组 | def9 | def10 | zjzqrwztp | zjzqrswtp |
| 工段长 | def25 | def26 | qrwztp | qrswtp |

后端常量（`N_BJSCRAP_APPROVE.java`）：

```java
private static final String SECTION_POSITION_PICTURE = "qrwztp";     // 工段长 def25
private static final String SECTION_OBJECT_PICTURE  = "qrswtp";      // 工段长 def26
private static final String EXPERT_POSITION_PICTURE = "zjzqrwztp";   // 专家组 def9
private static final String EXPERT_OBJECT_PICTURE   = "zjzqrswtp";   // 专家组 def10
```

## 3. 架构演进（三轮）

1. **按角色字段判断（被否）**：用主表 `def14`（工段长用户）、`def15`（专家组用户）与当前登录人比对。问题：同一用户可兼任工段长与专家组。
2. **按工作流待办节点判断（采用）**：新增 `getCurrentApprovalStage()`，按当前用户在当前单据上的未处理待办解析出审批节点，再经自定义档案 `EMS_SCRAPFLOW` 翻译成阶段名。
3. **抽离集中规则类（收敛）**：新增 `ScrapPictureRule`（阶段归一 + 后缀映射）、`ScrapPictureValidator`（真实附件校验）、`ScrapPictureWorkflowGadget`（工作流插件）、`PfSparepartscrap_detailsCheck`（审批回调），并配 `ScrapPictureRuleTest` 单测，避免每个入口各写一套硬编码。

## 4. 关键机制与 SQL

阶段解析 SQL（参考 `N_BJSCRAP_APPROVE.getCurrentApprovalStage`，参数顺序：pk_group、billPk、currentUserId）：

```sql
select distinct pbt.activitydefid, cfg.name
  from pub_workflownote pw
  join pub_wf_task pbt on pw.pk_wf_task = pbt.pk_wf_task
  left join (select bd.code, bd.name
               from bd_defdoc bd
               join bd_defdoclist bdl on bd.pk_defdoclist = bdl.pk_defdoclist
              where bdl.code = 'EMS_SCRAPFLOW' and bd.pk_group = ?
                and nvl(bd.dr, 0) = 0 and nvl(bdl.dr, 0) = 0) cfg
    on cfg.code = pbt.activitydefid
 where pw.billid = ? and pw.checkman = ?
   and pw.dealdate is null and pw.ischeck = 'N'
```

要点：

- `EMS_SCRAPFLOW` 是**自定义档案编码**（`bd_defdoclist.code`），不是物理表，不能 `select * from EMS_SCRAPFLOW`。
- 阶段归一：`工段长` 精确匹配；`专家组`/`专家组1` 用 `startsWith("专家组")` 归一为 `专家组`；无法映射或同时存在多个不同阶段时显式抛业务异常，不要猜。
- 真实附件校验：`sm_pub_filesystem` 中 `nvl(dr,0)=0 and isfolder='n' and isdoc='z' and filepath like billPk||suffix||'%'`；字段有值 ≠ 附件真实存在（文件夹行不算）。

## 5. 最终改动文件清单

Web 前端（React）：

- `hbwork\src\ems\sparepartscrap\sparepartscrap_details\main\index.js`（制单/详情页：6 图片字段入口、修正 def9 查看后缀 bug、加 def25/def26）
- `hbwork\src\ems\sparepartscrap\sparepartscrap_detailsp\main\index.js`（审批中心页：上传按钮与字段）

Java 后端（报废模块 `ems\sparepartscrap`）：

- `N_BJSCRAP_APPROVE.java`（审批 Action：阶段解析 + 图片校验，前置到 `procFlowBacth` 前）
- `ScrapPictureRule.java`（新增，集中规则：`resolveStage` + `pictureSuffixes`）
- `ScrapPictureValidator.java`（新增，真实附件查询）
- `ScrapPictureWorkflowGadget.java`（新增，工作流 gadget）
- `PfSparepartscrap_detailsCheck.java`（审批 check 回调）
- `Sparepartscrap_detailsServiceImpl.java`（保存/服务实现）
- `test\...\ScrapPictureRuleTest.java`（新增，规则单测）

App 后端：

- `ems\appinterface\src\public\nccloud\api\ems\appinterface\riawf\DingdingServiceResources.java`（6 接口，见下）

## 6. App 后端 6 接口（DingdingServiceResources.java）

| 接口 | 用途 |
|---|---|
| `/getBJBFTaskBill` | 报废待办详情：def7/8/9/10/25/26 图片 + `stageName` |
| `/doAppBJBFAction` | 报废审批动作（doAgree 内按 taskid 解析阶段做图片校验） |
| `/getFilds` | BJSCRAP 分支：photoList=`bjphoto,def7,def8,def9,def10,def25,def26`，uploadList 同上 |
| `/updateScrap` | 保存审批图片，写回 def9/10/25/26 |
| `/getBJXFTaskBill` | 备件修复详情（仅编译兼容） |
| `/doAppBJXFAction` | 备件修复审批（仅编译兼容） |

App 前端 `processDetails` 上传字段曾硬编码 def9/def10，且页面不调用 `/getFilds`，导致工段长 def25/def26 只有标签没有“+”上传按钮——后端返回字段不足以保证前端出现上传入口。

## 7. 问题与解决时间线

- 本地/仿真页面不一致 → 账号问题，换账号解决。
- 制单人不上传也能提交 → 制单人校验在提交入口（`SaveSparepartreplaceAction`），属本期范围边界，未实现。
- 查不到 `EMS_SCRAPFLOW` → 是档案编码非表，改走 `bd_defdoc/bd_defdoclist`。
- 一人兼任工段长+专家组 → 按待办节点判断，不用角色字段。
- def9/def10 与 def25/def26 反复 → 按历史数据兼容确定专家组=def9/10、工段长=def25/26。
- 审批中心专家组图片无上传按钮 → 审批页前端 + 模板设置字段。
- 上传了还报错/传错字段 → 前端上传目录与后端校验后缀不一致，统一后缀。
- `BusinessException` message 为 null → class 字节码版本/部署问题。
- 仿真补丁缺上传按钮 → 补丁未打全/前端 bundle 未覆盖。
- SVN `Item is out of date` → 先 `svn update` 再合并。
- `DingdingServiceResources` 311/312/944 编译错误 → 改用 `getParent()`/`getChildrenVO()` 兼容。

## 8. 验证状态与遗留

已完成：Web 前端两页、Java 后端（集中规则 + 审批校验）、App 后端 6 接口（含 `getBJBFTaskBill` 的 `stageName`）。

验证：`ScrapPictureRuleTest` 单测覆盖阶段归一与后缀映射；用测试单据逐步验证工段长/专家组真实审批拦截。

遗留：

- App H5 前端 `processDetails` 上传字段需加 def25/def26（源码目录不在 NCC 常规目录，需另行定位）。
- `doAppBJBFAction` 的 stageName 输出（`getBJBFTaskBill` 已实现，`doAppBJBFAction` 内待补，按需处理）。
- 制单人强制校验未实现（属提交入口范围，需单独立项）。