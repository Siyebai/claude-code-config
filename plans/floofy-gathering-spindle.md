# 白夜交易系统 — 深度整合计划

## Context

白夜交易系统（`WorkBuddy/Claw/baiye-trading-system/`）是一个均值回归量化交易系统，125+ Python 文件，币安 USDM 期货，纸交易模式。经过三轮深度审计（指标重复、风控/执行引擎、主引擎/配置），发现系统**策略逻辑有数据支撑**（663笔 OOS 验证，胜率 70.7%，PF 1.51），但**代码工程质量严重拖后腿**。

### 核心问题

| 类别 | 数量 | 最严重的问题 |
|------|------|-------------|
| 指标逻辑重复 | 12+ 份 Wilder、8+ 份 ADX、17+ 份 EMA | 任何修复需要改 4+ 个文件 |
| 信号检测分叉 | 5 种不同实现，3 种 cc 算法变体 | offline_replay 验的不是主引擎的策略 |
| 关键 Bug | 15 个（2 CRITICAL, 6 HIGH） | ws_feeder.py 缺失导致 live_engine 无法启动 |
| 配置腐化 | 20+ 个死变量，版本号矛盾（6.1/7.3/8.0/8.1/8.4/9.3） | 无人知道当前运行的是哪个版本 |

### 用户需求

- **短线交易**：3-60 分钟时间线 ✓（系统已支持 3m/5m/15m/1h）
- **中频交易**：每天几十笔（当前 8 品种约 5-20 笔/天，可扩展）
- **高胜率 + 高盈利率 + 合理盈亏比**：✓ 回测已证明可行

---

## 实施计划

### 阶段一：基础层（建立共享真相源）

#### 步骤 1：创建 `engine/indicators.py` — 规范指标库

新建文件，从 `main_v73.py` 提取经过实战检验的算法：

- `wilder(arr, n)` — Wilder 平滑（12 处重复 → 1 处）
- `compute_indicators(df)` — ATR/ADX/EMA200/RSI/vol_ratio/cu/cd/cc 全量计算
- `ema(df, period)` — EMA 便捷包装
- `atr_vol_pct(df)` — ATR 价格占比

来源：`main_v73.py:117-201`，与 backtest_engine_v3.py 的公式变体统一。

#### 步骤 2：创建 `engine/ws_feeder.py` — 补全缺失模块

`live_engine.py:26` 导入的模块从未存在。需实现：

- `Kline` 数据类（带 `open/high/low/close/volume` 属性别名）
- `KlineBuffer` — 线程安全滑动窗口（maxlen=300）
- `init_buffer_from_rest()` — REST API 预填充历史 K 线
- `BinanceWSFeeder` — WebSocket 实时 K 线订阅 + 自动重连

#### 步骤 3：创建 `engine/signals.py` — 规范信号引擎

合并 `main_v73.py` 的 `_raw_signal` + `compute_signal_score` 和 `engine/signal_engine.py` 的 `evaluate`：

- `Signal` 数据类 — 统一定向/入场/止损/止盈/评分
- `detect_signal(df, sym_cfg)` — 单周期信号检测（纯函数）
- `compute_signal_score(symbol, tf_data, sym_cfg, sig)` — 多周期共振评分 (0-10)

关键修复：统一 `cc` 累计算法为 main_v73 的"方向切换重置"版本（正确版本）。

---

### 阶段二：Bug 修复（8 个）

| # | 严重度 | 文件:行号 | 问题 | 修复 |
|---|--------|-----------|------|------|
| 1 | CRITICAL | ws_feeder.py | 模块缺失 | 步骤 2 已创建 |
| 2 | CRITICAL | live_engine.py:33 | config/strategy_v12.json 不存在 | 改用 `config.py` 的 `SYM_CFG` |
| 3 | HIGH | risk_engine.py:246 | PERCENT 模式 risk_pct 返回美元而非比例 | 统一 `risk_u / capital` |
| 4 | MEDIUM | risk_engine.py:240 | `_was_reduced()` 逻辑脆弱 | 添加 `risk_was_reduced: bool` 标志 |
| 5 | HIGH | order_executor.py:241 | `close_position()` 不取消 SL/TP | 平仓前先 `cancel_all_orders` |
| 6 | HIGH | order_executor.py:313 | `recover_positions()` 用强平价做止损 | 从活跃止损单恢复，找不到则用入场价 ±2% |
| 7 | HIGH | live_engine.py:282 | PnL 估算公式错误 | 用 `(exit-entry) * qty * side` 统一计算 |
| 8 | MEDIUM | risk_engine.py:78 | `consecutive_win_resume` 不可配置 | 加入 `_apply_config` 字段列表 |

---

### 阶段三：迁移重构

#### 步骤 4：重构 `main_v73.py`

删除第 117-201 行（指标）和第 249-396 行（信号），改为：

```python
from engine.indicators import wilder, compute_indicators
from engine.signals import detect_signal, compute_signal_score, Signal
```

持仓管理、Kelly、WRGuard、CorrFilter、主循环保留在 main_v73.py 不动。

#### 步骤 5：重构 `offline_replay.py`

删除第 75-155 行（`_wilder` + `compute_indicators`），导入共享模块。`generate_signals` 改为调用 `detect_signal` 的薄包装。

#### 步骤 6：重构 `live_engine.py`

- 导入 `engine/indicators` + `engine/signals` + `engine/ws_feeder`
- 移除对不存在文件路径的依赖
- Kline 列表转 DataFrame → `compute_indicators` → `detect_signal`

#### 步骤 7：清理 `config.py`

- 删除 20+ 个死变量（EMA_FAST/MID/SLOW、MACD_*、ATR_VOL_*、TRAIL_BREAKEVEN_ATR 等）
- 修复版本号混乱（删除第 35 行 `VERSION = "8.0"`，仅保留 `VERSION = "8.4"`）
- 保留所有被 `main_v73.py` 实际引用的变量

---

### 阶段四：测试与归档

#### 步骤 8：添加单元测试

| 文件 | 覆盖 |
|------|------|
| `tests/test_indicators.py` | wilder 常量/NaN，compute_indicators vs main_v73 回归 |
| `tests/test_signals.py` | detect_signal 长短/过滤/禁用，compute_signal_score 范围 |
| `tests/test_risk_engine.py` | 日熔断、连亏降仓、连胜恢复、was_reduced 回归 |
| `tests/test_order_executor.py` | 签名格式、断线续单安全默认值 |

#### 步骤 9：归档死代码

移入 `scripts/_round6_archive/`：`main_v71.py`、`main_v72.py`、`deep_test_v2.py`、`deep_test_v8.py`、`live_paper_100.py`、`validate_*.py`、`run_100trades_*.py`

保留：`main_v73.py`（生产引擎）、`offline_replay.py`、`optimize_params.py`

#### 步骤 10：端到端验证

1. **指标回归**：新旧 `compute_indicators` 输出 100% 匹配
2. **信号回归**：同一历史数据，新旧信号检测结果一致
3. **离线回放**：重构前后报告（WR/PF/Sharpe）差异 <1%
4. **风控测试**：`python engine/risk_engine.py` 全部断言通过
5. **WebSocket 冒烟**：ws_feeder 导入成功，测试网连接正常

---

## 执行顺序

```
步骤1 indicators ──→ 步骤3 signals ──→ 步骤2 ws_feeder
         ↓                    ↓              ↓
         步骤4 main_v73 ←─────┘              │
         ↓                    ↓              ↓
         步骤5 offline_replay 步骤6 live_engine
         ↓
         步骤7 config 清理 → 步骤8 测试 → 步骤9 归档 → 步骤10 验证
```

前三步无依赖可并行开发。步骤 4-6 依赖前三步完成后进行。

## 关键文件

| 操作 | 文件 |
|------|------|
| 新建 | `engine/indicators.py`, `engine/ws_feeder.py`, `engine/signals.py` |
| 新增 | `tests/test_indicators.py`, `tests/test_signals.py`, `tests/test_risk_engine.py`, `tests/test_order_executor.py` |
| 重构 | `main_v73.py`, `offline_replay.py`, `engine/live_engine.py` |
| 修复 | `engine/risk_engine.py`, `engine/order_executor.py` |
| 清理 | `config.py` |
| 归档 | `main_v71.py`, `main_v72.py`, `deep_test_v*.py`, `live_paper_100.py`, `validate_*.py` |
