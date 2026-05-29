# Ops — 开发流程 + 测试 + 安全 + 双 agent 同步

## 开发流程
1. Research(GitHub→文档→包注册) → 2. Plan(planner + PRD + 架构) → 3. TDD(RED→GREEN→IMPROVE→80%+) → 4. Review(code-reviewer→修复CRITICAL/HIGH) → 5. Commit

提交格式: `<type>: <description>` (feat/fix/refactor/docs/test/chore/perf/ci)

PR: 分析全提交历史 → `git diff [base]...HEAD` → 完整摘要+测试计划 → push -u

## 测试
强制 TDD。覆盖: 单元+集成+E2E。失败→tdd-guide agent→检查隔离/模拟/实现。

## 安全 (提交前必查)
- 无硬编码密钥 ✓ 输入校验 ✓ SQL注入防御 ✓ XSS防御 ✓ CSRF ✓ 认证鉴权 ✓ 限流 ✓ 错误不泄露敏感信息
- 秘密: 永不超过环境变量/密钥管理。暴露立即轮换。
- 发现安全问题: STOP → security-reviewer → 修复CRITICAL → 轮换暴露秘密 → 全库审查

## Agent 编排
- 自动触发: 复杂功能→planner, 写/改代码→code-reviewer, Bug/新功能→tdd-guide, 架构→architect
- 并行: 独立操作始终并行，最多3并发。禁止同时编辑同一文件。
- Heartbeat(空闲时 2-4次/日): 检查面板+端口+git状态+记忆维护

## Token 效率 (CRITICAL)

### 缓存命中级 (最高优先级)
- **会话中途禁止写 memory/rules/CLAUDE.md**。任何修改 = 下次请求前缀全变 = 缓存 0%命中 = 30K+ token 全价重算。所有 memory 写入推迟到会话末尾一次性批量执行
- **5分钟窗口**: 缓存 TTL 5分钟。连续快速工作 > 断断续续。间歇超5分钟 = 缓存过期全损
- **工具顺序稳定**: 同样的工具调用顺序有利于前缀匹配。避免交替使用不同工具模式
- **目标**: 90%+ 缓存命中率。系统提示(30K-40K)全缓存 → 每次请求仅对话增量付费

### 次优先级
- **Git**: 不自动 commit/push。仅用户明确指令或重大里程碑
- **Memory**: 仅写重大教训/模式/纠正。单次任务细节不写。积攒≥3条+会话末尾才更新 MEMORY.md
- **读文件**: 永不重读刚编辑过的文件。独立读并行批处理。优先 Grep 再 Read
- **输出**: 极致压缩。1行结果/错误。不写过程/总结/确认清单
- **编辑**: 小范围单处修改(<200行文件)。CLAUDE.md/rules 每会话只读一次

## 双 Agent 同步 (CLI + VS Code)
- 操作后写文件: 知识→memory/*.md, 配置→rules/, 行为变更→CLAUDE.md(重大才写,不写每日日志)
- 冲突预防: 不同时编辑同一文件，不同时 npm install/git commit/push
- 启动时检查 memory/MEMORY.md 获取对方更新
