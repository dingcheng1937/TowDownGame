extends Area2D
class_name ExtractionPoint
## 撤离点 - 玩家达成条件后可以从此处撤离

signal activated()
signal deactivated()

## 撤离点是否激活
var is_active: bool = false:
	set(value):
		is_active = value
		if is_active:
			_activate()
		else:
			_deactivate()

## 撤离倒计时（秒）
@export var countdown_duration: float = 5.0

var _countdown_remaining: float = 0.0
var _player_in_zone: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _label: Label = $Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 注册到撤离服务器
	ExtractionServer.register_extraction_point(self)

	# 监听服务器倒计时信号
	ExtractionServer.countdown_tick.connect(_on_countdown_tick)
	ExtractionServer.extraction_completed.connect(_on_extraction_completed)

	# 初始状态
	_deactivate()


func _exit_tree() -> void:
	# 断开信号连接，避免内存泄漏
	# 检查autoload是否仍然有效（场景切换时可能已被清理）
	if not is_instance_valid(ExtractionServer):
		return
	if ExtractionServer.countdown_tick.is_connected(_on_countdown_tick):
		ExtractionServer.countdown_tick.disconnect(_on_countdown_tick)
	if ExtractionServer.extraction_completed.is_connected(_on_extraction_completed):
		ExtractionServer.extraction_completed.disconnect(_on_extraction_completed)
	# 从服务器注销
	ExtractionServer.unregister_extraction_point(self)


func _process(_delta: float) -> void:
	# 倒计时由 ExtractionServer 统一管理
	# 这里只处理视觉效果更新
	pass


func _on_countdown_tick(time_remaining: float) -> void:
	if not is_active or not _player_in_zone:
		return

	if _label:
		_label.text = "撤离中: %.1f" % time_remaining


func _on_extraction_completed() -> void:
	_player_in_zone = false
	if _label:
		_label.text = "撤离成功!"


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

	emit_signal("activated")


func _deactivate() -> void:
	if _sprite:
		_sprite.modulate = Color.RED
	if _label:
		_label.text = "条件未满足"

	_countdown_remaining = countdown_duration
	emit_signal("deactivated")


func _on_body_entered(body: Node2D) -> void:
	if body is Player and is_active:
		_player_in_zone = true
		ExtractionServer.start_extraction()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_zone = false
		if _label:
			_label.text = "可撤离"
		ExtractionServer.cancel_extraction()
