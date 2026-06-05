# 2D魂+搜打撤 MVP 模块设计文档 - 补充篇

---

## 目录（续）

10. [怪物生成器模块设计](#10-怪物生成器模块设计)
11. [诡异怪物AI模块设计](#11-诡异怪物ai模块设计)
12. [战利品生成模块设计](#12-战利品生成模块设计)
13. [氛围控制器模块设计](#13-氛围控制器模块设计)
14. [UI整合模块设计](#14-ui整合模块设计)
15. [测试用例设计](#15-测试用例设计)

---

## 10. 怪物生成器模块设计

### 10.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| MG-001 | 定时生成诡异怪物（Shade/Whisperer/Aberration） |
| MG-002 | 生成位置与玩家保持安全距离 |
| MG-003 | 随时间增加生成数量和怪物强度 |
| MG-004 | 怪物死亡时注册击杀数（用于撤离条件） |

### 10.2 设计思路

继承现有 MonsterBuilder 模式，改造为生成诡异怪物。

### 10.3 核心数据结构

```gdscript
const MONSTERS = {
    "shade": preload("res://game/monster/weird/Shade.tscn"),
    "whisperer": preload("res://game/monster/weird/Whisperer.tscn"),
    "aberration": preload("res://game/monster/weird/Aberration.tscn")
}

var spawn_interval: float = 3.0    # 生成间隔
var spawn_count: int = 1            # 每次生成数量
var difficulty_level: int = 1       # 难度等级
var safe_distance: float = 200.0    # 与玩家的安全距离
```

### 10.4 接口设计

| 方法名 | 参数 | 返回值 | 功能说明 |
|--------|------|--------|----------|
| `start()` | 无 | `void` | 启动生成器 |
| `stop()` | 无 | `void` | 停止生成器 |
| `spawn_monster()` | 无 | `void` | 生成一个怪物 |
| `_get_spawn_position()` | 无 | `Vector2` | 获取安全的生成位置 |

### 10.5 代码实现

**文件**: `game/map/WeirdZone/WeirdMonsterBuilder.gd`

```gdscript
extends Node2D

const MONSTERS = {
    "shade": preload("res://game/monster/weird/Shade.tscn"),
    "whisperer": preload("res://game/monster/weird/Whisperer.tscn"),
    "aberration": preload("res://game/monster/weird/Aberration.tscn")
}

@export var spawn_interval: float = 3.0
@export var initial_spawn_count: int = 1
@export var safe_distance: float = 200.0

var current_count: int = 1
var difficulty_level: int = 1
var _timer: Timer = null
var _land: TileMap = null
var _monster_root: Node2D = null
var _spawn_points: Array[Vector2] = []

func _ready():
    _timer = Timer.new()
    _timer.wait_time = spawn_interval
    _timer.timeout.connect(_on_spawn)
    add_child(_timer)

func start():
    _timer.start()

func stop():
    _timer.stop()

func set_land(land: TileMap):
    _land = land
    _cache_spawn_points()

func set_monster_root(root: Node2D):
    _monster_root = root

func _cache_spawn_points():
    if not _land:
        return
    
    _spawn_points.clear()
    var cells = _land.get_used_cells(0)
    for cell in cells:
        var world_pos = _land.map_to_world(cell)
        _spawn_points.append(world_pos)

func _on_spawn():
    for _ in range(current_count):
        spawn_monster()
    
    # 每30秒增加难度
    difficulty_level += 1
    if difficulty_level % 5 == 0:
        current_count = min(current_count + 1, 5)
        spawn_interval = max(spawn_interval - 0.2, 1.0)

func spawn_monster():
    var monster_type = _select_monster_type()
    var monster_scene = MONSTERS.get(monster_type)
    
    if not monster_scene or not _monster_root:
        return
    
    var monster = monster_scene.instantiate()
    var spawn_pos = _get_spawn_position()
    
    if spawn_pos == Vector2.ZERO:
        monster.queue_free()
        return
    
    monster.global_position = spawn_pos
    _apply_difficulty_modifiers(monster)
    _monster_root.add_child(monster)

func _select_monster_type() -> String:
    var rand = randi() % 100
    
    if difficulty_level < 3:
        # 低难度：以残影为主
        if rand < 70:
            return "shade"
        elif rand < 90:
            return "whisperer"
        else:
            return "aberration"
    elif difficulty_level < 6:
        # 中难度：平衡分布
        if rand < 40:
            return "shade"
        elif rand < 70:
            return "whisperer"
        else:
            return "aberration"
    else:
        # 高难度：更多畸变体
        if rand < 30:
            return "shade"
        elif rand < 50:
            return "whisperer"
        else:
            return "aberration"

func _get_spawn_position() -> Vector2:
    if _spawn_points.size() == 0:
        return Vector2.ZERO
    
    for _ in range(10):
        var pos = _spawn_points[randi() % _spawn_points.size()]
        
        if Utils.player:
            var distance = pos.distance_to(Utils.player.global_position)
            if distance >= safe_distance:
                return pos
        
        # 如果没有玩家或者找不到安全位置，直接返回随机位置
        return pos
    
    return Vector2.ZERO

func _apply_difficulty_modifiers(monster):
    var hp_multiplier = 1.0 + (difficulty_level - 1) * 0.2
    var speed_multiplier = 1.0 + (difficulty_level - 1) * 0.1
    var damage_multiplier = 1.0 + (difficulty_level - 1) * 0.15
    
    if hasattr(monster, "HP"):
        monster.HP = int(monster.HP * hp_multiplier)
    if hasattr(monster, "SPEED"):
        monster.SPEED *= speed_multiplier
    if hasattr(monster, "hurt"):
        monster.hurt *= damage_multiplier
```

---

## 11. 诡异怪物AI模块设计

### 11.1 Shade（残影）

#### 11.1.1 核心特性

| 特性 | 值 | 说明 |
|------|-----|------|
| 类型 | 高速刺客 | 快速接近并造成理智伤害 |
| HP | 2 | 低血量 |
| SPEED | 120 | 高速移动 |
| 攻击方式 | 碰撞伤害 | 接触玩家造成伤害 |
| 理智伤害 | 5 | 每次攻击造成5点理智伤害 |

#### 11.1.2 AI行为

```gdscript
# 追踪阶段
- 持续追踪玩家
- 距离>100时，2.5倍速冲刺0.3秒

# 攻击阶段
- 接触玩家时造成物理伤害+理智伤害
- 攻击后短暂退开
```

### 11.2 Whisperer（低语者）

#### 11.2.1 核心特性

| 特性 | 值 | 说明 |
|------|-----|------|
| 类型 | 远程施法者 | 远程攻击+范围理智流失 |
| HP | 4 | 中等血量 |
| SPEED | 50 | 缓慢移动 |
| 攻击方式 | 投射物 | 发射远程攻击 |
| 范围理智流失 | 2/秒 | 周围150px内持续流失 |

#### 11.2.2 AI行为

```gdscript
# 追踪阶段
- 保持与玩家150-250px距离
- 缓慢移动调整位置

# 攻击阶段
- 每2秒发射一个投射物
- 投射物命中造成3点理智伤害
- 持续对周围150px内玩家造成理智流失
```

### 11.3 Aberration（畸变体）

#### 11.3.1 核心特性

| 特性 | 值 | 说明 |
|------|-----|------|
| 类型 | 重装坦克 | 高血量+冲锋攻击 |
| HP | 15 | 高血量 |
| SPEED | 30 | 平时缓慢 |
| 冲锋速度 | 90 | 3倍速冲锋 |
| 减伤 | 30% | 受到伤害降低30% |
| 理智伤害 | 10 | 冲锋命中造成10点理智伤害 |

#### 11.3.2 AI行为

```gdscript
# 追踪阶段
- 缓慢追踪玩家

# 冲锋阶段
- 距离>200px时触发冲锋
- 冲锋持续0.5秒，速度x3
- 冲锋期间无敌
- 冲锋命中造成高伤害+理智伤害
```

---

## 12. 战利品生成模块设计

### 12.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| LG-001 | 在地图上随机散落战利品 |
| LG-002 | 战利品类型随机分布 |
| LG-003 | 玩家靠近显示拾取提示 |
| LG-004 | 按E拾取战利品到背包 |

### 12.2 核心数据结构

```gdscript
const LOOT_TYPES = {
    "sanity_potion": {
        "scene": preload("res://game/loot/SanityPotion.tscn"),
        "weight": 40,      # 权重
        "rarity": LootServer.Rarity.COMMON,
        "can_extract": false
    },
    "mysterious_artifact": {
        "scene": preload("res://game/loot/MysteriousArtifact.tscn"),
        "weight": 35,
        "rarity": LootServer.Rarity.RARE,
        "can_extract": true
    },
    "tainted_essence": {
        "scene": preload("res://game/loot/TaintedEssence.tscn"),
        "weight": 25,
        "rarity": LootServer.Rarity.LEGENDARY,
        "can_extract": true
    }
}
```

### 12.3 代码实现

**文件**: `game/map/WeirdZone/WeirdZone.gd`（_spawn_loot 方法）

```gdscript
func _spawn_loot():
    var positions = [
        Vector2(200, 200), Vector2(400, 200),
        Vector2(300, 350), Vector2(500, 350),
        Vector2(150, 300), Vector2(550, 300)
    ]
    
    for pos in positions:
        var loot = _create_random_loot()
        if loot:
            loot.global_position = pos
            $LootRoot.add_child(loot)

func _create_random_loot():
    var total_weight = 0
    for type_info in LOOT_TYPES.values():
        total_weight += type_info["weight"]
    
    var rand = randi() % total_weight
    var current_weight = 0
    
    for loot_type, type_info in LOOT_TYPES:
        current_weight += type_info["weight"]
        if rand < current_weight:
            return type_info["scene"].instantiate()
    
    return null
```

---

## 13. 氛围控制器模块设计

### 13.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| AT-001 | 根据理智值调整画面色调 |
| AT-002 | 理智阈值跨越时显示提示 |
| AT-003 | 低理智时添加视觉扭曲效果 |

### 13.2 设计思路

监听 SanityServer 的信号，根据理智值动态调整 WorldEnvironment 的颜色校正参数。

### 13.3 核心数据结构

```gdscript
@export var world_environment: WorldEnvironment

var _effect_intensity: float = 0.0
```

### 13.4 代码实现

**文件**: `game/atmosphere/AtmosphereController.gd`（现有文件，补充完整）

```gdscript
extends Node2D
class_name AtmosphereController

@export var world_environment: WorldEnvironment

var _current_sanity_level: float = 100.0
var _effect_intensity: float = 0.0

func _ready():
    SanityServer.sanity_changed.connect(_on_sanity_changed)
    SanityServer.sanity_threshold_crossed.connect(_on_threshold_crossed)
    _setup_environment()

func _setup_environment():
    if not world_environment:
        world_environment = WorldEnvironment.new()
        add_child(world_environment)
    
    var env = Environment.new()
    world_environment.environment = env

func _on_sanity_changed(current: float, max_val: float):
    _current_sanity_level = current
    _update_visual_effects()

func _on_threshold_crossed(threshold: String):
    match threshold:
        "mild":
            Utils.showToast("你感到不安...")
        "moderate":
            Utils.showToast("幻觉开始出现...")
        "severe":
            Utils.showToast("理智即将崩溃！")
        "recovered_normal":
            Utils.showToast("理智恢复正常")

func _update_visual_effects():
    var sanity_percent = _current_sanity_level / 100.0
    
    if sanity_percent > 0.75:
        _adjust_environment(1.0, 1.0, 1.0)
        _effect_intensity = 0.0
    elif sanity_percent > 0.5:
        _adjust_environment(1.1, 0.95, 0.95)
        _effect_intensity = 0.25
    elif sanity_percent > 0.25:
        _adjust_environment(1.2, 0.85, 0.85)
        _effect_intensity = 0.5
    else:
        _adjust_environment(1.4, 0.7, 0.7)
        _effect_intensity = 1.0

func _adjust_environment(contrast: float, saturation: float, brightness: float):
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        env.adjustment_enabled = true
        env.adjustment_contrast = contrast
        env.adjustment_saturation = saturation
        env.adjustment_brightness = brightness - 0.1
```

---

## 14. UI整合模块设计

### 14.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| UI-001 | 显示理智条（SanityBar） |
| UI-002 | 显示精力条（StaminaBar） |
| UI-003 | 显示撤离状态（ExtractionStatus） |
| UI-004 | 显示战利品背包（LootInventoryUI） |

### 14.2 场景结构

```
WeirdUI (CanvasLayer)
├── SanityBar (ProgressBar) - 理智条
│   └── SanityLabel (Label) - 理智数值
├── StaminaBar (ProgressBar) - 精力条
│   └── StaminaLabel (Label) - 精力数值
├── ExtractionStatus (Control) - 撤离状态
│   ├── StatusLabel (Label) - 状态文字
│   └── CountdownLabel (Label) - 倒计时
└── LootButton (Button) - 打开战利品背包
```

### 14.3 代码实现

**文件**: `ui/weird/WeirdUI.gd`

```gdscript
extends CanvasLayer

@onready var _sanity_bar: ProgressBar = $SanityBar
@onready var _stamina_bar: ProgressBar = $StaminaBar
@onready var _extraction_status: Control = $ExtractionStatus
@onready var _loot_button: Button = $LootButton
@onready var _countdown_label: Label = $ExtractionStatus/CountdownLabel

func _ready():
    # 连接理智信号
    SanityServer.sanity_changed.connect(_on_sanity_changed)
    
    # 连接精力信号
    PlayerData.stamina_changed.connect(_on_stamina_changed)
    
    # 连接撤离信号
    ExtractionServer.extraction_available.connect(_on_extraction_available)
    ExtractionServer.extraction_started.connect(_on_extraction_started)
    ExtractionServer.countdown_tick.connect(_on_countdown_tick)
    ExtractionServer.extraction_completed.connect(_on_extraction_completed)
    
    # 初始化UI
    _sanity_bar.max_value = SanityServer.max_sanity
    _sanity_bar.value = SanityServer.current_sanity
    
    _stamina_bar.max_value = PlayerData.max_stamina
    _stamina_bar.value = PlayerData.current_stamina
    
    _loot_button.pressed.connect(_on_loot_button_pressed)

func _on_sanity_changed(current: float, max: float):
    _sanity_bar.value = current
    _sanity_bar.max_value = max
    
    # 根据理智值改变颜色
    var percent = current / max
    if percent > 0.75:
        _sanity_bar.modulate = Color.GREEN
    elif percent > 0.5:
        _sanity_bar.modulate = Color.YELLOW
    elif percent > 0.25:
        _sanity_bar.modulate = Color.ORANGE
    else:
        _sanity_bar.modulate = Color.RED

func _on_stamina_changed(current: float, max: float):
    _stamina_bar.value = current
    _stamina_bar.max_value = max

func _on_extraction_available():
    _extraction_status.visible = true
    $ExtractionStatus/StatusLabel.text = "撤离点已激活"
    $ExtractionStatus/StatusLabel.modulate = Color.GREEN

func _on_extraction_started():
    $ExtractionStatus/StatusLabel.text = "撤离中..."
    $ExtractionStatus/StatusLabel.modulate = Color.YELLOW

func _on_countdown_tick(time_remaining: float):
    _countdown_label.visible = true
    _countdown_label.text = "%.1fs" % time_remaining

func _on_extraction_completed():
    _extraction_status.visible = false

func _on_loot_button_pressed():
    var loot_ui = preload("res://ui/weird/LootInventoryUI.tscn").instantiate()
    add_child(loot_ui)
```

---

## 15. 测试用例设计

### 15.1 功能测试用例

#### 15.1.1 游戏状态机测试

| 用例ID | 测试场景 | 预期结果 |
|--------|----------|----------|
| GS-001 | 从大厅进入游戏 | GameState变为PLAYING，SanityServer启动流失 |
| GS-002 | 玩家死亡 | GameState变为DEAD，游戏暂停 |
| GS-003 | 撤离成功 | GameState变为SETTLEMENT，战利品转移 |
| GS-004 | 从结算返回大厅 | GameState变为LOBBY，状态重置 |

#### 15.1.2 精力系统测试

| 用例ID | 测试场景 | 预期结果 |
|--------|----------|----------|
| ST-001 | 消耗精力攻击 | 精力减少，is_stamina_draining=true |
| ST-002 | 停止消耗后恢复 | 延迟0.3秒后开始恢复 |
| ST-003 | 精力不足时尝试攻击 | 显示"精力不足"提示 |
| ST-004 | 休息恢复精力 | 精力恢复至最大值 |

#### 15.1.3 近战武器测试

| 用例ID | 测试场景 | 预期结果 |
|--------|----------|----------|
| MW-001 | 挥砍攻击范围内敌人 | 敌人受到伤害 |
| MW-002 | 攻击冷却期间再次攻击 | 攻击被拒绝 |
| MW-003 | 精力不足时攻击 | 攻击被拒绝，显示提示 |

#### 15.1.4 闪避翻滚测试

| 用例ID | 测试场景 | 预期结果 |
|--------|----------|----------|
| RO-001 | 按空格翻滚 | 玩家移动，无敌帧激活 |
| RO-002 | 翻滚期间被攻击 | 伤害被规避 |
| RO-003 | 精力不足时翻滚 | 翻滚被拒绝 |

#### 15.1.5 篝火系统测试

| 用例ID | 测试场景 | 预期结果 |
|--------|----------|----------|
| BF-001 | 玩家靠近篝火 | 篝火自动点燃 |
| BF-002 | 按E休息 | HP和精力恢复 |
| BF-003 | 死亡后篝火复活 | 玩家满血复活到篝火位置 |

#### 15.1.6 撤离系统测试

| 用例ID | 测试场景 | 预期结果 |
|--------|----------|----------|
| EX-001 | 达成撤离条件 | 撤离点激活，显示绿色提示 |
| EX-002 | 进入撤离点 | 开始5秒倒计时 |
| EX-003 | 撤离成功 | 战利品转移到已带出背包 |
| EX-004 | 撤离期间离开 | 倒计时取消 |

### 15.2 完整流程测试

| 用例ID | 测试场景 | 步骤 | 预期结果 |
|--------|----------|------|----------|
| FL-001 | 完整游戏循环 | 1. 大厅点击出发 2. 进入诡异区域 3. 收集战利品 4. 击杀怪物 5. 撤离 6. 结算 | 成功完成所有步骤 |
| FL-002 | 死亡流程 | 1. 进入游戏 2. 被怪物击杀 | 显示死亡面板，可选择复活方式 |
| FL-003 | 理智归零 | 1. 进入游戏 2. 不恢复理智 | 理智归零时玩家死亡 |

---

## 附录：数值配置表

### 怪物基础数值

| 怪物 | HP | SPEED | 伤害 | 理智伤害 | 特殊能力 |
|------|-----|-------|------|----------|----------|
| Shade | 2 | 120 | 1 | 5 | 2.5x冲刺 |
| Whisperer | 4 | 50 | 1 | 3(投射)/2(范围) | 远程攻击+范围理智流失 |
| Aberration | 15 | 30 | 3 | 10 | 3x冲锋+30%减伤 |

### 系统数值

| 系统 | 参数 | 值 |
|------|------|-----|
| 理智 | 被动流失速率 | 0.3/秒 |
| 理智 | 药剂恢复量 | 30 |
| 精力 | 最大值 | 100 |
| 精力 | 恢复速率 | 20/秒 |
| 精力 | 恢复延迟 | 0.3秒 |
| 精力 | 翻滚消耗 | 20 |
| 精力 | 近战消耗 | 15 |
| 撤离 | 时间条件 | 30秒 |
| 撤离 | 击杀条件 | 5个 |
| 撤离 | 倒计时 | 5秒 |

### 难度递增规则

| 难度等级 | 怪物HP倍率 | 速度倍率 | 伤害倍率 | 生成数量 |
|----------|-----------|----------|----------|----------|
| 1 | 1.0x | 1.0x | 1.0x | 1 |
| 2 | 1.2x | 1.1x | 1.15x | 1 |
| 3 | 1.4x | 1.2x | 1.3x | 2 |
| 4 | 1.6x | 1.3x | 1.45x | 2 |
| 5 | 1.8x | 1.4x | 1.6x | 3 |
| 6+ | +0.2x/级 | +0.1x/级 | +0.15x/级 | +1/5级 |

---

## 附录：输入映射配置

| 动作名称 | 按键 | 功能 |
|----------|------|------|
| move_left | A | 向左移动 |
| move_right | D | 向右移动 |
| move_up | W | 向上移动 |
| move_down | S | 向下移动 |
| dash | Space | 闪避翻滚 |
| melee_attack | MouseRight | 近战攻击 |
| shoot | MouseLeft | 射击 |
| reload | R | 换弹 |
| interact | E | 交互（休息/拾取） |
| inventory | Tab | 打开背包 |

---

## 附录：场景引用路径

| 场景 | 路径 |
|------|------|
| 大厅 | `res://game/map/Lobby/Lobby.tscn` |
| 诡异区域 | `res://game/map/WeirdZone/WeirdZone.tscn` |
| 结算 | `res://game/map/Settlement/Settlement.tscn` |
| 残影怪物 | `res://game/monster/weird/Shade.tscn` |
| 低语者怪物 | `res://game/monster/weird/Whisperer.tscn` |
| 畸变体怪物 | `res://game/monster/weird/Aberration.tscn` |
| 剑武器 | `res://game/weapons/Sword.tscn` |
| 篝火 | `res://game/bonfire/Bonfire.tscn` |
| 撤离点 | `res://game/extraction/ExtractionPoint.tscn` |
| 理智药剂 | `res://game/loot/SanityPotion.tscn` |
| 神秘神器 | `res://game/loot/MysteriousArtifact.tscn` |
| 污浊精华 | `res://game/loot/TaintedEssence.tscn` |

---

## 总结

本设计文档涵盖了2D魂+搜打撤MVP的所有核心模块：

1. **游戏状态机** - 管理大厅/游戏/暂停/死亡/结算状态切换
2. **精力系统** - 攻击/闪避消耗与恢复机制
3. **近战武器** - 剑类武器的挥砍攻击和范围检测
4. **闪避翻滚** - 无敌帧翻滚和精力消耗
5. **篝火系统** - 点燃/休息/复活点功能
6. **场景切换** - 大厅/诡异区域/结算场景切换
7. **大厅场景** - 标题/战利品预览/出发按钮
8. **诡异区域场景** - 怪物生成/战利品散落/撤离系统
9. **结算场景** - 结果显示/战利品统计
10. **怪物生成器** - 诡异怪物的定时生成
11. **诡异怪物AI** - 三种怪物的独特行为模式
12. **战利品生成** - 随机散落机制
13. **氛围控制器** - 理智相关的视觉效果
14. **UI整合** - 游戏内UI组件
15. **测试用例** - 功能测试和完整流程测试

所有模块均已设计完成，可以按照此文档进行实现。