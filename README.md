# Claude Code 配置仓库 — v2.0 极致精简版

姜出尘(Siyebai)的完整 Claude Code 配置。**新环境克隆即用，快速唤醒全部 AI 记忆。**

> GitHub: https://github.com/Siyebai/claude-code-config

## 快速部署

```bash
git clone https://github.com/Siyebai/claude-code-config.git
cd claude-code-config
cp rules/*.md ~/.claude/rules/
cp memory/*.md ~/.claude/projects/C--Users----/memory/
cp agents/*.md ~/.claude/agents/
cp -r commands/* ~/.claude/commands/
cp CLAUDE.md ~/CLAUDE.md
cp mcp.json ~/.claude/.mcp.json
cp settings.json ~/.claude/settings.json
```

## 结构

```
├── CLAUDE.md              # 启动协议 + 关键项目索引
├── MASTER-REFERENCE.md    # ★ 主控参考 — 新环境唤醒全部记忆
├── 13-Codex部署配置教程.md  # Codex Desktop + DeepSeek 完整教程
├── mcp.json               # MCP 服务配置
├── settings.json          # Claude Code 设置 (bypassPermissions)
├── rules/ (2.4KB)         # 行为规则 — identity + craft + ops
├── agents/ (45个)          # Agent 定义
├── commands/ (8目录)       # 斜杠命令
└── memory/ (17个)          # 持久记忆 — MEMORY.md 索引
```

## 核心文件

| 文件 | 用途 | 新环境必读 |
|------|------|-----------|
| **MASTER-REFERENCE.md** | 系统全貌：身份·项目·架构·配置·经验 | ★ 第一 |
| CLAUDE.md | 启动协议：5步启动·关键项目·输出风格 | ★ 第二 |
| rules/ops.md | Token效率·自动维护·安全·流程 | ★ 第三 |
| 13-Codex部署配置教程.md | Codex+DeepSeek 新手部署 | 按需 |

## 版本

| 日期 | 版本 | 说明 |
|------|------|------|
| 2026-05-29 | v2.0 | 极致精简：规则-58%·Skills-42%·磁盘<16MB·自动维护机制 |
| 2026-05-29 | v1.0 | 初始：45agent+8命令+17记忆+3规则 |
