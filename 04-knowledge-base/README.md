# 设计史研究知识基础设施

## 一、项目定位

`04-knowledge-base`用于把仓库中的原始文献、深度报告、增强报告和审计结果，转化为可追溯、可验证、可计算、可比较、可扩展的设计史知识系统。

本目录不以教材写作为唯一目标，也不把深度报告的切块检索等同于知识库建设。知识库应同时支持：

- 学术论文、专著、教材与课程写作；
- 文献综述、概念史、思想史、史学史与研究方法分析；
- 人物、机构、运动、作品、技术、材料、媒介与事件研究；
- 版本、译本、术语和跨文献观点比较；
- 全球设计史、区域设计史与跨国传播研究；
- 知识图谱、时间线、地图、网络分析与文献计量；
- 档案整理、展览策划、专题数据库和公共知识产品；
- RAG问答、研究智能体、证据检索与研究问题生成。

## 二、与现有目录的关系

```text
00-book / 00-paper
        ↓ 原始语料与证据来源
01-book-report / 01-paper-report
        ↓ 文献级语义分析与证据定位
03-enhanced-report
        ↓ 文献级解释、关联和批判性分析
04-knowledge-base
        ↓ 原子知识、实体、关系、争议与任务视图
研究 / 写作 / 教学 / 策展 / 计算分析 / AI应用
```

现有目录继续保留，不被覆盖：

- `00-book/`、`00-paper/`：受控的原始文本层；
- `01-book-report/`、`01-paper-report/`：文献级分析层；
- `02-audit/`：源报告和证据锚点审计层；
- `03-enhanced-report/`：文献级增强解释层；
- `04-knowledge-base/`：跨文献知识组织层。

## 三、核心原则

1. 知识必须回到来源和证据，不以模型摘要作为最终证据。
2. 一条知识记录只表达一个主要命题。
3. 历史事实、作者主张、编辑判断、知识库综合和模型推断必须分开。
4. 时间、地域、媒介、对象和适用条件必须尽可能明确。
5. 不同学者的冲突解释并存，不强行合成为单一答案。
6. 版本、译本、节录、书评和OCR入口分别登记。
7. 未核定、证据不足和存在争议必须被显式保存。
8. 实体名称需要规范化，但原始名称和不同译名不得丢失。
9. 关系必须有证据支持，词语共现不能自动视为历史关系。
10. 知识只保存一次，通过专题视图和任务视图重复调用。
11. 向量检索只负责召回，不负责判定知识真值。
12. 全过程遵守仓库的权利治理和受限语料政策。

## 四、第一阶段目录

```text
04-knowledge-base/
├── 00-governance/
│   ├── knowledge-principles.md
│   ├── editorial-policy.md
│   └── confidence-and-version-policy.md
├── 01-schema/
│   └── core.schema.json
├── 02-controlled-vocabularies/
│   ├── knowledge-types.yml
│   ├── evidence-types.yml
│   ├── entity-types.yml
│   └── relation-and-status-types.yml
├── 03-pilot/
│   ├── 00-pilot-plan.md
│   ├── pilot-batch.json
│   ├── source-records.jsonl
│   ├── entry-records.jsonl
│   ├── anchor-evidence-records.jsonl
│   ├── content-candidate-records.jsonl
│   ├── comparison-evidence-records.jsonl
│   ├── comparison-query-fixtures.json
│   ├── pilot-review-queue.csv
│   ├── pilot-review-packets.json
│   ├── pilot-review-decisions.csv
│   └── example-records.jsonl
├── 04-audit/
│   ├── 00-audit-standard.md
│   ├── 01-pilot-candidate-audit.md
│   ├── 02-post-pilot-decisions.md
│   └── 03-comparison-model-pre-review.md
└── README.md
```

后续在试验批次通过后，再建立正式数据目录：来源、证据、实体、知识原子、概念、事件、关系、争议、专题视图、任务视图和导出层。

## 五、知识处理链

```text
文献登记
→ 版本与权利核定
→ 章节和证据单元切分
→ 原子知识抽取
→ 实体识别与消歧
→ 概念和术语规范
→ 关系建立
→ 争议与冲突识别
→ 跨文献验证
→ 人工复核
→ 专题和任务视图
```

## 六、成熟度等级

| 等级 | 含义 |
|---|---|
| `L0` | 文献已登记 |
| `L1` | 元数据、版本和权利状态已核定 |
| `L2` | 证据单元已结构化并可回查 |
| `L3` | 知识原子已抽取并完成类型标注 |
| `L4` | 实体、概念和关系已规范化 |
| `L5` | 已完成跨文献比较、冲突识别和来源互证 |
| `L6` | 已通过研究级人工复核，可进入正式应用 |

`COMPLETE`不再只由篇幅、标题或板块关键词决定。每个知识对象必须记录自己的成熟度、证据强度、置信度和复核状态。

## 七、权利边界

本知识库只在必要范围内保存证据定位、受控摘录和研究性转述。原始OCR全文继续受根目录`DATA_LICENSE.md`、`RIGHTS_POLICY.json`和`RIGHTS_AND_SOURCES.csv`约束。知识库记录不得把私有语料的技术可访问性解释为可公开再分发的授权。

## 八、当前阶段

当前已完成首批试验的`Phase A：来源与版本`，并进入`Phase B-D`候选抽取与人工复核：

- `pilot-batch.json`固定12项真实试验对象、最低数量和6组比较问题；
- `source-records.jsonl`登记12项来源，并从权利清单、深度报告审计和增强报告覆盖审计继承状态；
- `entry-records.jsonl`确定性登记原始OCR、深度报告和增强报告之间的结构入口关系；这些元数据证据不计入360条正文证据；
- `anchor-evidence-records.jsonl`导入已由深度报告审计确认可回查的正文锚点；它们仍是未绑定命题、未做语义复核的候选证据；
- `content-candidate-records.jsonl`为每项来源建立30条精确字符锚点、20条模型命题候选、13个词汇概念候选、10条弱文本提及关系和1个待核比较问题；所有记录均标记为机器候选且未做人工语义复核；
- `comparison-evidence-records.jsonl`按六组研究问题为每项来源补充6条定向、精确字符锚点；`comparison-query-fixtures.json`把两侧证据、命题和概念组织为可复现数据包，不自动输出历史结论；
- `pilot-review-queue.csv`确定性抽取48条命题（20%）、36个概念（超过20%）、全部12项争议、全部6组比较问题和全部高风险关系；`pilot-review-packets.json`汇集目标文本、来源和证据锚点；人工决定只写入`pilot-review-decisions.csv`，不会覆盖生成候选；
- `example-records.jsonl`只用于说明格式，不计入试验数量；
- 原先6项待核年份已补证，paper-0034增强报告入口已补齐，book-0019缺失锚点已按原文修复；全部来源权利仍为`UNVERIFIED/RESTRICTED`；
- 机械数量线已经满足，但命题原子性、概念规范化、关系语义、争议内容和六组比较结论仍须人工复核，不能据此将批次标为完成。

运行机械与批次一致性校验：

```bash
python -B tools/validate_knowledge_base.py
```

只有试验计划的所有数量目标和质量门槛完成后，才运行最终覆盖门：

```bash
python -B tools/validate_knowledge_base.py --require-complete
```

默认校验通过只表示当前已登记数据内部一致，不表示试验批次完成，更不表示语义、关系、历史判断或权利获得人工核定。在首批试验规则稳定之前，不对全部有效目标进行不可逆的批量转换。

人工复核决定的`decision`只能使用`APPROVED`、`REVISE`或`REJECTED`。最终门要求队列全部获得可追溯决定；其中命题须给出人工知识类型和必要的主张者，概念须给出规范名称，争议与比较须写明证据边界。空白决定表是有意的，不得由模型自动填充为`APPROVED`。
