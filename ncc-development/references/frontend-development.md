# NCC 前端开发

## 先定位区域

不要按旧行号插入。搜索方法名和区域编码：

```powershell
rg -n "initMeta|onAfterEventForm|setFormItemsValue|qualityobjection_form" <index.js>
```

- 元数据形态、参照路径、过滤函数：放入 `initMeta` 返回前。
- 字段变更联动：放入表单编辑后事件内部，与其他 `if (key === ...)` 同级。
- AJAX 查询方法：放在类体中，与其他箭头函数同级，不能嵌入另一个方法。
- 保存校验：放在统一保存入口，确保保存和保存新增都覆盖。

## 参照值结构

兼容常见结构：

```javascript
const pk = value && (value.refpk || value.value);
const code = value && (value.refcode || value.values?.code?.value);
const name = value && (value.refname || value.values?.name?.value);
```

先在 Console 查看真实 `value` 和 `value.values`，再决定字段名。参照列能显示不代表返回对象一定携带扩展字段。

## 枚举显示

- 表单/查询区：使用 `select` 并配置相同 `options`。
- 列表区：设置 `itemtype: 'select'` 和 `options`；旧组件不渲染时使用 `render(text, record)` 映射值。
- 数据库存值、表单值、列表映射必须采用同一编码，例如字符串 `'1'/'2'`。

## 联动规则

变更上游字段时先清除已经失效的下游字段，再按新值查询。不要在选择质检报告时清空作为筛选条件的物料，除非业务明确要求重新选择。

日期字段保持 NCC 可接受格式，与 VO/数据库类型一致。不要把复杂对象直接赋给字符串或日期属性，否则可能出现 `argument type mismatch`。

## 自定义参照必须进入构建入口

新建的自定义参照前端目录只放文件不会生效：页面不会请求对应 `GridRefAction.do`。必须同时：

1. 在前端 `config.json` 的 `patch.path`（或等价构建入口）中加入该 `index.js`；
2. 在 `initMeta` 中把表单字段设为 `itemtype: 'refer'`、`refcode: 'ems/refer/<module>/<refName>/index.js'`，并显式恢复 `visible/disabled/isMultiSelectedEnabled`；
3. 重新启动前端构建；新增入口仅热更新或 `Ctrl+F5` 不够。

## 多行文本框

页面模板设置“另起一行”和整行占用列数后，仍可能显示单行。在 `initMeta` 中强制设置：

```javascript
item.itemtype = 'textarea';
item.rows = 2;
```

不改数据库列类型；大文本字段通常保持 `VARCHAR2` 长度即可。

## 参照带出字段

- 跨表信息使用详情 Action，返回值必须与 `setFormItemsValue` 字段名一致。
- 更换或清空上游参照时同步清空其派生字段，避免残留旧值。

## 联系人按最新主职去重

内部联系人参照若出现一人多岗，从 `BD_PSNJOB` 按人员取 `INDUTYDATE` 最新且 `ISMAINJOB='Y'` 的记录，每人只显示一行，再按岗位名称过滤。

## 编译排错

`Unexpected token` 常由前一方法多/少一个大括号或把 `if` 放到类体导致。错误行经常只是解析器最终发现问题的位置；从上一个完整方法开始检查括号层级。
