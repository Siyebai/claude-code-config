---
name: zhihu-monetization-pipeline
description: "知乎短篇变现管线 v1.0: 7阶段管道 + MCP工具链 + 35指标五维Rubric"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5102d8c9-5998-476e-8358-79d826bcc17c
---

# 知乎短篇变现管线 v1.0

2026-05-22 创建。知乎盐言短篇小说创作→发布的全流程管线。

## 管线架构

7 阶段: 热点发现 (hotnews-mcp) → 选题决策 (story-short-scan) → 对标拆文 (story-short-analyze) → AI创作 (story-short-write) → 多角审查 (story-review) → 去AI味 (story-deslop) → 发布配图 (zhihu-mcp + baoyu-image-cards)

## 核心文件

- **管线编排**: `~/.claude/skills/story-short-scan/references/pipelines/zhihu-monetization.md`
- **知乎 Rubric**: `~/.claude/skills/story-review/references/rubrics/zhihu.md` (35 指标, 五维加权)
- **MCP 配置**: `~/.claude/mcp.json`
- **安装脚本**: `~/mcp-servers/setup.sh`

## MCP 工具链 (3 个)

1. `wengchengjian/hotnews-mcp` — 知乎热榜/微博/百度/抖音实时数据
2. `futurehafuture/zhihu-mcp` — 知乎搜索 & 内容获取 (Playwright)
3. `wingAGI/zhihu-mcp` — 知乎 Markdown 发布 (Playwright)

## 阻塞

MCP 服务器未安装 — 网络不通无法 git clone。setup.sh 和 mcp.json 已就绪，网络恢复后运行 `bash ~/mcp-servers/setup.sh` 即可。

## 改进点 (vs 原始状态)

- zhihu rubric: 8 个 PASS/FAIL → 35 指标五维加权 (情绪工程 1.5x 权重最高)
- 数据来源: CDP only → MCP 优先 → CDP 降级
- 管线: 零散 skill 调用 → 7 阶段统一编排
- 交叉引用: rubric ↔ pipeline ↔ skills 全部互链
- story-short-write: 明确知乎盐言加载 rubric 指令

**Why:** 知乎盐选是短篇变现最直接路径。原有 14 个 story-* skills 功能完备但缺乏知乎平台特化配置和管线编排。
**How to apply:** `/story-short-scan zhihu` 触发完整管线。MCP 安装前用 CDP 或用户提供数据降级运行。

## 创作方法 (v4)

**核心原则**: 多角色差异化叙事 · 热叙事底 · 口语魂 · 反陈词滥调

### 三大技法
1. **负空间描述法** — 写"没做什么"而非"做了什么"
2. **异常细节法** — 只写不对劲的地方
3. **人物化描述法** — 给场景态度（拟人化场景）

### 四层叙事
- 叙事底层: 热的——允许情绪直接书写
- 对话层: 口语魂——口癖、废话、突然转移话题
- 动作层: 差异化——每人独特动作习惯
- 观察层: 反陈词滥调——不写套路描写

### 检测三问（每段）
1. 是我自己观察到的，还是"记得别人这样写过"？后者→换
2. 删掉这段有影响吗？无→删
3. 读者看过多少遍类似的？100+→必须换

### 创作铁律10条
1. 不完美才是人，完美即是AI
2. 陈词滥调是AI的温床
3. 拒绝所有"似曾相识"
4. 主角必须主动——不做则已，做就做到底
5. 每500字必须有新的信息量
6. 不用"突然""忽然""猛地"——写出具体转折过程
7. 对话中不说话的一方必须有动作
8. 结尾不需要总结——让最后一个画面自己说话
9. 不使用emoji作为正文标点
10. 输出仅故事文本，不做解释

### 盐选投稿参数
- 导语 ≤300字 / 全篇 1w-2w / 付费点前3000字精磨
- 第一人称全程不切换 / 直角引号「」
- 投前发回答攒数据（女频100+赞，男频20+赞）
- 热门题材: 悬疑·校园·职场·亲情（均有模板）

## 参考

- 完整系统文档: `C:\Users\李初尘\OneDrive\桌面\思夜白创作运营全系统_v1.md`
