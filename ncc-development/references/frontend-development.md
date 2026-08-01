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

## 编译排错

`Unexpected token` 常由前一方法多/少一个大括号或把 `if` 放到类体导致。错误行经常只是解析器最终发现问题的位置；从上一个完整方法开始检查括号层级。
