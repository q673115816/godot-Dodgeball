extends Node

## 技能管理器 (Autoload Singleton)
## 负责管理所有技能的获取、生效和移除

signal skill_acquired(skill_id: String)
signal skill_removed(skill_id: String)
signal level_up()

# 激活的技能 {skill_id: stack_count}
var active_skills: Dictionary = {}

# 技能数据
var skill_data = {}

# 技能权重配置
var skill_weights = {
    "positive": 50,
    "negative": 30,
    "special": 20
}

func _ready():
    _init_skill_data()

func _init_skill_data():
    """初始化所有技能数据"""
    skill_data = {
        # === 增益类技能 ===
        "slow_time": {
            "name": "时间减缓",
            "type": "positive",
            "description": "球速降低 10%",
            "max_stack": 5,
            "effect": {"ball_speed": -0.1}
        },
        "shield": {
            "name": "护盾",
            "type": "positive",
            "description": "可抵挡 1 次撞击",
            "max_stack": 99,
            "effect": {"shield": 1}
        },
        "slow_spawn": {
            "name": "生成减缓",
            "type": "positive",
            "description": "球生成间隔 +15%",
            "max_stack": 5,
            "effect": {"spawn_interval": 0.15}
        },
        "small_player": {
            "name": "缩小化",
            "type": "positive",
            "description": "玩家体积缩小 20%",
            "max_stack": 3,
            "effect": {"player_scale": -0.2}
        },
        "speed_boost": {
            "name": "加速移动",
            "type": "positive",
            "description": "玩家移动速度 +15%",
            "max_stack": 4,
            "effect": {"player_speed": 0.15}
        },
        "ball_slowdown": {
            "name": "减速力场",
            "type": "positive",
            "description": "靠近玩家的球自动减速 30%",
            "max_stack": 3,
            "effect": {"ball_slowdown_field": 0.3}
        },
        "double_score": {
            "name": "时间扭曲",
            "type": "positive",
            "description": "生存时间流逝速度 -20%",
            "max_stack": 3,
            "effect": {"time_slow": 0.2}
        },
        "magnet": {
            "name": "磁力偏转",
            "type": "positive",
            "description": "自动偏转身边的球",
            "max_stack": 1,
            "effect": {"magnet_deflect": true}
        },
        "regen": {
            "name": "生命恢复",
            "type": "positive",
            "description": "每级恢复 1 层护盾",
            "max_stack": 1,
            "effect": {"regen_on_level": 1}
        },
        "luck": {
            "name": "幸运",
            "type": "positive",
            "description": "增益技能概率 +10%",
            "max_stack": 3,
            "effect": {"luck_bonus": 0.1}
        },
        "fortune": {
            "name": "财富",
            "type": "positive",
            "description": "金币获取 +25% (未实现)",
            "max_stack": 3,
            "effect": {"gold_bonus": 0.25}
        },
        "blessing": {
            "name": "祝福",
            "type": "positive",
            "description": "所有属性 +5%",
            "max_stack": 5,
            "effect": {"all_stats": 0.05}
        },

        # === 减益类技能 ===
        "fast_balls": {
            "name": "狂怒之球",
            "type": "negative",
            "description": "球速增加 15%",
            "max_stack": 5,
            "effect": {"ball_speed": 0.15}
        },
        "rapid_spawn": {
            "name": "疯狂生成",
            "type": "negative",
            "description": "球生成间隔 -10%",
            "max_stack": 5,
            "effect": {"spawn_interval": -0.1}
        },
        "big_player": {
            "name": "巨大化",
            "type": "negative",
            "description": "玩家体积增大 25%",
            "max_stack": 3,
            "effect": {"player_scale": 0.25}
        },
        "slow_player": {
            "name": "沉重步伐",
            "type": "negative",
            "description": "玩家移动速度 -15%",
            "max_stack": 4,
            "effect": {"player_speed": -0.15}
        },
        "blind_mode": {
            "name": "盲视模式",
            "type": "negative",
            "description": "玩家半透明，视野变暗",
            "max_stack": 1,
            "effect": {"blind": true}
        },
        "reverse_controls": {
            "name": "反向控制",
            "type": "negative",
            "description": "方向键反转",
            "max_stack": 1,
            "effect": {"reverse_controls": true}
        },
        "multi_spawn": {
            "name": "多重生成",
            "type": "negative",
            "description": "每次生成额外 +1 个球",
            "max_stack": 3,
            "effect": {"multi_spawn": 1}
        },
        "tornado_mode": {
            "name": "龙卷风",
            "type": "negative",
            "description": "球轨迹变为曲线",
            "max_stack": 1,
            "effect": {"tornado_trajectory": true}
        },

        # === 特殊类技能 ===
        "vampire": {
            "name": "吸血",
            "type": "special",
            "description": "每躲避 50 个球，Level -1",
            "max_stack": 1,
            "effect": {"vampire": 50}
        },
        "bomb": {
            "name": "炸弹",
            "type": "special",
            "description": "每 10 秒清除屏幕上所有球",
            "max_stack": 1,
            "effect": {"bomb_timer": 10.0}
        },
        "ghost": {
            "name": "幽灵",
            "type": "special",
            "description": "死亡后 3 秒内可复活 (每局限 1 次)",
            "max_stack": 1,
            "effect": {"ghost_revive": true}
        },
        "chaos": {
            "name": "混沌",
            "type": "special",
            "description": "随机应用 2 个增益 +2 个减益",
            "max_stack": 1,
            "effect": {"chaos": true}
        }
    }

func acquire_skill(skill_id: String) -> bool:
    """获取技能，返回是否成功"""
    if not skill_data.has(skill_id):
        push_warning("Unknown skill:", skill_id)
        return false

    var current_stack = active_skills.get(skill_id, 0)
    var max_stack = skill_data[skill_id].max_stack

    if current_stack >= max_stack:
        # 已达到最大叠加，不获取
        return false

    active_skills[skill_id] = current_stack + 1
    skill_acquired.emit(skill_id)

    # 特殊技能效果处理
    if skill_id == "chaos":
        _apply_chaos_effect()

    return true

func remove_skill(skill_id: String) -> void:
    """移除技能"""
    if active_skills.has(skill_id):
        active_skills.erase(skill_id)
        skill_removed.emit(skill_id)

func has_skill(skill_id: String) -> bool:
    """检查是否拥有技能"""
    return active_skills.has(skill_id)

func get_skill_stack(skill_id: String) -> int:
    """获取技能叠加层数"""
    return active_skills.get(skill_id, 0)

func get_all_active_skills() -> Array:
    """获取所有激活的技能"""
    return active_skills.keys()

func generate_random_skill(difficulty_level: int = 1) -> String:
    """根据权重随机生成一个技能"""
    var weights = _get_dynamic_weights(difficulty_level)

    # 应用幸运加成
    if has_skill("luck"):
        weights["positive"] += get_skill_stack("luck") * 0.1 * 100

    # 按权重选择类型
    var skill_type = _select_by_weight(weights)

    # 从该类型中随机选择技能
    var type_skills = []
    for skill_id in skill_data:
        if skill_data[skill_id].type == skill_type:
            # 排除已达到最大叠加的技能
            if get_skill_stack(skill_id) < skill_data[skill_id].max_stack:
                type_skills.append(skill_id)

    if type_skills.size() == 0:
        # 如果该类型没有可用技能，从所有技能中选
        for skill_id in skill_data:
            if get_skill_stack(skill_id) < skill_data[skill_id].max_stack:
                type_skills.append(skill_id)

    if type_skills.size() == 0:
        return ""  # 所有技能都满级了

    return type_skills[randi() % type_skills.size()]

func _get_dynamic_weights(difficulty_level: int) -> Dictionary:
    """根据难度等级动态调整权重"""
    var weights = skill_weights.duplicate()

    if difficulty_level <= 3:
        # 新手保护
        weights["positive"] += 20
        weights["negative"] -= 10
    elif difficulty_level >= 8:
        # 高风险
        weights["negative"] += 15
        weights["positive"] -= 10

    if difficulty_level > 10:
        # 极限挑战
        weights["special"] += 20

    return weights

func _select_by_weight(weights: Dictionary) -> String:
    """根据权重选择类型"""
    var total = weights["positive"] + weights["negative"] + weights["special"]
    var roll = randf() * total

    if roll < weights["positive"]:
        return "positive"
    elif roll < weights["positive"] + weights["negative"]:
        return "negative"
    else:
        return "special"

func _apply_chaos_effect():
    """应用混沌效果"""
    var positive_skills = []
    var negative_skills = []

    for skill_id in skill_data:
        if skill_data[skill_id].type == "positive":
            positive_skills.append(skill_id)
        elif skill_data[skill_id].type == "negative":
            negative_skills.append(skill_id)

    # 随机选择 2 个增益和 2 个减益
    for i in range(2):
        if positive_skills.size() > 0:
            var idx = randi() % positive_skills.size()
            acquire_skill(positive_skills[idx])
            positive_skills.remove_at(idx)

    for i in range(2):
        if negative_skills.size() > 0:
            var idx = randi() % negative_skills.size()
            acquire_skill(negative_skills[idx])
            negative_skills.remove_at(idx)

# === 效果修饰器获取 ===

func get_ball_speed_modifier() -> float:
    """获取球速修饰"""
    var modifier = 0.0
    if has_skill("slow_time"):
        modifier += get_skill_stack("slow_time") * (-0.1)
    if has_skill("fast_balls"):
        modifier += get_skill_stack("fast_balls") * 0.15
    if has_skill("blessing"):
        modifier -= get_skill_stack("blessing") * 0.05
    return clamp(modifier, -0.9, 2.0)

func get_spawn_interval_modifier() -> float:
    """获取生成间隔修饰"""
    var modifier = 0.0
    if has_skill("slow_spawn"):
        modifier += get_skill_stack("slow_spawn") * 0.15
    if has_skill("rapid_spawn"):
        modifier += get_skill_stack("rapid_spawn") * (-0.1)
    return clamp(modifier, -0.75, 2.0)

func get_player_speed_modifier() -> float:
    """获取玩家速度修饰"""
    var modifier = 0.0
    if has_skill("speed_boost"):
        modifier += get_skill_stack("speed_boost") * 0.15
    if has_skill("slow_player"):
        modifier += get_skill_stack("slow_player") * (-0.15)
    if has_skill("blessing"):
        modifier += get_skill_stack("blessing") * 0.05
    return clamp(modifier, -0.6, 1.0)

func get_player_scale_modifier() -> float:
    """获取玩家大小修饰"""
    var modifier = 1.0
    if has_skill("small_player"):
        modifier += get_skill_stack("small_player") * (-0.2)
    if has_skill("big_player"):
        modifier += get_skill_stack("big_player") * 0.25
    return clamp(modifier, 0.3, 2.0)

func get_shield_count() -> int:
    """获取护盾层数"""
    var count = 0
    if has_skill("shield"):
        count += get_skill_stack("shield")
    if has_skill("regen"):
        count += 1  # 每级恢复在 main 中处理
    return count

func has_blind_mode() -> bool:
    return has_skill("blind_mode")

func has_reverse_controls() -> bool:
    return has_skill("reverse_controls")

func has_magnet_deflect() -> bool:
    return has_skill("magnet")

func has_tornado_trajectory() -> bool:
    return has_skill("tornado_mode")

func get_ball_slowdown_field() -> float:
    if has_skill("ball_slowdown"):
        return get_skill_stack("ball_slowdown") * 0.3
    return 0.0

func get_time_slow_modifier() -> float:
    """获取时间流逝修饰"""
    var modifier = 0.0
    if has_skill("double_score"):
        modifier += get_skill_stack("double_score") * 0.2
    return clamp(modifier, 0.0, 0.6)

func get_extra_spawn_count() -> int:
    """获取额外生成球数量"""
    var count = 0
    if has_skill("multi_spawn"):
        count += get_skill_stack("multi_spawn")
    return count

# === 工具函数 ===

func clear_all_skills():
    """清除所有技能"""
    active_skills.clear()

func get_skill_info(skill_id: String) -> Dictionary:
    """获取技能信息"""
    return skill_data.get(skill_id, {})
