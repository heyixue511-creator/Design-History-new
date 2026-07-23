# REVIEW复核进度

> 当前状态：Step 3 已完成。全部既有增强报告均已通过质量检查或完成版本归并。

## 一、最终结果

- 初始`REVIEW`：33份；
- 升级为`COMPLETE`：32份；
- 转为`N/A（版本归并）`：1份（`0278 → 0504`）；
- 当前`REVIEW`：**0份**；
- 当前`COMPLETE`：**41份**；
- 当前`TODO`：541份；
- 当前`N/A`：7份；
- 有效增强目标：582份。

## 二、第一批：理论核心组

- `0503` Discovering Design；
- `0504` The Idea of Design；
- `0505` Design Studies: A Reader；
- `0508` Design History or Design Studies；
- `0511` World History of Design, Volume 1；
- `0512` World History of Design, Volume 2；
- `0513` An Introduction to Design and Culture；
- `0515` Design After Modernism。

## 三、第二批：Bauhaus与平面设计史

- `0152` Frank Whitford, Bauhaus；
- `0428` Walter Gropius, The New Architecture and the Bauhaus；
- `0448` Éva Forgács, The Bauhaus Idea and Bauhaus Politics；
- `0294` Meggs' History of Graphic Design。

## 四、第三批：UX／HCI与设计研究方法

- `0053` Bringing Design to Software；
- `0082` Contextual Design；
- `0122` The Design of Everyday Things；
- `0123` The Reflective Practitioner；
- `0194` A Pattern Approach to Interaction Design；
- `0258` The Semantic Turn。

## 五、第四批：社会设计、生态设计与产品文化

- `0061` Adversarial Design；
- `0105` Design Futuring；
- `0133` Universal Design: Creating Inclusive Environments；
- `0151` Objects of Desire；
- `0180` Designing for People；
- `0405` The Green Imperative；
- `0419` Design for the Real World。

> `0061`源报告存在题名与正文语料错配。增强稿已保留证据警示；后续取得可靠原文后需重新逐章核读。

## 六、第五批：设计文化、视觉传播与设计话语

- `0173` From Visual Culture to Design Culture；
- `0174` The Culture of Design；
- `0417` Design Discourse: History, Theory, Criticism。

版本治理：

- `0278`与`0504`均对应1995年《The Idea of Design: A Design Issues Reader》；
- `0504`语料更完整，作为规范主编号；
- `0278`转为`N/A（已归并）`。

## 七、第六批：普适设计与设计知识论论文

- `0444` Universal Design Handbook；
- `0011` Design Research and the New Learning；
- `0019` Designerly Ways of Knowing；
- `0059` Wicked Problems in Design Thinking。

> `0059`源报告资料卡题名被页眉误识别为“The MIT Press”，但正文、章节入口与论证均对应Buchanan论文。增强稿已记录该元数据问题。

## 八、Step 3质量标准

每份升级报告必须满足：

1. 显式映射规范源报告路径；
2. 达到实质篇幅，不以增加标题或关键词伪造完成；
3. 理论解析、设计史关联、批判性评估、研究使用四项中至少三项充分成立；
4. 明确证据边界、版本关系与语料风险；
5. 能用于论文问题、章节结构、课程教学或案例研究；
6. 经覆盖审计和REVIEW质量脚本自动验收。

## 九、Step 4：TODO生成阶段

下一阶段不再修补旧短稿，而是从541份`TODO`中新增完整增强报告。执行原则：

1. 优先补Batch 05、02、06的低覆盖领域；
2. 同时维持Batch 01、03、07理论主干的连续性；
3. 每批选择5—8份，先核对源报告质量、版本与重复关系；
4. 新报告直接采用Step 3形成的完整结构；
5. 每批完成后运行覆盖审计，新增文件必须直接进入`COMPLETE`，不得制造新的`REVIEW`；
6. 遇到语料错配、题名错误或重复版本，先治理再写作。

完整状态以以下自动生成文件为准：

- `03-enhanced-report/00-增强报告覆盖审计索引.md`
- `03-enhanced-report/00-增强报告覆盖审计明细.csv`
- `03-enhanced-report/00-REVIEW质量复核清单.md`
- `03-enhanced-report/00-重复与版本治理登记.md`
