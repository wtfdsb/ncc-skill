# 项目地图

## 已验证根目录

| 层 | 位置 | 说明 |
|---|---|---|
| EMS 后端 | `D:\nccproject\ems` | Java、yyconfig、SQL、资源、组件 |
| NCC 前端 | `D:\nccproject\hbwork\src\ems` | 页面与 EMS 公共前端 |
| 自定义参照 | `D:\nccproject\hbwork\src\ems\refer` | 参照入口 `index.js` |
| 元数据 | `D:\nccproject\ems\METADATA` 或具体模块目录 | BMF 位置需实际搜索 |

不同模块可能同时存在模块工程、公共 `src`、部署目录和旧模块副本。先搜索，不能仅凭模块名推断。

## 定位命令

```powershell
rg --files D:\nccproject\ems | rg '模块名|类名|应用编码'
rg --files D:\nccproject\hbwork\src\ems | rg '模块名|参照名'
rg -n "ActionName|字段编码|页面编码" D:\nccproject\ems D:\nccproject\hbwork\src\ems
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

优先级：同模块已工作代码 > 同 EMS 工程相邻模块 > 平台标准代码 > 论坛片段。复制前比较包名、区域编码、字段编码、Action 名称、请求 JSON 结构和版本依赖。
