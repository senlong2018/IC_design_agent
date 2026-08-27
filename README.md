# IC_design_agent

这是一个数字IC设计的agent，功能是根据DE的输入文档产出lint clean的RTL，注意lint不包括CDC/RDC；
各个文件/文件夹含义:
AGENTS.md           -> 告诉Codex怎么做IC设计
scripts与Makefile   -> 告诉Codex怎么调用EDA工具
.codex/agents/      -> 定义专门的Subagent
.codex/config.toml  -> 
rtl                 -> DE设计的RTL文件
logs                -> 调用EDA工具产生的log

