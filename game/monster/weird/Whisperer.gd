extends BaseMonster
class_name Whisperer
## 低语者 - 远程攻击、持续降低周围理智的诡异怪物

## 理智降低范围
@export var sanity_drain_radius: float = 150.0
## 每秒理智降低量
@export var sanity_drain_rate: float = 2.0
## 远程攻击间隔
@export var attack_interval: float = 2.0
## 远程攻击伤害
@export var ranged_damage: int = 1

var _attack_timer: float = 0.0
var _sanity_drain_area: Area2D


func _ready() -> void:
	super._ready()
	# 低语者特性：中速、中血量
	SPEED = 50.0
	HP = 4
	hurt = 1
	knockback_def = 3

	# 创建理智降低区域
	_setup_sanity_drain_area()


func _setup_sanity_drain_area() -> void:
	_sanity_drain_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = sanity_drain_radius
	collision.shape = circle
	_sanity_drain_area.add_child(collision)
	add_child(_sanity_drain_area)


func _physics_process(delta: float) -> void:
	if is_die:
		return

	# 检查玩家是否在理智降低范围内
	_check_sanity_drain()

	_attack_timer -= delta

	super._physics_process(delta)

	# 远程攻击逻辑
	if _attack_timer <= 0 and target_player != null:
		var distance = global_position.distance_to(target_player.global_position)
		if distance < 200.0:
			_ranged_attack()
			_attack_timer = attack_interval


func _check_sanity_drain() -> void:
	if _sanity_drain_area and target_player:
		var bodies = _sanity_drain_area.get_overlapping_bodies()
		for body in bodies:
			if body is Player:
				SanityServer.change_sanity(-sanity_drain_rate * get_physics_process_delta_time())
				break


func _ranged_attack() -> void:
	# 创建投射物
	var projectile = preload("res://game/monster/weird/WhispererProjectile.tscn").instantiate()
	projectile.global_position = global_position
	projectile.direction = global_position.direction_to(target_player.global_position)
	projectile.damage = ranged_damage
	projectile.sanity_damage = 3.0
	get_tree().current_scene.add_child(projectile)

	anim.play("attack")


func onDie(is_death_effect: bool = true) -> void:
	ExtractionServer.register_kill()
	super.onDie(is_death_effect)
