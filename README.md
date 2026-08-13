# NCC Development Skill

面向 NCC / NCCloud 项目的专有 Codex Skill，用于辅助开发、扩展、诊断、部署和测试。

## 支持范围

- BMF 元数据、数据库表、VO 与代码生成
- NCC 前端 `index.js`、页面模板、参照、联动与自动带出
- Java Action、Action/Authorize XML、`.do` 请求和鉴权
- Oracle 表结构及只读数据核对
- 应用注册、菜单、权限、审批流和部署排查

该 Skill 适用于整个 NCC 项目，不限定 EMS 模块。EMS 质量异议内容仅作为经过项目验证的参考案例。

## 安装

### 方式一：使用发布压缩包

1. 下载 [`release/ncc-ems-development-v1.2.0.zip`](release/ncc-ems-development-v1.2.0.zip)。
2. 解压后得到 `ncc-ems-development` 目录。
3. 将目录复制到：

   ```text
   %USERPROFILE%\.codex\skills\ncc-ems-development
   ```

4. 完全重启 Codex，或新建一个任务。

### 方式二：直接复制源码目录

将仓库中的 [`ncc-ems-development`](ncc-ems-development) 目录复制到 `%USERPROFILE%\.codex\skills\`。

## 使用

```text
使用 $ncc-ems-development，帮我定位某 NCC 模块新增按钮对应的后端 Action。
```

首次提问建议提供项目根目录、模块名称、应用/页面编码、报错文本或 Network 请求，并明确希望“只诊断”还是“直接修改”。

完整说明：

- [中文 Markdown 使用说明](docs/NCC专有Skill使用说明.md)
- [中文 Word 使用说明](docs/NCC专有Skill使用说明.docx)

## SQLcl MCP

Skill 包含可选的 SQLcl MCP 接入规范。数据库连接由使用者在本机单独配置，仓库不保存数据库地址、账号或口令。

- 单条 `SELECT`、`WITH` 和结构查询可按只读流程执行；
- DML、DDL、PL/SQL、脚本或其他状态变更命令必须先展示完整影响并获得二次确认；
- 查询身份证号、手机号等敏感字段时，需要明确业务授权并优先脱敏输出。

## 安全说明

公开内容已移除个人目录、数据库连接、账号口令、真实业务主键和个人信息。新增案例时请继续使用 `<NCC_WORKSPACE>` 等占位符。

## 版本

当前发布版本：`1.2.0`  
校验值见 [`SHA256SUMS.txt`](SHA256SUMS.txt)。
