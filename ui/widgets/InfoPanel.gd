extends CanvasLayer
## 可复用的信息面板组件
## 用于教程、游戏提示、测试关卡说明等
## 按键显示/隐藏

class_name InfoPanel

## 显示/隐藏的按键，可在检查器中配置
@export var toggle_key: Key = KEY_H

## 面板标题
@export var title: String = "":
	set(value):
		title = value
		if _title_label:
			_title_label.text = value

## 主要内容文本
@export_multiline var content: String = "":
	set(value):
		content = value
		if _content_label:
			_content_label.text = value

## 是否默认显示
@export var show_by_default: bool = true

## 面板宽度
@export var panel_width: int = 200:
	set(value):
		panel_width = value
		_update_panel_size()

## 面板背景透明度 (0.0 - 1.0)
@export_range(0.0, 1.0) var bg_opacity: float = 0.5:
	set(value):
		bg_opacity = value
		if _panel:
			_panel.self_modulate.a = bg_opacity

@onready var _panel: Panel = $Panel
@onready var _title_label: Label = $Panel/VBox/Title
@onready var _content_label: Label = $Panel/VBox/Content
@onready var _hint_label: Label = $Panel/VBox/Hint

var _is_visible: bool = true


func _ready() -> void:
	layer = 10

	# 应用导出属性
	if title != "":
		_title_label.text = title
	if content != "":
		_content_label.text = content

	_is_visible = show_by_default
	_panel.visible = _is_visible

	_update_panel_size()
	_update_hint_text()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == toggle_key:
		toggle()


func toggle() -> void:
	_is_visible = !_is_visible
	_panel.visible = _is_visible


func show_panel() -> void:
	_is_visible = true
	_panel.visible = true


func hide_panel() -> void:
	_is_visible = false
	_panel.visible = false


## 设置标题文本
func set_title(text: String) -> void:
	title = text


## 设置内容文本
func set_content(text: String) -> void:
	content = text


## 设置切换按键
func set_toggle_key(key: Key) -> void:
	toggle_key = key
	_update_hint_text()


func _update_panel_size() -> void:
	if _panel:
		_panel.custom_minimum_size.x = panel_width


func _update_hint_text() -> void:
	if _hint_label:
		var key_name = OS.get_keycode_string(toggle_key)
		_hint_label.text = "[%s] 切换显示" % key_name
