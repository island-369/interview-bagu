# 主题文件分类清单

按主题分文件，不塞一个大文件。新增主题时问用户确认。

| 文件名 | 覆盖范围 |
|--------|---------|
| LLM应用架构.md | Workflow/Agent/Skill、ReAct、Function Call、工具路由、多Agent协作 |
| RAG检索增强.md | Embedding、rerank、chunk策略、混合检索、query改写、评估指标 |
| 机器学习基础.md | 损失函数、正则化、优化器、BN/LN、过拟合、评估指标 |
| 深度学习.md | Transformer、Attention、CNN/RNN、训练技巧、分布式训练 |
| 推荐系统.md | 双塔、SASRec、TIGER、特征工程、冷启动、AB实验 |
| 数据库与SQL.md | 索引、事务、锁、MVCC、SQL优化、分库分表 |
| 操作系统.md | 进程/线程、内存管理、文件系统、调度算法、IO模型 |
| 计算机网络.md | TCP/UDP、HTTP/HTTPS、DNS、CDN、拥塞控制 |
| 数据结构与算法.md | 常见题型、时间复杂度、手写代码模板 |
| Python与工程.md | GIL、装饰器、异步、设计模式、项目架构 |
| 系统设计与场景题.md | 限流、缓存、消息队列、微服务、高可用 |

## 归属判断规则

1. 问题关键词能直接映射到上表某行 → 自动归入
2. 跨两个主题（如"RAG里用的Embedding模型怎么微调"） → 归入主要主题（RAG），另一个加交叉引用
3. 完全新主题 → 问用户："这个放哪个文件？还是新建一个？"

## 交叉引用格式

当 Q 涉及其他主题文件的内容时，在末尾加：

```markdown
**关联：** 见 [RAG检索增强.md](RAG检索增强.md) Q3 Embedding 微调部分
```
