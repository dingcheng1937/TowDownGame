extends RigidBody2D
class_name ThrowableItem
## 投掷物弹体 - 被投出后在物理世界飞行，碰撞时触发效果

signal thrown
signal hit_something(hit_target: Node, position: Vector2)
signal expired

enum ThrowableType { STONE, MEDICINE_BOTTLE, PLATE }

@export var throwable_type: ThrowableType = ThrowableType.STONE
@export var damage: float = 0.0
@export var throw_speed: float = 400.0
@export var knockback_force: float = 100.0
@export var noise_amount: float = 10.0
@export var lure_enemies: bool = false
@export var item_name: String = "投掷物"
@export_multiline var description: String = ""
@export var lifetime: float = 5.0

var _has_thrown: bool = false
var _timer: Timer


func _ready() -> void:
	freeze = true
	gravity_scale = 0.0
	body_entered.connect(_on_body_entered)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_expired)
	add_child(_timer)


func throw_in_dir(direction: Vector2) -> void:
	if _has_thrown: return
	_has_thrown = true
	freeze = false
	gravity_scale = 1.0
	linear_velocity = direction * throw_speed
	emit_signal("thrown")
	if noise_amount > 0.0 and is_instance_valid(AlertServer):
		AlertServer.add_noise(noise_amount, "throw")
	_timer.wait_time = lifetime
	_timer.start()


func _on_body_entered(body: Node2D) -> void:
	if not _has_thrown: return
	if body is BaseMonster and not body.is_die:
		if damage > 0.0:
			body.onHit(damage)
			Utils.showHitLabel(damage, body)
		if knockback_force > 0.0:
			var kdir: Vector2 = (body.global_position - global_position).normalized()
			body.velocity = kdir * knockback_force
			body.hit = true
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(body) and not body.is_die:
				body.hit = false
		hit_something.emit(body, global_position)
		queue_free()
		return
	if lure_enemies and body is StaticBody2D:
		_distract_enemies()
	hit_something.emit(body, global_position)
	queue_free()


func _distract_enemies() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("correction_enemies")
	for e in enemies:
		if e is BaseMonster and not e.is_die:
			e.target_player = null
			var pos: Vector2 = global_position
			var timer: SceneTreeTimer = get_tree().create_timer(1.0)
			await timer.timeout
			if is_instance_valid(e) and not e.is_die:
				e.target_player = Utils.player


func _on_expired() -> void:
	expired.emit()
	queue_free()


static func create(type: ThrowableType, pos: Vector2) -> ThrowableItem:
	var inst: ThrowableItem = preload("res://game/correction/items/ThrowableItem.tscn").instantiate()
	inst.throwable_type = type
	inst.global_position = pos
	match type:
		ThrowableType.STONE:
			inst.item_name = "石子"; inst.damage = 0.0; inst.noise_amount = 5.0
			inst.lure_enemies = true; inst.description = "很多人都试过。"
		ThrowableType.MEDICINE_BOTTLE:
			inst.item_name = "药瓶"; inst.damage = 5.0; inst.noise_amount = 15.0
			inst.description = "标签已经脱落。"
		ThrowableType.PLATE:
			inst.item_name = "餐盘"; inst.damage = 3.0; inst.noise_amount = 10.0
			inst.knockback_force = 200.0; inst.description = "今日菜单：无。"
	return inst
