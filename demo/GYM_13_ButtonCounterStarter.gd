extends CanvasLayer
## GYM_13 按钮计数器 - 学习 Godot UI 基础
##
## 学习内容：
## - Button 节点的基本使用
## - Label 节点的文本更新
## - 信号连接与回调函数
## - @onready 节点引用

## 计数器值
var _count: int = 0

## 节点引用（使用 @onready 延迟获取）
@onready var _button: Button = $CounterUI/VBoxContainer/Button
@onready var _label: Label = $CounterUI/VBoxContainer/CountLabel
@onready var _info_panel: InfoPanel = $InfoPanel


func _ready() -> void:
    # 纯UI场景，显示鼠标
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

    # 配置 InfoPanel
    _setup_info_panel()

    # 初始化显示
    _update_display()


## 配置信息面板
func _setup_info_panel() -> void:
    _info_panel.title = "GYM_13 Button Counter"
    _info_panel.content = """学习内容：
- Button 节点
- Label 节点
- 信号连接
- @onready 引用

按 H 键隐藏/显示此面板"""


## 按钮点击回调（需在场景中连接 pressed 信号）
func _on_button_pressed() -> void:
    _count += 1
    _update_display()


## 更新 Label 显示
func _update_display() -> void:
    _label.text = "Count: %d" % _count
