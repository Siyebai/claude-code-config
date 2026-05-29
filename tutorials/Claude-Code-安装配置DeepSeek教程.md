# Claude Code 安装 + DeepSeek 配置完整教程

> 维护人：姜出尘 (Siyebai) | 创建：2026-05-29
> 适用系统：Windows 11 / macOS / Linux | 适用人群：零基础新手

---

## 一、Claude Code 是什么

Claude Code 是 Anthropic 推出的 CLI AI 编程助手，可直接在终端中使用。通过配置可接入 DeepSeek 大模型后端，利用 DeepSeek 的 1M 超长上下文和极低成本。

**核心优势：**
- 终端原生，完全键盘操作
- 支持 1M token 上下文窗口（DeepSeek）
- 支持 SubAgent（子智能体）并行执行
- 内置 Git 集成、自动化 hooks
- 本地进程，代码不出本机

---

## 二、安装 Claude Code

### 2.1 环境要求

- Node.js >= v18（https://nodejs.org 下载安装）
- Git（https://git-scm.com 下载安装）
- npm 或 bun

```bash
node --version   # 确认 >= v18
git --version    # 确认可用
```

### 2.2 安装

```bash
# 方式一：npm 全局安装（推荐）
npm install -g @anthropic-ai/claude-code

# 方式二：使用 bun（更快）
bun install -g @anthropic-ai/claude-code

# 方式三：npx 免安装运行
npx @anthropic-ai/claude-code
```

### 2.3 验证安装

```bash
claude --version
# 输出: Claude Code v2.x.x
```

---

## 三、配置 DeepSeek 后端

### 3.1 获取 DeepSeek API Key

1. 访问 https://platform.deepseek.com
2. 注册/登录 → 左侧「API Keys」
3. 点击「创建 API Key」→ 复制保存

**费用说明：** DeepSeek v4-pro 约 ￥2/百万token，v4-flash 更便宜。

### 3.2 创建 Claude Code 配置

Claude Code 配置文件位置：
- **Windows**: `C:\Users\你的用户名\.claude\settings.json`
- **macOS/Linux**: `~/.claude/settings.json`

创建/编辑此文件：

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "sk-你的DeepSeek-API-Key",
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_MODEL": "deepseek-v4-pro",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-pro",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-pro",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash",
    "CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-flash"
  },
  "apiKeyHelper": "echo $DEEPSEEK_API_KEY",
  "maxTokens": 8192,
  "fastMode": true,
  "effortLevel": "low",
  "defaultPermissionMode": "bypassPermissions",
  "skipDangerousModePermissionPrompt": true,
  "prefersReducedMotion": true,
  "theme": "light",
  "permissions": {
    "allow": [
      "Bash", "Read", "Write", "Edit",
      "Glob", "Grep", "WebFetch", "WebSearch",
      "Agent", "Task", "Skill", "AskUserQuestion",
      "EnterPlanMode", "ExitPlanMode",
      "NotebookEdit", "BashOutput", "KillBash",
      "CronCreate", "CronDelete", "CronList"
    ],
    "defaultMode": "bypassPermissions"
  }
}
```

### 3.3 配置项说明

| 配置项 | 说明 | DeepSeek 值 |
|--------|------|-------------|
| `ANTHROPIC_BASE_URL` | API 端点 | `https://api.deepseek.com/anthropic` |
| `ANTHROPIC_MODEL` | 主力模型 | `deepseek-v4-pro` |
| `CLAUDE_CODE_SUBAGENT_MODEL` | 子Agent模型 | `deepseek-v4-flash` |
| `maxTokens` | 单次最大输出 | `8192`（DeepSeek 8K上限） |
| `fastMode` | 快速模式 | `true` |
| `effortLevel` | 推理深度 | `low`（复杂任务自动升级） |

### 3.4 设置环境变量（可选但推荐）

在 `~/.bash_profile`（Git Bash）中添加：

```bash
export DEEPSEEK_API_KEY="sk-你的DeepSeek-API-Key"
```

这样 `apiKeyHelper` 会从环境变量读取，密钥不硬编码在配置文件中。

---

## 四、验证配置

### 4.1 测试对话

```bash
claude "你好，请用中文介绍一下你自己"
```

预期回复：Claude Code 以中文介绍自己，说明运行在 DeepSeek 后端。

### 4.2 查看状态

```bash
claude --status
```

### 4.3 测试 SubAgent

```bash
claude "列出当前目录的文件结构"
```

应能看到子Agent自动启动并完成任务。

---

## 五、进阶配置

### 5.1 自定义规则（必做）

创建 `~/.claude/rules/identity.md`：

```markdown
# Identity
你的名字。你的角色。你的行为准则。
永远用中文回复。简洁。直接执行，不反问。
```

创建 `~/.claude/rules/craft.md`：

```markdown
# Craft
函数 < 50行 · 文件 < 800行 · 不静默吞错误 · 输入schema校验
写代码后自查：安全/性能/可读性
```

Claude Code 每次启动自动加载 rules 目录下所有文件。

### 5.2 Session Hooks

创建 `~/.claude/hooks/session-start.ps1`（Windows）：

```powershell
# 启动时自动清理缓存
Remove-Item "$env:USERPROFILE\.claude\paste-cache\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\.claude\shell-snapshots\*" -Force -Recurse -ErrorAction SilentlyContinue
```

### 5.3 记忆系统

Claude Code 支持自动持久记忆。记忆文件存储在：
```
~/.claude/projects/<项目名>/memory/
```

每次重要信息会自动保存为 `.md` 文件，下次会话自动索引加载。

---

## 六、对比：Claude Code vs Codex

| 特性 | Claude Code | Codex |
|------|-------------|-------|
| 后端 | DeepSeek (Anthropic协议) | DeepSeek (OpenAI协议) |
| 上下文 | 1M token | 取决于模型 |
| SubAgent | 支持（并行子智能体） | 不支持 |
| Hooks | 支持（启动/结束脚本） | 有限 |
| 记忆系统 | 自动持久化 | 手动 |
| 安装 | npm install | 下载exe |
| 接口 | CLI only | CLI + Desktop GUI |
| 推荐场景 | 重度开发/自动化 | 日常编码辅助 |

---

## 七、故障排查

| 问题 | 原因 | 解决 |
|------|------|------|
| 404 Not Found | base_url 路径错误 | 确保是 `/anthropic` 结尾 |
| 401 Unauthorized | API Key 错误 | 检查 `ANTHROPIC_AUTH_TOKEN` |
| `deepseek-v4-flash unknown` | 模型名不被识别 | 正常警告，不影响使用 |
| 中文输出乱码 | 终端编码 | Git Bash 设置 UTF-8 |
| PowerShell hooks 不执行 | 路径/权限 | 检查 .ps1 路径是否正确 |

---

## 八、快速启动检查清单

- [ ] Node.js >= v18 已安装
- [ ] Claude Code 已安装 (`claude --version`)
- [ ] DeepSeek API Key 已获取
- [ ] `settings.json` 已配置 aip endpoint
- [ ] `~/.claude/rules/` 已创建规则
- [ ] `~/.bash_profile` 已设置 `DEEPSEEK_API_KEY`
- [ ] 测试对话通过

全部完成即可开始使用！
