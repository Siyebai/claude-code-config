---
name: dual-agent-sync
description: 双 Claude Code 智能体并行运行时的状态同步机制与冲突预防规则
metadata:
  node_type: memory
  type: feedback
  originSessionId: a7957cca-13e6-4986-94d5-01238ad92443
---

## 运行环境

本地同时运行 2 个 Claude Code 智能体：
- **CLI 智能体**（当前）— 终端/Git Bash 中运行
- **VS Code 智能体** — VS Code 扩展中运行

双方共享同一套文件系统，但对话上下文独立。

## 同步机制

完成以下操作后，**必须写入指定文件**让另一方可见：

| 操作 | 写入位置 | 加载方式 |
|------|---------|---------|
| 学到新知识 | `memory/*.md` | 重启后自动加载 |
| 执行新配置 | `memory/*.md` 或 `rules/` | 重启后 / 自动加载 |
| 完成新任务 | `memory/YYYY-MM-DD.md`（每日日志） | 重启后加载 |
| 知识库更新 | `D:\openclaw\knowledge-base\` | 直接可读 |
| 全局行为变更 | `CLAUDE.md` 或 `~/.claude/rules/` | 双方均加载 |

**Why:** 双方共用同一套文件，不存在同步延迟。文件是唯一的真相源。

**How to apply:** 任务完成 → 判断是否有对方需要知道的信息 → 写入对应文件 → 更新 MEMORY.md 索引。

## 冲突预防

### 绝对禁止
- ❌ 同时编辑同一文件（后保存覆盖前保存）
- ❌ 同时运行 `npm install`（锁冲突）
- ❌ 同时运行 `git commit` / `git push`（引用冲突）

### 建议
- 分任务：VS Code 搞前端，CLI 搞后端/系统
- 编辑文件前检查是否有对方正在操作（检查文件修改时间）
- 一方执行写操作时，另一方只做阅读/研究
- 若仅需存储内容，**不要覆盖文件的现有内容**（追加而非替换）

## 启动协议

每次会话启动时：
1. 检查 `memory/YYYY-MM-DD.md` 是否存在 → 加载当日更新
2. 检查 `D:\openclaw\knowledge-base\` 是否有新文件
3. 若有冲突（记忆与文件不一致），以文件为准
