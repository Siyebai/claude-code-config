# Claude Code 配置仓库

姜出尘(Siyebai)的 Claude Code 完整配置文件。独立维护，可快速部署到新环境。

## 目录结构

```
claude-code-config/
├── CLAUDE.md              # 项目指令(放到 ~/CLAUDE.md)
├── mcp.json               # MCP 服务配置(放到 ~/.claude/.mcp.json)
├── settings.json          # Claude Code 设置(放到 ~/.claude/settings.json)
├── rules/                 # 行为规则(放到 ~/.claude/rules/)
│   ├── identity.md        # 身份定义+权限
│   ├── craft.md           # 代码质量标准
│   └── ops.md             # 开发流程+Token优化
├── memory/                # 持久记忆(放到 ~/.claude/projects/.../memory/)
│   ├── MEMORY.md          # 记忆索引(17个记忆文件)
│   ├── user-identity.md   # 用户身份
│   ├── feedback-output-style.md # 输出风格规则
│   └── ...                # 其他15个记忆文件
├── agents/                # 45个Agent定义(放到 ~/.claude/agents/)
├── commands/              # 斜杠命令(放到 ~/.claude/commands/)
├── MASTER-REFERENCE.md    # 主控参考 — 新环境快速唤醒全部记忆
└── 13-Codex部署配置教程.md  # Codex Desktop + DeepSeek 新手完整部署教程
```

## 部署方法

```bash
# 1. 克隆仓库
git clone <repo-url>
cd claude-code-config

# 2. 复制规则
cp rules/*.md ~/.claude/rules/

# 3. 复制记忆
cp memory/*.md ~/.claude/projects/C--Users----/memory/

# 4. 复制Agent
cp agents/*.md ~/.claude/agents/

# 5. 复制命令
cp -r commands/* ~/.claude/commands/

# 6. 复制主配置
cp CLAUDE.md ~/CLAUDE.md
cp mcp.json ~/.claude/.mcp.json
cp settings.json ~/.claude/settings.json
```

## 核心配置说明

### Rules (行为规则)
- **identity.md** — 定义AI助手身份：姜出尘的AI幕僚，全栈工程师，最高信任模式
- **craft.md** — 代码质量：不可变数据、小文件、错误处理、输入校验
- **ops.md** — 开发流程：TDD→Review→Commit，Token效率优化，Agent编排

### Memory (持久记忆)
- 17个记忆文件覆盖：项目开发计划、写作风格、交易研究、平台运营、经验教训
- 启动时读MEMORY.md索引，按需加载具体文件
- 记忆写操作推迟到会话末尾批量执行(保护缓存)

### 优化要点
- 缓存命中率目标: 90%+
- 会话中不修改rules/memory/CLAUDE.md(保护前缀缓存)
- 输出风格: 极致精简，中文1-5行，不展示代码块和执行过程
- 不自动commit/push，不弹确认，先探索后提问

## 维护

```bash
# 本地配置变更后同步到仓库
cp ~/.claude/rules/*.md rules/
cp ~/CLAUDE.md .
# 提交推送
git add -A && git commit -m "chore: sync config" && git push
```

## 版本历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-05-29 | v1.0 | 初始版本：45 agent + 8命令目录 + 17记忆 + 3规则 |
