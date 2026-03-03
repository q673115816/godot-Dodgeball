# 产品需求文档 (PRD)
## 躲避球 × Roguelike - 技能系统设计方案

**版本**: 1.0
**日期**: 2026-03-03
**项目**: Godot Dodgeball Game (躲避球)

---

## 1. 项目概述

### 1.1 产品定位
在原有快节奏 2D 躲避球游戏基础上，融入 Roguelike 元素，增加技能获取系统，提升游戏的策略性和重复可玩性。

### 1.2 核心变更
- **原机制**: 纯生存躲避，难度随时间线性增长
- **新机制**: 每提升一个 Level 随机获得一个技能，技能可能提升或降低游戏难度

---

## 2. Roguelike 技能系统设计

### 2.1 技能获取机制

| 触发条件 | 说明 |
|---------|------|
| **触发时机** | 每存活 5 秒，Level +1 时 |
| **获取方式** | 三选一随机技能池 |
| **技能持续** | 当前局内永久生效 |
| **技能叠加** | 同类技能可叠加（有上限） |

### 2.2 技能分类

#### 🟢 增益类技能 (Positive) - 约 50% 概率

| 技能 ID | 技能名称 | 效果描述 | 叠加规则 |
|--------|---------|---------|---------|
| `slow_time` | 时间减缓 | 球速降低 10% | 可叠加，上限 50% |
| `shield` | 护盾 | 可抵挡 1 次撞击 | 不可叠加，仅层数 +1 |
| `slow_spawn` | 生成减缓 | 球生成间隔 +15% | 可叠加，上限 75% |
| `small_player` | 缩小化 | 玩家体积缩小 20% | 可叠加，上限 50% |
| `speed_boost` | 加速移动 | 玩家移动速度 +15% | 可叠加，上限 60% |
| `ball_slowdown` | 减速力场 | 靠近玩家的球自动减速 30% | 可叠加，效果范围扩大 |
| `double_score` | 时间扭曲 | 生存时间流逝速度 -20% | 可叠加，上限 60% |
| `magnet` | 磁力偏转 | 自动偏转身边的球 (小范围) | 不可叠加，仅扩大范围 |

#### 🔴 减益类技能 (Negative) - 约 30% 概率

| 技能 ID | 技能名称 | 效果描述 | 叠加规则 |
|--------|---------|---------|---------|
| `fast_balls` | 狂怒之球 | 球速增加 15% | 可叠加 |
| `rapid_spawn` | 疯狂生成 | 球生成间隔 -10% | 可叠加 |
| `big_player` | 巨大化 | 玩家体积增大 25% | 可叠加 |
| `slow_player` | 沉重步伐 | 玩家移动速度 -15% | 可叠加 |
| `blind_mode` | 盲视模式 | 玩家半透明，视野变暗 | 不可叠加 |
| `reverse_controls` | 反向控制 | 方向键反转 | 不可叠加 |
| `multi_spawn` | 多重生成 | 每次生成额外 +1 个球 | 可叠加 |
| `tornado_mode` | 龙卷风 | 球轨迹变为曲线 (难预测) | 不可叠加 |

#### ⚡ 特殊类技能 (Special) - 约 20% 概率

| 技能 ID | 技能名称 | 效果描述 | 叠加规则 |
|--------|---------|---------|---------|
| `vampire` | 吸血 | 每躲避 50 个球，Level -1 | 不可叠加 |
| `bomb` | 炸弹 | 每 10 秒清除屏幕上所有球 | 不可叠加 |
| `ghost` | 幽灵 | 死亡后 3 秒内可复活 (每局限 1 次) | 不可叠加 |
| `chaos` | 混沌 | 随机应用 2 个增益 +2 个减益 | 可叠加，每次随机 |
| `golden_touch` | 黄金触手 | 每级获得额外金币 (未来扩展) | 可叠加 |
| `time_freeze` | 时间冻结 | 每 20 秒冻结所有球 2 秒 | 不可叠加 |
| `black_hole` | 黑洞 | 屏幕中央生成吸引球的黑洞 | 不可叠加 |
| `mirror` | 镜像 | 生成一个诱饵吸引球 | 可叠加，数量 +1 |

---

## 3. 技能池权重系统

### 3.1 动态权重调整

```
基础权重:
- 增益类：50%
- 减益类：30%
- 特殊类：20%

动态调整因子:
- Level 1-3: 增益类 +20% (新手保护)
- Level 4-7: 基础权重
- Level 8-10: 减益类 +15% (高风险高回报)
- Level 10+: 特殊类 +20% (极限挑战)
```

### 3.2 技能选择 UI

```
┌─────────────────────────────────────┐
│         LEVEL UP!                   │
│         Choose a Skill              │
├─────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐ │
│  │  时间减缓    │  │  加速移动    │ │
│  │  球速 -10%   │  │  速度 +15%   │ │
│  │   [SELECT]   │  │   [SELECT]   │ │
│  └──────────────┘  └──────────────┘ │
│  ┌──────────────┐                   │
│  │  疯狂生成 ⚠️ │                   │
│  │  生成 +10%   │                   │
│  │   [SELECT]   │                   │
│  └──────────────┘                   │
└─────────────────────────────────────┘
```

---

## 4. 技术实现方案

### 4.1 新增文件结构

```
game/
├── skill_manager.gd       # 技能管理器 (单例)
├── skill_data.gd          # 技能数据定义
├── skill_selection_ui.tscn # 技能选择 UI 场景
├── skill_selection_ui.gd   # 技能选择 UI 逻辑
└── skills/
    ├── slow_time.gd
    ├── shield.gd
    ├── fast_balls.gd
    └── ... (其他技能)
```

### 4.2 SkillManager 核心接口

```gdscript
# skill_manager.gd (Autoload Singletons)
class_name SkillManager extends Node

signal skill_acquired(skill_id: String)
signal skill_removed(skill_id: String)

var active_skills: Dictionary = {}  # {skill_id: stack_count}

func acquire_skill(skill_id: String) -> void
func remove_skill(skill_id: String) -> void
func has_skill(skill_id: String) -> bool
func get_skill_stack(skill_id: String) -> int
func generate_skill_pool(count: int = 3) -> Array
func apply_all_modifiers() -> void
```

### 4.3 技能数据结构

```gdscript
# skill_data.gd
class SkillData:
    const SKILLS = {
        "slow_time": {
            "name": "时间减缓",
            "type": "positive",
            "description": "球速降低 10%",
            "max_stack": 5,
            "effect": {"ball_speed_modifier": -0.1}
        },
        "shield": {
            "name": "护盾",
            "type": "positive",
            "description": "抵挡 1 次撞击",
            "max_stack": 99,
            "effect": {"shield_layer": 1}
        },
        # ... 其他技能
    }
```

### 4.4 main.gd 修改点

```gdscript
# 在 increase_difficulty() 函数中
func increase_difficulty():
    difficulty_level += 1
    $HUD/DifficultyLabel.text = "Level: " + str(difficulty_level)

    # Level Up 时触发技能选择
    if difficulty_level > 1:  # Level 1 不触发
        SkillManager.pause_game()
        SkillManager.show_skill_selection()

    # ... 原有难度逻辑
```

### 4.5 Player.gd 修改点

```gdscript
# 在 _physics_process 中应用技能效果
func _physics_process(delta):
    var current_speed = speed

    # 应用技能修饰
    if SkillManager.has_skill("speed_boost"):
        current_speed *= 1.0 + (SkillManager.get_skill_stack("speed_boost") * 0.15)

    if SkillManager.has_skill("slow_player"):
        current_speed *= 1.0 - (SkillManager.get_skill_stack("slow_player") * 0.15)

    # ... 原有移动逻辑
```

---

## 5. 游戏平衡设计

### 5.1 期望体验曲线

```
难度
  ↑
  │                    ╭─── 带技能期望
  │                  ╱
  │                ╱
  │              ╱
  │            ╱
  │          ╱
  │        ╱
  │      ╱
  │    ╱────── 原始难度曲线
  │  ╱
  │╱
  └──────────────────→ 时间/Level
```

### 5.2 动态难度补偿

- **连败补偿**: 连续 3 局未超过 Level 5 → 下一局增益类技能 +15%
- **连胜惩罚**: 连续 3 局超过 Level 10 → 下一局减益类技能 +15%
- **技能 Ban 选**: 允许玩家 Ban 掉 1 个最不想要的技能 (后期功能)

---

## 6. UI/UX 需求

### 6.1 技能选择界面
- [ ] 三选一卡片展示
- [ ] 技能名称、图标、描述
- [ ] 稀有度颜色标识 (绿/红/紫)
- [ ] 选择后动画反馈
- [ ] 超时自动选择随机技能 (15 秒)

### 6.2 游戏中 HUD
- [ ] 当前激活技能图标栏 (左上角)
- [ ] 技能层数显示
- [ ] 护盾层数单独显示
- [ ] 特殊技能冷却指示器

### 6.3 技能收集系统 (未来扩展)
- [ ] 技能图鉴
- [ ] 解锁成就
- [ ] 技能点数系统

---

## 7. 技术风险与解决

| 风险 | 影响 | 解决方案 |
|-----|------|---------|
| 技能效果冲突 | 游戏崩溃/异常 | 效果应用顺序标准化，设置优先级 |
| 性能下降 | 大量技能检查拖累帧率 | 使用事件驱动而非每帧检查 |
| 数值失衡 | 过于简单/困难 | A/B 测试 + 玩家数据调优 |
| UI 阻塞 | 技能选择打断节奏 | 添加暂停/不暂停可选模式 |

---

## 8. 开发里程碑

### Phase 1 - 基础框架 (Week 1)
- [ ] SkillManager 单例实现
- [ ] 技能数据结构定义
- [ ] 基础技能选择 UI

### Phase 2 - 核心技能 (Week 2)
- [ ] 实现 8 个增益技能
- [ ] 实现 8 个减益技能
- [ ] 实现 4 个特殊技能

### Phase 3 - 平衡调试 (Week 3)
- [ ] 权重系统调优
- [ ] 动态难度补偿
- [ ] 内部测试迭代

### Phase 4 -  polish (Week 4)
- [ ] UI 美化与动画
- [ ] 音效与反馈
- [ ] 技能图鉴系统

---

## 9. 成功指标

| 指标 | 目标值 | 测量方式 |
|-----|-------|---------|
| 平均单局时长 | +30% | 游戏数据统计 |
| 7 日留存率 | +15% | 玩家追踪 |
| 技能选择多样性 | >80% 技能被选择 | 技能使用率统计 |
| 玩家满意度 | >4.0/5.0 | 评分系统 |

---

## 10. 附录

### 10.1 技能完整列表 (24 个)

**增益 (12 个)**: slow_time, shield, slow_spawn, small_player, speed_boost, ball_slowdown, double_score, magnet, regen, luck, fortune, blessing

**减益 (8 个)**: fast_balls, rapid_spawn, big_player, slow_player, blind_mode, reverse_controls, multi_spawn, tornado_mode

**特殊 (4 个)**: vampire, bomb, ghost, chaos

### 10.2 未来扩展方向
- 多人对战模式 (技能互相干扰)
- 每日挑战 (固定技能组合)
- 无尽模式 (Level 10+ 后继续)
- 技能合成系统

---

**文档结束**

*本文档为躲避球 × Roguelike 技能系统的初始设计，具体实现细节将在开发过程中迭代优化。*
