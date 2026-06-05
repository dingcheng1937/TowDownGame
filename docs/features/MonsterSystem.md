# 怪物系统开发文档

## 概述

本项目怪物系统采用**动态创建模式**，而非预放置模式。怪物在游戏运行时通过代码动态生成，确保 `target_player` 等依赖项正确初始化。

---

## 系统架构

### 文件结构

```
game/monster/
├── BaseMonster.gd          # 怪物基类（核心逻辑）
├── Ghoul/
│   ├── Ghoul.gd            # Ghoul 实现
│   └── Ghoul.tscn          # Ghoul 场景
├── Monster 1/
│   ├── Monster1.gd
│   └── Monster1.tscn
├── Monster 2/
│   ├── Monster2.gd
│   ├── Monster2.tscn
└── weird/
    ├── Shade.gd            # 诡异怪物：残影
    ├── Whisperer.gd        # 诡异怪物：低语者
    ├── Aberration.gd       # 诡异怪物：畸变体
    └── WhispererProjectile.gd  # 投射物
```

---

## BaseMonster 基类

### 核心属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `SPEED` | float | 移动速度（默认 50） |
| `hurt` | int | 攻击伤害值 |
| `HP` | int | 血量 |
| `knockback_def` | int | 击退抵抗值 |
| `target_player` | Player | 追踪目标（注意初始化时机） |
| `is_die` | bool | 是否死亡 |
| `is_atk` | bool | 是否正在攻击 |

### 核心方法

```gdscript
# 设置怪物属性（动态创建时调用）
func setData(data):
    SPEED = data['speed']
    hurt = data['hurt']
    HP = data['hp']

# 受伤处理
func onHit(hit_num, is_show_label = true, is_death_effect = true)

# 死亡处理
func onDie(is_death_effect = true)

# 设置死亡回调
func setDeathCallBack(death_callback: Callable)
```

### 关键注意事项

**⚠️ target_player 初始化问题**

```gdscript
# BaseMonster.gd 第15行
var target_player: Player = Utils.player  # 类变量初始化
```

问题：类变量在节点实例化时初始化，此时 `Utils.player` 可能为 `null`。

**解决方案**：
- 动态创建怪物（推荐，原游戏采用此方式）
- 或在子类 `_ready()` 中覆盖（如 Ghoul）

---

## 怪物分类

### 普通怪物

#### Ghoul（食尸鬼）
- **特点**：基础追踪怪物
- **攻击**：无攻击逻辑（仅追踪）
- **文件**：`game/monster/Ghoul/Ghoul.gd`

```gdscript
func _ready():
    super._ready()
    target_player = PlayerServer.player_scene  # 显式覆盖
    anim.play("idle")
```

#### Monster1
- **特点**：基础怪物
- **攻击**：无特殊攻击
- **依赖**：基类默认 `Utils.player`

#### Monster2
- **特点**：带攻击检测的怪物
- **攻击**：Area2D 检测 + 攻击动画 + AtkTimer
- **场景组件**：
  - Area2D（攻击检测范围）
  - AtkTimer（攻击间隔定时器）

```gdscript
func _on_area_2d_body_entered(body):
    if body is Player && !is_die:
        area_player = body
        is_atk = true
        $AtkTimer.start()

func _on_animated_sprite_2d_frame_changed():
    if anim.animation == "atk" && anim.frame == 5:
        if area_player != null && !is_die:
            area_player.onHit(hurt)  # 对玩家造成伤害
```

### 诡异怪物（Weird Monsters）

位于 `game/monster/weird/`，用于诡异搜打撤模式。

#### Shade（残影）
- **特点**：高速、低血量、冲刺攻击
- **伤害**：物理伤害 + 理智伤害
- **特殊能力**：冲刺（dash_multiplier, dash_distance）

#### Whisperer（低语者）
- **特点**：远程攻击、持续降低周围理智
- **特殊能力**：理智降低范围（sanity_drain_radius）
- **攻击方式**：投射物（WhispererProjectile）

#### Aberration（畸变体）
- **特点**：高血量、高伤害、慢速
- **特殊能力**：冲锋（charge_distance, charge_speed_mult）
- **减伤**：受伤时减免 30%

---

## 怪物生成系统

### MonsterBuilder（怪物生成器）

**文件**：`game/map/SnowWorld/MonsterBuilder.gd`

**功能**：
- 定时生成怪物
- 管理怪物等级
- 计算安全生成位置

```gdscript
const monster_pre = preload("res://game/monster/Ghoul/Ghoul.tscn")

# 怪物等级数据
var level_data = [
    {"hp": 2, "speed": 45, "hurt": 1},  # Lv0
    {"hp": 3, "speed": 45, "hurt": 2},  # Lv1
    {"hp": 5, "speed": 45, "hurt": 3},  # Lv2
    # ...
]

# 创建怪物
func createMonster(monster):
    var ins = monster.instantiate()
    ins.setData(level_data[level])      # 设置属性
    ins.global_position = getPosition() # 设置位置
    ins.setDeathCallBack(self.onMonsterDeath)  # 设置死亡回调
    monsterRoot.add_child(ins)          # 添加到场景

# 获取安全生成位置（避开玩家）
func getPosition():
    var next_point = global_array[randi() % global_array.size()] * 0.3
    if Utils.player.global_position.distance_to(next_point) < distanceThreshold:
        return getPosition()  # 重新获取
    return next_point
```

### Town 地图动态生成

**文件**：`game/map/mapTown/Town.gd`

```gdscript
const monster_pre = preload("res://game/monster/Monster 2/Monster2.tscn")

func monsterCreate():
    var ins = monster_pre.instantiate()
    ins.global_position = getPoint()
    ins.setData(LevelServer.getLevelMonsterData())
    ins.setDeathCallBack(self.onMonsterDeath)
    monster_root.add_child(ins)
```

---

## 开发指南

### 创建新怪物

#### 步骤 1：创建场景文件

1. 在 `game/monster/YourMonster/` 创建目录
2. 创建 `YourMonster.tscn`：
   - 根节点：`CharacterBody2D`
   - collision_layer：`3`（怪物层）
   - collision_mask：根据需要设置

#### 步骤 2：添加必要节点

```
YourMonster (CharacterBody2D)
├── UndeadShadow (Sprite2D)        # 影子效果
├── body (Node2D)
│   └── AnimatedSprite2D           # 动画
├── CollisionShape2D               # 物理碰撞
├── EffectRoot (Node2D)            # 特效容器
└── [可选] Area2D                   # 攻击检测
    └── CollisionShape2D
└── [可选] AtkTimer (Timer)         # 攻击间隔
```

#### 步骤 3：编写脚本

```gdscript
extends BaseMonster
class_name YourMonster

func _ready():
    super._ready()
    # 设置怪物特性
    SPEED = 60.0
    HP = 8
    hurt = 2

func _physics_process(delta):
    if is_die:
        return
    super._physics_process(delta)
    # 添加自定义逻辑

# [可选] 攻击检测信号
func _on_area_2d_body_entered(body):
    if body is Player and not is_die:
        # 攻击逻辑
```

#### 步骤 4：创建动画

在 AnimatedSprite2D 中创建 SpriteFrames：
- `idle` - 待机动画
- `run` - 移动动画
- `atk` - 攻击动画（可选）
- `die` - 死亡动画

---

### 正确使用怪物

#### ❌ 错误方式：预放置

```gdscript
# 在场景中直接放置怪物节点
[node name="Monster" parent="." instance=ExtResource("monster")]
position = Vector2(200, 200)
```

**问题**：怪物 `_ready()` 时 `Utils.player` 可能为 `null`

#### ✓ 正确方式：动态创建

```gdscript
# 在代码中动态创建
const MonsterPre = preload("res://game/monster/Monster2/Monster2.tscn")

func spawn_monster():
    var ins = MonsterPre.instantiate()
    ins.setData({"hp": 5, "speed": 50, "hurt": 1})
    ins.global_position = Vector2(200, 200)
    ins.setDeathCallBack(on_monster_death)
    monster_root.add_child(ins)
```

---

## GYM 场景使用指南

### GYM_03_Monster 示例

**正确实现**（动态创建）：

```gdscript
# GYM_03_MonsterStarter.gd
const MonsterPre = preload("res://game/monster/Monster 2/Monster2.tscn")

var spawn_points: Array[Vector2] = [
    Vector2(200, 200),
    Vector2(600, 200),
    Vector2(200, 400),
    Vector2(600, 400)
]

var monster_data = {
    "hp": 5,
    "speed": 50,
    "hurt": 1
}

func _ready():
    Utils.gameStart()
    _spawn_monsters()

func _spawn_monsters():
    for spawn_pos in spawn_points:
        var ins = MonsterPre.instantiate()
        ins.setData(monster_data)
        ins.global_position = spawn_pos
        ins.setDeathCallBack(_on_monster_death)
        $MonstersRoot.add_child(ins)
```

---

## 怪物属性参考

### level_data 配置模板

```gdscript
var level_data = [
    {"hp": 2,  "speed": 45, "hurt": 1},   # 简单
    {"hp": 5,  "speed": 50, "hurt": 2},   # 普通
    {"hp": 10, "speed": 55, "hurt": 3},   # 困难
    {"hp": 15, "speed": 60, "hurt": 4},   # 精英
    {"hp": 20, "speed": 70, "hurt": 5},   # Boss
]
```

### 诡异怪物特殊属性

| 怪物 | 特殊属性 | 值范围 |
|------|---------|--------|
| Shade | sanity_damage | 5.0 |
| Shade | dash_multiplier | 2.5 |
| Whisperer | sanity_drain_radius | 150.0 |
| Whisperer | sanity_drain_rate | 2.0/sec |
| Aberration | charge_distance | 200.0 |
| Aberration | 减伤比例 | 0.7 |

---

## 常见问题

### Q: 怪物不移动？

**检查**：
1. 是否使用动态创建模式？
2. `setData()` 是否正确调用？
3. `Utils.player` 在怪物创建时是否已设置？

### Q: 怪物不攻击玩家？

**检查**：
1. 是否有 Area2D 节点？
2. Area2D 信号是否连接？
3. collision_mask 是否正确设置（检测玩家层）？

### Q: 怪物死亡不掉落物品？

**解决**：使用 `setDeathCallBack()`

```gdscript
ins.setDeathCallBack(func(monster):
    var gold = GoldPre.instantiate()
    gold.global_position = monster.global_position
    monster_root.add_child(gold)
)
```

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `game/monster/BaseMonster.gd` | 怪物基类 |
| `game/map/SnowWorld/MonsterBuilder.gd` | 怪物生成器示例 |
| `game/map/mapTown/Town.gd` | 动态生成示例 |
| `demo/GYM_03_MonsterStarter.gd` | GYM 正确实现 |
| `docs/features/CreatePosition.md` | 玩家出生点文档 |