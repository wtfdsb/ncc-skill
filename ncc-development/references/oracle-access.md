# Oracle SQLcl MCP 受控访问

## 前提

- SQLcl 25.2+ 与 Java 17/21 可用；
- SQLcl 连接已用 `-savepwd` 保存到 MCP 使用的同一 `-home`；
- Codex MCP 配置以 `sql ... -home <connection-store> -mcp` 启动；
- 修改配置后完全重启 Codex，并在新任务中确认 SQLcl 工具已出现。

SQLcl MCP 使用保存连接名，不需要把密码发给 Codex。若 `connmgr list` 有连接但当前任务无 SQLcl 工具，问题在 MCP 加载层，不在 Oracle 登录层。

## 执行分类

可直接执行：

- 单条 `SELECT`；
- 最终语句为 SELECT 的只读 `WITH`；
- 连接列表、当前 schema、表列定义等只读检查。

必须先确认：

- DML：`INSERT/UPDATE/DELETE/MERGE`；
- DDL：`CREATE/ALTER/DROP/TRUNCATE/RENAME`；
- PL/SQL、过程、函数、包、`CALL`；
- `GRANT/REVOKE` 和用户权限；
- 脚本、主机命令、多语句、动态 SQL；
- `EXPLAIN PLAN` 等可能写辅助表的命令；
- 无法可靠判定只读的任何输入。

## 确认合同

执行前必须展示：完整命令、保存连接、目标 schema/对象、预计影响行数或范围、是否可回滚、执行后 COMMIT/ROLLBACK 策略、DDL 隐式提交等风险。用户批准仅覆盖该版本命令。

## 查询卫生

- 先查列和关系，再查业务数据；
- 探索查询使用 `ROWNUM` 或分页限制；
- 只取需要列，不默认 `SELECT *`；
- 不输出敏感个人信息；
- 将查询结论标为“当前连接/当前时点验证”，不要永久写死易变数据。

## 常见连接错误

- `ORA-01017`：当次用户名/密码不匹配；
- `ORA-12514`：服务名不匹配；
- `ORA-12541`：监听器或端口不可达；
- 保存连接可由 `connmgr list` 查看，并用 `conn -name <name>` 验证。
