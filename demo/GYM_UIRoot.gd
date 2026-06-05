extends CanvasLayer
## GYM 场景的 UIRoot - 提供 showToast 等基础功能

@onready var _toast_label: Label = $ToastUI/Label
@onready var _toast_container: Control = $ToastUI
@onready var _toast_timer: Timer = $ToastUI/Timer

func _ready():
	# 确保初始状态隐藏
	if _toast_container:
		_toast_container.visible = false

func showToast(msg: String, time: float = 1.0):
	"""显示 Toast 消息"""
	if not _toast_label or not _toast_container or not _toast_timer:
		push_warning("Toast UI nodes not found")
		print("[Toast] ", msg)
		return

	# 停止之前的计时器
	_toast_timer.stop()
	_toast_timer.wait_time = time
	_toast_timer.start()

	# 显示消息
	_toast_label.text = msg
	_toast_container.visible = true

	# 淡入动画
	var tween = create_tween()
	tween.tween_property(_toast_container, "modulate:a", 1.0, 0.1).from(0.0)

func _on_toast_timer_timeout():
	"""Toast 计时器超时 - 淡出"""
	if not _toast_container:
		return

	var tween = create_tween()
	tween.tween_property(_toast_container, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): _toast_container.visible = false)

func crosshairChange(_is_change: bool):
	"""准星显示切换 - GYM场景可能不需要，提供空实现"""
	# GYM场景通常不使用独立准星控制
	pass
