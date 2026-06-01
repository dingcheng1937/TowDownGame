extends Area2D
class_name ExtractionPoint
## 撤离点 - 玩家达成条件后可以从此处撤离

signal extraction_activated()
signal extraction_deactivated()

## 撤离点是否激活
var is_active: bool = false:
	set(value):
		is_active = value
		if is_active:
			_activate()
		else:
			_deactivate()

## 撤离倒计时（秒）
@export var countdown_time: float = 5.0

var _countdown_remaining: float = 0.0
var _player_in_zone: bool = false

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _label: Label = $Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 注册到撤离服务器
	ExtractionServer.register_extraction_point(self)

	# 初始状态
	_deactivate()


func _process(delta: float) -> void:
	if not is_active or not _player_in_zone:
		return

	# 更新倒计时
	_countdown_remaining -= delta

	if _label:
		_label.text = "撤离中: %.1f" % _countdown_remaining

	if _countdown_remaining <= 0:
		_complete_extraction()


func activate() -> void:
	is_active = true


func deactivate() -> void:
	is_active = false


func _activate() -> void:
	# 视觉效果
	if _sprite:
		_sprite.modulate = Color.GREEN
	if _label:
		_label.text = "可撤离"

	emit_signal("extraction_activated")


func _deactivate() -> void:
	if _sprite:
		_sprite.modulate = Color.RED
	if _label:
		_label.text = "条件未满足"

	_countdown_remaining = countdown_time
	emit_signal("extraction_deactivated")


func _on_body_entered(body: Node2D) -> void:
	if body is Player and is_active:
		_player_in_zone = true
		_countdown_remaining = countdown_time
		ExtractionServer.start_extraction()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_zone = false
		_countdown_remaining = countdown_time
		if _label:
			_label.text = "可撤离"
		ExtractionServer.cancel_extraction()


func _complete_extraction() -> void:
	ExtractionServer.complete_extraction()
