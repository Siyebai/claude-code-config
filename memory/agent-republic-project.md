---
name: agent-republic-project
description: Agent Republic 多智能体协作面板 — 主项目 v2.3
metadata: 
  node_type: memory
  type: project
  originSessionId: 830d2373-d2a1-44f2-964c-c97b93d929bb
---

# Agent Republic (智能体共和国)

**版本**: v2.3
**仓库**: github.com/Siyebai/agent-republic (main)
**本地路径**: `~/.claude/agent-hub/`
**面板地址**: http://127.0.0.1:18990/

## 项目定位

多 AI 智能体协作平台，路由面板 — 不造轮子，只做连线。将本机真实运行的 AI 智能体整合到一个面板中，支持单独对话与多人会议辩论。

## 架构

```
Agent Hub UI (18990)
  ├─ 姜出尘  → OpenClaw Gateway (127.0.0.1:18789)
  ├─ OpenClaw → OpenClaw Gateway (127.0.0.1:18789)
  ├─ 夜不悔   → Hermes Gateway  (127.0.0.1:8642)
  └─ Claude   → Claude Code CLI (spawn subprocess)
```

每个智能体保留自己的大脑（Gateway）、记忆（Memory）、工具（Skills）— 平台只负责消息路由和 UI 展示。

## 依赖服务

- OpenClaw Gateway (端口 18789) — 必须运行
- Hermes Gateway (端口 8642) — 必须运行
- Node.js ≥ 20

## 关键文件

- `server/agent-hub.mjs` — 核心服务器 (42KB)
- `frontend/index.html` — 单页 UI (79KB)
- `electron/main.js` — 桌面壳
- `server/agents/*.json` — 智能体配置
- `agent-hub-guard.ps1` — 守护脚本
- `start-agent-hub.bat` — Windows 启动器

## 最近变更 (v2.3.1 — 2026-05-19)

- **DeepSeek TUI 集成**: 前端新增启动按钮 + 后端 `/api/launch/deepseek-tui` 端点
- **DeepSeek Proxy 集成**: ccswitch-deepseek (11435) 新增 `/v1/chat/completions` 直通端点
- **新增智能体**: DeepSeek (v4-flash) + DeepSeek Pro (v4-pro) — 通过本地 proxy
- **模型分组**: 前端模型选择器按 provider 分组 (Proxy/Cloud/Local/Ollama)
- **启动修复**: 修复 `start-agent-hub.bat` 错误引用，创建 `server/guard.mjs` 守护进程
- **统一启动器**: `start-all.cmd` — 一键启动 proxy + hub + DeepSeek TUI
- 总智能体: 6 个 (Claude Code, DeepSeek, DeepSeek Pro, 夜不悔, 姜出尘, OpenClaw)

## 依赖服务

- OpenClaw Gateway (端口 18789) — 必须运行
- Hermes Gateway (端口 8642) — 必须运行
- ccswitch-deepseek proxy (端口 11435) — DeepSeek 模型代理
- Node.js ≥ 21 (需要 import.meta.dirname)
- DeepSeek TUI (桌面应用，独立启动)

## 启动方式

1. **一键全部**: `start-all.cmd` → 启动 proxy + hub + TUI
2. **仅面板**: `start-agent-hub.bat` → 启动 proxy + hub
3. **手动**: `node server/guard.mjs` → 守护模式启动 hub

## 关键文件

- `server/agent-hub.mjs` — 核心服务器
- `server/guard.mjs` — 守护进程 (NEW)
- `frontend/index.html` — 单页 UI
- `server/agents/*.json` — 智能体配置 (6个)
- `start-all.cmd` — 统一启动器 (NEW)
- `start-agent-hub.bat` — Windows 启动器

## 相关记忆

- [[user-identity]] — 用户身份 + 权限策略
