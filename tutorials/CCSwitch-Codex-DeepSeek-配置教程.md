# CCSwitch + Codex + DeepSeek 完整配置教程

> 维护人：姜出尘 (Siyebai) | 创建：2026-05-29
> 适用系统：Windows 11 | 适用人群：零基础新手

---

## 一、CCSwitch 是什么

CCSwitch 是一个本地代理服务器，运行在 `127.0.0.1:11435`，作用是把 Codex 的请求转发给 DeepSeek API，并自动处理消息格式兼容、角色注入、长期记忆等功能。

**为什么需要 CCSwitch？**
- Codex 发送的消息格式与 DeepSeek 不完全兼容
- CCSwitch 自动翻译消息格式，让 Codex 无缝使用 DeepSeek
- 支持注入人设（PERSONA.md）和长期记忆（CODEX-MEMORY.md）
- 自动恢复被截断的 reasoning/thinking 内容

---

## 二、环境准备

### 2.1 安装 Node.js

CCSwitch 需要 Node.js 运行。下载地址：https://nodejs.org

```powershell
# 验证安装
node --version   # 需要 >= v18
npm --version
```

### 2.2 下载 CCSwitch

```bash
cd D:\DevTools
git clone https://github.com/Siyebai/ccswitch.git
# 如果 GitHub 被墙，直接从本地已有副本复制到 D:\DevTools\ccswitch
```

### 2.3 安装依赖

```bash
cd D:\DevTools\ccswitch
npm install
```

### 2.4 配置 API Key

在 `D:\DevTools\ccswitch\` 目录创建 `.env` 文件：

```env
api_key=sk-你的DeepSeek-API-Key
model=deepseek-v4-pro
port=11435
upstream_base_url=https://api.deepseek.com/v1
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `api_key` | DeepSeek API 密钥 | 必填 |
| `model` | 默认模型 | deepseek-v4-pro |
| `port` | CCSwitch 监听端口 | 11435 |
| `upstream_base_url` | DeepSeek API 地址 | https://api.deepseek.com/v1 |

---

## 三、启动 CCSwitch

### 方式一：手动启动

```bash
cd D:\DevTools\ccswitch
npm start
```

看到以下输出表示成功：
```
[CCSwitch] DeepSeek proxy running on http://127.0.0.1:11435
[CCSwitch] Upstream: https://api.deepseek.com/v1
[CCSwitch] Model: deepseek-v4-pro
```

### 方式二：VBS 静默后台启动（推荐）

创建 `D:\DevTools\ccswitch\start-proxy-hidden.vbs`：

```vbs
CreateObject("WScript.Shell").Run "cmd /c cd /d D:\DevTools\ccswitch && node index.js", 0, False
```

双击此文件即可在后台启动，无命令行窗口。

### 方式三：开机自启

1. `Win+R` → `shell:startup`
2. 创建快捷方式指向 `start-proxy-hidden.vbs`

---

## 四、配置 Codex 使用 CCSwitch

### 4.1 安装 Codex

从 https://github.com/openai/codex/releases 下载 `Codex-Setup-x64.exe`，双击安装。

### 4.2 配置 config.toml

编辑 `C:\Users\你的用户名\.codex\config.toml`：

```toml
model = "deepseek-v4-pro"
approval_policy = "never"

[models.deepseek-v4-pro]
provider = "openai"
api_key = "ccswitch"
base_url = "http://127.0.0.1:11435/v1"

[models.deepseek-v4-flash]
provider = "openai"
api_key = "ccswitch"
base_url = "http://127.0.0.1:11435/v1"
```

**关键点：**
- `base_url` 指向 CCSwitch 地址（非 DeepSeek 直连）
- `api_key` 填任意值（CCSwitch 会用 `.env` 中的真实 key）
- 所有请求经由 CCSwitch 翻译后转发 DeepSeek

### 4.3 验证

```bash
codex doctor          # 检查配置
codex "你好"           # 测试对话
```

---

## 五、进阶配置

### 5.1 人设注入

在 `D:\DevTools\ccswitch\PERSONA.md` 写入你的偏好：

```markdown
你是姜出尘的AI幕僚。全栈开发者。Windows 11。
永远用中文回复。简洁直接，不反问。
```

CCSwitch 会自动在每次对话中注入此内容。

### 5.2 长期记忆

Codex 可以通过 shell 命令写入记忆：

```bash
echo "## 2026-05-29\n- 完成XX项目配置" >> D:\DevTools\ccswitch\CODEX-MEMORY.md
```

CCSwitch 在每次请求时自动加载此文件作为上下文。

### 5.3 模型切换

临时使用 Flash 模型：
```bash
codex --model deepseek-v4-flash "快速问题"
```

---

## 六、故障排查

| 问题 | 原因 | 解决 |
|------|------|------|
| `Connection refused` | CCSwitch 未启动 | 先运行 `npm start` |
| `401 Unauthorized` | API Key 错误 | 检查 `.env` 中的 `api_key` |
| `config.toml 格式错误` | 配置段写错位置 | `approval_policy` 必须写在顶层 |
| 中文乱码 | 编码问题 | CCSwitch `.env` 用 UTF-8 保存 |

---

## 七、完整架构图

```
Codex (桌面/终端)
    │
    │  API 请求 (OpenAI 格式)
    ▼
CCSwitch (127.0.0.1:11435)
    │
    │  格式翻译 + 人设注入 + 记忆加载
    ▼
DeepSeek API (api.deepseek.com)
    │
    │  AI 响应
    ▼
CCSwitch → 翻译回 OpenAI 格式 → Codex 显示
```
