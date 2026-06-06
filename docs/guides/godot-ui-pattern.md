# Godot UI 实现模式指南

本文档总结 TowDownGame 项目中 UI 组件的实现模式，供学习和参考。

---

## 核心原则

### 1. 节点引用使用 `@onready`

在 `_ready()` 之前，子节点可能还未初始化。使用 `@onready` 延迟获取引用：

```gdscript
@onready var _button: Button = $VBoxContainer/Button
@onready var _label: Label = $VBoxContainer/Label
```

### 2. 信号回调使用 `_on_<节点>_<信号>` 命名

Godot 场景编辑器中连接信号时，默认生成的回调函数名遵循此命名规范：

```gdscript
# 按钮点击
func _on_button_pressed() -> void:
    pass

# 按钮按下/释放
func _on_button_button_down() -> void:
    pass

func _on_button_button_up() -> void:
    pass
```

### 3. 状态变量使用私有前缀 `_`

```gdscript
var _count: int = 0  # 私有状态变量
```

---

## 基础模式：按钮点击更新Label

### 完整示例

**场景结构：**
```
CounterUI (Control)
└── VBoxContainer (VBoxContainer)
    ├── Button (Button)
    └── CountLabel (Label)
```

**脚本 (CounterUI.gd)：**
```gdscript
extends Control

## 计数器值
var _count: int = 0

## 节点引用
@onready var _button: Button = $VBoxContainer/Button
@onready var _label: Label = $VBoxContainer/CountLabel


func _ready() -> void:
    # 初始化显示
    _update_label()


## 按钮点击回调（需在场景中连接 pressed 信号）
func _on_button_pressed() -> void:
    _count += 1
    _update_label()


## 更新Label显示
func _update_label() -> void:
    _label.text = "Count: %d" % _count
```

### 信号连接方式

在 Godot 编辑器中：
1. 选中 Button 节点
2. 切换到 "节点" 面板 → "信号" 标签
3. 双击 `pressed` 信号
4. 选择目标节点（脚本所在节点）
5. 回调函数名会自动生成为 `_on_button_pressed`

---

## 进阶模式：提供公共接口

项目中的 UI 组件通常提供 `set*()` 方法供外部配置。

### 示例：InfoPanel 模式

**参考文件：** `ui/widgets/InfoPanel.gd`

```gdscript
extends CanvasLayer

## 导出属性，可在检查器中配置
@export var title: String = "":
    set(value):
        title = value
        if _title_label:  # 检查引用是否存在
            _title_label.text = value

@export_multiline var content: String = "":
    set(value):
        content = value
        if _content_label:
            _content_label.text = value

## 节点引用
@onready var _title_label: Label = $Panel/VBox/Title
@onready var _content_label: Label = $Panel/VBox/Content


## 公共方法：设置标题
func set_title(text: String) -> void:
    title = text


## 公共方法：设置内容
func set_content(text: String) -> void:
    content = text
```

**使用方式：**
```gdscript
@onready var _info_panel: InfoPanel = $InfoPanel

func _ready():
    _info_panel.set_title("学习指南")
    _info_panel.set_content("按 H 键隐藏/显示此面板")
```

---

## 回调模式：使用 Callable

对于需要外部传入回调的场景，使用 `Callable` 类型。

### 示例：DeathBoard 模式

**参考文件：** `ui/widgets/DeathBoard.gd`

```gdscript
extends Control

## 回调函数引用
var click: Callable


## 设置点击回调
func set_on_click(callback: Callable) -> void:
    click = callback


## 按钮点击回调
func _on_button_pressed() -> void:
    if click.is_valid():
        click.call(true)  # 调用外部回调
    queue_free()
```

**使用方式：**
```gdscript
func show_death_board():
    var board = DeathBoardPre.instantiate()
    add_child(board)
    board.set_on_click(_on_death_board_response)


func _on_death_board_response(success: bool):
    if success:
        # 复活逻辑
        pass
    else:
        # 不复活
        pass
```

---

## 场景结构模式

### 简单 UI 组件

```
组件名 (Control 或 CanvasLayer)
└── Panel (Panel)
    └── VBoxContainer (VBoxContainer)
        ├── Header (Label)
        ├── Content (Label)
        └── ButtonContainer (HBoxContainer)
            ├── ConfirmButton (Button)
            └── CancelButton (Button)
```

### 带背景的 GYM 场景

```
GYM_XX_Name (CanvasLayer 或 Node2D)
├── Background (ColorRect, z_index=-1)
├── InfoPanel (InfoPanel.tscn 实例)
└── UIRoot (CanvasLayer, 可选)
    └── MainUI (Control)
```

---

## 常用信号

| 节点类型 | 信号名 | 触发时机 |
|---------|--------|----------|
| Button | `pressed` | 按钮被点击 |
| Button | `button_down` | 鼠标按下 |
| Button | `button_up` | 鼠标释放 |
| BaseButton | `toggled` | 切换状态变化（需 `toggle_mode=true`） |
| LineEdit | `text_submitted` | 按 Enter 提交 |
| LineEdit | `text_changed` | 文本变化 |

---

## 最佳实践

### 1. 节点命名使用 PascalCase

```
VBoxContainer
├── ClickButton      # 好
├── CountLabel       # 好
├── click_button     # 不好（下划线）
└── countLabel       # 不好（驼峰）
```

### 2. 脚本与场景同名

- 场景：`CounterUI.tscn`
- 脚本：`CounterUI.gd`

### 3. 使用 VBoxContainer/HBoxContainer 布局

避免手动设置坐标，使用容器自动布局：

```gdscript
# 设置容器间距
$VBoxContainer.add_theme_constant_override("separation", 10)
```

或在场景编辑器中：
1. 选中 VBoxContainer
2. 检查器 → Theme Overrides → Constants → separation = 10

### 4. 文本使用格式化字符串

```gdscript
# 好
label.text = "Count: %d" % count
label.text = "Player: %s, HP: %d" % [player_name, hp]

# 不好
label.text = "Count: " + str(count)
```

---

## 完整示例：计数器UI

### 场景文件 (CounterUI.tscn)

创建场景：右键 → 新建场景 → 选择根节点类型为 `Control`

```
CounterUI (Control)
└── VBoxContainer (VBoxContainer, separation=10)
    ├── TitleLabel (Label, text="Counter Demo")
    ├── Button (Button, text="Click Me")
    └── CountLabel (Label, text="Count: 0")
```

### 脚本 (CounterUI.gd)

```gdscript
extends Control

var _count: int = 0

@onready var _button: Button = $VBoxContainer/Button
@onready var _label: Label = $VBoxContainer/CountLabel


func _ready() -> void:
    # 居中显示
    anchors_preset = Control.PRESET_CENTER
    _update_display()


func _on_button_pressed() -> void:
    _count += 1
    _update_display()


func _update_display() -> void:
    _label.text = "Count: %d" % _count


## 重置计数器（公共接口）
func reset_count() -> void:
    _count = 0
    _update_display()
```

### 信号连接步骤

1. 选中 `Button` 节点
2. 右侧 "节点" 面板 → "信号" 标签
3. 双击 `pressed()` 信号
4. 在弹出对话框中：
   - 连接到：`CounterUI`（根节点）
   - 方法名：`_on_button_pressed`
5. 点击 "连接"

---

## 参考文件

| 组件 | 文件路径 | 学习要点 |
|------|----------|----------|
| 信息面板 | `ui/widgets/InfoPanel.gd` | @export 属性、setter、公共方法 |
| 死亡面板 | `ui/widgets/DeathBoard.gd` | Callable 回调、暂停游戏 |
| 伤害数字 | `ui/widgets/HitLabel.gd` | Tween 动画、自动销毁 |
| 商店面板 | `ui/widgets/ShopPanel.gd` | 复杂UI布局、多个按钮 |
| 设置界面 | `ui/SettingUI.gd` | 配置项读写、信号处理 |

---

## 下一步学习

完成本指南后，可以尝试：

1. **添加重置按钮** - 增加一个 "Reset" 按钮，点击后计数器归零
2. **添加步进值** - 使用 SpinBox 控制每次点击增加的数值
3. **持久化存储** - 使用 `ConfigFile` 保存计数值
4. **动画效果** - 使用 Tween 添加数字变化的缩放动画
