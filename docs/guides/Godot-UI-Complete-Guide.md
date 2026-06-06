# Godot UI 完整学习指南

---

## 一、Godot UI 基础知识

### 1.1 UI 核心概念

#### 什么是 UI？
UI（用户界面）是玩家与游戏交互的桥梁，包括按钮、菜单、进度条、提示信息等。

#### Godot UI 节点层级
```
CanvasLayer (画布层，始终显示在最上层)
└── Control (控制节点，基础UI容器)
    ├── Panel (面板，带背景的容器)
    ├── Label (文本标签)
    ├── Button (按钮)
    ├── ProgressBar (进度条)
    ├── VBoxContainer (垂直布局容器)
    ├── HBoxContainer (水平布局容器)
    └── TextureRect (纹理显示)
```

### 1.2 核心 UI 节点类型

| 节点类型 | 功能 | 常用属性 |
|---------|------|----------|
| **CanvasLayer** | 画布层，独立于相机 | `layer` - 层级 |
| **Control** | 基础控制节点 | `anchors_preset` - 锚点预设 |
| **Panel** | 带背景的面板 | `self_modulate` - 透明度 |
| **Label** | 文本显示 | `text`, `font_size`, `theme_override_colors/font_color` |
| **Button** | 可点击按钮 | `text`, `toggle_mode` |
| **ProgressBar** | 进度条 | `value`, `max_value` |
| **VBoxContainer** | 垂直布局 | `separation` - 间距 |
| **HBoxContainer** | 水平布局 | `separation` - 间距 |
| **TextureRect** | 纹理显示 | `texture`, `scale` |

### 1.3 信号系统

信号是 Godot UI 的核心通信机制：

```gdscript
# 连接信号的三种方式

# 方式1: 编辑器中连接（推荐）
# 在节点面板 → 信号标签 → 双击信号 → 选择目标节点

# 方式2: 代码连接
button.pressed.connect(_on_button_click)

# 方式3: 匿名函数
button.pressed.connect(func():
    print("Button clicked!")
)
```

### 1.4 Tween 动画系统

Tween 用于创建平滑的动画效果：

```gdscript
# 创建基础动画
var tween = create_tween()
tween.tween_property(node, "position", Vector2(100, 100), 0.5)
tween.tween_property(node, "scale", Vector2(1.5, 1.5), 0.3)

# 并行动画
tween.set_parallel(true)
tween.tween_property(node, "position:y", 100, 0.3)
tween.tween_property(node, "modulate:a", 0, 0.3)

# 链式动画（默认）
tween.tween_property(node, "scale", Vector2.ZERO, 0.2)
tween.tween_callback(node.queue_free)  # 动画结束后执行
```

---

## 二、项目 UI 架构分析

### 2.1 整体架构

本项目采用**信号驱动架构**，实现数据与视图分离：

```
┌─────────────────────────────────────────────────────────────┐
│                    数据层 (Autoload)                        │
│  PlayerData.gd ──发出信号──▶ UI层响应                        │
│  Utils.gd      ──工具函数──▶ UI控制                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   UI控制层 (CanvasLayer)                    │
│  ControlUI.tscn                                            │
│  ├── Crosshair (准星)                                       │
│  ├── GameUI (游戏内UI)                                      │
│  │   ├── hpUI (血量、金币、等级)                             │
│  │   ├── Container (弹药显示)                                │
│  │   ├── HBoxContainer (武器列表)                            │
│  │   └── WeaponChangeUI (武器切换动画)                       │
│  └── MainUI (主菜单)                                        │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 核心组件分析

#### 2.2.1 ControlUI - UI 主控制器

**文件位置：** [ui/ControlUI.gd](file:///d:/projects/TowDownGame/ui/ControlUI.gd)

**核心职责：**
- 作为所有 UI 的根容器
- 提供全局 UI 控制接口（Toast、准星显示）
- 注册到 `Utils.canvasLayer` 供全局访问

**关键代码解析：**

```gdscript
extends CanvasLayer

@onready var toast = $Control/Label
@onready var toast_ui = $Control

func _ready() -> void:
    Utils.canvasLayer = self  # 注册到全局工具类

func showToast(msg, time):
    timer.stop()
    timer.start(time)
    toast_ui.visible = true
    create_tween().tween_property(toast_ui, "modulate:a", 1, 0.1).from(0)
    toast.text = tr(msg)
```

**设计模式：** 单例注册模式，通过 `Utils.canvasLayer` 实现全局访问。

#### 2.2.2 GameUI - 游戏内 UI

**文件位置：** [ui/GameUI.gd](file:///d:/projects/TowDownGame/ui/GameUI.gd)

**核心职责：**
- 显示血量、金币、等级
- 显示弹药和武器列表
- 处理武器切换动画

**信号监听模式：**

```gdscript
func _ready() -> void:
    # 数据变化时自动更新 UI
    PlayerData.onHpChange.connect(_on_hp_change_internal)
    PlayerData.onGoldChange.connect(onGoldChange)
    PlayerData.onAmmoChange.connect(onAmmoChange)
    PlayerData.onPlayerLevelChange.connect(onPlayerLevelChange)
    PlayerData.onWeaponChangeAnim.connect(onWeaponChangeAnim)
```

**武器切换动画实现：**

```gdscript
func onWeaponChangeAnim(weapon_id, tag = Utils.GUN_CHANGE_TYPE.CHANGE):
    if tag == Utils.GUN_CHANGE_TYPE.CHANGE:
        change_audio.play()
        var weapon: BaseGun = PlayerData.player_weapon_list[weapon_id]
        weapon_change_name.text = weapon.weapon_name
        weapon_change_image.texture = weapon.image
        
        # 淡入淡出动画
        var tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
        tween.tween_property(weapon_change_image, "modulate:a", 1.0, 0.3).from(0.0)
        tween.tween_property(weapon_change_image, "modulate:a", 0.0, 0.3).from(1.0).set_delay(0.5)
```

#### 2.2.3 Crosshair - 准星组件

**文件位置：** [ui/widgets/Crosshair.gd](file:///d:/projects/TowDownGame/ui/widgets/Crosshair.gd)

**核心职责：**
- 跟随鼠标移动
- 根据武器属性显示漂移和散布效果
- 游戏开始时隐藏系统鼠标

**关键特性：**

```gdscript
func onGameStart():
    set_process(true)
    Input.mouse_mode = Input.MOUSE_MODE_HIDDEN  # 隐藏系统鼠标

func _process(delta: float) -> void:
    var mouse_pos = get_global_mouse_position()
    global_position = mouse_pos - pivot_offset * scale  # 跟随鼠标
```

#### 2.2.4 HitLabel - 伤害数字

**文件位置：** [ui/widgets/HitLabel.gd](file:///d:/projects/TowDownGame/ui/widgets/HitLabel.gd)

**核心职责：**
- 显示伤害数字
- 自动上浮消失动画

**生命周期管理：**

```gdscript
func _ready() -> void:
    var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector2(1,1), 0.2).from(Vector2.ZERO)  # 缩放出现
    tween.tween_property(self, "position:y", position.y - 50, 0.5)  # 向上移动
    tween.tween_property(self, "scale", Vector2.ZERO, 0.2).set_delay(0.7)  # 缩小消失
    tween.tween_callback(self.queue_free).set_delay(1)  # 自动销毁
```

#### 2.2.5 InfoPanel - 信息面板

**文件位置：** [ui/widgets/InfoPanel.gd](file:///d:/projects/TowDownGame/ui/widgets/InfoPanel.gd)

**核心职责：**
- 显示教程和提示信息
- 支持按键切换显示/隐藏
- 可配置的标题和内容

**@export 属性使用：**

```gdscript
@export var title: String = "":
    set(value):
        title = value
        if _title_label:
            _title_label.text = value

@export_multiline var content: String = "":
    set(value):
        content = value
        if _content_label:
            _content_label.text = value

@export var toggle_key: Key = KEY_H  # 可配置切换按键
```

---

## 三、UI 操作指南

### 3.1 创建 UI 组件步骤

#### 步骤 1：创建场景

```
1. 右键 → 新建场景 → 选择根节点类型（Control 或 CanvasLayer）
2. 添加子节点：Panel → VBoxContainer → Label/Button
3. 保存场景（建议与脚本同名）
```

#### 步骤 2：编写脚本

```gdscript
extends Control

@onready var _button: Button = $Panel/VBoxContainer/Button
@onready var _label: Label = $Panel/VBoxContainer/Label

func _ready() -> void:
    # 初始化逻辑
    _label.text = "Hello UI"

func _on_button_pressed() -> void:
    # 按钮点击回调
    _label.text = "Button clicked!"
```

#### 步骤 3：连接信号

```
1. 选中 Button 节点
2. 右侧面板 → 节点 → 信号
3. 双击 pressed() 信号
4. 连接到根节点，方法名自动生成为 _on_button_pressed
5. 点击"连接"
```

### 3.2 常用布局技巧

#### 锚点预设

```gdscript
# 居中显示
anchors_preset = Control.PRESET_CENTER

# 左上角
anchors_preset = Control.PRESET_TOP_LEFT

# 右下角
anchors_preset = Control.PRESET_BOTTOM_RIGHT
```

#### 容器布局

```gdscript
# 设置垂直容器间距
$VBoxContainer.add_theme_constant_override("separation", 10)

# 设置水平容器对齐
$HBoxContainer.alignment = HBoxContainer.ALIGNMENT_CENTER
```

### 3.3 动态创建 UI

```gdscript
# 预加载组件
const WeaponItemPre = preload("res://ui/widgets/WeaponListItem.tscn")

# 动态实例化
var item = WeaponItemPre.instantiate()
item.name = str(weapon_id)
item.local_id = weapon_id
weapon_list.add_child(item)
```

---

## 四、练习项目

### 练习 1：简单计数器 UI

**目标：** 创建一个点击按钮增加计数的 UI 组件

**场景结构：**
```
CounterUI (Control)
└── VBoxContainer (VBoxContainer, separation=10)
    ├── TitleLabel (Label, text="Counter Demo")
    ├── ClickButton (Button, text="Click Me")
    └── CountLabel (Label, text="Count: 0")
```

**脚本实现：**

```gdscript
extends Control

var _count: int = 0

@onready var _button: Button = $VBoxContainer/ClickButton
@onready var _label: Label = $VBoxContainer/CountLabel

func _ready() -> void:
    anchors_preset = Control.PRESET_CENTER
    _update_display()

func _on_button_pressed() -> void:
    _count += 1
    _update_display()

func _update_display() -> void:
    _label.text = "Count: %d" % _count

func reset_count() -> void:
    _count = 0
    _update_display()
```

**扩展任务：**
1. 添加重置按钮
2. 使用 Tween 添加数字变化动画
3. 添加颜色变化（计数超过 10 变红）

---

### 练习 2：血量条带颜色渐变

**目标：** 创建一个根据血量百分比变色的进度条

**场景结构：**
```
HealthBarUI (Control)
└── VBoxContainer
    ├── Label (text="HP")
    └── ProgressBar (name=HPBar)
```

**脚本实现：**

```gdscript
extends Control

@onready var _hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var _label: Label = $VBoxContainer/Label

func _ready() -> void:
    _hp_bar.max_value = 100
    _hp_bar.value = 100

func update_hp(hp: int, max_hp: int) -> void:
    var percent = hp / max_hp
    _hp_bar.value = hp
    _hp_bar.max_value = max_hp
    
    # 根据百分比设置颜色
    if percent > 0.5:
        _hp_bar.modulate = Color(0, 1, 0)  # 绿色
    elif percent > 0.25:
        _hp_bar.modulate = Color(1, 1, 0)  # 黄色
    else:
        _hp_bar.modulate = Color(1, 0, 0)  # 红色
    
    _label.text = "HP: %d/%d" % [hp, max_hp]
```

---

### 练习 3：伤害数字系统

**目标：** 创建一个显示伤害数字的系统

**场景结构：**
```
HitLabelSystem (CanvasLayer)
└── Label (name=HitLabel, visible=false)
```

**脚本实现：**

```gdscript
extends CanvasLayer

const HitLabelPre = preload("res://ui/widgets/HitLabel.tscn")

func show_hit_label(position: Vector2, damage: int, is_critical: bool = false) -> void:
    var label = HitLabelPre.instantiate()
    add_child(label)
    label.global_position = position
    label.setNumber(damage)
    
    # 暴击显示红色
    if is_critical:
        label.setColor(Color(1, 0, 0))
    else:
        label.setColor(Color(1, 1, 1))
```

---

### 练习 4：背包系统 UI

**目标：** 创建一个简单的背包显示系统

**场景结构：**
```
InventoryUI (Control)
├── Panel
│   └── GridContainer (name=ItemGrid, columns=4)
└── Button (name=CloseButton, text="Close")
```

**脚本实现：**

```gdscript
extends Control

@onready var _grid: GridContainer = $Panel/ItemGrid
@onready var _close_button: Button = $CloseButton

var _items: Array = []

func _ready() -> void:
    visible = false

func open(items: Array) -> void:
    _items = items
    _update_grid()
    visible = true

func close() -> void:
    visible = false

func _update_grid() -> void:
    # 清空现有物品
    for child in _grid.get_children():
        child.free()
    
    # 添加物品图标
    for item in _items:
        var item_node = TextureRect.new()
        item_node.texture = item.icon
        item_node.custom_minimum_size = Vector2(64, 64)
        _grid.add_child(item_node)

func _on_close_button_pressed() -> void:
    close()
```

---

## 五、项目实战指导

### 5.1 在 GYM 场景中添加 UI

**方法：** 在 Starter 脚本中添加 UI 初始化

```gdscript
# GYM_XX_Starter.gd
const ControlUIPre = preload("res://ui/ControlUI.tscn")

func _ready():
    # 添加游戏UI
    _setup_ui()

func _setup_ui():
    var control_ui = ControlUIPre.instantiate()
    add_child(control_ui)
    
    # 显示游戏内UI，隐藏主菜单
    control_ui.get_node("GameUI").show()
    control_ui.get_node("MainUI").hide()
```

### 5.2 自定义 UI 组件模板

```gdscript
extends Control

# ===== 导出属性 =====
@export var title: String = "Title":
    set(value):
        title = value
        if _title_label:
            _title_label.text = value

# ===== 节点引用 =====
@onready var _title_label: Label = $Panel/VBox/Title

# ===== 生命周期 =====
func _ready() -> void:
    # 初始化逻辑
    pass

func _exit_tree() -> void:
    # 清理逻辑
    pass

# ===== 公共接口 =====
func set_title(text: String) -> void:
    title = text

# ===== 信号回调 =====
func _on_button_pressed() -> void:
    # 按钮点击处理
    pass
```

### 5.3 最佳实践总结

| 原则 | 说明 |
|-----|------|
| **信号驱动** | 通过 PlayerData 信号更新 UI，避免直接调用 |
| **@onready** | 使用延迟初始化获取节点引用 |
| **资源预加载** | 使用 `preload()` 缓存场景资源 |
| **自动清理** | 使用 `queue_free()` 自动销毁临时节点 |
| **Tween 动画** | 使用 Tween 替代 `_process` 实现平滑动画 |
| **主题覆盖** | 使用 `add_theme_constant_override` 修改样式 |

---

## 六、参考文件索引

| 组件 | 文件路径 | 学习要点 |
|------|----------|----------|
| UI 主控制器 | [ui/ControlUI.gd](file:///d:/projects/TowDownGame/ui/ControlUI.gd) | Toast 提示、全局注册 |
| 游戏内 UI | [ui/GameUI.gd](file:///d:/projects/TowDownGame/ui/GameUI.gd) | 信号监听、武器切换 |
| 准星 | [ui/widgets/Crosshair.gd](file:///d:/projects/TowDownGame/ui/widgets/Crosshair.gd) | 鼠标跟随、武器状态显示 |
| 伤害数字 | [ui/widgets/HitLabel.gd](file:///d:/projects/TowDownGame/ui/widgets/HitLabel.gd) | Tween 动画、自动销毁 |
| 信息面板 | [ui/widgets/InfoPanel.gd](file:///d:/projects/TowDownGame/ui/widgets/InfoPanel.gd) | @export 属性、按键切换 |
| 数据层 | [autoload/PlayerData.gd](file:///d:/projects/TowDownGame/autoload/PlayerData.gd) | 信号定义、数据管理 |
| 工具类 | [autoload/Utils.gd](file:///d:/projects/TowDownGame/autoload/Utils.gd) | 全局 UI 访问 |

---

## 七、进阶学习路径

1. **基础组件** → 完成练习 1-2
2. **动画系统** → 完成练习 3，学习 Tween 高级用法
3. **数据绑定** → 理解 PlayerData 信号机制
4. **复杂布局** → 研究 ShopPanel、Inventory 等复杂 UI
5. **自定义主题** → 修改 theme.tres 自定义样式
6. **响应式设计** → 学习 Anchor 和 Margin 系统