# Ops

## 流程
Research→Plan→TDD(80%+)→Review→Commit。格式: `<type>: <description>`。

## 安全
无硬编码密钥·输入校验·SQL注入·XSS·CSRF·认证鉴权·限流·错误不泄密。
发现安全问题→STOP→security-reviewer→修复→轮换。

## Agent
自动触发: 复杂→planner, 代码→code-reviewer, Bug→tdd-guide, 架构→architect。
并行≤3。禁止同时编辑同一文件。

## Token效率 (CRITICAL)
- **会话中途不写memory/rules/CLAUDE.md** — 写操作推迟到会话末尾批量执行
- **5分钟缓存TTL** — 连续工作优于间歇
- **输出极致压缩** — 1行结果，不写过程/总结/清单
- **不重读刚编辑的文件** · **优先Grep再Read** · **独立读并行批处理**
- **不自动commit/push** · **Memory仅写重大教训(≥3条+会话末尾)**
- **CLAUDE.md/rules每会话只读一次**

## 系统维护 (CRITICAL)
- `.claude/` 磁盘预算: 30MB上限。超25MB触发清理。
- 每次会话结束: 清理file-history旧于2天、paste-cache、cache、shell-snapshots。
- 每周: npm/pip cache清理，Temp文件夹清理。
- 规则本身上限: 3文件×1KB=3KB。超了继续压缩。

## 双Agent同步
CLI+VS Code: 不同时编辑同一文件·不同时npm install/git commit/push。
启动时读MEMORY.md获取对方更新。
