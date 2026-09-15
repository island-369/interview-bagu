# 回答示例（展示三档 + 追问 + 沉淀全流程）

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

## 示例3：追问 → 沉淀全流程

**第一轮：** 用户问 "ReAct 是什么" → 中档回答（如上）

**第二轮：** 用户追问 "observe 具体长什么样" → 追问模式，轻档：

> **核心：** observe 就是工具返回的原始结果，直接拼进下一轮 prompt。
>
> 长这样：
> ```
> Action: search("Transformer attention机制")
> Observation: {"results": [{"title": "Attention Is All You Need", "snippet": "..."}]}
> ```
> 模型拿到这个 JSON 后进入下一个 Thought 决定怎么用。

**第三轮：** 用户说 "好，追加到文档"

→ 合并两轮为一个 Q 条目（追问内容融入展开部分），执行追加：

```markdown
## Q2: ReAct 循环中 Observe 是什么？

**核心：** Observe = 工具执行后返回给 agent 的结果，是环境"喂"回来的反馈，agent 主动做的只有 think + act。

**ReAct 循环：**
Thought → Action → Observation → Thought → ... → Answer

**Observe 实例：**
```
Action: search("xxx")
Observation: {"results": [...]}  ← 这个 JSON 直接拼进下轮 prompt
```

**面试总结：** ReAct 让推理和工具调用交替形成闭环——推理指导动作，动作反馈修正推理。

---
```

注意：追问的"observe长什么样"被合并进了 Q2 而不是单独建 Q3，因为离开 ReAct 上下文它没意义。
