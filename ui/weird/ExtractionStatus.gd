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
	ExtractionServer.extraction_countdown.connect(_on_countdown)

	_update_initial_state()


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


func _on_countdown(time_remaining: float) -> void:
	if _countdown_label:
		_countdown_label.text = "剩余: %.1f秒" % time_remaining
