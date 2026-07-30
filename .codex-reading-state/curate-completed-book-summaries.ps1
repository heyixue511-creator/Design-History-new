param(
    [string]$RepoRoot = 'D:\Design-history-new'
)

$ErrorActionPreference = 'Stop'

$libraryRoot = Join-Path $RepoRoot '07-textbook-writing\00-总纲与规范\文献研究库'
$summaryRoot = Join-Path $libraryRoot 'summaries'
$manifestPath = Join-Path $libraryRoot 'BOOK_MANIFEST.jsonl'
$assessmentPath = Join-Path $RepoRoot '.codex-reading-state\source-assessments.md'

function Escape-YamlSingleQuote {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return '' }
    return $Value.Replace("'", "''")
}

function Get-AssessmentBlocks {
    param([string]$Body)

    $blocks = [System.Collections.Generic.List[object]]::new()
    $pattern = '(?m)^-[ \t]+(?<label>[^：:\r\n]+)[：:](?<head>[^\r\n]*)(?<nested>(?:\r?\n[ \t]+[^\r\n]*)*)'
    foreach ($match in [regex]::Matches($Body, $pattern)) {
        $blocks.Add([pscustomobject]@{
            Label = $match.Groups['label'].Value.Trim()
            Head = $match.Groups['head'].Value.Trim()
            Nested = $match.Groups['nested'].Value.TrimEnd()
        })
    }
    return @($blocks)
}

function Format-Block {
    param([object]$Block)

    $text = if ([string]::IsNullOrWhiteSpace($Block.Head)) {
        "- **$($Block.Label)**："
    } else {
        "- **$($Block.Label)**：$($Block.Head)"
    }
    if (-not [string]::IsNullOrWhiteSpace($Block.Nested)) {
        $text += [Environment]::NewLine + $Block.Nested
    }
    return $text
}

function Render-Labels {
    param(
        [object[]]$Blocks,
        [string[]]$Labels,
        [string]$EditorialNote
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrWhiteSpace($EditorialNote)) {
        $parts.Add($EditorialNote.Trim())
    }
    foreach ($label in $Labels) {
        $match = $Blocks | Where-Object Label -eq $label | Select-Object -First 1
        if ($null -ne $match) {
            $parts.Add((Format-Block -Block $match))
        }
    }
    if ($parts.Count -eq 0) {
        throw "Curated section has no content. Labels: $($Labels -join ', ')"
    }
    return $parts -join ([Environment]::NewLine + [Environment]::NewLine)
}

$configs = @{
    'book-0001' = @{
        Summary = '本书是无印良品企业及核心参与者对品牌历史、产品原则、视觉传播和空间扩张的自我叙述。它有一手参与者材料价值，但宣传性与品牌正当化倾向明显；依照教材总纲，保留审读记录但不作为正文案例或主要引文。'
        Topics = "['企业设计系统', '消费伦理', '视觉识别', '零售空间']"
        Material = @('全文状态', '文献性质')
        Content = @('内容范围')
        Core = @('候选议题')
        Sources = @('内容范围')
        Limits = @('证据边界')
        Relations = @('候选议题')
        Use = @('使用约束')
        EntityNote = '- **关键参与者与机构**：良品計画、西友、堤清二、田中一光、小池一子、杉本贵志、深泽直人、原研哉；并涉及产品供应、广告、店铺、住宅、露营地和海外市场等组织环节。'
        TimelineNote = '- **主要过程**：以1980年创立为起点，追踪从早期产品三原则到独立店铺、海外扩展、住宅及生活方式项目的企业叙事。具体年代、项目名称和图版须回查原书。'
    }
    'book-0002' = @{
        Summary = '这是项目内部的补充书目索引，不是历史文献或学术论证。其价值仅在于查漏、导航和发现设计史／设计研究／全球设计史候选材料，不能作为教材正文参考文献。'
        Topics = "['文献导航', '设计研究学科史', '全球设计史方法']"
        Material = @('全文状态', '文献性质')
        Content = @('内容范围')
        Core = @('候选议题')
        Sources = @('内容范围')
        Limits = @('使用约束')
        Relations = @('候选议题')
        Use = @('使用约束')
        EntityNote = '- **索引涉及的主要作者**：Victor Margolin、Richard Buchanan、Hazel Clark、David Brody、Kjetil Fallan、Penny Sparke等；所有条目仍须分别回到原著或论文核验。'
        TimelineNote = '- **时间性质**：索引跨越现代设计史、设计研究形成及全球史转向等不同阶段，但自身不提供可核验的年代论证。'
    }
    'book-0003' = @{
        Summary = 'Laermans以1860—1914年巴黎、纽约和芝加哥的早期百货商店为中心，说明现代消费文化并非战后突然出现，而是在零售制度、城市空间、视觉陈列、性别秩序和阶级身份的共同作用中形成。文章同时修正“第一家现代百货商店”的发明神话。'
        Topics = "['百货商店', '消费文化', '城市视觉文化', '性别与公共空间']"
        Material = @('全文状态', '文献性质')
        Content = @('核心论证')
        Core = @('核心论证')
        Sources = @('主要史料与理论对话')
        Limits = @('证据边界')
        Relations = @('主要史料与理论对话', '候选议题')
        Use = @('候选议题')
        EntityNote = '- **关键机构与案例**：Bon Marché、Macy''s、Wanamaker、Marshall Field等百货企业；理论对话涉及Zola、Walter Benjamin、Bourdieu、Baudrillard、Haug、Sennett、Miller、Leach、Bowlby、Ewen和Perrot。'
        TimelineNote = '- **时空范围**：1860—1914年的巴黎、纽约与芝加哥；重点事件不是单一“发明”，而是固定价格、自由进入、橱窗、广告、部门化经营、服务设施和城市观看方式的长期组合。'
    }
    'book-0004' = @{
        Summary = '《A Color Notation》把色彩从含混的传统命名转化为可记录、比较和复现的三属性体系，并把艺术教育、心理物理测量与工业标准化连接起来。1967年第十二版混合了1905年原始思想、1915／1929年扩展和后世修订，引用时必须区分层次。'
        Topics = "['孟塞尔色彩体系', '设计教育', '色彩标准化', '艺术与工业']"
        Material = @('全文状态', '文献性质')
        Content = @('历史线索', '核心体系', '色彩构成论', '教育与工业意义')
        Core = @('核心体系', '色彩构成论', '教育与工业意义')
        Sources = @('历史线索')
        Limits = @('证据边界')
        Relations = @('候选议题')
        Use = @('候选议题')
        EntityNote = '- **人物、机构与出版物**：Albert H. Munsell、Massachusetts Normal Art School；1905年《A Color Notation》、1915年《Atlas of the Munsell Color System》、1929年《Book of Color》，以及后续编辑和标准化机构。'
        TimelineNote = '- **形成过程**：1858年Munsell出生；1898年前后因教学需要开始建构体系；1905、1915、1929年分别形成原著、图谱和扩展色样；1967年版又纳入后期术语与反射率修订。'
    }
    'book-0005' = @{
        Summary = 'Peter Adam的Eileen Gray传记综合档案、书信、账簿、照片、同期刊物、展览材料和作品目录，能够重建Gray从漆艺、织毯和家具走向室内与建筑的跨媒介实践。它也是带有亲近关系和作者解释框架的二手传记，涉及心理、性别、署名和跨文化问题时必须分层使用证据。'
        Topics = "['Eileen Gray', '装饰艺术', '现代住宅', '女性设计史', '作者身份']"
        Material = @('全文状态', '文献性质')
        Content = @('全文内容范围', '核心历史议题')
        Core = @('核心历史议题')
        Sources = @('可用史料链')
        Limits = @('证据边界与质量问题')
        Relations = @('章节匹配候选', '初步使用定位')
        Use = @('章节匹配候选', '初步使用定位')
        EntityNote = '- **人物、机构与作品**：Eileen Gray、Sugawara、Jean Badovici、Le Corbusier、Louise Dany；Jean Désert、UAM、CIAM及多种设计／建筑期刊；重点作品包括rue de Lota、Monte Carlo室内、E.1027、Tempe à Pailla、Lou Pérou，以及多项社会设施和预制建筑方案。'
        TimelineNote = '- **历史过程**：从1878年家庭与教育背景写起，覆盖巴黎装饰艺术实践、1920年代家具与建筑转向、1930年代社会项目、战争与流亡、战后重建及晚年重新进入展览和收藏体系。'
    }
    'book-0006' = @{
        Summary = '《Global Design History》不是按国家排列的世界设计通史，而是一部方法论文集。全书以“论文—回应”结构，把物、人、技术、资本、制度和意义的连接、翻译与不对称流动置于中心；教材必须同时呈现原作者命题和回应者的纠偏。'
        Topics = "['全球设计史', '连接史', '殖民与现代性', '跨区域流动', '设计史方法']"
        Material = @('全文状态', '文献性质')
        Content = @('全书方法框架', '各章主要内容及可用定位')
        Core = @('全书方法框架', '可复用的证据组织方式')
        Sources = @('各章主要内容及可用定位', '可复用的证据组织方式')
        Limits = @('证据边界与风险')
        Relations = @('主要章节匹配候选')
        Use = @('主要章节匹配候选')
        EntityNote = '- **编者与案例网络**：Glenn Adamson、Giorgio Riello、Sarah Teasley主编；案例覆盖威尼斯物质文化、景德镇瓷器、印度棉纺织、日本茶道、国际展览、电话网络、Werkbund、印度与土耳其现代设计、跨国时尚、中国早期社交网站、全球建筑史和加纳设计援助。'
        TimelineNote = '- **时空组织**：从早期现代全球贸易延伸到20世纪国家制度、殖民体系和21世纪数字平台。各章时代与地域差异很大，不应拼接成单线进步史。'
    }
    'book-0007' = @{
        Summary = 'Adburgham的Liberty百年企业传记保存了公司档案、目录、账簿、员工刊物、回忆和经营细节，可追踪零售、生产、品牌、设计者和帝国贸易网络。其纪念性企业史立场及“东方宝藏”修辞要求与后殖民、劳工和供应链研究交叉使用。'
        Topics = "['Liberty', '审美运动', '新艺术', '帝国贸易', '零售与品牌']"
        Material = @('全文状态', '文献性质')
        Content = @('核心历史线索')
        Core = @('核心历史线索')
        Sources = @('可用史料链及证据等级')
        Limits = @('证据边界与风险')
        Relations = @('章节匹配候选', '初步使用定位')
        Use = @('章节匹配候选', '初步使用定位')
        EntityNote = '- **人物、机构与产品体系**：Arthur Lasenby Liberty、E. W. Godwin、Thomas Wardle、Oscar Wilde、Whistler、Kate Greenaway、Voysey、Archibald Knox、Silver Studio；涉及Cymric银器、Tudric白镴、纺织品、服装、家具、Regent Street店铺及跨国分店与代理网络。'
        TimelineNote = '- **主要过程**：以1875年创业为中心，追溯1862年国际展览和东方商品零售前史，继而讨论19世纪末审美运动、20世纪初Art Nouveau与“Stile Liberty”、两次大战之间的组织惯性及后续企业复兴。'
    }
    'book-0008' = @{
        Summary = 'Dawn Ades以摄影蒙太奇为核心，梳理其在先锋艺术、印刷传播、政治宣传、广告和大众文化之间的多重路径。全书的价值在于把作品形式、复制技术、刊物、展览与政治语境并置；“发明者”和单一起源必须谨慎处理。'
        Topics = "['摄影蒙太奇', '达达', '构成主义', '政治宣传', '大众传播']"
        Material = @('全文状态', '文献性质')
        Content = @('概念与方法边界', '主要历史链条')
        Core = @('概念与方法边界', '主要历史链条')
        Sources = @('史料组织和可用性')
        Limits = @('证据风险')
        Relations = @('章节匹配候选', '初步使用定位')
        Use = @('章节匹配候选', '初步使用定位')
        EntityNote = '- **人物、团体与媒介**：重点涉及柏林达达、俄国构成主义、超现实主义以及相关艺术家、摄影师、设计师、杂志、海报、书籍和展览。人物归属和作品年代须按图录与原始刊物逐项核验。'
        TimelineNote = '- **历史链条**：以第一次世界大战后先锋艺术为重要节点，延伸至两次大战之间的革命宣传、商业广告和反法西斯视觉文化，并讨论战后摄影蒙太奇的延续与再解释。'
    }
    'book-0009' = @{
        Summary = '2019年选集把Loos不同时期关于装饰、建筑、城市、服装、家具、教育和文化的文章置于同一卷中。教材不能把“装饰与罪恶”压缩为一句现代主义口号，而应追踪其论点演变、修辞对象、版本差异和种族化／性别化语言风险。'
        Topics = "['Adolf Loos', '装饰与现代性', '建筑批评', '现代主义话语']"
        Material = @('全文状态', '版本性质')
        Content = @('主要文本与论点演变', 'Masheck评注的贡献与局限')
        Core = @('主要文本与论点演变')
        Sources = @('史料与引用规则')
        Limits = @('语言和意识形态风险', 'Masheck评注的贡献与局限', '史料与引用规则')
        Relations = @('章节匹配候选', '初步使用定位')
        Use = @('章节匹配候选', '初步使用定位')
        EntityNote = '- **人物与文本层级**：Adolf Loos原文、Joseph Masheck评注及选集编排构成不同解释层；还涉及Otto Wagner、维也纳文化环境、工匠、建筑师、服装和日常器物等论述对象。'
        TimelineNote = '- **时间问题**：选集跨越Loos多个写作阶段，“Ornament and Crime”的演讲／发表年代及不同版本长期存在争议；任何年份和原句必须回查具体版本。'
    }
    'book-0010' = @{
        Summary = 'Alain Weill的平面设计史以印刷、广告、字体、海报、杂志、企业识别和新媒体为线索形成全球性叙事，材料密集、图像丰富，但篇幅压缩导致因果跳跃和地域不均。它适合作为检索入口与图像史线索，不宜单独承担关键史实或“首创”判断。'
        Topics = "['平面设计史', '印刷与广告', '企业识别', '现代主义视觉传播', '全球史']"
        Material = @('全文状态', '版本与文献性质')
        Content = @('全书叙事结构', '主要历史线索与可用材料')
        Core = @('全书叙事结构', '主要历史线索与可用材料')
        Sources = @('书中历史文献的独立价值')
        Limits = @('全球史与立场局限', '事实、论证与版本风险')
        Relations = @('呼捷玛斯材料判断', '章节匹配候选', '初步使用定位')
        Use = @('呼捷玛斯材料判断', '章节匹配候选', '初步使用定位')
        EntityNote = '- **人物、机构与媒介范围**：覆盖欧美及部分非西方设计师、字体设计者、广告机构、出版社、先锋团体、企业和设计教育机构；重点媒介包括海报、书籍、杂志、包装、标志、企业识别、电视和数字视觉。'
        TimelineNote = '- **叙事范围**：从现代印刷与19世纪商业传播展开，经过先锋派、两次世界大战、国际主义和企业设计，延伸至后现代及数字媒介；不同地区不应被处理为同步发展。'
    }
    'book-0011' = @{
        Summary = 'Weill的海报世界史把19世纪印刷与城市商业传播、先锋艺术、战争宣传、政治运动、旅游与文化海报连接为长时段图像史。书中保存大量作者、作品、机构、印刷与展览线索，但1985年版本的地域结构、政治立场和附录数据必须与更新研究交叉核验。'
        Topics = "['海报史', '石版印刷', '商业传播', '战争宣传', '政治图像']"
        Material = @('全文状态', '版本与文献性质')
        Content = @('全书叙事结构', '可用的历史与制度材料')
        Core = @('全书叙事结构', '可用的历史与制度材料')
        Sources = @('可用的历史与制度材料')
        Limits = @('中国与东亚叙述评估', '战争、政治和亚文化的立场风险', '殖民、种族和性别问题', '事实、附录和版本风险')
        Relations = @('呼捷玛斯材料判断', '章节匹配候选', '初步使用定位')
        Use = @('呼捷玛斯材料判断', '章节匹配候选', '初步使用定位')
        EntityNote = '- **对象范围**：涉及海报艺术家、印刷商、广告机构、政治组织、政府宣传部门、文化机构和国际展览；作品跨商业、剧场、旅游、战争、革命、电影、音乐和社会运动等类型。'
        TimelineNote = '- **叙事过程**：从19世纪石版印刷和城市街头传播出发，覆盖新艺术、先锋运动、两次世界大战、战间期政治宣传、战后国际传播及20世纪后期亚文化与社会运动。'
    }
}

$assessmentText = Get-Content -LiteralPath $assessmentPath -Raw -Encoding UTF8
$assessmentMap = @{}
$assessmentPattern = '(?ms)^### `(?<name>[^`]+)`\r?\n(?<body>.*?)(?=^### `|\z)'
foreach ($match in [regex]::Matches($assessmentText, $assessmentPattern)) {
    $assessmentMap[$match.Groups['name'].Value] = $match.Groups['body'].Value.Trim()
}

$records = Get-Content -LiteralPath $manifestPath -Encoding UTF8 |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { $_ | ConvertFrom-Json }

$written = 0
foreach ($record in ($records | Where-Object reading_status -eq 'complete' | Sort-Object id)) {
    if (-not $configs.ContainsKey($record.id)) {
        throw "Missing curated configuration for $($record.id)"
    }
    $fileName = [System.IO.Path]::GetFileName($record.path)
    if (-not $assessmentMap.ContainsKey($fileName)) {
        throw "Missing assessment for $fileName"
    }

    $config = $configs[$record.id]
    $body = $assessmentMap[$fileName]
    $blocks = @(Get-AssessmentBlocks -Body $body)

    $material = Render-Labels -Blocks $blocks -Labels $config.Material -EditorialNote ''
    $content = Render-Labels -Blocks $blocks -Labels $config.Content -EditorialNote ''
    $core = Render-Labels -Blocks $blocks -Labels $config.Core -EditorialNote ''
    $sources = Render-Labels -Blocks $blocks -Labels $config.Sources -EditorialNote $config.EntityNote
    $history = Render-Labels -Blocks $blocks -Labels @() -EditorialNote $config.TimelineNote
    $limits = Render-Labels -Blocks $blocks -Labels $config.Limits -EditorialNote ''
    $relations = Render-Labels -Blocks $blocks -Labels $config.Relations -EditorialNote ''
    $use = Render-Labels -Blocks $blocks -Labels $config.Use -EditorialNote ''

    $title = Escape-YamlSingleQuote $record.title
    $author = Escape-YamlSingleQuote $record.author
    $source = "../../../../$($record.path)"
    $source = Escape-YamlSingleQuote $source
    $year = if ($null -eq $record.year) { '' } else { $record.year }

    $summaryText = @"
---
id: $($record.id)
title: '$title'
author: '$author'
year: $year
source: '$source'
source_hash: '$($record.hash)'
reading_status: 'complete'
summary_status: 'curated-needs-evidence-locators'
read_chars: $($record.read_until)
total_chars: $($record.chars)
topics: $($config.Topics)
generated_from: 'full-text-reading-and-manual-structure-map'
---

# 编辑摘要

$($config.Summary)

# 阅读状态、材料性质与版本

$material

# 内容结构与覆盖范围

$content

# 核心论证、概念与历史解释

$core

# 重要人物、机构、作品与史料链

$sources

# 时间、地点与历史事件

$history

# 证据等级、作者立场与局限

$limits

# 与专题及其他文献的关系

$relations

# 教材使用决策

$use

# 可引用证据与定位状态

- 原文已按SHA-256 `$($record.hash)` 连续读取至文件末尾，共 $($record.chars) 字符。
- 上述结论来自全文审读，不是依据题名推断。
- 精确引文仍须逐条补充章／节标题、页码、图版号或稳定字符范围；在定位补齐前，摘要转述不得冒充作者原话。
- 涉及“第一”“首次”“发明”“影响”“代表性”及因果关系的判断，进入教材前必须与原始档案或独立研究交叉核验。

# 待核实问题

- 回查原始Markdown及清晰扫描页，补齐关键结论的原文定位。
- 核对人名、机构名、作品名、年代、版本、译名和图版信息。
- 将本摘要与专题综合中的主证、互证、争议和“不采用”关系逐项对应。

# 全文审读底稿

$body
"@

    $summaryPath = Join-Path $summaryRoot "$($record.id).summary.md"
    Set-Content -LiteralPath $summaryPath -Value $summaryText -Encoding UTF8
    $written++
}

"CURATED=$written"
