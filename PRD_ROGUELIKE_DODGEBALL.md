# 产品需求文档 (PRD)
## 躲避球 × Roguelike - 技能系统设计方案

**版本**: 2.0
**日期**: 2026-03-05
**项目**: Godot Dodgeball Game (躲避球)
**状态**: 核心功能已实现

---

## 1. 项目概述

### 1.1 产品定位
在原有快节奏 2D 躲避球游戏基础上，融入 Roguelike 元素，增加技能获取系统，提升游戏的策略性和重复可玩性。

### 1.2 核心变更
- **原机制**: 纯生存躲避，难度随时间线性增长
- **新机制**: 每提升一个 Level 自动获得一个随机技能，技能可能提升或降低游戏难度

### 1.3 实现状态
| 模块 | 状态 | 完成度 |
|------|------|--------|
| SkillManager 单例 | ✅ 已完成 | 100% |
| 技能数据定义 | ✅ 已完成 | 100% |
| 技能效果修饰器 | ✅ 已完成 | 100% |
| 动态权重系统 | ✅ 已完成 | 100% |
| 技能选择 UI | ⏸️ 暂缓 (当前为自动获取) | 0% |
| HUD 技能显示 | ✅ 已完成 | 100% |

---

## 2. Roguelike 技能系统设计

### 2.1 技能获取机制

| 触发条件 | 说明 | 实现状态 |
|---------|------|---------|
| **触发时机** | 每存活约 8 秒，Level +1 时 | ✅ 已实现 |
| **获取方式** | 自动随机获取一个技能 | ✅ 已实现 (原设计为三选一) |
| **技能持续** | 当前局内永久生效 | ✅ 已实现 |
| **技能叠加** | 同类技能可叠加 (有上限) | ✅ 已实现 |

### 2.2 技能分类与实现状态

#### 🟢 增益类技能 (Positive) - 约 50% 概率

| 技能 ID | 技能名称 | 效果描述 | 叠加规则 | 实现状态 |
|--------|---------|---------|---------|---------|
| `slow_time` | 时间减缓 | 球速降低 10% | 可叠加，上限 5 层 | ✅ 已实现 |
| `shield` | 护盾 | 可抵挡 1 次撞击 | 不可叠加，仅层数 +1 | ✅ 已实现 |
| `slow_spawn` | 生成减缓 | 球生成间隔 +15% | 可叠加，上限 5 层 | ✅ 已实现 |
| `small_player` | 缩小化 | 玩家体积缩小 20% | 可叠加，上限 3 层 | ✅ 已实现 |
| `speed_boost` | 加速移动 | 玩家移动速度 +15% | 可叠加，上限 4 层 | ✅ 已实现 |
| `ball_slowdown` | 减速力场 | 靠近玩家的球自动减速 30% | 可叠加，上限 3 层 | ✅ 已实现 |
| `double_score` | 时间扭曲 | 生存时间流逝速度 -20% | 可叠加，上限 3 层 | ✅ 已实现 |
| `magnet` | 磁力偏转 | 自动偏转身边的球 (150 像素范围) | 不可叠加 | ✅ 已实现 |
| `regen` | 生命恢复 | 每级恢复 1 层护盾 | 不可叠加 | ✅ 已实现 |
| `luck` | 幸运 | 增益技能概率 +10% | 可叠加，上限 3 层 | ✅ 已实现 |
| `fortune` | 财富 | 金币获取 +25% | 可叠加，上限 3 层 | ⏸️ 预留 (金币系统未实现) |
| `blessing` | 祝福 | 所有属性 +5% | 可叠加，上限 5 层 | ✅ 部分实现 |

#### 🔴 减益类技能 (Negative) - 约 30% 概率

| 技能 ID | 技能名称 | 效果描述 | 叠加规则 | 实现状态 |
|--------|---------|---------|---------|---------|
| `fast_balls` | 狂怒之球 | 球速增加 15% | 可叠加，上限 5 层 | ✅ 已实现 |
| `rapid_spawn` | 疯狂生成 | 球生成间隔 -10% | 可叠加，上限 5 层 | ✅ 已实现 |
| `big_player` | 巨大化 | 玩家体积增大 25% | 可叠加，上限 3 层 | ✅ 已实现 |
| `slow_player` | 沉重步伐 | 玩家移动速度 -15% | 可叠加，上限 4 层 | ✅ 已实现 |
| `blind_mode` | 盲视模式 | 玩家半透明，视野变暗 | 不可叠加 | ✅ 已实现 |
| `reverse_controls` | 反向控制 | 方向键反转 | 不可叠加 | ✅ 已实现 |
| `multi_spawn` | 多重生成 | 每次生成额外 +1 个球 | 可叠加，上限 3 层 | ✅ 已实现 |
| `tornado_mode` | 龙卷风 | 球轨迹变为曲线 (难预测) | 不可叠加 | ✅ 已实现 |

#### ⚡ 特殊类技能 (Special) - 约 20% 概率

| 技能 ID | 技能名称 | 效果描述 | 叠加规则 | 实现状态 |
|--------|---------|---------|---------|---------|
| `vampire` | 吸血 | 每躲避 50 个球，Level -1 | 不可叠加 | ✅ 已实现 |
| `bomb` | 炸弹 | 每 10 秒清除屏幕上所有球 | 不可叠加 | ✅ 已实现 |
| `ghost` | 幽灵 | 死亡后 3 秒内可复活 (每局限 1 次) | 不可叠加 | ✅ 已实现 |
| `chaos` | 混沌 | 随机应用 2 个增益 +2 个减益 | 不可叠加 | ✅ 已实现 |

---

## 3. 技能池权重系统

### 3.1 动态权重调整

```
基础权重:
- 增益类 (positive): 50%
- 减益类 (negative): 30%
- 特殊类 (special): 20%

动态调整因子:
- Level 1-3: 增益类 +20% (新手保护)
- Level 4-7: 基础权重
- Level 8+: 减益类 +15% (高风险)
- Level 10+: 特殊类 +20% (极限挑战)

幸运加成:
- 拥有 luck 技能时，增益类概率进一步提升
```

### 3.2 技能排除机制

- 鼠标偏好玩家：排除 `reverse_controls` (反向控制)
- 已达最大叠加的技能：自动排除
- 不可叠加技能：已拥有时排除

---

## 4. 技术实现方案

### 4.1 文件结构

```
game/
├── skill_manager.gd       # 技能管理器 (Autoload Singleton) ✅
├── main.gd                # 主游戏逻辑 ✅
├── player.gd              # 玩家控制 ✅
├── ball.gd                # 球体逻辑 ✅
├── pause_menu.gd          # 暂停菜单 ✅
├── settings_menu.gd       # 设置菜单 ✅
├── question_block.gd      # 问号块 ✅
├── audio_manager.gd       # 音频管理 ✅
├── sfx_generator.gd       # 音效生成 ✅
├── music_generator.gd     # 音乐生成 ✅
├── settings_manager.gd    # 设置管理 (Autoload) ✅
└── *.tscn                 # 场景文件
```

### 4.2 SkillManager 核心接口

```gdscript
# skill_manager.gd (Autoload Singleton)
class_name SkillManager extends Node

# 信号
signal skill_acquired(skill_id: String)
signal skill_removed(skill_id: String)
signal level_up()

# 核心属性
var active_skills: Dictionary  # {skill_id: stack_count}
var skill_data: Dictionary     # 技能数据定义
var skill_weights: Dictionary  # 权重配置

# 核心方法
func acquire_skill(skill_id: String) -> bool
func remove_skill(skill_id: String) -> void
func has_skill(skill_id: String) -> bool
func get_skill_stack(skill_id: String) -> int
func get_all_active_skills() -> Array
func generate_random_skill(difficulty_level: int) -> String
func generate_random_skill_with_exclusions(difficulty_level: int, excluded_skills: Array) -> String
func clear_all_skills() -> void
func get_skill_info(skill_id: String) -> Dictionary

# 效果修饰器
func get_ball_speed_modifier() -> float
func get_spawn_interval_modifier() -> float
func get_player_speed_modifier() -> float
func get_player_scale_modifier() -> float
func get_shield_count() -> int
func get_time_slow_modifier() -> float
func get_extra_spawn_count() -> int
func get_ball_slowdown_field() -> float

# 状态查询
func has_blind_mode() -> bool
func has_reverse_controls() -> bool
func has_magnet_deflect() -> bool
func has_tornado_trajectory() -> bool
```

### 4.3 main.gd 集成点

```gdscript
# 游戏启动时
func start_game():
    SkillManager.clear_all_skills()

# Level Up 时
func increase_difficulty():
    difficulty_level += 1
    var excluded_skills = []
    if player_uses_mouse:
        excluded_skills.append("reverse_controls")
    var new_skill = SkillManager.generate_random_skill_with_exclusions(
        difficulty_level, excluded_skills
    )
    if new_skill != "":
        SkillManager.acquire_skill(new_skill)
        show_skill_notification(new_skill)

# 生成球时应用技能效果
func spawn_ball():
    var speed_multiplier = 1.0 + (difficulty_level * 0.03)
    var ball_speed_mod = SkillManager.get_ball_speed_modifier()
    speed_multiplier *= (1.0 + ball_speed_mod)

# 特殊技能：炸弹
if SkillManager.has_skill("bomb"):
    bomb_timer += delta
    if bomb_timer >= 10.0:
        activate_bomb()

# 特殊技能：吸血
func _on_ball_dodged():
    skills_dodged_count += 1
    if SkillManager.has_skill("vampire") and skills_dodged_count % 50 == 0:
        difficulty_level = max(1, difficulty_level - 1)
```

### 4.4 player.gd 集成点

```gdscript
func _physics_process(delta):
    # 应用反向控制
    if SkillManager.has_reverse_controls():
        input_direction = -input_direction

    # 获取当前速度 (含技能修饰)
    var current_speed = get_current_speed()

    # 获取当前缩放 (含技能修饰)
    var current_scale = get_current_scale()

func get_current_speed() -> float:
    var base_speed = speed
    var modifier = SkillManager.get_player_speed_modifier()
    return base_speed * (1.0 + modifier)

func get_current_scale() -> Vector2:
    var modifier = SkillManager.get_player_scale_modifier()
    return base_scale * modifier

func set_shield(count: int):
    current_shield = count
    # 更新 UI 显示
```

### 4.5 ball.gd 集成点

```gdscript
func _process(delta):
    # 应用磁力偏转
    if SkillManager.has_magnet_deflect() and player_reference:
        apply_magnet_deflect()

    # 应用减速力场
    var slowdown = SkillManager.get_ball_slowdown_field()
    if slowdown > 0 and player_reference:
        apply_ball_slowdown(slowdown)

func spawn_ball():
    # 应用龙卷风轨迹
    if SkillManager.has_tornado_trajectory():
        ball.angular_velocity = randf_range(200, 400) * (1 if randf() > 0.5 else -1)
```

---

## 5. 游戏平衡设计

### 5.1 实际体验曲线

```
难度
  ↑
  │              ╭─── 实际难度 (带技能波动)
  │            ╱   ╲
  │          ╱       ╲
  │        ╱           ╲
  │      ╱               ╲
  │    ╱──────────────────── 原始难度曲线
  │  ╱
  │╱
  └──────────────────→ 时间/Level
```

### 5.2 动态难度补偿

- **新手保护**: Level 1-3 增益类技能 +20%
- **高风险**: Level 8+ 减益类技能 +15%
- **极限挑战**: Level 10+ 特殊类技能 +20%
- **输入保护**: 鼠标玩家免疫反向控制

---

## 6. UI/UX 需求

### 6.1 技能通知 (已实现)
- ✅ Level Up 时显示获得的技能
- ✅ 技能名称、类型图标、描述
- ✅ 稀有度颜色标识 (🟢绿/🔴红/⚡紫)
- ✅ 1.5 秒后自动隐藏

### 6.2 游戏中 HUD (已实现)
- ✅ 左上角技能容器显示所有激活技能
- ✅ 技能层数显示 (x2, x3 等)
- ✅ 护盾层数单独显示 (🛡️ xN)
- ✅ 技能类型颜色标识

### 6.3 技能选择 UI (未实现 - 已调整为自动获取)
- [ ] 三选一卡片展示
- [ ] 选择动画反馈
- [ ] 超时自动选择 (15 秒)

### 6.4 暂停菜单 (已实现)
- ✅ ESC 键暂停
- ✅ 继续游戏
- ✅ 重新开始
- ✅ 设置选项
- ✅ 退出游戏

---

## 7. 技术风险与解决

| 风险 | 影响 | 解决方案 | 状态 |
|-----|------|---------|------|
| 技能效果冲突 | 游戏崩溃/异常 | 效果应用顺序标准化，设置优先级 | ✅ 已解决 |
| 性能下降 | 大量技能检查拖累帧率 | 使用事件驱动而非每帧检查 | ✅ 已解决 |
| 数值失衡 | 过于简单/困难 | A/B 测试 + 玩家数据调优 | ⏸️ 待调优 |
| UI 阻塞 | 技能选择打断节奏 | 改为自动获取，无需暂停 | ✅ 已解决 |

---

## 8. 开发里程碑

### Phase 1 - 基础框架 (Week 1) ✅ 已完成
- ✅ SkillManager 单例实现
- ✅ 技能数据结构定义
- ✅ 基础技能效果修饰器

### Phase 2 - 核心技能 (Week 2) ✅ 已完成
- ✅ 实现 12 个增益技能 (fortune 预留)
- ✅ 实现 8 个减益技能
- ✅ 实现 4 个特殊技能

### Phase 3 - 平衡调试 (Week 3) 🔄 进行中
- ✅ 权重系统调优
- ⏸️ 动态难度补偿 (部分实现)
- ⏸️ 内部测试迭代

### Phase 4 - Polish (Week 4) 🔄 进行中
- ✅ UI 美化与动画
- ✅ 音效与反馈 (AudioManager)
- ⏸️ 技能图鉴系统 (未来扩展)

### Phase 5 - 扩展功能 (已完成)
- ✅ 清除横条系统
- ✅ 问号块系统
- ✅ 输入偏好检测
- ✅ 暂停菜单

---

## 9. 成功指标

| 指标 | 目标值 | 测量方式 | 当前状态 |
|-----|-------|---------|---------|
| 平均单局时长 | +30% | 游戏数据统计 | ⏸️ 待统计 |
| 7 日留存率 | +15% | 玩家追踪 | ⏸️ 待统计 |
| 技能选择多样性 | >80% 技能被选择 | 技能使用率统计 | ⏸️ 待统计 |
| 玩家满意度 | >4.0/5.0 | 评分系统 | ⏸️ 待统计 |

---

## 10. 附录

### 10.1 技能完整列表 (24 个)

**增益 (12 个)**: slow_time, shield, slow_spawn, small_player, speed_boost, ball_slowdown, double_score, magnet, regen, luck, fortune, blessing

**减益 (8 个)**: fast_balls, rapid_spawn, big_player, slow_player, blind_mode, reverse_controls, multi_spawn, tornado_mode

**特殊 (4 个)**: vampire, bomb, ghost, chaos

### 10.2 技能效果修饰器汇总表

| 修饰器类型 | 相关技能 | 计算方式 | 范围限制 |
|-----------|---------|---------|---------|
| 球速 | slow_time(-), fast_balls(+), blessing(-) | 累加 | [-0.9, 2.0] |
| 生成间隔 | slow_spawn(+), rapid_spawn(-) | 累加 | [-0.75, 2.0] |
| 玩家速度 | speed_boost(+), slow_player(-), blessing(+) | 累加 | [-0.6, 1.0] |
| 玩家大小 | small_player(-), big_player(+) | 累乘 | [0.3, 2.0] |
| 时间流逝 | double_score | 累加 | [0.0, 0.6] |

### 10.3 未来扩展方向
- [ ] 三选一技能选择 UI
- [ ] 金币系统 (fortune, golden_touch)
- [ ] 技能图鉴/收集系统
- [ ] 多人对战模式 (技能互相干扰)
- [ ] 每日挑战 (固定技能组合)
- [ ] 无尽模式 (Level 10+ 后继续)
- [ ] 技能合成系统
- [ ] Ban 选系统 (排除 1 个最不想要的技能)

---

## 11. 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|---------|------|
| 1.0 | 2026-03-03 | 初始设计文档 | - |
| 2.0 | 2026-03-05 | 更新实现状态，补充已实现功能，调整技能选择机制 (三选一 → 自动获取) | - |

---

**文档结束**

*本文档为躲避球 × Roguelike 技能系统的设计文档，版本 2.0 反映当前实际实现状态。核心功能已完成，待后续平衡调优和 UI 扩展。*
