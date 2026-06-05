# Godot 核心概念学习指南

## 目录

1. [Scene（场景）](#1-scene场景)
2. [Node（节点）](#2-node节点)
3. [Signal（信号）](#3-signal信号)
4. [实战演练](#4-实战演练)
5. [代码示例](#5-代码示例)
6. [练习作业](#6-练习作业)

---

## 1. Scene（场景）

### 什么是 Scene？

**Scene（场景）** 是 Godot 中的核心组织单位，可以理解为：
- 一个独立的"关卡"
- 一个可复用的"组件"
- 一个游戏中的"界面"

每个 Scene 都是一个完整的节点树，可以单独保存、测试和复用。

### Scene 的特点

| 特点 | 说明 |
|------|------|
| **可嵌套** | 一个场景可以作为节点被其他场景引用（实例化） |
| **可保存** | 场景保存为 `.tscn` 文本文件 |
| **独立运行** | 每个场景有自己的脚本和逻辑 |
| **可实例化** | 通过代码动态创建场景实例 |

### 项目结构示例

```
learning/
├── Player.tscn       # 玩家角色场景
├── Target.tscn       # 目标对象场景
└── MainLearning.tscn # 主场景（实例化了 Player 和 Target）
```

### 实例化场景

在 Godot 编辑器中：
1. 右键点击场景树 → "Instance Child Scene"（实例化子场景）
2. 选择要实例化的 `.tscn` 文件

通过代码实例化：
```gdscript
var player_scene = preload("res://learning/Player.tscn")
var player = player_scene.instantiate()
add_child(player)
```

---

## 2. Node（节点）

### 什么是 Node？

**Node（节点）** 是构成场景的基本元素，是场景树（Scene Tree）中的每个对象。

### 常用节点类型

#### 2D 节点

| 节点类型 | 功能 | 使用场景 |
|---------|------|---------|
| `Node2D` | 2D 变换节点 | 2D 游戏根节点 |
| `CharacterBody2D` | 可控制角色物理体 | 玩家、敌人 |
| `StaticBody2D` | 静态物理体 | 地面、墙壁 |
| `RigidBody2D` | 物理模拟刚体 | 抛射物、箱子 |
| `Area2D` | 区域检测 | 触发器、拾取区 |
| `Sprite2D` | 显示 2D 图像 | 角色、道具 |
| `CollisionShape2D` | 碰撞形状 | 定义碰撞区域 |
| `Label` | 显示文本 | UI 文字 |
| `Button` | 可点击按钮 | 菜单按钮 |

#### 3D 节点

| 节点类型 | 功能 | 使用场景 |
|---------|------|---------|
| `Node3D` | 3D 变换节点 | 3D 游戏根节点 |
| `CharacterBody3D` | 3D 可控制角色 | 3D 玩家 |
| `StaticBody3D` | 3D 静态物理体 | 建筑、地形 |
| `MeshInstance3D` | 显示 3D 模型 | 角色模型 |
| `CollisionShape3D` | 3D 碰撞形状 | 碰撞区域 |

### 节点层级关系

```
MainLearning (Node2D)
├── Background (ColorRect)
├── Player (CharacterBody2D)     ← 实例化的子场景
│   ├── Sprite2D
│   └── CollisionShape2D
├── Target (Node2D)               ← 实例化的子场景
│   └── ColorRect
├── Ground (StaticBody2D)
│   ├── CollisionShape2D
│   └── ColorRect
└── Label (Label)
```

### 访问节点

```gdscript
# 通过路径访问（$ 符号）
@onready var player = $Player
@onready var sprite = $Player/Sprite2D
@onready var label = $Label

# 通过 get_node 方法
var player = get_node("Player")
var collision = get_node("Player/CollisionShape2D")
```

### 节点生命周期

| 回调函数 | 调用时机 |
|---------|---------|
| `_ready()` | 节点首次进入场景树时调用 |
| `_process(delta)` | 每帧调用（游戏循环） |
| `_physics_process(delta)` | 每物理帧调用（固定时间步） |
| `_input(event)` | 处理输入事件 |
| `_exit_tree()` | 节点即将从场景树移除时调用 |

---

## 3. Signal（信号）

### 什么是 Signal？

**Signal（信号）** 是 Godot 中的事件通知机制，用于实现节点间的解耦通信。

### 信号的工作原理

```
[发出者] emit_signal("信号名", 参数...) 
    ↓
[信号传播]
    ↓
[接收者] 回调函数被执行
```

### 定义信号

```gdscript
extends Node

# 定义无参数信号
signal my_signal

# 定义带参数信号
signal player_jumped(height: float)
signal player_moved(direction: Vector2)
signal item_collected(item_name: String, count: int)
```

### 发出信号

```gdscript
extends CharacterBody2D

signal player_jumped(height: float)

func _physics_process(delta: float):
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_force
        # 发出信号并传递参数
        emit_signal("player_jumped", abs(jump_force))
```

### 连接信号

#### 方式一：编辑器中连接

1. 选中发出信号的节点
2. 切换到 "Node" 标签
3. 双击要连接的信号
4. 选择接收者节点和方法

#### 方式二：代码中连接

```gdscript
extends Node2D

@onready var player = $Player
@onready var target = $Target

func _ready():
    # 连接到自身的方法
    player.connect("player_jumped", Callable(self, "_on_player_jumped"))
    
    # 直接连接到其他节点的方法（参数自动传递）
    player.connect("player_clicked", Callable(target, "activate"))
    
    # 连接到匿名函数（Lambda）
    player.connect("player_moved", func(dir): print("Moved: ", dir))

func _on_player_jumped(height: float):
    print("Player jumped with height: ", height)
```

### 内置信号

Godot 内置了许多常用信号：

| 节点 | 信号 | 说明 |
|-----|------|------|
| `Button` | `pressed()` | 按钮被点击 |
| `Button` | `toggled(toggled_on)` | 按钮切换状态 |
| `Area2D/3D` | `body_entered(body)` | 物体进入区域 |
| `Area2D/3D` | `body_exited(body)` | 物体离开区域 |
| `CharacterBody2D/3D` | `body_entered(body)` | 碰撞发生 |
| `Timer` | `timeout()` | 计时器结束 |
| `Tween` | `tween_completed(object, key)` | 动画完成 |

### 信号的优缺点

| 优点 | 缺点 |
|------|------|
| 解耦：发出者和接收者不直接依赖 | 调试困难：信号传递链路不直观 |
| 灵活：一个信号可连接多个接收者 | 可能导致意外的副作用 |
| 可动态连接/断开 | 需要良好的命名规范 |

---

## 4. 实战演练

### 场景说明

我们创建了一个学习场景来演示 Scene、Node、Signal 的关系：

```
learning/
├── Player.tscn       # 玩家角色
├── Target.tscn       # 可交互目标
└── MainLearning.tscn # 主场景（信号连接中心）
```

### 运行场景

1. 打开 Godot 编辑器
2. 点击 "Import" 导入 `learning/MainLearning.tscn`
3. 点击 F5 或 "Play" 运行场景

### 操作说明

| 操作 | 按键 | 效果 |
|------|------|------|
| 移动 | WASD / 方向键 | 控制玩家移动 |
| 跳跃 | Space | 玩家跳跃，触发 `player_jumped` 信号 |
| 激活目标 | 鼠标左键 | 激活目标，触发 `player_clicked` 信号 |

---

## 5. 代码示例

### 5.1 Player.tscn - 玩家角色脚本

```gdscript
extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_force: float = -500.0
@export var gravity: float = 1200.0

# ========== 信号定义 ==========
signal player_jumped(height: float)      # 跳跃信号
signal player_moved(direction: Vector2)  # 移动信号
signal player_clicked()                   # 点击信号

# ========== 生命周期 ==========
func _physics_process(delta: float):
    # 获取输入方向
    var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
    
    # 处理水平移动
    if input_dir != Vector2.ZERO:
        velocity.x = input_dir.x * speed
        emit_signal("player_moved", input_dir)
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
    
    # 处理重力
    if not is_on_floor():
        velocity.y += gravity * delta
    
    # 处理跳跃
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_force
        emit_signal("player_jumped", abs(jump_force))
        emit_signal("player_clicked")
    
    # 应用物理移动
    set_velocity(velocity)
    move_and_slide()

# ========== 输入处理 ==========
func _input(event: InputEvent):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            emit_signal("player_clicked")
```

### 5.2 Target.tscn - 目标对象脚本

```gdscript
extends Node2D

@export var color_normal: Color = Color(1.0, 0.3, 0.3)    # 正常颜色
@export var color_active: Color = Color(0.3, 1.0, 0.3)   # 激活颜色

var is_active: bool = false

# ========== 信号定义 ==========
signal target_activated()    # 被激活信号
signal target_deactivated()  # 被停用信号

func _ready():
    update_color()

func activate():
    """激活目标"""
    is_active = true
    update_color()
    emit_signal("target_activated")
    print("Target activated!")

func deactivate():
    """停用目标"""
    is_active = false
    update_color()
    emit_signal("target_deactivated")
    print("Target deactivated!")

func update_color():
    """更新显示颜色"""
    $ColorRect.color = color_active if is_active else color_normal
```

### 5.3 MainLearning.tscn - 主场景脚本

```gdscript
extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var target: Node2D = $Target
@onready var label: Label = $Label

var jump_count: int = 0   # 跳跃次数
var move_count: int = 0   # 移动次数

# ========== 信号连接 ==========
func _ready():
    # 连接玩家的信号到自身方法
    player.connect("player_jumped", Callable(self, "_on_player_jumped"))
    player.connect("player_moved", Callable(self, "_on_player_moved"))
    
    # 连接玩家信号到目标方法（直接调用）
    player.connect("player_clicked", Callable(target, "activate"))
    
    # 连接目标的信号到自身方法
    target.connect("target_activated", Callable(self, "_on_target_activated"))
    target.connect("target_deactivated", Callable(self, "_on_target_deactivated"))
    
    label.text = "Jump: 0 | Move: 0"

# ========== 回调函数 ==========
func _on_player_jumped(height: float):
    """处理玩家跳跃"""
    jump_count += 1
    update_label()
    print("Player jumped! Height: %s" % height)

func _on_player_moved(direction: Vector2):
    """处理玩家移动"""
    move_count += 1
    update_label()

func _on_target_activated():
    """处理目标激活"""
    label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
    print("Main: Target activated!")
    
    # 2秒后自动停用目标
    await get_tree().create_timer(2.0).timeout
    target.deactivate()

func _on_target_deactivated():
    """处理目标停用"""
    label.add_theme_color_override("font_color", Color.WHITE)
    print("Main: Target deactivated!")

func update_label():
    """更新显示标签"""
    label.text = "Jump: %s | Move: %s" % [jump_count, move_count]
```

### 5.4 信号通信流程图

```
┌─────────────┐
│   Player    │
│ (Character) │
└──────┬──────┘
       │
       ├────────── emit_signal("player_jumped", height)
       │                         │
       │                         ▼
       │                 ┌───────────────┐
       ├────────────────►│ MainLearning  │
       │                 │  _on_player   │
       │                 │  _jumped()    │──► 更新跳跃计数
       │                 └───────────────┘
       │
       ├────────── emit_signal("player_clicked")
       │                    │
       │                    ▼
       ├──────────► ┌─────────────┐
       │            │   Target    │
       │            │  activate() │──► emit_signal("target_activated")
       │            └─────────────┘
       │                    │
       │                    ▼
       └──────────► ┌───────────────┐
                    │ MainLearning   │
                    │ _on_target     │
                    │ _activated()   │──► 改变标签颜色
                    └───────────────┘
```

---

## 6. 练习作业

### 练习 1：修改玩家属性

在 `Player.tscn` 中：
1. 找到脚本的 `@export` 变量
2. 修改 `speed` 为 500.0
3. 修改 `jump_force` 为 -800.0
4. 重新运行，观察变化

### 练习 2：添加新信号

在 `Player.tscn` 中添加一个新信号：
```gdscript
signal player_landed()  # 落地信号
```

在落地时发出：
```gdscript
if is_on_floor() and velocity.y >= 0:
    emit_signal("player_landed")
```

### 练习 3：连接新信号

在 `MainLearning.tscn` 中连接新信号：
```gdscript
player.connect("player_landed", Callable(self, "_on_player_landed"))

func _on_player_landed():
    print("Player landed!")
```

### 练习 4：创建新节点

1. 在 `MainLearning.tscn` 中添加一个新的 `Label` 节点
2. 命名为 "ScoreLabel"
3. 在脚本中引用并更新分数显示

### 练习 5：实例化新场景

1. 创建一个新的敌人场景 `Enemy.tscn`
2. 在 `MainLearning.tscn` 中实例化多个敌人
3. 让玩家碰撞敌人时触发事件

---

## 附录：GDScript 快速参考

### 常用语法

```gdscript
# 变量声明
var name = "value"
var number: int = 42
var position: Vector2 = Vector2(100, 200)

# 函数定义
func my_function(param: int) -> void:
    pass

# 条件判断
if condition:
    pass
elif other_condition:
    pass
else:
    pass

# 循环
for i in range(10):
    print(i)

while condition:
    pass

# 数组和字典
var array = [1, 2, 3]
var dict = {"key": "value"}

# 类型注解 (Godot 4.x)
@export var speed: float = 300.0
@onready var sprite: Sprite2D = $Sprite2D
```

### 常用内置类

| 类名 | 说明 | 示例 |
|-----|------|------|
| `Vector2` | 2D 向量 | `Vector2(100, 200)` |
| `Vector3` | 3D 向量 | `Vector3(1, 2, 3)` |
| `Color` | 颜色 | `Color(1.0, 0.5, 0.0)` |
| `Input` | 输入管理 | `Input.is_action_pressed("ui_left")` |
| `get_tree()` | 场景树 | `get_tree().change_scene_to_file("...")` |
| `get_node()` | 获取节点 | `get_node("Sprite2D")` |

---

## 下一步学习

- 物理系统：刚体、碰撞检测
- 动画系统：AnimationPlayer、骨骼动画
- UI 系统：Control 节点、Container
- 资源管理：preload、load、Resource
- 信号总线：实现模块间通信
- 持久化：保存/读取游戏数据

---

**文档版本**: 1.0
**创建日期**: 2026-06-04
**适用版本**: Godot 4.x
