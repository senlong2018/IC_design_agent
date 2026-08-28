# IC_design_agent
设计此agent的思考：
- 拿到一个IP级的设计任务，应该遵循什么样的流程才能产出一份高质量的RTL?
- 我认为如果给的时间是5天，那么至少花费3天时间来仔细想IP工作机制，接口定义，模块划分，边界场景，设计约束；
想清楚透彻之后，花一天时间coding，再花一天时间本地验证；
- 那么引入AI之后，就有了一位博学且耐心的工程师成为你的工作搭子，如何用好这个工作搭子达成产出一份高质量RTL的目标，
就是本agent做的事情；
- 本agent的实现概念是Context-Engineering，即告诉Coding Agent在什么时间点看什么内容，产出什么结果，在什么时间点通知人来参与讨论，审核以及做判断；
- 本agent保证RTL质量的方式是：DE必须手写一份设计方案+此设计方案 经过内设的AI审核机制，并进行loop；这可以保证DE不会沦为AI的人肉挂件，而是始终可以保持住自己的独立性，可以指导AI做事情；
- 因为现有LLM有上下文限制，一般是100万token，超出此上下文，AI会忘记之前讨论的内容，因此应尽量减少对一个问题的反复讨论，人需要尽量少的迭代次数将问题讲清楚，这也是使用AI做什么样子的任务这件事儿的“度”的把握；


Getting Started:

这是一个数字IC设计的agent，功能是根据DE的输入文档产出满足设计要求的RTL，注意此阶段没有lint/CDC/RDC检查，
产出的RTL需要由DE审核质量；
各个文件/文件夹含义:
doc                 -> DE输入的设计方案文档，markdown格式
scripts与Makefile   -> 告诉Codex怎么调用EDA工具（暂时未做）
skills              -> 用于数字设计的skills文档
stage1              -> AI对设计文档的检查checklist
stage3              -> DE和AI讨论结果
stage3              -> RTL文件
AGENTS.md           -> 告诉Codex怎么做IC设计


1. 打开coding agent,例如Codex；
2. 输入“开始一个IP设计，设计文档是 xxx ”；
3. 开始与AI交互；