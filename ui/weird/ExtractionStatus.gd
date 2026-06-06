extends Control
class_name ExtractionStatus
## 撤离状态 UI - 显示撤离条件和进度

@onready var _condition_label: Label = $VBox/ConditionLabel
@onready var _status_label: Label = $VBox/StatusLabel
@onready var _countdown_label: Label = $VBox/CountdownLabel


func _ready() -> void:
	ExtractionServer.extraction_available.connect(_on_extraction_available)
	ExtractionServer.extraction_started.connect(_on_extraction_started)
	ExtractionServer.extraction_completed.connect(_on_extraction_completed)
	ExtractionServer.extraction_failed.connect(_on_extraction_failed)
	ExtractionServer.countdown_tick.connect(_on_countdown)

	_update_initial_state()


func _exit_tree() -> void:
	# 断开信号连接，避免内存泄漏
	# 检查autoload是否仍然有效（场景切换时可能已被清理）
	if not is_instance_valid(ExtractionServer):
		return
	if ExtractionServer.extraction_available.is_connected(_on_extraction_available):
		ExtractionServer.extraction_available.disconnect(_on_extraction_available)
	if ExtractionServer.extraction_started.is_connected(_on_extraction_started):
		ExtractionServer.extraction_started.disconnect(_on_extraction_started)
	if ExtractionServer.extraction_completed.is_connected(_on_extraction_completed):
		ExtractionServer.extraction_completed.disconnect(_on_extraction_completed)
	if ExtractionServer.countdown_tick.is_connected(_on_countdown):
		ExtractionServer.countdown_tick.disconnect(_on_countdown)
	if ExtractionServer.extraction_failed.is_connected(_on_extraction_failed):
		ExtractionServer.extraction_failed.disconnect(_on_extraction_failed)


func _update_initial_state() -> void:
	if _condition_label:
		_condition_label.text = "待够30秒后可撤离"
	if _status_label:
		_status_label.text = "撤离点：不可用"
	if _countdown_label:
		_countdown_label.visible = false


func _on_extraction_available() -> void:
	if _status_label:
		_status_label.text = "撤离点：可用"
		_status_label.modulate = Color.GREEN


func _on_extraction_started() -> void:
	if _status_label:
		_status_label.text = "撤离中..."
	if _countdown_label:
		_countdown_label.visible = true


func _on_extraction_completed() -> void:
	if _status_label:
		_status_label.text = "撤离成功！"
		_status_label.modulate = Color.CYAN
	if _countdown_label:
		_countdown_label.visible = false


func _on_extraction_failed(reason: String) -> void:
	if _status_label:
		_status_label.text = "撤离失败: " + reason
		_status_label.modulate = Color.RED
	if _countdown_label:
		_countdown_label.visible = false


func _on_countdown(time_remaining: float) -> void:
	if _countdown_label:
		_countdown_label.text = "剩余: %.1f秒" % time_remaining
