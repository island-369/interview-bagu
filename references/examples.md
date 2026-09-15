# 回答示例（展示四档 + 追问 + 沉淀 + 体检 + 校准全流程）

---

## 示例1：轻档（术语追问）

**用户问：** enum 是啥

**回答：**

**核心：** enum（枚举）= 把一个字段所有合法取值列成固定清单，模型只能从清单里选，不能自由发挥。

**类比：** 像点奶茶时"甜度"只能选无糖/三分/五分/全糖，不能说"我要 0.37 甜"。

**面试口径：** "enum 约束解码空间，把开放生成变成有限选择，降低幻觉率。"

---

## 示例2：中档（概念对比）

**用户问：** CoT 和 ReAct 什么区别

**回答：**

## 一句话核心
CoT 只想不做（纯推理链），ReAct 边想边做（推理+工具调用交替）。

## 类比
CoT = 闭卷考试，全凭脑子里推导；ReAct = 开卷考试，推导到一半可以翻书查资料再继续推。

## 展开

| 维度 | CoT | ReAct |
|------|-----|-------|
| 核心动作 | think → think → answer | think → act → observe → think → ... |
| 是否调工具 | 否 | 是 |
| 幻觉风险 | 高（推理链越长越容易编） | 低（每步有真实反馈校正） |
| 适用场景 | 数学/逻辑推理 | 需要外部知识的复杂任务 |
| 代表论文 | Wei et al. 2022 | Yao et al. 2022 |

## 常见追问
- "ReAct 什么时候该停？" → 模型判断信息足够时输出 Answer 终止循环，或设最大步数兜底
- "CoT 怎么减少幻觉？" → Self-consistency（多次采样投票）、配合检索做 RAG+CoT

## 面试总结
CoT 是纯推理链适合封闭问题，ReAct 加了工具调用形成闭环适合开放任务，两者可以嵌套（ReAct 的 think 步里用 CoT）。

---

## 示例3：追问 → 沉淀全流程（v2 层级编号）

**第一轮：** 用户问 "ReAct 是什么" → 中档回答

**第二轮：** 用户追问 "observe 具体长什么样" → 追问模式，轻档：

> **核心：** observe 就是工具返回的原始结果，直接拼进下一轮 prompt。
>
> ```
> Action: search("Transformer attention机制")
> Observation: {"results": [{"title": "Attention Is All You Need", "snippet": "..."}]}
> ```

**第三轮：** 用户说 "好，追加到文档"

先查编号：
```bash
bash scripts/append.sh "LLM应用架构.md" --next
# next_topic=2  last_topic=1  next_subsection=1.3
```

判断：ReAct 和之前的 workflow/agent/skill 是同一领域，且能拆 3+ 子知识点（循环步骤 / observe 定义 / 停止条件），建主题：

```bash
cat <<'CONTENT_EOF' | bash scripts/append.sh "LLM应用架构.md"
## 主题 2: ReAct 循环机制

### 2.1 一句话核心
Thought → Action → Observation 循环，让 LLM 边推理边调工具边看反馈。

### 2.2 Observe 是什么
工具执行后的原始返回值，直接拼进下一轮 prompt。
```
Action: search("xxx")
Observation: {"results": [...]}
```

### 2.3 停止条件
模型输出 Answer / 达到最大步数 / 置信度阈值。

### 2.4 面试一句话总结
ReAct = 推理和工具调用交替形成闭环，推理指导动作、动作反馈修正推理。
CONTENT_EOF
```

**关键判断：** 追问的"observe 长什么样"合并进 2.2 而不是单独建小节，因为离开 ReAct 上下文它没意义。

---

## 示例4：校准档（项目相关问题，v2 新增）

**用户问：** "我项目里数据源异构，是要存到不同数据库吗？我记得都存一个库里啊"

**❌ 错误做法：** 直接根据用户之前的口头描述（"25篇文档、bge-small-zh、hit@3=0.925"）推理答案。

**✅ 正确做法（校准档）：**

1. **触发信号识别**：用户提到"我项目" + 具体路径 `/Users/xqy/Documents/蚂蚁/data_agent2_副本`

2. **派 Explore agent**，问题清单：
   - 项目到底干啥？（读 README / pyproject.toml）
   - 数据源实际结构？几个文档？
   - 向量库是几个 collection？
   - 检索打分公式在哪个文件？
   - 最新评估指标（hit@K / MRR）？
   - 延迟数据是最新的吗？

3. **拿到证据后逐条核对**用户口头描述，发现：
   - "25 篇文档" → 实际 24 篇（KB1 16 表 + KB2 8 指标）
   - "hit@3=0.925" → 最新是 0.9896（用的是旧基线）
   - "200-455s 延迟" → 优化后是 123-135s
   - "存在一个向量库" → 实际 3 个 ChromaDB collection

4. **输出校准话术**：

```markdown
## 前面说错的地方

### 1. 文档数量
**我说的：** 25 篇
**代码真相：** 24 篇（KB1 16 张表 + KB2 8 个指标，`config/kb_paths.yaml:12-30`）

### 2. hit@3 指标
**我说的：** 0.925
**代码真相：** 0.9896（`eval/baselines/2025-08-latest.json`，0.925 是 5 月旧基线）

### 3. 向量库结构
**我说的：** 一个库
**代码真相：** 3 个 ChromaDB collection — kb1_tables / kb2_metrics / sql_examples
（`retriever/vector_store.py:45-78`），这就是"数据源异构"的物理体现

## 面试稿改口版

> "我项目做了信贷风控 NL2SQL，24 篇 KB 文档分成 3 个 ChromaDB collection 存
> （表定义/业务指标/SQL 范例），bge-small-zh-v1.5 CPU-only 编码，检索时
> 关键词+向量加权融合打分，hit@3=0.99、MRR=0.94，端到端 123-135s。"
```

5. **归档**：这段进 `我的项目.md`，不进 `LLM应用架构.md`。

**铁律：** 涉及用户项目具体数字/结构时，宁可多花 5 分钟派 agent 也不要瞎推理。用户面试被问细节答错会当场翻车。

---

## 示例5：结构体检模式（v2 新增）

**用户问：** "感觉 Q5 是 Q4 里的一个追问？你看看哪些是同问题或者一个问题的追问，要不要合并整理"

**工作流程：**

1. **列当前所有主题+小节：**
   ```bash
   bash scripts/append.sh "LLM应用架构.md" --list
   ```

2. **分析追问关系、冗余、太小节：**
   ```markdown
   ## 追问关系梳理
   - Q4「工具路由与召回」→ Q5「置信度阈值」：Q5 离开 Q4 上下文没意义 → 合并
   - Q6「Agent-as-Tool」→ Q7「LangGraph 编排」：Q7 是 Q6 的具体实现 → 合并成"编排模式"主题

   ## 发现的冗余
   - Q2「Function Call 提升」里的"few-shot 示例"和 Q3 里的"prompt 工程"部分重叠 30%

   ## 建议的重构方案
   主题 2: Function Call 能力提升
     2.1 结构化输出约束
     2.2 参数 schema 设计（含 enum）
     2.3 Few-shot 示例设计
     2.4 工具路由与置信度阈值（合并原 Q4+Q5）
   主题 3: 工具调用编排模式
     3.1 ReAct / Plan-Execute / Parallel / Hierarchical
     3.2 Agent-as-Tool（合并原 Q6+Q7）
     3.3 代码示例
   ```

3. **等用户确认再动手：**
   > "要我按这个方案重写文档吗？会先备份到 workspace。"

4. **执行时用 mktemp+Python 双层解耦**（内容含代码围栏时 heredoc 直接跑会崩）：
   ```bash
   cp "$FILE" "$FILE.bak.$(date +%s)"  # 二次备份
   
   TMPFILE=$(mktemp)
   cat > "$TMPFILE" << 'RESTRUCTURE_EOF_XYZ'
   （新的主题结构 markdown）
   RESTRUCTURE_EOF_XYZ
   
   python3 - "$FILE" "$TMPFILE" <<'PYEOF'
   import sys, re
   main, new_content_path = sys.argv[1], sys.argv[2]
   doc = open(main).read()
   new = open(new_content_path).read()
   # 用正则替换旧的 Q4/Q5 段落为新的 2.4 层级
   doc = re.sub(r'## Q4:.*?(?=## Q6:)', new, doc, flags=re.DOTALL)
   open(main, 'w').write(doc)
   PYEOF
   rm "$TMPFILE"
   ```

**铁律：** 不擅自重构，一定先出方案让用户选。

---

## 示例6：简单追加 vs 复杂插入的选择

| 场景 | 用哪个 |
|---|---|
| 往文档末尾加新小节/新主题 | `append.sh`（stdin） |
| 内容含代码围栏 ` ``` ` + 单引号 | `append.sh`（stdin+heredoc 已处理） |
| 往文档中间插入 / 修改已有小节编号 | mktemp + Python（示例5的方式） |
| 大重构（改多个主题） | 先备份 → mktemp+Python → 让用户 diff 检查 |

**永远不要：** 直接 `sed -i` 或 `echo "..." >> file.md` — 引号地狱 + 破坏 footer + 路径含 `:` 会被 Bash 拒绝。
