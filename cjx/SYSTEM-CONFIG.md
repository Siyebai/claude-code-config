# Codex 系统配置快照

## settings.json 关键值
- effortLevel: low
- fastMode: true
- model: deepseek-v4-pro
- subagent: deepseek-v4-flash
- permissions: bypass
- hooks: SessionStart + Stop (自动清理缓存)

## CLAUDE.md 铁律
1. 输出 ≤3行，只给结论
2. 不反问，直接执行
3. 不预读全部记忆
4. ≤5次工具调用

## 记忆文件 (12个核心)
1. AIP-RFC-合集.md (~64KB)
2. agent-republic-plan-v4.md (~38KB)
3. 系统配置合集.md (~12KB)
4. siyebai-default-writing-style.md (~12KB)
5. night-log.md (~13KB)
6. baiye-research-findings.md (~7KB)
7. lessons-learned.md (~4KB)
8-12: 其他轻量文件

## 自动维护
- SessionStart: 清空 paste-cache/shell-snapshots/telemetry
- SessionEnd: 压缩 >200KB 的JSONL
- 每周日03:00: 深度清理 (计划任务)
