---
name: night-evolution
description: 夜间自主进化系统 v2.0：六模块全自动执行（记忆维护+自主学习+自主进化+自主优化+健康检查+Git扫描）
metadata: 
  node_type: memory
  type: project
  originSessionId: 606883ef-c917-486f-bc5c-497626f92169
---

# 夜间自主进化系统 v2.0

**触发**: 每晚 23:00 后自动执行（持久化 cron）
**模型**: 本地 Ollama (qwen2.5:7b) 辅助 + Claude 主力
**模式**: 安静模式，所有产出写文件，不修改运行中服务

## 六模块

### 1. 记忆系统维护
- 读 MEMORY.md，逐条检查时效性
- 合并重复，删除过时/冗余
- 清理 >7 天未更新的临时记忆
- ≥3 条变更时更新 MEMORY.md 索引

### 2. 自主学习 (Self-Learning)
- 读 recent-sessions.md，分析近 3 天会话
- 识别：反复问题模式、被纠正行为、有效策略
- 新发现 → lessons-learned.md
- 有网络时 WebSearch AI/LLM/Agent 最新动态
- 学习项目相关最佳实践
- **平台运营研究** (2026-05-28新增): 每次执行时选一个平台方向，WebSearch 搜集运营知识 → platform-research.md
  - 四个方向轮询: 知乎 → 今日头条 → 番茄小说 → 小红书
  - 搜索关键词示例: "{平台名} 创作者运营技巧 2026" / "{平台名} 算法推荐机制" / "{平台名} 变现模式 新手"
  - 每条知识标注来源+可信度，避免收录营销软文

### 3. 自主进化 (Self-Evolution)
- 基于学习发现更新 `~/.claude/rules/`
- 优化 CLAUDE.md 启动协议和指令
- 更新 patterns.md
- 新工作流 → 对应规则文件
- 原则：具体、可验证，不写空泛内容

### 4. 自主优化 (Self-Optimization)
- 清理桌面/临时目录可回收空间
- 检查 Claude Code 配置效率
- Skills 扫描：标记 stub，统计质量
- 清理过期 cron 任务
- 更新本文件版本号

### 5. 系统健康检查
- 端口: Ollama :11434 / Hermes :18789 / OpenClaw :8642 / Agent Republic :18990
- C 盘空间
- Git 仓库状态

### 6. 执行收尾
- 摘要 → night-log.md
- 待决策事项 → night-pending.md
- 更新本文件版本号和变更记录

## 执行协议
1. 读 memory 系统加载上下文
2. 六模块顺序执行（不可跳过 1/5，其余按需调整）
3. 所有产出写入文件
4. 发现需用户决策的事项 → night-pending.md
5. 无事可做时输出 "无任务" 并退出

## 禁止事项
- 修改运行中服务配置
- 删除用户文件（仅清理明确的临时文件）
- 弹通知/弹窗
- git commit/push（除非用户明确授权夜间可提交）
