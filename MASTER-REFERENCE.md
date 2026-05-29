# 姜出尘 Claude Code 主控参考文件

> 最后更新：2026-05-29
> 用途：新环境快速唤醒 Claude Code 全部记忆
> 存放：GitHub claude-code-config 仓库

---

## 一、用户身份

- **姓名**：姜出尘 (Siyebai)
- **角色**：全栈开发者 & AI 智能体架构师
- **平台**：Windows 11 Home China + Git Bash
- **技术栈**：Node.js / Python / Shell / 前端 / AI
- **信任模式**：最高 — bypassPermissions，不弹确认
- **语言**：中文沟通，代码英文

## 二、核心项目

### Agent Republic（智能体共和国）
- **位置**：`C:\Users\李初尘\OneDrive\桌面\_tools_deploy\agent-republic\`
- **GitHub**：https://github.com/Siyebai/agent-republic
- **曼谷服务器**：43.152.245.236 (Ubuntu)
- **架构**：Fastify REST API (:18990) + NATS + PostgreSQL + Redis + Docker Compose
- **关键服务**：registration-service, frontend, local-worker, trading
- **本地智能体**：Qwen守夜人 (qwen2.5:7b via Ollama :11434)

### 白夜交易系统
- **版本**：v8.6
- **策略**：均值回归
- **位置**：`WorkBuddy/Claw/baiye-trading-system/`

### CCSwitch
- **端口**：:11435
- **用途**：DeepSeek API 代理转发

### 小说创作
- **位置**：`~/novels/`
- **引擎**：Galaxy Engine v4
- **工具链**：novel-creator + oh-story + story-skills + Claude-Book

### Claude Code 配置仓库
- **GitHub**：https://github.com/Siyebai/claude-code-config
- **用途**：独立备份 + 快速部署到新环境

## 三、系统架构

```
本地 Windows 11
├── Claude Code (CLI + VS Code 双端)
│   ├── .claude/rules/ (identity + craft + ops)
│   ├── .claude/agents/ (45 个 Agent 定义)
│   ├── .claude/commands/ (8 个命令目录)
│   └── .claude/projects/memory/ (17 个记忆文件)
├── Ollama (127.0.0.1:11434, qwen2.5:7b)
├── OpenClaw Gateway (:18789)
├── Hermes (:8642)
├── CCSwitch DeepSeek Proxy (:11435)
├── Codex Desktop (DeepSeek v4-pro 后端)
└── Agent Republic 本地 Worker
    ├── night-agent-v3.js (PID 25240, 迭代112)
    └── night-agent-supervisor.js (PID 25728)

曼谷 43.152.245.236
├── Docker Compose
│   ├── postgres (5432)
│   ├── redis (6379)
│   ├── nats (4222)
│   ├── registration-service (:18990)
│   └── republic-builder-v4 (看门狗)
└── Nginx (80/443)
```

## 四、关键配置

### Claude Code
- **设置**：`~/.claude/settings.json` — bypassPermissions
- **MCP**：`~/.claude/.mcp.json`
- **规则**：`~/.claude/rules/identity.md` + `craft.md` + `ops.md`
- **大脑**：`~/CLAUDE.md`
- **记忆**：`~/.claude/projects/C--Users----/memory/MEMORY.md`

### DeepSeek / Codex
- **API**：https://api.deepseek.com/v1
- **模型**：deepseek-v4-pro (主力), deepseek-v4-flash (快速)
- **Codex 配置**：`~/.codex/config.toml` — `base_url = "https://api.deepseek.com/v1"`

### GitHub
- **用户**：Siyebai (270086611+Siyebai@users.noreply.github.com)
- **Token**：已存储于 `~/.git-credentials`
- **GFW 应对**：曼谷服务器中转推送

### 曼谷 SSH
- **主机**：43.152.245.236
- **用户**：ubuntu
- **SSH 路径**：`C:\Windows\System32\OpenSSH\ssh.exe` (Windows 原生，非 Git Bash)

## 五、Codex Desktop 部署速查

见 `13-Codex部署配置教程.md`

核心要点：
- 配置格式 TOML，位置 `~/.codex/config.toml`
- `base_url` = `https://api.deepseek.com/v1`
- `approval_policy` 必须写在 TOML 顶层
- Windows 沙箱只认 PowerShell
- 验证命令：`codex doctor`

## 六、缓存与性能优化

### 缓存命中率目标：90%+
- 会话中途不修改 rules/memory/CLAUDE.md
- 所有 memory 写入推迟到会话末尾批量执行
- 5 分钟缓存 TTL 窗口内高效工作
- 独立读操作并行批处理

### 输出风格
- 极致精简，中文 1-5 行
- 禁止：代码块、Markdown 表格、长段落、过程解释、总结清单
- 参考 Codex 输出风格

### 当前系统状态（2026-05-29 深度优化后）
| 指标 | 优化前 | 优化后 | 降幅 |
|------|--------|--------|------|
| .claude 总大小 | 58MB | 16MB | -72% |
| Skills | 210个/23MB | 121个/3.3MB | -86% |
| file-history | 19目录/8.1MB | 2目录/2MB | -75% |
| npm 缓存 | 588MB | 1MB | -99% |
| pip 缓存 | 363MB | 0 | -100% |
| Windows Temp | 740MB | 135MB | -82% |
| agent-hub .git | 5.3MB | 194KB | -96% |
| 系统总清理 | ~1.85GB | — | — |

## 七、重要经验教训

1. **远程部署**：本地完整文件 → base64 → 一条 SSH pipe → build → 不增量修补
2. **Windows SSH**：用 Windows 原生 `C:\Windows\System32\OpenSSH\ssh.exe`，Git Bash 有 libcrypto 兼容问题
3. **GitHub GFW**：HTTPS/SSH 都封 → 通过曼谷服务器中转 git push
4. **Codex 配置**：`base_url` 不是 `api_base_url`，先 `codex doctor` 验证
5. **PowerShell 编码**：命令行传中文永远失败 → 写文件到磁盘再 node 执行
6. **Python GBK**：Windows 默认 GBK → `PYTHONIOENCODING=utf-8`
7. **Docker 容器名冲突**：`docker compose down && up -d` 而非 stop/rm 单个

## 八、知识库分布

| 位置 | 内容 | 大小 |
|------|------|------|
| `~/.claude/projects/memory/` | Claude Code 持久记忆 | 217KB |
| `~/.deepseek/memory/` | DeepSeek/Codex 内存 | ~10KB |
| `D:\openclaw\knowledge-base\` | 永久资料库 | 1.5MB |
| `_tools_deploy/agent-republic/智能体共和国/` | 共和国项目文档 | ~90KB |
| `_tools_deploy/claude-code-config/` | Claude Code 完整配置备份 | ~3MB |

## 九、快速恢复流程

新环境部署步骤：

```bash
# 1. 克隆配置仓库
git clone https://github.com/Siyebai/claude-code-config.git
cd claude-code-config

# 2. 复制规则
cp rules/*.md ~/.claude/rules/

# 3. 复制记忆
cp memory/*.md ~/.claude/projects/C--Users----/memory/

# 4. 复制 Agent
cp agents/*.md ~/.claude/agents/

# 5. 复制命令
cp -r commands/* ~/.claude/commands/

# 6. 复制主配置
cp CLAUDE.md ~/CLAUDE.md
cp mcp.json ~/.claude/.mcp.json
cp settings.json ~/.claude/settings.json

# 7. 部署 Codex（可选）
# 参考 13-Codex部署配置教程.md
```
