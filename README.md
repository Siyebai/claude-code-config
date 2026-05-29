# Claude Code 配置仓库 — 姜出尘 (Siyebai)

> 最后更新：2026-05-29
> 模型：deepseek-v4-pro (1M上下文)
> 后端：https://api.deepseek.com/anthropic

## 目录结构

```
├── agents/          # 45个Agent定义（含novel/novel-os）
├── commands/        # 118个/命令（dev/docs/performance/project等）
├── rules/           # 运行规则（craft/identity/ops + common/python）
├── memory/          # 持久记忆（14个文件）
├── hooks/           # 会话钩子（start/end PowerShell脚本）
├── cjx/             # CJX配置文档
├── plans/           # 项目计划
├── settings.json    # 主配置文件
├── settings.local.json  # 本地覆盖配置
├── mcp.json         # MCP服务器配置
├── CLAUDE.md        # 项目指令文件
└── SKILLS_INDEX.md  # 技能索引
```

## 核心配置

- **Agent**: 45个专业Agent，覆盖代码审查/架构/测试/安全/部署
- **Commands**: 118个/命令，12个类别
- **Rules**: craft（代码规范）+ identity（身份行为）+ ops（性能清理）
- **Memory**: 14个记忆文件，含Agent Republic/AIP/白夜/知乎/头条等
- **Permissions**: bypassPermissions模式，全权限
# 维护
# 每次重大配置变更后，运行以下命令更新备份：
# cp -r ~/.claude/agents/ ~/.claude/commands/ ~/.claude/rules/ ~/.claude/settings.json ~/.claude/mcp.json ~/CLAUDE.md <repo>/
# cd <repo> && git add -A && git commit -m "backup: $(date -I)" && git push
