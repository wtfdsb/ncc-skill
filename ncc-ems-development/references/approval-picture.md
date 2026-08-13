# 审批图片校验（Web + App + 后端）

适用：审批流各节点必须上传照片并后台校验的场景（案例：备件报废 `BJSCRAP`，制单人→工段长→专家组）。

## 契约表（动手前先确认）

| 阶段 | 字段 | 附件目录 | 提示文案关键词 |
|---|---|---|---|
| 制单人 | def7 / def8 | bfwz / bfsw | 制单人 |
| 专家组 | def9 / def10 | zjzqrwztp / zjzqrswtp | 专家组 |
| 工段长 | def25 / def26 | qrwztp / qrswtp | 工段长 |

关键事实：

- 附件实体在 `sm_pub_filesystem`，`def*` 只是模板/展示入口，`filepath = billPk + 后缀`。
- **字段归属由历史数据决定，不由“哪个字段空着”决定**：专家组历史用 def9/10 就保留；工段长用空字段 def25/26。对调字段编码时**附件后缀保持不变**，否则旧数据不可见。
- `EMS_SCRAPFLOW` 是自定义档案编码（`bd_defdoclist.code`），不是物理表。
- 同一用户可兼多阶段 → 按**待办节点**判断，不按 def14/def15 角色字段判断。

## 阶段解析 SQL

参数顺序：`pk_group`、`billId`、`userId`。

```sql
select distinct pbt.activitydefid, cfg.name
  from pub_workflownote pw
  join pub_wf_task pbt on pw.pk_wf_task = pbt.pk_wf_task
  left join (select bd.code, bd.name
               from bd_defdoc bd
               join bd_defdoclist bdl on bd.pk_defdoclist = bdl.pk_defdoclist
              where bdl.code = 'EMS_SCRAPFLOW' and bd.pk_group = ?
                and nvl(bd.dr,0)=0 and nvl(bdl.dr,0)=0) cfg
    on cfg.code = pbt.activitydefid
 where pw.billid = ? and pw.checkman = ?
   and pw.dealdate is null and pw.ischeck = 'N'
```

- App 端简化版：只 `select cfg.name`，`ResultSetProcessor` 里 `next()?getString(1):null` 取第一条。
- 归一化：`工段长` 精确匹配；`专家组`/`专家组1` 用 `startsWith("专家组")`；查不到或同时多个不同阶段 → 抛业务异常，不要猜。
- `BaseDAO` 用 `try/catch/finally`，finally 里 `close()`；异常时保持返回 null，不影响原接口。

## 附件存在性校验

```sql
select 1 from sm_pub_filesystem
 where nvl(dr,0)=0 and isfolder='n' and isdoc='z'
   and filepath like :billPk || :suffix || '%'
```

字段有值 ≠ 附件真实存在（文件夹行不算）。

## 关键文件

- Web 前端：`hbwork/src/ems/sparepartscrap/sparepartscrap_details/main/index.js`（制单/详情页）、`.../sparepartscrap_detailsp/main/index.js`（审批中心页）——两页都要改，只改一页不生效。
- Java 后端：`ems/sparepartscrap/src/public/nc/bs/pub/action/N_BJSCRAP_APPROVE.java`（校验前置到 `procFlowBacth` 前）；集中规则 `nc/bs/ems/sparepartscrap/` 下 `ScrapPictureRule.java`（resolveStage + pictureSuffixes）、`ScrapPictureValidator.java`、`ScrapPictureWorkflowGadget.java`、`PfSparepartscrap_detailsCheck.java`；服务实现 `Sparepartscrap_detailsServiceImpl.java`。
- App 后端：`ems/appinterface/src/public/nccloud/api/ems/appinterface/riawf/DingdingServiceResources.java`。

## App 接口（DingdingServiceResources，@Path ems/riawf/webservice）

| 接口 | 作用 |
|---|---|
| `/getBJBFTaskBill` | 报废待办详情：def7/8/9/10/25/26 图片 + `stageName` |
| `/doAppBJBFAction` | 报废审批动作（doAgree 内按 taskid 校验图片） |
| `/getFilds` | BJSCRAP：photoList=`bjphoto,def7,def8,def9,def10,def25,def26`；uploadList 同上 |
| `/updateScrap` | 保存审批图片，写回 def9/10/25/26 |
| `/getBJXFTaskBill`、`/doAppBJXFAction` | 备件修复，仅编译兼容 |

约束：不新增 `@Path`、不改入参 `JSONString`、保持 `code/msg/data` 结构；只在既有对象补字段（如 `stageName`）。不写 App 前端按钮逻辑。

## 实施 checklist

- [ ] 前后端字段/后缀契约先写死并经需求方确认
- [ ] 前端两页都加字段 + 上传/查看入口，上传与查看用**同一后缀**（历史 bug：def9 查看用了 def7 后缀）
- [ ] 后端集中规则不写死（rule 类统一 resolveStage + pictureSuffixes）
- [ ] 校验前置到工作流处理前
- [ ] App `processDetails` 上传字段不能写死 def9/def10，要含 def25/def26（该页不调 `/getFilds`，改后端返回不会自动出按钮）
- [ ] 编译 + 打补丁含内部类（`$1/$2` class）+ 重启 NCC

## 测试矩阵

1. 两图都不传 → 拦第一张；只传第一张 → 拦第二张；都传 → 通过。
2. 文件落对后缀；另一阶段图片不满足本阶段。
3. 一人多角色 → 按待办节点校验。
4. 字段有值但附件已删 → 仍拦截。

## 常见坑

- `BusinessException` message 为 null → class 字节码版本 / 部署问题。
- 上传成功仍报错 → 前端上传目录与后端校验后缀不一致。
- 审批中心无上传按钮 → detailsp 页 + 模板设置 + 补丁没打全。
- SVN `Item is out of date` → 先 `svn update` 再合并。
- 查不到 `EMS_SCRAPFLOW` → 档案编码非表。
- 本地/仿真页面不一致 → 先查账号，再看模板/补丁。