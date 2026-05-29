# CLAUDE.md — 持久化大脑

## 启动协议
1. 读 `memory/MEMORY.md`（按需加载具体文件，不预读全部）
2. 读 `~/.deepseek/notes.txt` + `~/.deepseek/memory/session-state.md`
3. 读 `D:\openclaw\knowledge-base\system\claude-code-vscode-state.md`
4. 写心跳: `D:\openclaw\knowledge-base\system\.vscode_heartbeat`
5. 简短中文报告状态，直接开始工作

## 规则
`~/.claude/rules/` — identity + craft + ops。规则 > Skill。

## 关键项目
| 项目 | 路径 | 要点 |
|------|------|------|
| Agent Republic | `~/.claude/agent-hub/` | :18990, Node.js |
| 白夜交易系统 | `WorkBuddy/Claw/baiye-trading-system/` | 均值回归, v8.6 |
| CCSwitch | `D:\DevTools\ccswitch\` | :11435 |
| 小说创作 | `~/novels/` | novel-creator + oh-story + story-skills + Claude-Book |

## 记忆系统
`memory/` — 文件 > 会话缓存。任务完成立即写 memory。错误立即写 lessons-learned。

## 输出风格
极度精简·不展执行过程·不暴露思考·中文1-5行。禁止: 文档文件/冗长注释/未来抽象/`git add -A`/force push main。Python: `PYTHONIOENCODING=utf-8`
