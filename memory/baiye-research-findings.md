---
name: baiye-research-findings
description: 白夜交易系统完整研究结论 — v5逐品种优化 + v6 Monte Carlo + v8.6 FarAboveEMA策略集成
metadata:
  node_type: memory
  type: project
  originSessionId: 2026-05-21-vscode
---

# 白夜交易系统 — 完整研究结论

> 最后更新: 2026-05-21 02:30 UTC+8
> 来源: VS Code 端 Claude Code 五轮回测验证 (validate_v2 → v6)

---

## 一、核心发现

**唯一持续盈利的信号: FarAboveEMA SHORT（价格极端偏离 EMA200 时做空）**

经过 v2-v6 五轮回测，均值回归 cu/cd 信号在 25 品种上表现不稳定，而 FarAboveEMA 策略在所有验证维度均通过:
- Monte Carlo 1000次: P(PF>1.5)=100%, P(PF>2.0)=99.9%
- 滚动窗口 18窗: 全部 PF>1.0
- 最大回撤: 1.4%
- Sharpe≈8.24

## 二、策略逻辑 (FarAboveEMA SHORT v8.6)

```
信号触发: (close - ema200) / atr > ema_thresh 且 ADX > 15
方向:     SHORT（做空）
入场:     当前 close 价
止盈:     无 TP，纯时间止盈（持仓 N bar 后市价平仓）
止损:     无 SL
仓位:     5% 资本 × min(2.0, ema_dist / ema_thresh) [动态]
冷却:     平仓后 2 bar
上限:     最多 5 个同时持仓
```

### 为什么无 SL/TP?
- SL 始终降低 PF（noSL 2.90 vs SL4.0 1.89）
- 时间止盈优于价格止盈（极端偏离的均值回归时间可预测，精确价格不可预测）
- 动态仓位自动调节风险暴露

### 为什么是 SHORT 而不是 LONG?
- 25 品种中，下跌趋势 (12品种) >> 上涨趋势 (5品种)
- FarAboveEMA SHORT 在所有市场分区 PF>2.0
- 极端下跌偏离比极端上涨偏离更可持续盈利

## 三、v5 逐品种优化结果 (886s)

### 最优配置: PerSym + noSL + DynamicSize

| 指标 | 值 |
|------|-----|
| 总交易 | 425笔 |
| WR | 65.6% |
| PF | 2.90 |
| 总 PnL | +$736 (14.7% on $5000) |
| 品种数 | 5 (BTC/ETH/BNB/SOL/DOGE) |

### 逐品种最优参数

| 品种 | EMA阈值 | 持仓(bar) | Test PF | Test PnL |
|------|---------|-----------|---------|----------|
| BTCUSDT | >6.0 ATR | 48b | 1.38 | +$36 |
| ETHUSDT | >6.0 ATR | 48b | 6.90 | +$215 |
| BNBUSDT | >6.0 ATR | 36b | 3.60 | +$111 |
| SOLUSDT | >5.5 ATR | 48b | 2.42 | +$119 |
| DOGEUSDT | >6.0 ATR | 48b | 2.52 | +$128 |

**关键发现**:
- 所有品种收敛到 EMA > 6.0 ATR（只有 SOL 5.5）
- 动态仓位一致优于固定仓位
- SL 在所有品种上降低 PF

## 四、v6 深度稳健性验证 (13s)

### Monte Carlo (1000次)
- PF mean = 2.95
- P(PF > 1.5) = 100%
- P(PF > 2.0) = 99.9%
- Sharpe ≈ 8.24

### 市场分区测试
- 所有 ADX 分区 PF > 2.0
- 高 ADX (>25) 分区: PF = 9.07
- 极端偏离 (dist > 9 ATR): PF = 47.53
- 温和偏离 (dist < 5 ATR): PF = 1.01 (唯一边缘区域)

### 滚动窗口 (18窗)
- 全部 PF > 1.0
- 最低 1.06，最高 27.75
- 无连续亏损窗口

### 权益曲线
- 最大回撤: 1.4%
- 每 80 笔分块: 全部正收益
- 无过拟合迹象

## 五、v8.6 代码集成

### config.py 新增
```python
VERSION = "8.6"
FAR_ABOVE_ENABLED = True
FAR_ABOVE_BASE_PS = 0.05       # 每笔 5% 资本
FAR_ABOVE_MAX_POS = 5          # 最多 5 个同时持仓
FAR_ABOVE_COOLDOWN = 2         # 冷却 2 bar
FAR_ABOVE_DYN_SIZE = True      # 动态仓位
FAR_ABOVE_ADX_MIN = 15         # ADX 最低过滤

FAR_ABOVE_PARAMS = {
    "BTCUSDT":  {"ema_thresh": 6.0, "hold_bars": 48},
    "ETHUSDT":  {"ema_thresh": 6.0, "hold_bars": 48},
    "BNBUSDT":  {"ema_thresh": 6.0, "hold_bars": 36},
    "SOLUSDT":  {"ema_thresh": 5.5, "hold_bars": 48},
    "DOGEUSDT": {"ema_thresh": 6.0, "hold_bars": 48},
}
```

### engine/signals.py 新增
- `detect_far_above_signal()` — FarAboveEMA SHORT 信号检测（纯函数）
- `Signal` 扩展: `signal_type` (cu_cd|far_above), `hold_bars`, `ema_dist`

### engine/paper_engine.py → v3.0 双策略
- 策略 A (主力): FarAboveEMA SHORT — 极端偏离检测 → 时间止盈 → 动态仓位
- 策略 B (备用): cu/cd 趋势跟随 — TP/SL/追踪止损/多周期评分
- `VirtualPosition` 扩展: signal_type, hold_bars, ema_dist
- `ClosedTrade` 扩展: signal_type
- 状态恢复兼容: 旧数据无新字段 → setdefault 兼容

## 六、验证脚本

| 脚本 | 用途 | 耗时 |
|------|------|------|
| validate_v1.py | 初始可行性 | - |
| validate_v2.py | 参数扫描 | - |
| validate_v3.py | SL/TP 测试 | - |
| validate_v4.py | 多品种验证 | - |
| validate_v5.py | 逐品种优化 (PerSym+noSL+Dyn) | 886s |
| validate_v6.py | Monte Carlo + 滚动窗口 + 分区 | 13s |

## 七、策略对比总结

| 维度 | cu/cd (v8.4) | FarAboveEMA (v8.6) |
|------|-------------|-------------------|
| 信号类型 | 趋势跟随 (连涨做空/连跌做多) | 极端偏离回归 (偏离EMA→做空) |
| 止盈 | TP (ATR倍数) | 时间止盈 (持仓N bar市价平) |
| 止损 | SL (ATR倍数) | 无 SL |
| 仓位 | 固定/动态 | 动态 (5% × dist/thresh, max 2x) |
| 验证 | 663笔 WF | 1000次 MC |
| PF | 1.38 (均值) | 2.95 (均值) |
| 角色 | 备用策略 | **主力策略** |

## 八、下一步

1. 启动 v3.0 纸交易引擎观察 FarAbove 信号频率
2. 如信号太少 → 降低阈值 (6.0→5.0 ATR)
3. 如信号过多 → 提高阈值或 ADX 过滤
4. 考虑扩展更多品种的逐品种参数

## 九、v9.1 升级 (2026-05-23)

### config.py
- `FAR_ABOVE_ADX_MIN`: 15 → 20 (过滤弱趋势噪音)
- `FAR_BELOW_ADX_MIN`: 15 → 20 (对称)
- 品种扩展: 10 → 25品种
- 策略扩展: FarAbove SHORT + FarBelow LONG 双策略

### engine/paper_engine.py — Bug修复
- **FarBelow TP/SL 对称**: TP=+5%, SL=-3% (原 TP=+3%, SL=-5%, RR=0.6)
- **每策略仓位限制**: FarAbove=7, FarBelow=7 (原 combined max_pos=14)
- **防重复开仓**: position创建前检查 `symbol in _global_positions`

### engine/watchdog.py — 引擎启动修复
- **pythonw.exe → python.exe**: pythonw.exe Win11静默崩溃
- **启动方式**: subprocess.Popen + python.exe + CREATE_NO_WINDOW
- **PID 文件**: data/.engine_pid 进程追踪

### 过夜验证 (9小时)
- 9笔新交易，全部 ADX≥20 信号
- Capital: $996.50 → $1012.80 (+$16.33, +1.6%)
- 平仓: 10→19笔 (14W/5L), WR: 50%→74%
- PF: 0.79→1.77
- FarBelow 信号首次出现 (ETH/ADA/LTC/SOL)，被 EV 过滤

### 运行状态 (05-23 15:42)
- Engine PID 348 + Watchdog PID 18004 (双层守护)
- 7 FarBelow LONG 仓位: BTC, ETH, SOL, DOGE, XRP, DOT, LINK
- Capital: $1029.16 | PnL: +$29.16 (+2.9%)
- 28 trades (23W/5L) | WR=82% | PF=2.76

### 待观察
- FarBelow 需要更大回调触发 (当前弱回调被EV过滤)
- 进一步 ADX_MIN 调整可考虑 (20→25 如果 PF 持续 <2.0)
- python.exe 启动方式是否完全消除静默崩溃

---

## 平台运营研究 (from platform-research)

四大写作平台运营知识库：知乎(思夜白)、今日头条(夜不悔)、番茄小说、小红书。研究方向：推荐算法、变现模式、起号策略。知识标注：平台|来源|日期|可信度。
