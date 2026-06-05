# 2D魂+搜打撤 MVP 模块设计文档

---

## 目录

1. [游戏状态机模块设计](#1-游戏状态机模块设计)
2. [精力系统模块设计](#2-精力系统模块设计)
3. [近战武器模块设计](#3-近战武器模块设计)
4. [闪避翻滚模块设计](#4-闪避翻滚模块设计)
5. [篝火系统模块设计](#5-篝火系统模块设计)
6. [场景切换模块设计](#6-场景切换模块设计)
7. [大厅场景模块设计](#7-大厅场景模块设计)
8. [诡异区域场景模块设计](#8-诡异区域场景模块设计)
9. [结算场景模块设计](#9-结算场景模块设计)

---

## 1. 游戏状态机模块设计

### 1.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| GS-001 | 管理游戏状态：大厅 → 游戏中 → 暂停 → 死亡 → 结算 |
| GS-002 | 状态切换时发出信号通知其他系统 |
| GS-003 | 提供状态查询接口 |
| GS-004 | 状态进入时执行初始化/清理逻辑 |

### 1.2 设计思路

采用有限状态机模式，将游戏状态抽象为枚举值，每个状态对应一组进入/退出动作。

### 1.3 核心数据结构

```gdscript
enum State {
    LOBBY,      # 大厅界面
    PLAYING,    # 游戏进行中
    PAUSED,     # 暂停
    DEAD,       # 死亡状态
    SETTLEMENT  # 结算界面
}

var current_state: State = State.LOBBY
```

### 1.4 接口设计

| 方法名 | 参数 | 返回值 | 功能说明 |
|--------|------|--------|----------|
| `transition_to(new_state)` | `new_state: State` | `void` | 切换到指定状态 |
| `is_state(target_state)` | `target_state: State` | `bool` | 判断当前是否为指定状态 |
| `get_current_state()` | 无 | `State` | 获取当前状态 |

### 1.5 信号设计

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `state_changed` | `old_state: State, new_state: State` | 状态切换时 |

### 1.6 状态转换表

| 当前状态 | 可转换到 | 触发条件 |
|----------|----------|----------|
| LOBBY | PLAYING | 点击出发按钮 |
| PLAYING | PAUSED | 按下暂停键 |
| PLAYING | DEAD | 玩家HP归零或理智归零 |
| PLAYING | SETTLEMENT | 撤离成功 |
| PAUSED | PLAYING | 按下暂停键 |
| DEAD | LOBBY | 选择返回大厅 |
| DEAD | PLAYING | 篝火复活 |
| SETTLEMENT | LOBBY | 点击返回大厅 |

### 1.7 代码实现

**文件**: `autoload/server/GameStateServer.gd`

```gdscript
extends Node

enum State {
    LOBBY,
    PLAYING,
    PAUSED,
    DEAD,
    SETTLEMENT
}

signal state_changed(old_state: State, new_state: State)

var current_state: State = State.LOBBY

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS

func transition_to(new_state: State):
    if current_state == new_state:
        return
    
    var old = current_state
    current_state = new_state
    
    _execute_state_exit(old)
    emit_signal("state_changed", old, new_state)
    _execute_state_enter(new_state)

func _execute_state_enter(state: State):
    match state:
        State.LOBBY:
            _on_enter_lobby()
        State.PLAYING:
            _on_enter_playing()
        State.PAUSED:
            _on_enter_paused()
        State.DEAD:
            _on_enter_dead()
        State.SETTLEMENT:
            _on_enter_settlement()

func _execute_state_exit(state: State):
    match state:
        State.LOBBY:
            _on_exit_lobby()
        State.PLAYING:
            _on_exit_playing()
        # 其他状态的退出逻辑

func _on_enter_lobby():
    SanityServer.reset_sanity()
    LootServer.clear_current_loot()
    ExtractionServer.reset()
    Utils.is_game_start = false

func _on_enter_playing():
    Utils.gameStart()
    SanityServer.start_drain()
    get_tree().paused = false

func _on_enter_paused():
    get_tree().paused = true

func _on_enter_dead():
    SanityServer.stop_drain()
    get_tree().paused = true

func _on_enter_settlement():
    pass

func is_state(target_state: State) -> bool:
    return current_state == target_state

func get_current_state() -> State:
    return current_state
```

---

## 2. 精力系统模块设计

### 2.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| ST-001 | 精力值范围：0-100 |
| ST-002 | 攻击/闪避消耗精力 |
| ST-003 | 停止消耗后延迟恢复 |
| ST-004 | 精力变化时发出信号通知UI |

### 2.2 设计思路

在 PlayerData 中扩展精力相关属性，通过 setter 自动发出信号，UI 监听信号更新显示。

### 2.3 核心数据结构

```gdscript
var max_stamina: float = 100.0
var current_stamina: float = 100.0
var stamina_regen_rate: float = 20.0  # 每秒恢复
var stamina_regen_delay: float = 0.3   # 停止消耗后延迟恢复时间
var is_stamina_draining: bool = false  # 是否正在消耗
```

### 2.4 接口设计

| 方法名 | 参数 | 返回值 | 功能说明 |
|--------|------|--------|----------|
| `consume_stamina(amount)` | `amount: float` | `bool` | 消耗指定精力，成功返回true |
| `regenerate_stamina(delta)` | `delta: float` | `void` | 更新精力恢复 |
| `set_stamina(value)` | `value: float` | `void` | 直接设置精力值 |
| `reset_stamina()` | 无 | `void` | 重置为最大值 |

### 2.5 信号设计

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `stamina_changed` | `current: float, max: float` | 精力值变化时 |

### 2.6 流程图

```
玩家输入 → 检测动作类型 → 需要精力？
                           ↓
                      检查当前精力 ≥ 消耗值？
                           ↓
              是 → 消耗精力 → 设置 is_stamina_draining = true
              否 → 显示提示 "精力不足"
                           ↓
                   每帧调用 regenerate_stamina(delta)
                           ↓
              is_stamina_draining = false 且 延迟时间已过？
                           ↓
              是 → 恢复精力 += regen_rate * delta
              否 → 等待
```

### 2.7 代码实现

**文件**: `autoload/PlayerData.gd`（修改）

```gdscript
signal stamina_changed(current: float, max: float)

var max_stamina: float = 100.0
var current_stamina: float = 100.0:
    set(value):
        current_stamina = clamp(value, 0.0, max_stamina)
        emit_signal("stamina_changed", current_stamina, max_stamina)

var stamina_regen_rate: float = 20.0
var stamina_regen_delay: float = 0.3
var is_stamina_draining: bool = false
var _time_since_last_consume: float = 0.0

func consume_stamina(amount: float) -> bool:
    if current_stamina >= amount:
        current_stamina -= amount
        is_stamina_draining = true
        _time_since_last_consume = 0.0
        return true
    return false

func regenerate_stamina(delta: float):
    if is_stamina_draining:
        _time_since_last_consume += delta
        if _time_since_last_consume >= stamina_regen_delay:
            is_stamina_draining = false
        return
    
    current_stamina = min(current_stamina + stamina_regen_rate * delta, max_stamina)

func set_stamina(value: float):
    current_stamina = value

func reset_stamina():
    current_stamina = max_stamina
```

---

## 3. 近战武器模块设计

### 3.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| MW-001 | 支持多种近战武器（剑、刀、棍） |
| MW-002 | 挥砍攻击有范围检测 |
| MW-003 | 攻击消耗精力 |
| MW-004 | 攻击有冷却时间 |
| MW-005 | 支持连击系统（可选） |

### 3.2 设计思路

创建 MeleeWeapon 基类，定义通用攻击逻辑，具体武器类型继承扩展。

### 3.3 核心数据结构

```gdscript
@export var damage: float = 2.0          # 伤害值
@export var swing_range: float = 60.0    # 攻击范围
@export var swing_duration: float = 0.3  # 挥砍持续时间
@export var stamina_cost: float = 15.0   # 精力消耗
@export var cooldown: float = 0.5        # 冷却时间

var is_swinging: bool = false
var is_on_cooldown: bool = false
var player: Player = null
```

### 3.4 接口设计

| 方法名 | 参数 | 返回值 | 功能说明 |
|--------|------|--------|----------|
| `swing()` | 无 | `void` | 执行挥砍攻击 |
| `_detect_enemies()` | 无 | `void` | 检测范围内敌人 |
| `_apply_damage(target)` | `target: Node2D` | `void` | 对目标造成伤害 |

### 3.5 代码实现

**文件**: `game/weapons/MeleeWeapon.gd`

```gdscript
extends Node2D
class_name MeleeWeapon

@export var damage: float = 2.0
@export var swing_range: float = 60.0
@export var swing_duration: float = 0.3
@export var stamina_cost: float = 15.0
@export var cooldown: float = 0.5

var is_swinging: bool = false
var is_on_cooldown: bool = false
var player: Player = null

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
    _collision_shape.disabled = true

func swing():
    if is_swinging || is_on_cooldown:
        return
    
    if not PlayerData.consume_stamina(stamina_cost):
        Utils.showToast("精力不足")
        return
    
    is_swinging = true
    _collision_shape.disabled = false
    
    _play_swing_animation()
    _detect_enemies()
    
    await get_tree().create_timer(swing_duration).timeout
    is_swinging = false
    _collision_shape.disabled = true
    
    # 启动冷却
    await get_tree().create_timer(cooldown).timeout
    is_on_cooldown = false

func _play_swing_animation():
    var tween = get_tree().create_tween()
    tween.tween_property(self, "rotation", deg_to_rad(90), swing_duration * 0.5)
    tween.tween_property(self, "rotation", 0, swing_duration * 0.5)

func _detect_enemies():
    var area = Area2D.new()
    var shape = CircleShape2D.new()
    shape.radius = swing_range
    area.add_child(CollisionShape2D.new())
    area.get_child(0).shape = shape
    area.global_position = global_position
    get_tree().root.add_child(area)
    
    for body in area.get_overlapping_bodies():
        if body is BaseMonster and body != player:
            _apply_damage(body)
    
    area.queue_free()

func _apply_damage(target: BaseMonster):
    target.onHit(damage)
    # 可选：添加击退效果
    var direction = target.global_position.direction_to(player.global_position)
    target.set_knockback(30)
```

**文件**: `game/weapons/Sword.gd`

```gdscript
extends MeleeWeapon

func _ready():
    damage = 3.0
    swing_range = 70.0
    stamina_cost = 18.0
```

---

## 4. 闪避翻滚模块设计

### 4.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| RO-001 | 按空格键触发翻滚 |
| RO-002 | 翻滚期间玩家无敌 |
| RO-003 | 翻滚消耗精力 |
| RO-004 | 翻滚方向跟随移动输入 |
| RO-005 | 翻滚有残影效果 |

### 4.2 设计思路

在 Hero.gd 中实现翻滚逻辑，利用现有的冲刺粒子效果作为残影。

### 4.3 核心数据结构

```gdscript
var is_rolling: bool = false
var roll_duration: float = 0.2
var roll_distance: float = 120.0
var roll_stamina_cost: float = 20.0
var is_invincible: bool = false
```

### 4.4 接口设计

| 方法名 | 参数 | 返回值 | 功能说明 |
|--------|------|--------|----------|
| `_roll()` | 无 | `void` | 执行翻滚动作 |
| `_can_roll()` | 无 | `bool` | 检查是否可以翻滚 |

### 4.5 代码实现

**文件**: `game/hero/Hero.gd`（修改）

```gdscript
var is_rolling: bool = false
var roll_duration: float = 0.2
var roll_distance: float = 120.0
var roll_stamina_cost: float = 20.0

func _input(event: InputEvent):
    if Input.is_action_just_pressed("dash") && _can_roll():
        _roll()

func _can_roll() -> bool:
    return !is_rolling && !is_dash && !is_dead && Utils.is_game_start

func _roll():
    if not PlayerData.consume_stamina(roll_stamina_cost):
        Utils.showToast("精力不足")
        return
    
    is_rolling = true
    is_invincible = true
    
    # 获取翻滚方向（优先移动输入，其次朝向鼠标）
    var direction = Input.get_vector("left", "right", "up", "down")
    if direction == Vector2.ZERO:
        direction = global_position.direction_to(get_global_mouse_position())
    
    # 设置翻滚速度
    velocity = direction.normalized() * roll_distance / roll_duration
    
    # 播放翻滚动画和粒子效果
    anim.play("roll")
    dash_part.emitting = true
    
    # 生成残影
    for _ in range(3):
        var shadow = dash_obj.instantiate()
        shadow.texture = anim.sprite_frames.get_frame_texture("roll", 0)
        shadow.global_position = global_position
        get_tree().root.add_child(shadow)
        await get_tree().create_timer(0.05).timeout
    
    await get_tree().create_timer(roll_duration).timeout
    
    is_rolling = false
    is_invincible = false
    dash_part.emitting = false

func onHit(hurt):
    if is_invincible:
        return  # 翻滚期间无敌
    # 原有伤害处理逻辑...
```

---

## 5. 篝火系统模块设计

### 5.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| BF-001 | 玩家靠近自动点燃篝火 |
| BF-002 | 点燃后提供照明和粒子效果 |
| BF-003 | 玩家在篝火旁按E休息（恢复HP和精力） |
| BF-004 | 篝火作为复活点 |
| BF-005 | 死亡后可选择篝火复活（满血）或普通复活（残血） |

### 5.2 设计思路

篝火作为 Area2D 节点，检测玩家进入事件，提供交互功能。

### 5.3 核心数据结构

```gdscript
var is_lit: bool = false
var is_checkpoint: bool = true
var respawn_position: Vector2 = Vector2.ZERO
```

### 5.4 接口设计

| 方法名 | 参数 | 返回值 | 功能说明 |
|--------|------|--------|----------|
| `_light()` | 无 | `void` | 点燃篝火 |
| `_extinguish()` | 无 | `void` | 熄灭篝火 |
| `_rest()` | 无 | `void` | 休息恢复 |
| `respawn_player()` | 无 | `void` | 将玩家复活到篝火位置 |

### 5.5 代码实现

**文件**: `game/bonfire/Bonfire.gd`

```gdscript
extends Area2D
class_name Bonfire

signal lit()
signal extinguished()
signal rested()

var is_lit: bool = false
var is_checkpoint: bool = true
var _player_in_range: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _light: PointLight2D = $PointLight2D
@onready var _particles: Particles2D = $Particles2D
@onready var _label: Label = $Label

func _ready():
    add_to_group("bonfire")
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    _extinguish()

func _on_body_entered(body: Node2D):
    if body is Player:
        _player_in_range = true
        if not is_lit:
            _light()
        else:
            _label.visible = true

func _on_body_exited(body: Node2D):
    if body is Player:
        _player_in_range = false
        _label.visible = false

func _input(event: InputEvent):
    if _player_in_range && Input.is_action_just_pressed("e"):
        _rest()

func _light():
    is_lit = true
    _sprite.modulate = Color.WHITE
    _light.visible = true
    _particles.emitting = true
    _label.text = "按E休息"
    emit_signal("lit")

func _extinguish():
    is_lit = false
    _sprite.modulate = Color(0.5, 0.5, 0.5)
    _light.visible = false
    _particles.emitting = false
    _label.visible = false
    emit_signal("extinguished")

func _rest():
    PlayerData.player_hp = PlayerData.player_hp_max
    PlayerData.reset_stamina()
    Utils.showToast("已恢复")
    emit_signal("rested")

func respawn_player():
    if is_lit && is_checkpoint:
        PlayerServer.setPlayerPosition(global_position)
        PlayerData.resurrectPlayer(PlayerData.player_hp_max, 100)
        Utils.showToast("从篝火复活")
```

---

## 6. 场景切换模块设计

### 6.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| MS-001 | 提供场景切换接口 |
| MS-002 | 切换前清理状态 |
| MS-003 | 切换时发出信号通知 |

### 6.2 设计思路

利用 Godot 的场景切换 API，结合 GameStateServer 管理状态。

### 6.3 接口设计

| 方法名 | 参数 | 返回值 | 功能说明 |
|--------|------|--------|----------|
| `go_to_lobby()` | 无 | `void` | 切换到大厅 |
| `go_to_weird_zone()` | 无 | `void` | 切换到诡异区域 |
| `go_to_settlement()` | 无 | `void` | 切换到结算场景 |

### 6.4 代码实现

**文件**: `autoload/server/MapServer.gd`（修改）

```gdscript
extends Node

signal map_changed(map_name: String)

const SCENES = {
    "lobby": "res://game/map/Lobby/Lobby.tscn",
    "weird_zone": "res://game/map/WeirdZone/WeirdZone.tscn",
    "settlement": "res://game/map/Settlement/Settlement.tscn"
}

func go_to_lobby():
    GameStateServer.transition_to(GameStateServer.State.LOBBY)
    _change_scene("lobby")

func go_to_weird_zone():
    GameStateServer.transition_to(GameStateServer.State.PLAYING)
    _change_scene("weird_zone")

func go_to_settlement():
    GameStateServer.transition_to(GameStateServer.State.SETTLEMENT)
    _change_scene("settlement")

func _change_scene(scene_name: String):
    var path = SCENES.get(scene_name)
    if path:
        get_tree().change_scene_to_file(path)
        emit_signal("map_changed", scene_name)
```

---

## 7. 大厅场景模块设计

### 7.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| LB-001 | 显示游戏标题 |
| LB-002 | 显示已带出战利品 |
| LB-003 | 出发按钮进入游戏 |
| LB-004 | 显示篝火复活选项（如果有激活的篝火） |

### 7.2 场景结构

```
Lobby (Node2D)
├── Background (ColorRect) - 背景
├── UIRoot (CanvasLayer)
│   ├── TitleLabel (Label) - "诡异搜打撤"
│   ├── LootPanel (VBoxContainer) - 战利品预览
│   ├── BonfirePanel (HBoxContainer) - 篝火状态
│   └── DeployButton (Button) - 出发按钮
```

### 7.3 代码实现

**文件**: `game/map/Lobby/Lobby.gd`

```gdscript
extends Node2D

@onready var _title_label: Label = $UIRoot/TitleLabel
@onready var _loot_panel: VBoxContainer = $UIRoot/LootPanel
@onready var _bonfire_panel: HBoxContainer = $UIRoot/BonfirePanel
@onready var _deploy_button: Button = $UIRoot/DeployButton

func _ready():
    _update_loot_preview()
    _update_bonfire_status()
    
    _deploy_button.pressed.connect(_on_deploy_pressed)

func _update_loot_preview():
    _loot_panel.clear()
    
    if LootServer.extracted_loot.size() == 0:
        var label = Label.new()
        label.text = "暂无带出战利品"
        _loot_panel.add_child(label)
        return
    
    for loot in LootServer.extracted_loot:
        var item = HBoxContainer.new()
        
        var icon = TextureRect.new()
        icon.texture = loot.get("icon")
        icon.size = Vector2(32, 32)
        item.add_child(icon)
        
        var info = VBoxContainer.new()
        
        var name_label = Label.new()
        name_label.text = loot.get("name")
        name_label.modulate = LootServer.get_rarity_color(loot.get("rarity"))
        info.add_child(name_label)
        
        var value_label = Label.new()
        value_label.text = str(loot.get("value")) + " 金币"
        info.add_child(value_label)
        
        item.add_child(info)
        _loot_panel.add_child(item)

func _update_bonfire_status():
    # 检查是否有激活的篝火存档
    # 这里可以扩展为存档系统
    _bonfire_panel.visible = false

func _on_deploy_pressed():
    # 重置玩家状态
    PlayerData.player_hp = PlayerData.player_hp_max
    PlayerData.reset_stamina()
    SanityServer.reset_sanity()
    LootServer.clear_current_loot()
    ExtractionServer.reset()
    
    MapServer.go_to_weird_zone()
```

---

## 8. 诡异区域场景模块设计

### 8.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| WZ-001 | 初始化玩家和武器 |
| WZ-002 | 生成诡异怪物 |
| WZ-003 | 散落战利品 |
| WZ-004 | 放置篝火和撤离点 |
| WZ-005 | 启动理智流失 |
| WZ-006 | 处理玩家死亡和撤离 |

### 8.2 场景结构

```
WeirdZone (Node2D)
├── Land (TileMap) - 地图
├── PlayerRoot (Node2D) - 玩家容器
├── MonsterRoot (Node2D) - 怪物容器
├── LootRoot (Node2D) - 战利品容器
├── ExtractionRoot (Node2D) - 撤离点容器
├── Bonfire (Bonfire) - 篝火
├── AtmosphereController (AtmosphereController) - 氛围控制
├── MonsterBuilder (Node2D) - 怪物生成器
├── CanvasLayer
│   ├── ControlUI - 原有UI
│   └── WeirdUI (CanvasLayer)
│       ├── SanityBar - 理智条
│       ├── StaminaBar - 精力条
│       └── ExtractionStatus - 撤离状态
```

### 8.3 代码实现

**文件**: `game/map/WeirdZone/WeirdZone.gd`

```gdscript
extends Node2D

@onready var _player_root: Node2D = $PlayerRoot
@onready var _monster_root: Node2D = $MonsterRoot
@onready var _loot_root: Node2D = $LootRoot
@onready var _extraction_root: Node2D = $ExtractionRoot
@onready var _monster_builder: Node2D = $MonsterBuilder

func _ready():
    # 初始化玩家
    PlayerServer.addPlayerToScene(_player_root)
    PlayerServer.setPlayerPosition($SpawnPoint.global_position)
    
    # 初始化武器
    PlayerData.player_ammo = 9999999
    PlayerData.add_weapon(Utils.weapon_list['0'].instantiate())
    
    # 生成近战武器
    var sword = preload("res://game/weapons/Sword.tscn").instantiate()
    sword.player = Utils.player
    _player_root.add_child(sword)
    Utils.player.melee_weapon = sword
    
    # 初始化撤离系统
    ExtractionServer.set_conditions(30.0, [], 5)
    
    # 启动理智流失
    SanityServer.start_drain()
    
    # 生成战利品
    _spawn_loot()
    
    # 启动怪物生成
    _monster_builder.start()
    
    # 连接信号
    PlayerData.onPlayerDeath.connect(_on_player_death)
    SanityServer.sanity_depleted.connect(_on_sanity_depleted)
    ExtractionServer.extraction_completed.connect(_on_extraction_success)

func _spawn_loot():
    var positions = [
        Vector2(200, 200), Vector2(400, 200),
        Vector2(300, 350), Vector2(500, 350),
        Vector2(150, 300), Vector2(550, 300)
    ]
    
    for pos in positions:
        var loot_type = randi() % 3
        var loot = null
        
        match loot_type:
            0:
                loot = preload("res://game/loot/SanityPotion.tscn").instantiate()
            1:
                loot = preload("res://game/loot/MysteriousArtifact.tscn").instantiate()
            2:
                loot = preload("res://game/loot/TaintedEssence.tscn").instantiate()
        
        if loot:
            loot.global_position = pos
            _loot_root.add_child(loot)

func _on_player_death():
    GameStateServer.transition_to(GameStateServer.State.DEAD)
    LootServer.clear_current_loot()
    
    var death_board = preload("res://ui/widgets/DeathBoard.tscn").instantiate()
    death_board.setOnClick(func(success):
        if success:
            # 篝火复活
            var bonfires = get_tree().get_nodes_in_group("bonfire")
            for bonfire in bonfires:
                if bonfire.is_lit:
                    bonfire.respawn_player()
                    break
        else:
            # 普通复活
            PlayerData.resurrectPlayer(1, 20)
        
        get_tree().paused = false
        death_board.queue_free()
    )
    $CanvasLayer.add_child(death_board)

func _on_sanity_depleted():
    PlayerData.player_hp = 0  # 理智归零导致死亡

func _on_extraction_success():
    MapServer.go_to_settlement()
```

---

## 9. 结算场景模块设计

### 9.1 功能需求

| 需求编号 | 需求描述 |
|----------|----------|
| ST-001 | 显示撤离成功或失败 |
| ST-002 | 显示本次收获的战利品 |
| ST-003 | 显示统计信息（击杀数、存活时间） |
| ST-004 | 返回大厅按钮 |

### 9.2 场景结构

```
Settlement (Node2D)
├── Background (ColorRect)
├── UIRoot (CanvasLayer)
│   ├── ResultTitle (Label) - 结果标题
│   ├── LootScroll (ScrollContainer) - 战利品列表
│   ├── StatsLabel (Label) - 统计信息
│   └── ReturnButton (Button) - 返回按钮
```

### 9.3 代码实现

**文件**: `game/map/Settlement/Settlement.gd`

```gdscript
extends Node2D

@onready var _result_title: Label = $UIRoot/ResultTitle
@onready var _loot_scroll: ScrollContainer = $UIRoot/LootScroll
@onready var _stats_label: Label = $UIRoot/StatsLabel
@onready var _return_button: Button = $UIRoot/ReturnButton

func _ready():
    _return_button.pressed.connect(_on_return_pressed)
    
    _display_result()

func _display_result():
    var success = ExtractionServer.current_state == ExtractionServer.ExtractionState.COMPLETED
    
    if success:
        _result_title.text = "撤离成功"
        _result_title.modulate = Color.GREEN
        _display_loot()
    else:
        _result_title.text = "行动失败"
        _result_title.modulate = Color.RED
        _loot_scroll.visible = false
    
    _stats_label.text = "击杀: %d | 存活时间: %.1fs" % [
        ExtractionServer.kill_count,
        ExtractionServer.time_in_zone
    ]

func _display_loot():
    var loot_list = VBoxContainer.new()
    
    for loot in LootServer.extracted_loot:
        var item = HBoxContainer.new()
        
        var icon = TextureRect.new()
        icon.texture = loot.get("icon")
        icon.size = Vector2(48, 48)
        item.add_child(icon)
        
        var info = VBoxContainer.new()
        
        var name_label = Label.new()
        name_label.text = loot.get("name")
        name_label.modulate = LootServer.get_rarity_color(loot.get("rarity"))
        info.add_child(name_label)
        
        var desc_label = Label.new()
        desc_label.text = loot.get("description")
        desc_label.size = Vector2(200, 0)
        info.add_child(desc_label)
        
        var value_label = Label.new()
        value_label.text = str(loot.get("value")) + " 金币"
        info.add_child(value_label)
        
        item.add_child(info)
        loot_list.add_child(item)
    
    _loot_scroll.add_child(loot_list)

func _on_return_pressed():
    MapServer.go_to_lobby()
```

---

## 附录：UI组件设计

### 精力条 UI

**文件**: `ui/weird/StaminaBar.gd`

```gdscript
extends ProgressBar

func _ready():
    max_value = PlayerData.max_stamina
    value = PlayerData.current_stamina
    PlayerData.stamina_changed.connect(_on_stamina_changed)

func _on_stamina_changed(current: float, max: float):
    value = current
    max_value = max
```

---

## 附录：项目配置修改

**文件**: `project.godot`

```ini
[autoload]
GameStateServer="*res://autoload/server/GameStateServer.gd"
```

主场景修改为：
```ini
[application]
main_scene="res://game/map/Lobby/Lobby.tscn"
```
