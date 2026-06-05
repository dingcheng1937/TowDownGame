# UI系统设计文档

## 概述

TowDownGame的UI系统采用**信号驱动架构**，数据与视图分离。所有UI更新都通过 `PlayerData` 发出的信号触发，实现了松耦合的设计。

---

## 架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        游戏场景层                                │
│  SnowWorld.tscn / GYM_XX.tscn                                   │
└───────────────────────────┬─────────────────────────────────────┘
                            │ 实例化
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      UI控制层 (CanvasLayer)                      │
│  ControlUI.tscn                                                 │
│  ├── Crosshair (准星)                                           │
│  ├── GameUI (游戏内UI)                                          │
│  │   ├── hpUI (血量、金币、等级)                                 │
│  │   ├── Container (弹药显示)                                    │
│  │   ├── HBoxContainer (武器列表)                                │
│  │   └── WeaponChangeUI (武器切换动画)                           │
│  ├── MainUI (主菜单)                                             │
│  └── Control (Toast提示)                                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │ 监听信号
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      数据层 (Autoload)                          │
│  PlayerData.gd ←→ Utils.gd                                      │
│  └── 发出信号驱动UI更新                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 核心组件

### 1. 准星 (Crosshair)

**文件位置：** [ui/widgets/Crosshair.tscn](../ui/widgets/Crosshair.tscn)

**功能：**
- 跟随鼠标移动
- 持续旋转动画
- 游戏开始时自动显示

**实现原理：**

```gdscript
# Crosshair.gd
func _ready() -> void:
    set_process(false)
    Utils.onGameStart.connect(onGameStart)  # 监听游戏启动信号

func onGameStart():
    set_process(true)
    Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN  # 隐藏系统鼠标

func _process(delta: float) -> void:
    rotation += rotation_speed * delta  # 持续旋转
    global_position = get_global_mouse_position() - size / 2  # 跟随鼠标
```

**动画系统：**
- 使用 `AnimationPlayer` 组件
- `idle` 动画：scale 从 1.0 → 0.8 的呼吸效果
- 自动播放，循环模式

**显示/隐藏控制：**
```gdscript
# Utils.gd
func crosshairChange(is_change):
    canvasLayer.crosshairChange(is_change)

# ControlUI.gd
func crosshairChange(is_show):
    $TextureRect.visible = is_show
```

---

### 2. 弹药显示系统

**文件位置：** [ui/ControlUI.tscn](../ui/ControlUI.tscn) 中的 `Container` 节点

**组成部分：**

| 节点路径 | 功能 | 更新信号 |
|---------|------|---------|
| `Container/BulletHbox` | 弹夹子弹图标容器 | `onWeaponBulletsChange` |
| `Container/Label` | 当前弹夹子弹数 | `onWeaponChangeAnim` |
| `Container/all_ammo` | 备用弹药总数 | `onAmmoChange` |

**弹夹子弹图标 (BulletCountItem)：**

**文件位置：** [ui/widgets/BulletCountItem.tscn](../ui/widgets/BulletCountItem.tscn)

每个子弹图标代表弹夹中的一发子弹。射击时图标会"掉落"消失。

```gdscript
# GameUI.gd - 加载子弹图标
func loadWeaponBullets(weapon_id):
    # 清空旧图标
    for item in weapon_bullet_list.get_children():
        item.free()
    
    var weapon: BaseGun = PlayerData.player_weapon_list[weapon_id]
    var local_count = weapon.bullets_max_count - weapon.bullets_count
    
    # 为每发子弹创建图标
    for item in weapon.bullets_count:
        var ins = weapon_bullet_pre.instantiate()
        weapon_bullet_list.add_child(ins)
```

**子弹消耗动画：**
```gdscript
# BulletCountItem.gd
func destory():
    reparent(get_parent().get_parent().get_parent())  # 移到外层
    set_process(true)
    velocity = Vector2(-55, -100)  # 向左上飞出
    
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(0.3, 0.3), 1)  # 缩小
    tween.tween_callback(self.queue_free)  # 删除

func _process(delta):
    velocity.y += GRAVITY * delta * speed  # 重力下落
    rotation += speed * delta  # 旋转
    position += velocity * delta
```

---

### 3. 武器列表UI

**文件位置：** [ui/widgets/WeaponListItem.tscn](../ui/widgets/WeaponListItem.tscn)

**功能：**
- 显示已装备武器的图标
- 快捷键切换 (1-9)
- 当前武器高亮显示

**实现原理：**

```gdscript
# WeaponListItem.gd
func _ready():
    PlayerData.onWeaponChanged.connect(onWeaponChanged)  # 监听武器切换
    var pressed_index = get_index() + 1
    press_label.text = str(pressed_index)  # 显示快捷键数字
    pressed_name = "pressed_%s" % pressed_index  # 对应的输入动作名
    
    var gun: BaseGun = PlayerData.player_weapon_list[local_id]
    image.texture = gun.image  # 显示武器图标

func _input(event):
    # 监听快捷键
    if event.is_action_pressed(pressed_name):
        PlayerData.changeWeapon(local_id)

func onWeaponChanged():
    # 当前武器高亮
    if Utils.player.gun.weapon_id == local_id:
        self_modulate = Color("#83e0ff")  # 高亮蓝色
    else:
        self_modulate = Color.WHITE
```

---

### 4. 武器切换动画

**触发时机：** 切换武器时显示武器名称和图标

```gdscript
# GameUI.gd
func onWeaponChangeAnim(weapon_id, tag = Utils.GUN_CHANGE_TYPE.CHANGE):
    if tag == Utils.GUN_CHANGE_TYPE.CHANGE:
        change_audio.play()  # 播放音效
        
        var weapon: BaseGun = PlayerData.player_weapon_list[weapon_id]
        weapon_change_name.text = weapon.weapon_name
        weapon_change_image.texture = weapon.image
        
        # 淡入淡出动画
        var tween = get_tree().create_tween()
        tween.tween_property(weapon_change_image, "modulate:a", 1.0, 0.3).from(0.0)
        tween.tween_property(weapon_change_image, "modulate:a", 0.0, 0.3).from(1.0).set_delay(0.5)
    
    call_deferred("loadWeaponBullets", weapon_id)  # 更新子弹图标
```

---

### 5. 血量与状态UI

**节点结构：**
```
hpUI/
├── ProgressBar      # 血量条
├── ProgressBar2     # 经验条
├── Label           # 金币数量
├── Label2          # 奖励点数
└── Label3          # 等级显示
```

**信号监听：**
```gdscript
# GameUI.gd
func _ready():
    PlayerData.onHpChange.connect(func hpChange(hp, max_hp):
        hp_bar.max_value = max_hp
        hp_bar.value = hp
    )
    
    PlayerData.onPlayerLevelChange.connect(onPlayerLevelChange)
    PlayerData.onPlayerExpChange.connect(onPlayerExpChange)
    PlayerData.onGoldChange.connect(onGoldChange)
```

---

## 信号驱动机制

### PlayerData 核心信号

| 信号名 | 参数 | 触发时机 |
|-------|------|---------|
| `onGameStart` | - | 游戏开始 |
| `onWeaponChangeAnim` | weapon_id | 切换武器 |
| `onWeaponBulletsChange` | bullet, max_bullet | 射击消耗子弹 |
| `onAmmoChange` | ammo | 备用弹药变化 |
| `onHpChange` | hp, max_hp | 血量变化 |
| `onGoldChange` | gold | 金币变化 |
| `onPlayerLevelChange` | level | 等级提升 |
| `playerWeaponListChange` | - | 获得新武器 |

### Utils 工具函数

```gdscript
# Utils.gd - 全局访问点
var canvasLayer: CanvasLayer  # UI控制层引用

func gameStart():
    is_game_start = true
    emit_signal("onGameStart")

func crosshairChange(is_change):
    canvasLayer.crosshairChange(is_change)

func showToast(msg, time = 1):
    canvasLayer.showToast(msg, time)
```

---

## 场景结构对比

### 完整游戏场景 (SnowWorld)
```
SnowWorld.tscn
├── Hero (玩家)
├── Camera2D
├── ControlUI ← 包含所有UI
│   ├── Crosshair
│   ├── GameUI
│   └── MainUI
└── MonsterBuilder
```

### GYM测试场景 (GYM_02_Weapon)
```
GYM_02_Weapon.tscn
├── Hero (玩家)
├── Camera2D
├── MonstersRoot (测试怪物)
└── InfoPanel (说明面板)
└── ❌ 没有ControlUI → 没有准星和弹药UI
```

---

## 如何在GYM场景添加UI

### 方法1: 添加ControlUI实例

```gdscript
# GYM_XX_Starter.gd
func _ready():
    # ... 现有初始化代码 ...
    
    # 添加完整UI
    var control_ui = preload("res://ui/ControlUI.tscn").instantiate()
    add_child(control_ui)
```

### 方法2: 只添加需要的组件

```gdscript
# 只添加准星
var crosshair = preload("res://ui/widgets/Crosshair.tscn").instantiate()
add_child(crosshair)

# 需要手动触发信号
Utils.onGameStart.emit()
```

---

## GYM场景UI实现

### 已实现UI的GYM场景

| GYM场景 | UI组件 | 状态 |
|---------|--------|------|
| GYM_02_Weapon | ControlUI（准星+弹药+血量） | ✅ 已实现 |
| GYM_11_WeirdLoot | SanityBar + ExtractionStatus + LootInventory | ✅ 已实现 |

### 实现步骤

**1. 场景文件添加UIRoot节点**

在场景根节点下添加 `CanvasLayer` 类型的 `UIRoot` 节点：

```
GYM_XX_Xxx.tscn
├── ...
└── UIRoot (CanvasLayer)  ← 新增
```

**2. Starter脚本添加UI初始化**

```gdscript
# GYM_XX_Starter.gd
const ControlUIPre = preload("res://ui/ControlUI.tscn")

func _ready():
    # ... 其他初始化代码 ...
    
    # 添加游戏UI
    _setup_ui()

func _setup_ui():
    var control_ui = ControlUIPre.instantiate()
    $UIRoot.add_child(control_ui)
    
    # 显示游戏内UI，隐藏主菜单
    control_ui.get_node("GameUI").show()
    control_ui.get_node("MainUI").hide()
```

### GYM_02_Weapon 完整示例

**场景结构：**
```
WeaponDemo (Node2D)
├── PlayerRoot
│   ├── Hero
│   └── Anchor/Camera2D
├── MonstersRoot
├── Background
├── InfoPanel
└── UIRoot (CanvasLayer)  ← 存放UI组件
```

**Starter脚本：** [demo/GYM_02_WeaponStarter.gd](../demo/GYM_02_WeaponStarter.gd)

---

## 最佳实践

### 1. 信号命名规范
- `onXxxChange` - 数据变化信号
- `onXxxAdd/Remove` - 添加/移除信号
- 使用过去式表示已发生的动作

### 2. UI更新原则
- **不要**直接调用UI方法更新
- **应该**通过信号通知，让UI自己响应

```gdscript
# ❌ 错误做法
game_ui.update_ammo(30)

# ✅ 正确做法
PlayerData.set_ammo(30)  # 内部发出 onAmmoChange 信号
```

### 3. 性能优化
- 弹药图标使用对象池（可优化）
- 动画使用 Tween 而不是 _process
- 大量UI更新使用 `call_deferred`

---

## 相关文件索引

| 文件 | 说明 |
|-----|------|
| [ui/ControlUI.tscn](../ui/ControlUI.tscn) | UI主场景 |
| [ui/ControlUI.gd](../ui/ControlUI.gd) | UI控制器 |
| [ui/GameUI.gd](../ui/GameUI.gd) | 游戏内UI逻辑 |
| [ui/widgets/Crosshair.tscn](../ui/widgets/Crosshair.tscn) | 准星组件 |
| [ui/widgets/BulletCountItem.tscn](../ui/widgets/BulletCountItem.tscn) | 子弹图标 |
| [ui/widgets/WeaponListItem.tscn](../ui/widgets/WeaponListItem.tscn) | 武器列表项 |
| [autoload/PlayerData.gd](../autoload/PlayerData.gd) | 数据管理 |
| [autoload/Utils.gd](../autoload/Utils.gd) | 工具函数 |
