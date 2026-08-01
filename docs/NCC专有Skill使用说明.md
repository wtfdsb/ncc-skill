# NCC 专有 Skill 使用说明

版本：1.0.0  
发布日期：2026-08-01  
Skill 名称：`ncc-development`

## 1. 用途与适用范围

`ncc-development` 用于辅助 NCC/NCCloud 项目的开发、扩展、诊断、部署与测试，覆盖：

- BMF 元数据、建表脚本、VO 与代码生成；
- NCC 前端 `index.js`、页面模板、参照、联动和自动带出；
- Java Action、Action/Authorize XML、`.do` 请求与鉴权；
- Oracle 表结构和只读数据核对；
- 应用注册、菜单、权限、审批流与部署排查。

Skill 面向整个 NCC 项目，不限定 EMS 模块。包内“质量异议上报”内容仅是经过实际项目验证的 EMS 案例，用于展示通用排查方法。

## 2. 安装

1. 解压 `ncc-development-v1.0.0.zip`，得到唯一目录 `ncc-development`。
2. 将该目录复制到：

   ```text
   %USERPROFILE%\.codex\skills\ncc-development
   ```

3. 确认以下文件存在：

   ```text
   %USERPROFILE%\.codex\skills\ncc-development\SKILL.md
   ```

4. 完全重启 Codex，或新建一个任务后再使用。

兼容其他 Agent 运行环境时，可另行复制到：

```text
~/.agents/skills/ncc-development
```

## 3. 基本使用

显式调用方式：

```text
使用 $ncc-development，帮我定位某 NCC 模块新增按钮对应的后端 Action。
```

也可以直接描述 NCC 开发问题；当任务明显涉及元数据、页面模板、Action、参照、Oracle 或部署时，Codex 会按 Skill 流程处理。

首次提问建议提供：

- 项目根目录，例如 `<NCC_WORKSPACE>`；
- 模块或组件名称；
- 应用编码、页面编码（如已知）；
- 报错文本、Network 请求或相关文件路径；
- 希望“只诊断”还是“直接修改”。

示例：

```text
使用 $ncc-development。项目根目录是 <NCC_WORKSPACE>，模块是 qualityobjection。
请检查“找不到活动名”错误，只做诊断，不修改文件。
```

```text
使用 $ncc-development，检查 BMF、VO、页面模板、前端 index.js、Java Action、XML 和数据库字段是否一致。
```

## 4. 只读检查脚本

Skill 内置 `scripts/check-ncc-module.ps1`，用于只读定位模块文件、应用编码和 Action 配置。

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check-ncc-module.ps1 `
  -Root '<NCC_WORKSPACE>' `
  -Scope 'module-a;frontend\src\module-a' `
  -Module 'qualityobjection' `
  -AppCode '90HA0707'
```

说明：

- `-Root` 必填，为当前同事自己的 NCC 工作区；
- `-Scope` 可选，多个范围用分号分隔；
- 脚本只读取文件，不修改代码或数据库；
- 包内没有写死任何人的本地目录。

## 5. SQLcl MCP 数据库接入（可选）

SQLcl MCP 可让 Codex在获得授权后直接执行 Oracle 结构查询和只读 SQL。每位同事需自行安装 SQLcl，并在本机创建连接；Skill 不携带账号、口令、地址或保存连接。

配置示例（占位符必须替换为本机路径）：

```toml
[mcp_servers.sqlcl]
command = '<SQLCL_HOME>\bin\sql.exe'
args = ["-home", '<SQLCL_CONNECTION_HOME>', "-mcp"]

[mcp_servers.sqlcl.env]
JAVA_HOME = '<JAVA_17_OR_21_HOME>'
```

连接安全要求：

- 账号和口令只在 SQLcl 的安全交互中输入，不写进 Skill、聊天、脚本或配置仓库；
- 建议由每位同事在本机 SQLcl 中保存命名连接；
- 即使数据库账号本身拥有写权限，Codex 仍按下述操作边界执行。

### 数据库操作边界

- 可直接执行：单条只读 `SELECT`、`WITH` 查询和表/列/索引等结构查询；
- 必须二次确认：任何 `INSERT`、`UPDATE`、`DELETE`、`MERGE`、DDL、PL/SQL、脚本、多语句或可能改变会话/数据库状态的命令；
- 二次确认前必须展示：连接名称、完整 SQL、目标对象、影响范围、风险、回滚方式以及是否提交；
- 未获得明确确认时，不执行写入或结构变更；
- 查询身份证号、手机号等敏感字段时，只在用户明确授权且业务必要时查询，并优先脱敏输出。

## 6. 推荐工作流

1. 先定位真实文件、页面编码、Action 名和数据库字段。
2. 再建立“前端字段 → VO 属性 → 数据库列 → 参照返回字段”的映射。
3. 对错误先复现和取证，再给修改方案。
4. 修改后按顺序验证：编译、`.do` 请求、返回结构、页面联动、保存 SQL、数据库结果。
5. Action/XML 调整后，确认部署目录正确，并按实际环境重启后端服务。

## 7. 更新与卸载

更新：

1. 备份本地自己添加的参考资料；
2. 用新版 `ncc-development` 目录整体替换旧目录；
3. 完全重启 Codex；
4. 新建任务执行一次 `$ncc-development` 验证。

卸载：删除以下目录并重启 Codex：

```text
%USERPROFILE%\.codex\skills\ncc-development
```

## 8. 常见问题

### 8.1 输入 `$ncc-development` 没有生效

检查目录层级，确保不是 `ncc-development\ncc-development\SKILL.md`；然后完全重启 Codex并新建任务。

### 8.2 Skill 找不到项目文件

Skill 不内置项目路径。请明确告诉 Codex 当前工作区 `<NCC_WORKSPACE>`、模块名和应用编码。

### 8.3 `.do` 请求提示“找不到活动名”

依次核对前端 URL、Action XML 的 `<name>`、Java `<clazz>`、XML 部署目录、类是否已编译部署以及后端是否重启。

### 8.4 SQLcl MCP 无法连接

先在 SQLcl 命令行中验证命名连接，再检查 MCP 配置中的 SQLcl、连接 home 和 Java 路径。不要在聊天中粘贴真实口令。

### 8.5 可以让 Codex 直接改数据库吗

可以提出要求，但所有非查询命令都必须先经过二次确认。没有明确确认时，Skill 只允许只读查询与结构检查。

## 9. 分发注意事项

- 不要把本机用户名、项目绝对路径、数据库地址、账号、口令、真实业务主键或个人信息加入公共版本；
- 新增案例时应抽象为通用方法，并使用 `<NCC_WORKSPACE>` 等占位符；
- EMS 案例可保留为参考，但不要将 NCC 其他模块错误地归入 EMS。
