# 拓展开发方向分析

## 一、当前框架评估

### 1.1 架构优势
- 模块化设计，职责清晰
- 信号系统实现组件解耦
- 单例模式集中管理数据

### 1.2 核心问题
- 状态管理简单化（状态机缺失）
- AI行为单一（行为树缺失）
- 无存档系统
- 网络功能空白

## 二、短期拓展（1-2周）

### 2.1 存档系统

```gdscript
const SAVE_PATH = "user://save_data.json"

func save_data():
    var data = {
        "player_hp": player_hp,
        "player_level": player_level,
        "player_weapon_list": serialize_weapons()
    }
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))
        file.close()
```

### 2.2 成就系统

```gdscript
var achievements = {
    "first_blood": {"name": "初次击杀", "reward": {"gold": 100}},
    "survivor": {"name": "生存专家", "reward": {"hp_max": 5}}
}
```

### 2.3 状态机重构

```gdscript
enum PlayerState { IDLE, RUN, ATTACK, DASH, HURT, DEAD }
var current_state = PlayerState.IDLE

func change_state(new_state):
    exit_state(current_state)
    current_state = new_state
    enter_state(new_state)
```

## 三、中期拓展（2-4周）

### 3.1 行为树AI

```gdscript
class BehaviorTree:
    var root
    
    func tick(delta):
        root.execute(delta)

class SelectorNode:
    var children
    
    func execute(delta):
        for child in children:
            if child.execute(delta) == SUCCESS:
                return SUCCESS
        return FAILURE
```

### 3.2 道具系统

```gdscript
class Consumable:
    @export var effect: Dictionary
    
    func use():
        match effect.type:
            "heal": PlayerData.addPlayerHp(effect.value)
            "damage_boost": PlayerData.base_bullet_damage += effect.value
```

### 3.3 装备稀有度

```gdscript
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

func get_rarity_color(rarity):
    match rarity:
        Rarity.COMMON: return Color(0.8, 0.8, 0.8)
        Rarity.LEGENDARY: return Color(1.0, 0.8, 0.0)
```

## 四、诡异主题改造

### 4.1 主题转换策略

| 原系统 | 诡异主题改造 |
|--------|--------------|
| 武器系统 | 符咒/法器/诅咒 |
| 怪物系统 | 幽灵/怨灵/灵异生物 |
| 奖励系统 | 冥币/魂魄/法器碎片 |
| UI风格 | 暗色/血红/灵异特效 |

### 4.2 恐惧值系统

```gdscript
var fear_value = 0
var max_fear = 100

func update_fear(delta):
    if in_dark_area:
        fear_value += fear_rate * delta
    if fear_value > max_fear * 0.7:
        show_hallucination()
        player_speed *= 0.8
```

### 4.3 诅咒系统

```gdscript
class Curse:
    @export var effect: Dictionary
    var remaining_time: float
    
    func apply():
        match effect.type:
            "damage_over_time": schedule_damage()
            "slow": PlayerData.player_speed *= (1 - effect.value)
```

## 五、开发路线图

```
第1-2周：基础完善
├── 存档系统
├── 成就系统
└── UI优化

第3-4周：战斗深度
├── 状态机重构
├── 武器升级
└── 道具系统

第5-8周：内容扩展
├── AI行为树
├── 关卡系统
└── 装备稀有度

第9-12周：高级功能
├── 多人联网
└── 诡异主题改造
```

## 六、优先执行建议

1. **存档系统** - 高优先级
2. **状态机模式** - 高优先级
3. **成就系统** - 中优先级
4. **行为树AI** - 中优先级
5. **诡异主题改造** - 按需