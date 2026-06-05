# 2D魂+搜打撤 MVP 开发计划

## 核心定位

**游戏类型**：俯视角2D射击 + 魂系战斗 + 搜打撤玩法

**MVP目标**：跑通完整游戏循环，验证核心玩法是否有乐趣

---

## 玩家选择确认

| 选项 | 选择 |
|------|------|
| 魂元素 | 近战/闪避/精力管理/篝火复活 |
| 地图设计 | 现有地图改造（复用SnowWorld） |
| MVP重点 | 完整游戏循环 |

---

## 已有系统分析（可直接复用）

### ✅ 已完成的基础系统

| 系统 | 文件位置 | 状态 | 复用方式 |
|------|----------|------|---------|
| 玩家移动 | `game/hero/Hero.gd` | ✅ | 直接复用 |
| 武器射击 | `game/guns/BaseGun.gd` | ✅ | 直接复用 |
| 怪物基类 | `game/monster/BaseMonster.gd` | ✅ | 直接复用 |
| 诡异怪物 | `game/monster/weird/` | ✅ | 直接复用 |
| 理智系统 | `autoload/server/SanityServer.gd` | ✅ | 直接复用 |
| 战利品系统 | `autoload/server/LootServer.gd` | ✅ | 直接复用 |
| 撤离系统 | `autoload/server/ExtractionServer.gd` | ✅ | 直接复用 |
| 氛围控制 | `game/atmosphere/AtmosphereController.gd` | ✅ | 直接复用 |
| 玩家数据 | `autoload/PlayerData.gd` | ✅ | 需要扩展精力值 |

### 📝 需要新增的系统

| 系统 | 说明 |
|------|------|
| 精力系统 | 攻击/闪避消耗精力，自动恢复 |
| 近战武器 | 剑/刀类近战攻击 |
| 闪避翻滚 | 带无敌帧的翻滚动作 |
| 篝火系统 | 复活点/检查点 |
| 游戏状态机 | 管理大厅→游戏→结算流程 |
| 地图切换 | 实现MapServer |

---

## MVP 游戏流程

```
┌────────────────────┐     点击出发     ┌────────────────────┐
│    大厅场景        │ ───────────────→ │    诡异区域        │
│  - 显示已带出战利品 │                  │  - 理智流失开始     │
│  - 出发按钮        │                  │  - 探索/战斗        │
│  - 篝火选项        │                  │  - 收集战利品       │
└────────────────────┘                  │  - 寻找撤离点       │
       ↑                               └─────────┬──────────┘
       │                                         │
       │ 返回大厅                                │
       │                                         ▼
┌────────────────────┐     撤离成功     ┌────────────────────┐
│    结算场景        │ ←─────────────── │    撤离点激活      │
│  - 显示收获/损失   │                  │  - 5秒倒计时       │
│  - 统计信息        │                  └────────────────────┘
│  - 返回大厅按钮    │
└────────────────────┘
       ↑
       │ 死亡/理智归零
       │
┌────────────────────┐
│   死亡面板         │
│  - 篝火复活（满血）│
│  - 普通复活（残血）│
│  - 丢失当前战利品  │
└────────────────────┘
```

---

## 实施步骤

### Step 1: 扩展 PlayerData 添加精力系统

**修改文件**: `autoload/PlayerData.gd`

新增属性：
```gdscript
signal stamina_changed(current: float, max: float)

var max_stamina: float = 100.0
var current_stamina: float = 100.0:
    set(value):
        current_stamina = clamp(value, 0, max_stamina)
        emit_signal("stamina_changed", current_stamina, max_stamina)

var stamina_regen_rate: float = 20.0  # 每秒恢复
var is_stamina_draining: bool = false  # 是否在消耗中（停止消耗后延迟恢复）
var stamina_regen_delay: float = 0.3   # 停止消耗后延迟恢复时间

# 消耗精力
func consume_stamina(amount: float) -> bool:
    if current_stamina >= amount:
        current_stamina -= amount
        is_stamina_draining = true
        return true
    return false

# 恢复精力
func regenerate_stamina(delta: float):
    if not is_stamina_draining:
        current_stamina = min(current_stamina + stamina_regen_rate * delta, max_stamina)
```

### Step 2: 创建近战武器系统

**新建文件**: 
- `game/weapons/MeleeWeapon.gd`
- `game/weapons/Sword.tscn`
- `game/weapons/Sword.gd`

MeleeWeapon.gd 基类：
```gdscript
extends Node2D
class_name MeleeWeapon

@export var damage: float = 2.0
@export var swing_range: float = 60.0
@export var swing_duration: float = 0.3
@export var stamina_cost: float = 15.0

var is_swinging: bool = false
var player: Player = null

func swing():
    if is_swinging:
        return
    if not PlayerData.consume_stamina(stamina_cost):
        Utils.showToast("精力不足")
        return
    
    is_swinging = true
    # 播放挥砍动画
    # 检测范围内的敌人
    _detect_enemies()
    await get_tree().create_timer(swing_duration).timeout
    is_swinging = false

func _detect_enemies():
    var area = Area2D.new()
    var shape = CircleShape2D.new()
    shape.radius = swing_range
    area.shape = shape
    area.global_position = player.global_position
    add_child(area)
    
    for body in area.get_overlapping_bodies():
        if body is BaseMonster:
            body.onHit(damage)
    
    area.queue_free()
```

### Step 3: 扩展 Hero.gd 添加闪避翻滚和精力管理

**修改文件**: `game/hero/Hero.gd`

新增属性和方法：
```gdscript
# 精力相关
var is_rolling: bool = false
var roll_duration: float = 0.2
var roll_distance: float = 120.0
var roll_stamina_cost: float = 20.0

# 近战武器
var melee_weapon: MeleeWeapon = null

func _input(event: InputEvent):
    # 原有的冲刺逻辑改为闪避翻滚
    if Input.is_action_just_pressed("dash") && !is_rolling && !is_dash:
        _roll()
    
    # 近战攻击
    if Input.is_action_just_pressed("melee_attack") && melee_weapon:
        melee_weapon.swing()

func _roll():
    if not PlayerData.consume_stamina(roll_stamina_cost):
        Utils.showToast("精力不足")
        return
    
    is_rolling = true
    is_invincible = true  # 翻滚期间无敌
    var direction = Input.get_vector("left", "right", "up", "down")
    if direction == Vector2.ZERO:
        direction = global_position.direction_to(get_global_mouse_position())
    
    velocity = direction.normalized() * roll_distance / roll_duration
    anim.play("roll")
    
    await get_tree().create_timer(roll_duration).timeout
    is_rolling = false
    is_invincible = false

func onHit(hurt):
    if is_invincible:
        return  # 翻滚期间无敌
    # 原有逻辑...

func _physics_process(delta):
    # 精力恢复
    PlayerData.regenerate_stamina(delta)
    # 原有逻辑...
```

### Step 4: 创建篝火系统

**新建文件**:
- `game/bonfire/Bonfire.gd`
- `game/bonfire/Bonfire.tscn`

Bonfire.gd：
```gdscript
extends Area2D
class_name Bonfire

signal lit()
signal extinguished()

var is_lit: bool = false
var is_checkpoint: bool = true  # 是否作为复活点

@onready var sprite = $Sprite2D
@onready var light = $PointLight2D
@onready var particles = $Particles2D

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body is Player:
        if not is_lit:
            _light()
        else:
            _rest()

func _light():
    is_lit = true
    sprite.texture = preload("res://Sprites/bonfire_lit.png")
    light.visible = true
    particles.emitting = true
    emit_signal("lit")
    Utils.showToast("篝火已点燃")

func _rest():
    # 休息恢复HP和精力
    PlayerData.player_hp = PlayerData.player_hp_max
    PlayerData.current_stamina = PlayerData.max_stamina
    Utils.showToast("已恢复")

func respawn_player():
    if is_lit and is_checkpoint:
        PlayerServer.setPlayerPosition(global_position)
        PlayerData.resurrectPlayer(PlayerData.player_hp_max, 100)
```

### Step 5: 创建 GameStateServer（游戏状态机）

**新建文件**: `autoload/server/GameStateServer.gd`

```gdscript
extends Node

enum State {
    LOBBY,      # 大厅
    PLAYING,    # 游戏中
    PAUSED,     # 暂停
    DEAD,       # 死亡
    SETTLEMENT  # 结算
}

signal state_changed(old_state: State, new_state: State)

var current_state: State = State.LOBBY

func transition_to(new_state: State):
    var old = current_state
    current_state = new_state
    emit_signal("state_changed", old, new_state)
    
    match new_state:
        State.LOBBY:
            _on_enter_lobby()
        State.PLAYING:
            _on_enter_playing()
        State.DEAD:
            _on_enter_dead()
        State.SETTLEMENT:
            _on_enter_settlement()

func _on_enter_lobby():
    SanityServer.reset_sanity()
    LootServer.clear_current_loot()
    ExtractionServer.reset()

func _on_enter_playing():
    Utils.gameStart()
    SanityServer.start_drain()

func _on_enter_dead():
    SanityServer.stop_drain()

func _on_enter_settlement():
    pass
```

### Step 6: 实现 MapServer（场景切换）

**修改文件**: `autoload/server/MapServer.gd`

```gdscript
extends Node

signal map_changed(map_name: String)

const LOBBY_SCENE = preload("res://game/map/Lobby/Lobby.tscn")
const WEIRD_ZONE_SCENE = preload("res://game/map/WeirdZone/WeirdZone.tscn")
const SETTLEMENT_SCENE = preload("res://game/map/Settlement/Settlement.tscn")

func go_to_lobby():
    GameStateServer.transition_to(GameStateServer.State.LOBBY)
    get_tree().change_scene_to_file("res://game/map/Lobby/Lobby.tscn")

func go_to_weird_zone():
    GameStateServer.transition_to(GameStateServer.State.PLAYING)
    get_tree().change_scene_to_file("res://game/map/WeirdZone/WeirdZone.tscn")

func go_to_settlement():
    GameStateServer.transition_to(GameStateServer.State.SETTLEMENT)
    get_tree().change_scene_to_file("res://game/map/Settlement/Settlement.tscn")

func go_to_death():
    GameStateServer.transition_to(GameStateServer.State.DEAD)
```

### Step 7: 创建大厅场景（Lobby）

**新建文件**:
- `game/map/Lobby/Lobby.tscn`
- `game/map/Lobby/Lobby.gd`

场景结构：
```
Lobby (Node2D)
├── Background (ColorRect)
├── UIRoot (CanvasLayer)
│   ├── TitleLabel (Label) - "诡异搜打撤"
│   ├── LootPreview (VBoxContainer) - 已带出战利品
│   ├── BonfireButton (Button) - 篝火复活选项
│   └── DeployButton (Button) - 出发按钮
```

Lobby.gd 逻辑：
```gdscript
func _ready():
    _update_loot_preview()
    
func _update_loot_preview():
    # 显示 LootServer.extracted_loot
    
func _on_deploy_button_pressed():
    # 重置游戏状态
    PlayerData.player_hp = PlayerData.player_hp_max
    PlayerData.current_stamina = PlayerData.max_stamina
    SanityServer.reset_sanity()
    LootServer.clear_current_loot()
    ExtractionServer.reset()
    
    MapServer.go_to_weird_zone()
```

### Step 8: 创建诡异区域场景（WeirdZone）

**新建文件**:
- `game/map/WeirdZone/WeirdZone.tscn`
- `game/map/WeirdZone/WeirdZone.gd`

基于 SnowWorld 改造，核心改动：
1. 添加篝火作为复活点
2. 添加撤离点
3. 添加诡异怪物生成器
4. 添加战利品散落
5. 添加氛围控制器
6. 添加理智条和精力条UI

WeirdZone.gd 关键逻辑：
```gdscript
func _ready():
    # 初始化玩家
    PlayerServer.addPlayerToScene($PlayerRoot)
    PlayerServer.setPlayerPosition($SpawnPoint.global_position)
    
    # 初始化武器（手枪+近战）
    PlayerData.player_ammo = 9999999
    PlayerData.add_weapon(Utils.weapon_list['0'].instantiate())
    
    # 生成近战武器
    var sword = preload("res://game/weapons/Sword.tscn").instantiate()
    Utils.player.melee_weapon = sword
    
    # 初始化撤离系统（30秒+5击杀）
    ExtractionServer.set_conditions(30.0, [], 5)
    
    # 启动理智流失
    SanityServer.start_drain()
    
    # 生成战利品
    _spawn_loot()
    
    # 启动怪物生成
    $MonsterBuilder.start()
    
    # 连接信号
    PlayerData.onPlayerDeath.connect(_on_player_death)
    SanityServer.sanity_depleted.connect(_on_sanity_depleted)
    ExtractionServer.extraction_completed.connect(_on_extraction_success)

func _spawn_loot():
    # 在地图上随机生成战利品
    var loot_positions = [
        Vector2(200, 200),
        Vector2(400, 200),
        Vector2(300, 350),
        Vector2(500, 350),
        Vector2(150, 300),
    ]
    
    for pos in loot_positions:
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
            $LootRoot.add_child(loot)
```

### Step 9: 创建结算场景（Settlement）

**新建文件**:
- `game/map/Settlement/Settlement.tscn`
- `game/map/Settlement/Settlement.gd`

场景结构：
```
Settlement (Node2D)
├── Background (ColorRect)
├── UIRoot (CanvasLayer)
│   ├── ResultTitle (Label) - "撤离成功"或"行动失败"
│   ├── LootList (ScrollContainer) - 本次收获
│   ├── StatsLabel (Label) - 击杀数/存活时间/理智
│   └── ReturnButton (Button) - 返回大厅
```

Settlement.gd 逻辑：
```gdscript
func _ready():
    var success = GameStateServer.current_state == GameStateServer.State.SETTLEMENT
    
    if success:
        $ResultTitle.text = "撤离成功"
        _show_loot()
    else:
        $ResultTitle.text = "行动失败"
        $LootList.visible = false
    
    $StatsLabel.text = "击杀: %d | 时间: %.1fs" % [
        ExtractionServer.kill_count,
        ExtractionServer.time_in_zone
    ]

func _show_loot():
    # 显示 LootServer.extracted_loot 中新增的物品
```

### Step 10: 修改死亡面板添加篝火选项

**修改文件**: `ui/widgets/DeathBoard.gd`

添加篝火复活按钮：
```gdscript
func _on_bonfire_button_pressed():
    # 检查是否有激活的篝火
    var bonfires = get_tree().get_nodes_in_group("bonfire")
    for bonfire in bonfires:
        if bonfire.is_lit:
            get_tree().paused = false
            bonfire.respawn_player()
            queue_free()
            return
    
    Utils.showToast("没有可用的篝火")
```

### Step 11: 添加精力条UI

**新建文件**:
- `ui/weird/StaminaBar.tscn`
- `ui/weird/StaminaBar.gd`

StaminaBar.gd：
```gdscript
extends ProgressBar

func _ready():
    max_value = PlayerData.max_stamina
    value = PlayerData.current_stamina
    
    PlayerData.stamina_changed.connect(_on_stamina_changed)

func _on_stamina_changed(current, max):
    value = current
    max_value = max
```

### Step 12: 修改 project.godot

1. 添加 GameStateServer 到 Autoload
2. 修改主场景为 Lobby.tscn

---

## 文件变更清单

### 新建文件（16个）

| 文件 | 说明 |
|------|------|
| `autoload/server/GameStateServer.gd` | 游戏状态机 |
| `game/weapons/MeleeWeapon.gd` | 近战武器基类 |
| `game/weapons/Sword.tscn` | 剑武器场景 |
| `game/weapons/Sword.gd` | 剑武器逻辑 |
| `game/bonfire/Bonfire.gd` | 篝火逻辑 |
| `game/bonfire/Bonfire.tscn` | 篝火场景 |
| `game/map/Lobby/Lobby.gd` | 大厅逻辑 |
| `game/map/Lobby/Lobby.tscn` | 大厅场景 |
| `game/map/WeirdZone/WeirdZone.gd` | 诡异区域逻辑 |
| `game/map/WeirdZone/WeirdZone.tscn` | 诡异区域场景 |
| `game/map/Settlement/Settlement.gd` | 结算逻辑 |
| `game/map/Settlement/Settlement.tscn` | 结算场景 |
| `ui/weird/StaminaBar.gd` | 精力条UI |
| `ui/weird/StaminaBar.tscn` | 精力条场景 |

### 修改文件（5个）

| 文件 | 修改内容 |
|------|---------|
| `autoload/PlayerData.gd` | 新增精力系统属性和方法 |
| `autoload/server/MapServer.gd` | 实现场景切换方法 |
| `game/hero/Hero.gd` | 添加闪避翻滚和近战攻击 |
| `ui/widgets/DeathBoard.gd` | 添加篝火复活选项 |
| `project.godot` | 添加 GameStateServer Autoload |

---

## 核心玩法验证清单

### ✅ 搜打撤循环
- [ ] 进入区域开始理智流失
- [ ] 搜索并收集战利品
- [ ] 战斗（近战+远程）
- [ ] 达成撤离条件（时间+击杀）
- [ ] 撤离成功带出战利品

### ✅ 魂系战斗
- [ ] 近战挥砍攻击
- [ ] 闪避翻滚（无敌帧）
- [ ] 精力管理（攻击/闪避消耗，自动恢复）
- [ ] 篝火系统（点燃/休息/复活点）
- [ ] 死亡惩罚（丢失当前战利品）

---

## 测试计划

1. **大厅测试**: 出发按钮、战利品预览显示
2. **移动测试**: WASD移动、闪避翻滚、冲刺
3. **战斗测试**: 手枪射击、近战挥砍、精力消耗
4. **理智测试**: 理智流失、氛围效果变化、理智药剂恢复
5. **战利品测试**: 拾取战利品、背包显示、稀有度颜色
6. **怪物测试**: 诡异怪物生成、追踪攻击、击杀计数
7. **撤离测试**: 条件检测、撤离点激活、倒计时、成功结算
8. **死亡测试**: 死亡面板、篝火复活、普通复活、失败结算
9. **完整流程**: 大厅→区域→战斗→撤离→结算→大厅

---

## 开发优先级

### 第1周：基础架构
1. GameStateServer + MapServer
2. PlayerData 精力系统扩展
3. 大厅场景

### 第2周：核心战斗
4. Hero 闪避翻滚 + 精力管理
5. MeleeWeapon 近战系统
6. Bonfire 篝火系统

### 第3周：场景整合
7. WeirdZone 诡异区域场景
8. Settlement 结算场景
9. UI整合（精力条+理智条）

### 第4周：测试调优
10. 完整流程测试
11. 数值平衡调整
12. Bug修复

---

## 关键数值建议

| 系统 | 参数 | 建议值 |
|------|------|--------|
| 理智 | 被动流失速率 | 0.3/秒 |
| 理智 | 药剂恢复量 | 30 |
| 精力 | 最大精力 | 100 |
| 精力 | 恢复速率 | 20/秒 |
| 精力 | 翻滚消耗 | 20 |
| 精力 | 近战消耗 | 15 |
| 撤离 | 时间条件 | 30秒 |
| 撤离 | 击杀条件 | 5个 |
| 撤离 | 倒计时 | 5秒 |
