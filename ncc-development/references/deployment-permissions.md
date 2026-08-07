# 注册、部署与权限

## 三类状态不要混淆

1. 应用注册/菜单注册存在；
2. 权限管理可分配；
3. 用户拥有角色并能访问/调用 Action。

三者依赖不同记录和缓存。应用页面能看到不等于职务“分配应用”一定出现。

## Action 配置部署

源码中常见位置：

```text
<module>\src\client\yyconfig\modules\ems\<component>\<subcomponent>\config\action\*.xml
<module>\src\client\yyconfig\modules\ems\<component>\<subcomponent>\config\authorize\*.xml
```

服务运行时需要在实际 `home\hotwebs\nccloud\WEB-INF\extend\yyconfig\modules\...` 或由部署工具解压到等价位置。路径必须含 `action`/`authorize` 对应目录关键字，XML 必须合法。同步后重启后端。

## 应用与菜单

检查 `SM_APPREGISTER`、`SM_APPMENUITEM` 时：

- 同一应用/菜单可能因脚本重复执行产生两条有效记录；
- `APPID`、`PK_APPREGISTER`、菜单记录引用必须匹配；
- `MENUDES`、`PARENTCODE`、组织类型、启用状态和 `dr` 会影响权限树；
- 直接改库前先做只读对比，任何 UPDATE/DELETE 都须明确审批和回滚方案。

## 交易类型与审批流

若表中 `TRANSTYPEPK` 非空，新增加载必须来自交易类型小应用上下文或明确默认值。不要靠伪造常量绕过；确认应用参数、交易类型发布和单据类型配置。

审批流先确定单据类型、交易类型、组织范围和提交动作。提交/收回能否调用同时依赖前端按钮、Action、流程定义和单据状态。

## JNDI 组件未部署

`xxx is not found in jndi please deploy it!` 表示对应接口/服务没有注册进运行时，不是代码调用错误。检查顺序：

1. public 接口、private 实现、`META-INF/*.upm` 是否齐全；
2. 是否重新部署了整个模块（不只复制单个 class）；
3. 是否在部署后完整重启；
4. 同一模块手动建单/保存能否成功，排除模块级未加载。

## 前端补丁包结构

NCC 前端补丁 ZIP 通常必须同时包含两套前端资源目录，只放一套会导致页面 404：

```text
replacement/hotwebs/resources/<module>/...
replacement/hotwebs/nccloud/resources/<module>/...
```

后端 class 与 XML 放在：

```text
replacement/hotwebs/nccloud/WEB-INF/classes/...
replacement/hotwebs/nccloud/WEB-INF/extend/yyconfig/modules/...
```

新增自定义参照时，除上述资源外还要把参照 `index.js` 加入前端 `config.json` 的 `patch.path`，并用项目自带补丁脚本重新打包，不能只复制源码目录。
