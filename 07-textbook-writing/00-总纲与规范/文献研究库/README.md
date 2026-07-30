# 文献研究库

本目录采用“四层结构”管理《现当代设计史》教材文献：

1. [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md)：书库范围、规则、进度、主要冲突和研究空白。
2. [`topics/`](topics/)：跨书专题综合，说明结论来自哪些书及其证据等级。
3. [`summaries/`](summaries/) 与 [`paper-summaries/`](paper-summaries/)：逐书、逐篇结构化摘要，来源类型分别管理。
4. [`../../../00-book/`](../../../00-book/) 与 [`../../../00-paper/`](../../../00-paper/)：原始书籍和论文Markdown，保持不改并作为最终回查依据。

辅助文件：

- [`BOOK_INDEX.md`](BOOK_INDEX.md)：人工阅读索引。
- [`BOOK_MANIFEST.jsonl`](BOOK_MANIFEST.jsonl)：稳定编号、哈希、读取进度和摘要状态。
- [`PAPER_INDEX.md`](PAPER_INDEX.md)：论文、书评、资料页等文件的人工阅读索引。
- [`PAPER_MANIFEST.jsonl`](PAPER_MANIFEST.jsonl)：论文层的稳定编号、哈希、读取进度和摘要状态。
- [`GLOSSARY.md`](GLOSSARY.md)：人物、机构、流派与术语。
- [`TIMELINE.md`](TIMELINE.md)：跨书核验后的年代与事件。

## 状态含义

- `reading_status: complete`：哈希对应的全文已经连续读完。
- `reading_status: in_progress`：正在逐段读取，不能视为全书结论。
- `summary_status: migrated-needs-evidence-locators`：已有完整审读判断，但尚需把每条可引用证据补成“章/节标题＋字符范围或图版号”。
- `summary_status: curated`：结构化摘要与证据定位已经人工复核；自动更新脚本不得覆盖。
- `summary_status: pending`：尚未生成逐书摘要。

## 同步更新链

```text
完成一部原文的连续全文读取与哈希核验
├─ 更新该书／该篇结构化摘要及证据定位
├─ 更新相关专题综合
├─ 更新 GLOSSARY
├─ 更新 TIMELINE
├─ 更新 PROJECT_CONTEXT 与处理进度
└─ 记录对教材章节“主要材料入口”的候选关系
```

以上工作是一个同步批次，不等待全库读完才开始。全库完成后的工作是交叉核验、消歧、去重、补缺和正式定稿，而不是首次生成这些文件。

若某部原文没有产生新术语、年代或书库级判断，也必须在其摘要中明确记录“本次无新增”，不能用未更新的空白状态代替判断。原文仍在 `in_progress` 时，可以记录带有“已读范围”标识的临时线索，但不得写成全书结论。

任何阶段都不得仅凭文件名或搜索命中替代全文判断。`00-paper/` 中题名标为“论文”的文件仍可能实际是书评、会议启事、目录、资料页或截断摘录，必须在逐篇摘要中明确来源性质与源文件缺陷。
