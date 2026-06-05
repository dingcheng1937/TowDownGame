extends BaseMonster
class_name Shade
## 残影 - 高速、低血量、造成理智伤害的诡异怪物

## 理智伤害
@export var sanity_damage: float = 5.0
## 冲刺速度倍率
@export var dash_multiplier: float = 2.5
## 冲击距离
@export var dash_distance: float = 100.0
## 冲击冷却
@export var dash_cooldown: float = 3.0

var _dash_timer: float = 0.0
var _is_dashing: bool = false
var _dash_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()
	# 残影特性：高速度、低血量
	SPEED = 120.0
	HP = 2
	hurt = 1
	knockback_def = 2

	# 创建接触检测区域（CharacterBody2D没有body_entered信号）
	_setup_detection_area()


func _physics_process(delta: float) -> void:
	if is_die:
		return

	_dash_timer -= delta

	if _is_dashing:
		# 冲刺中
		velocity = _dash_direction * SPEED * dash_multiplier
		move_and_slide()
		return

	if not is_atk and not hit and target_player != null:
		# 检查是否可以冲刺
		var distance_to_player = global_position.distance_to(target_player.global_position)
		if distance_to_player < dash_distance and _dash_timer <= 0:
			_start_dash()
		else:
			super._physics_process(delta)


func _start_dash() -> void:
	_is_dashing = true
	_dash_timer = dash_cooldown
	_dash_direction = global_position.direction_to(target_player.global_position)

	# 冲刺动画效果
	anim.play("run")

	await get_tree().create_timer(0.3).timeout
	# 检查怪物是否仍然有效且未死亡（可能在冲刺期间被击杀）
	if is_instance_valid(self) and not is_die:
		_is_dashing = false


func onHit(hit_num: float, is_show_label: bool = true, is_death_effect: bool = true) -> void:
	super.onHit(hit_num, is_show_label, is_death_effect)


func onDie(is_death_effect: bool = true) -> void:
	# 注册击杀
	ExtractionServer.register_kill()
	super.onDie(is_death_effect)


## 创建接触检测区域
func _setup_detection_area() -> void:
	var detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	# 设置碰撞检测：检测玩家（collision_layer 25）
	detection_area.collision_layer = 0  # 不参与物理碰撞
	detection_area.collision_mask = 25  # 检测玩家层
	# 使用与主体相同的碰撞形状
	var collision_shape = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 4.0
	shape.height = 18.0
	collision_shape.shape = shape
	collision_shape.position = Vector2(0, -10)
	detection_area.add_child(collision_shape)
	add_child(detection_area)
	# 连接信号
	detection_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_die and not hit:
		# 设置击中冷却，防止重复伤害
		hit = true
		# 对玩家造成物理伤害
		body.onHit(hurt)
		# 造成理智伤害
		SanityServer.change_sanity(-sanity_damage)
