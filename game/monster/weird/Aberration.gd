extends BaseMonster
class_name Aberration
## 畸变体 - 高血量、高伤害、慢速的诡异怪物

## 冲锋距离
@export var charge_distance: float = 200.0
## 冲锋速度倍率
@export var charge_speed_mult: float = 3.0
## 冲锋冷却
@export var charge_cooldown: float = 5.0

var _charge_timer: float = 0.0
var _is_charging: bool = false


func _ready() -> void:
	super._ready()
	# 畸变体特性：低速度、高血量、高伤害
	SPEED = 30.0
	HP = 15
	hurt = 2
	knockback_def = 10

	# 创建接触检测区域（CharacterBody2D没有body_entered信号）
	_setup_detection_area()


func _physics_process(delta: float) -> void:
	if is_die:
		return

	_charge_timer -= delta

	if _is_charging:
		move_and_slide()
		return

	super._physics_process(delta)

	# 检查是否可以冲锋
	if target_player != null and _charge_timer <= 0:
		var distance = global_position.distance_to(target_player.global_position)
		if distance > charge_distance:
			_start_charge()


func _start_charge() -> void:
	_is_charging = true
	_charge_timer = charge_cooldown

	# 面向玩家
	var direction = global_position.direction_to(target_player.global_position)
	velocity = direction * SPEED * charge_speed_mult

	anim.play("attack")

	# 冲锋持续时间
	await get_tree().create_timer(0.5).timeout
	# 检查怪物是否仍然有效且未死亡（可能在冲锋期间被击杀）
	if is_instance_valid(self) and not is_die:
		_is_charging = false


func onHit(hit_num: float, is_show_label: bool = true, is_death_effect: bool = true) -> void:
	# 畸变体有减伤
	var reduced_damage = hit_num * 0.7
	super.onHit(reduced_damage, is_show_label, is_death_effect)


func onDie(is_death_effect: bool = true) -> void:
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
	shape.radius = 8.0
	shape.height = 30.0
	collision_shape.shape = shape
	collision_shape.position = Vector2(0, -15)
	detection_area.add_child(collision_shape)
	add_child(detection_area)
	# 连接信号
	detection_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_die and not hit:
		# 设置击中冷却，防止重复伤害
		start_hit_cooldown(0.5)
		body.onHit(hurt)
		# 畸变体攻击造成额外理智伤害
		SanityServer.change_sanity(-10.0)
