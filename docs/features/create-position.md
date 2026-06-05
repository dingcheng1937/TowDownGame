# CreatePosition 使用文档

## 概述

`CreatePosition` 是一个 **Node2D 节点**，用于标记玩家在场景中的出生位置。它是原项目的标准做法，广泛应用于所有正式游戏地图。

---

## 代码实现

### 1. 场景中的节点

在地图场景文件中放置一个 `Node2D` 节点：

```tscn
[node name="CreatePosition" type="Node2D" parent="."]
position = Vector2(-374, 135)
```

**要点：**
- 节点类型：`Node2D`
- 无需脚本，无需额外属性
- 只需要设置 `position` 来指定出生点坐标

---

### 2. PlayerServer.setPlayerPosition()

相关代码位于 `autoload/server/PlayerServer.gd`:

```gdscript
func setPlayerPosition(position):
    if player_scene:
        player_scene.global_position = position
```

**功能：** 设置玩家实例的 `global_position`

---

### 3. 使用方式

在地图脚本的 `_ready()` 中调用：

```gdscript
func _ready() -> void:
    # 创建玩家并添加到场景
    PlayerServer.addPlayerToScene($PlayerRoot)
    
    # 设置玩家出生位置（使用 CreatePosition 节点）
    PlayerServer.setPlayerPosition($CreatePosition.global_position)
    
    # 触发游戏启动
    Utils.gameStart()
```

---

## 数据流

```
CreatePosition 节点 (Node2D)
         ↓
$CreatePosition.global_position  →  获取世界坐标 (Vector2)
         ↓
PlayerServer.setPlayerPosition()  →  调用设置函数
         ↓
player_scene.global_position = position  →  玩家移动到指定位置
```

---

## 为什么使用 CreatePosition 而非硬编码？

| 方式 | 优点 | 缺点 |
|------|------|------|
| `CreatePosition` 节点 | 可视化编辑、易于调整、支持多出生点、符合项目规范 | 需要额外节点 |
| 硬编码 `Vector2(400, 300)` | 简单直接 | 不直观、难以调整位置、偏离项目规范 |

---

## 实际应用示例

### SnowWorld 地图

**场景结构：** `game/map/SnowWorld/SnowWorld.tscn`

```tscn
[node name="CreatePosition" type="Node2D" parent="."]
position = Vector2(-374, 135)
```

**初始化代码：** `game/map/SnowWorld/SnowWorld.gd`

```gdscript
func _ready() -> void:
    $MonsterBuilder.land = land
    $MonsterBuilder.monsterRoot = $MonsterRoot
    $CanvasLayer.onMonsterJoin.connect(onMonsterJoin)
    PlayerServer.addPlayerToScene($PlayerRoot)
    PlayerServer.setPlayerPosition($CreatePosition.global_position)  # ← 使用 CreatePosition
    Utils.gameStart()
```

### Moon 地图

**场景结构：** `game/map/Moon/Moon.tscn`

```tscn
[node name="CreatePosition" type="Node2D" parent="."]
position = Vector2(172, 93)
```

**初始化代码：** `game/map/Moon/Moon.gd`

```gdscript
func _ready() -> void:
    PlayerServer.addPlayerToScene($TileMap/PlayerRoot)
    PlayerServer.setPlayerPosition($CreatePosition.global_position)  # ← 使用 CreatePosition
    Utils.gameStart()
```

---

## GYM 场景应用

GYM 场景应遵循原项目规范，使用 `CreatePosition` 节点：

1. **添加节点：** 在场景中创建 `CreatePosition` Node2D 节点
2. **设置位置：** 在编辑器中调整 `position` 属性
3. **调用函数：** 在 Starter 中使用 `$CreatePosition.global_position`

```gdscript
# GYM Starter 示例
func _enter_tree():
    PlayerServer.addPlayerToScene($PlayerRoot)
    PlayerServer.setPlayerPosition($CreatePosition.global_position)
```

---

## 相关文件

- `autoload/server/PlayerServer.gd` - PlayerServer 单例
- `game/map/SnowWorld/SnowWorld.tscn` - SnowWorld 地图场景
- `game/map/SnowWorld/SnowWorld.gd` - SnowWorld 初始化脚本
- `game/map/Moon/Moon.tscn` - Moon 地图场景
- `game/map/Moon/Moon.gd` - Moon 初始化脚本

---

## 扩展用法

### 多出生点支持

可创建多个 CreatePosition 节点，根据条件选择：

```gdscript
func _ready():
    PlayerServer.addPlayerToScene($PlayerRoot)
    
    # 根据条件选择不同出生点
    if some_condition:
        PlayerServer.setPlayerPosition($CreatePosition1.global_position)
    else:
        PlayerServer.setPlayerPosition($CreatePosition2.global_position)
```

### 动态生成出生点

在运行时动态创建出生点位置：

```gdscript
var spawn_points = [$CreatePosition1, $CreatePosition2, $CreatePosition3]
var random_spawn = spawn_points[randi() % spawn_points.size()]
PlayerServer.setPlayerPosition(random_spawn.global_position)
```