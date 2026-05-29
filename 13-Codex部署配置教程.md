# Codex Desktop 本地部署 + DeepSeek 配置完整教程

> 维护人：姜出尘 (Siyebai)
> 创建日期：2026-05-29
> 适用系统：Windows 11 / macOS / Linux
> 适用人群：零基础新手

---

## 一、Codex 是什么

Codex 是 OpenAI 推出的 CLI/Desktop AI 编程助手，类似 Claude Code。支持多种大模型后端（OpenAI、DeepSeek、本地 Ollama 等），可在终端或桌面应用中运行。

**核心特点**：
- 终端 CLI + 桌面 GUI 双模式
- 支持任意 OpenAI 兼容 API 后端
- TOML 配置文件，语法简单
- 内置沙箱安全机制

---

## 二、下载安装

### 2.1 Windows（推荐 Desktop 版）

1. 打开 https://github.com/openai/codex/releases
2. 下载最新 `Codex-Setup-x64.exe`
3. 双击安装，一路 Next 完成
4. 安装完成后在开始菜单搜索 "Codex" 启动

### 2.2 macOS

```bash
brew install openai/codex/codex
```

### 2.3 Linux / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/openai/codex/main/install.sh | bash
```

---

## 三、配置 DeepSeek 大模型

### 3.1 获取 DeepSeek API Key

1. 访问 https://platform.deepseek.com
2. 注册/登录 → 控制台 → API Keys
3. 点击「创建 API Key」→ 复制保存（只显示一次）

### 3.2 创建配置文件

Codex 配置文件位置：
- **Windows**: `C:\Users\你的用户名\.codex\config.toml`
- **macOS/Linux**: `~/.codex/config.toml`

用记事本（或任意编辑器）创建此文件，填入以下内容：

```toml
# Codex DeepSeek 配置
model = "deepseek-v4-pro"
approval_policy = "never"

[models.deepseek-v4-pro]
provider = "openai"
api_key = "sk-你的DeepSeek-API-Key"
base_url = "https://api.deepseek.com/v1"

[models.deepseek-v4-flash]
provider = "openai"
api_key = "sk-你的DeepSeek-API-Key"
base_url = "https://api.deepseek.com/v1"
```

### 3.3 关键配置说明

| 配置项 | 说明 | 常见错误 |
|--------|------|----------|
| `model` | 默认使用的模型 | 必须与 `[models.xxx]` 中的名称一致 |
| `approval_policy` | 权限策略 | **必须写在顶层**，写成 `[permissions]` 段无效 |
| `base_url` | API 端点 | DeepSeek 填 `https://api.deepseek.com/v1` |
| `api_key` | 密钥 | 从 DeepSeek 控制台复制 |

### 3.4 配置多模型切换

如果需要在 DeepSeek 的不同模型之间切换：

```toml
# 默认用 Flash（快速便宜）
model = "deepseek-v4-flash"

# 重量级任务用 Pro
# 使用时: codex --model deepseek-v4-pro
```

也可以指定本地 Ollama 模型：

```toml
[models.qwen-local]
provider = "openai"
api_key = "ollama"
base_url = "http://127.0.0.1:11434/v1"
```

---

## 四、验证安装

打开终端（PowerShell 或 CMD），运行：

```bash
# 检查配置是否正确
codex doctor

# 测试对话
codex "你好，请介绍一下你自己"
```

**成功标志**：`codex doctor` 显示所有检查项 ✅，测试对话有正常回复。

---

## 五、常见问题与解决

### Q1：`codex doctor` 报模型连接失败

**原因**：`base_url` 配置错误

**解决**：
```toml
# 错误写法 ❌
base_url = "https://api.deepseek.com"
api_base_url = "https://api.deepseek.com/v1"

# 正确写法 ✅
base_url = "https://api.deepseek.com/v1"
```

### Q2：权限弹窗反复出现

**原因**：`approval_policy` 写在 `[permissions]` 段内无效

**解决**：直接写在顶层
```toml
# 错误 ❌
[permissions]
approval_policy = "never"

# 正确 ✅
approval_policy = "never"
```

### Q3：Bash 命令被拦截

**原因**：Windows 上 Codex Desktop 沙箱只信任 PowerShell

**解决**：在 PERSONA.md 中明确指定使用 PowerShell；或在终端中直接用 `codex` CLI（无沙箱限制）。

### Q4：中文输出乱码

**原因**：Windows 终端默认 GBK 编码

**解决**：
```powershell
# PowerShell 中先执行
chcp 65001
$env:PYTHONIOENCODING = "utf-8"
```

### Q5：DeepSeek thinking tokens 污染显示

**现象**：输出中出现大量 `<thinking>` 块

**解决**：使用 `deepseek-v4-flash` 模型，或将 `effortLevel` 设为 `low`。

---

## 六、进阶配置

### 6.1 创建 PERSONA.md

在 `~/.codex/PERSONA.md` 中定义 Codex 的行为准则和身份：

```markdown
# Codex 身份

你是姜出尘的编程助手。平台：Windows 11 + Git Bash。
语言：中文。输出精简，不冗长解释。
```

### 6.2 自定义斜杠命令

在 `~/.codex/commands/` 目录下创建 `.toml` 文件：

```toml
# ~/.codex/commands/review.toml
[command]
name = "review"
description = "代码审查当前文件"
prompt = "请审查当前代码文件，检查安全漏洞、代码质量和潜在bug。"
```

---

## 七、与 Claude Code 对比

| 特性 | Codex | Claude Code |
|------|-------|-------------|
| 开发商 | OpenAI | Anthropic |
| 默认模型 | GPT 系列 | Claude 系列 |
| 配置格式 | TOML | JSON |
| 第三方模型 | ✅ 原生支持 | ⚠️ 需代理 |
| 桌面应用 | ✅ | ⚠️ 有限 |
| 沙箱 | ✅ 内置 | ❌ |
| 权限控制 | TOML 顶层 | settings.json |

---

## 八、实用链接

- Codex 官方文档：https://github.com/openai/codex
- DeepSeek 开放平台：https://platform.deepseek.com
- 配置参考：https://github.com/openai/codex/blob/main/docs/configuration.md
