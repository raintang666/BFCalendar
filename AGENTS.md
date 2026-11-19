## 公开 API 兼容性

- 重构和性能优化优先只调整内部实现，尽最大可能保持用户使用的公开 API 不变，包括类名、构造参数、方法签名、回调和自定义样式扩展入口。
- 现有调用方式和方法覆盖应继续有效；为兼容行为补充必要的回归验证。
- 只有在确实无法兼容时才更新公开 API。保留原有方法作为兼容入口，并使用 `@Deprecated` 标注替代 API 和迁移方式；在文档中说明变更。

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
