# 项目地图

## 工作区约定

| 层 | 位置 | 说明 |
|---|---|---|
| NCC 工作区 | `<NCC_WORKSPACE>` | 团队项目根目录，由使用者提供 |
| 后端模块 | `<NCC_WORKSPACE>\<MODULE>` | Java、yyconfig、SQL、资源、组件；目录名以项目为准 |
| 前端工程 | `<NCC_WORKSPACE>\<FRONTEND>\src\<MODULE>` | 页面、公共前端和自定义参照；工程名以项目为准 |
| 元数据 | `<NCC_WORKSPACE>\<MODULE>\METADATA` 或具体模块目录 | BMF 位置必须实际搜索 |

不同模块可能同时存在模块工程、公共 `src`、部署目录和旧模块副本。先搜索，不能仅凭模块名推断。

## 定位命令

```powershell
rg --files <NCC_WORKSPACE> | rg '模块名|类名|应用编码'
rg -n "ActionName|字段编码|页面编码" <NCC_WORKSPACE>
```

## 层级核对

一个新增字段或联动通常可能涉及：

1. BMF 属性和数据库列；
2. 生成 VO 常量、字段、getter/setter；
3. 页面模板的查询区、表格区、表单区；
4. 前端 `initMeta`、编辑后事件、保存校验；
5. 后端 Action/Service/SQL；
6. Action 与 Authorize XML；
7. 编译产物和部署目录；
8. 应用、菜单、职务/角色权限、交易类型与审批流。

## 查找相似实现

优先级：同模块已工作代码 > 同业务工程相邻模块 > 平台标准代码 > 论坛片段。复制前比较包名、区域编码、字段编码、Action 名称、请求 JSON 结构和版本依赖。

EMS 质量异议的目录结构是已验证案例，不代表采购、财务、供应链等其他 NCC 模块采用相同目录名。
