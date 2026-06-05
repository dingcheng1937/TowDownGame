extends Control
class_name SanityBar
## 理智条 UI - 显示玩家当前理智状态

@onready var _progress_bar: ProgressBar = $ProgressBar
@onready var _label: Label = $Label

var _sanity_state_colors: Dictionary = {
	"normal": Color(0.3, 0.8, 0.3),    # 绿色
	"mild": Color(0.8, 0.8, 0.3),      # 黄色
	"moderate": Color(0.9, 0.5, 0.2),  # 橙色
	"severe": Color(0.9, 0.2, 0.2),    # 红色
}


func _ready() -> void:
	SanityServer.sanity_changed.connect(_on_sanity_changed)
	SanityServer.sanity_threshold_crossed.connect(_on_threshold_crossed)

	# 初始化显示
	_update_display(100.0, 100.0)


func _exit_tree() -> void:
	# 断开信号连接，避免内存泄漏
	# 检查autoload是否仍然有效（场景切换时可能已被清理）
	if not is_instance_valid(SanityServer):
		return
	if SanityServer.sanity_changed.is_connected(_on_sanity_changed):
		SanityServer.sanity_changed.disconnect(_on_sanity_changed)
	if SanityServer.sanity_threshold_crossed.is_connected(_on_threshold_crossed):
		SanityServer.sanity_threshold_crossed.disconnect(_on_threshold_crossed)


func _on_sanity_changed(current: float, max_val: float) -> void:
	_update_display(current, max_val)


func _on_threshold_crossed(threshold: String) -> void:
	_update_color(threshold)


func _update_display(current: float, max_val: float) -> void:
	if _progress_bar:
		_progress_bar.max_value = max_val
		_progress_bar.value = current

	if _label:
		_label.text = "理智: %d/%d" % [int(current), int(max_val)]

	# 更新颜色
	var state = SanityServer.get_sanity_state()
	match state:
		SanityServer.SanityState.NORMAL:
			_update_color("normal")
		SanityServer.SanityState.MILD:
			_update_color("mild")
		SanityServer.SanityState.MODERATE:
			_update_color("moderate")
		SanityServer.SanityState.SEVERE:
			_update_color("severe")


func _update_color(state_key: String) -> void:
	var color = _sanity_state_colors.get(state_key, Color.WHITE)
	if _progress_bar:
		_progress_bar.modulate = color
