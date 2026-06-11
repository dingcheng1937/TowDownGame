extends Area2D
class_name DoorInteraction
## 敲门触发器 — 玩家靠近门后触发敲门 → 选择开门/不开门

signal door_knocked()
signal door_choice_made(opened: bool)

@export var knock_delay: float = 4.0      # 进入房间后多久敲门
@export var break_in_time: float = 10.0   # 不开门时护士破门时间
@export var room_exit_wall: String = ""   # 存活后移除的门墙节点名（相对于父节点）
@export var room_door_wall: NodePath      # 存活后移除的门墙

var _player_in_room: bool = false
var _knocked: bool = false
var _door_open: bool = false
var _break_in_timer: float = 0.0
var _room_timer: float = 0.0

@onready var label: Label = get_node_or_null("Label")
@onready var choice_label: Label = get_node_or_null("ChoiceLabel")
@onready var nurse_spawn: Marker2D = get_node_or_null("NurseSpawn")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("door_interaction")
	if label: label.visible = false
	if choice_label: choice_label.visible = false

func _process(delta: float) -> void:
	if _door_open: return
	_room_timer += delta
	# 4秒后第一次敲门
	if not _knocked and _room_timer >= knock_delay:
		_knocked = true
		_trigger_knock()
	# 敲完门后如果玩家没开门 → 10秒后护士破门
	if _knocked and not _door_open:
		_break_in_timer += delta
		if _break_in_timer >= break_in_time:
			_force_break_in()

func _trigger_knock() -> void:
	EventBus.door_knocked.emit()
	Utils.showToast("咚咚咚...有人敲门")
	if label: label.text = "按 E 开门 / 等待则不开门"; label.visible = true

func _on_body_entered(body: Node2D) -> void:
	if body is Player: _player_in_room = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("e") and _knocked and not _door_open:
		get_viewport().set_input_as_handled()
		_player_opened_door()

func _player_opened_door() -> void:
	_door_open = true
	EventBus.door_choice_made.emit(true)
	if label: label.visible = false
	Utils.showToast("你打开了门...")
	# 在护士生成点生成护士
	if nurse_spawn:
		var nurse: Node = preload("res://game/correction-survival/enemies/NurseMonster.tscn").instantiate()
		nurse.global_position = nurse_spawn.global_position
		# 需要设置护士的检测窗口模式，因为玩家选择了开门
		if nurse.has_method("set_door_opened"):
			nurse.set_door_opened(true)
		get_parent().add_child(nurse)

func _force_break_in() -> void:
	_door_open = true
	EventBus.door_choice_made.emit(false)
	if label: label.visible = false
	Utils.showToast("门被撞开了！")
	if nurse_spawn:
		var nurse: Node = preload("res://game/correction-survival/enemies/NurseMonster.tscn").instantiate()
		nurse.global_position = nurse_spawn.global_position
		if nurse.has_method("set_door_opened"):
			nurse.set_door_opened(false)
		get_parent().add_child(nurse)

func on_player_survived() -> void:
	# 存活后移除门墙 → 玩家可以离开房间
	if room_door_wall:
		var door_wall := get_node_or_null(room_door_wall)
		if door_wall:
			door_wall.queue_free()
	# 尝试通过 group 找到门墙
	if room_exit_wall != "":
		var door_wall := get_node_or_null("../" + room_exit_wall)
		if door_wall:
			door_wall.queue_free()
	Utils.showToast("门开了...前往走廊")
