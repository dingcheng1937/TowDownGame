extends BaseMonster
class_name PatrolGuard
## 巡逻员 - 基础敌人。巡逻+追击。

@export var chase_range: float = 200.0
@export var attack_damage: float = 1.0
@export var attack_cooldown: float = 1.5
@export var alert_noise_on_spawn: float = 0.0

var _is_chasing: bool = false
var _is_patrolling: bool = true
var _can_attack: bool = true
var _patrol_direction: Vector2 = Vector2.RIGHT
var _patrol_timer: float = 0.0
var _patrol_switch_interval: float = 3.0


func _ready() -> void:
	super._ready()
	add_to_group("correction_enemies")
	target_player = null  # 初始不追踪
	SPEED = 40.0


func _physics_process(delta: float) -> void:
	if is_die or is_atk:
		super._physics_process(delta)
		return

	# 检查是否在追击范围内
	if Utils.player and is_instance_valid(Utils.player):
		var dist: float = global_position.distance_to(Utils.player.global_position)
		if dist < chase_range:
			_is_chasing = true
			_is_patrolling = false
			target_player = Utils.player
		elif _is_chasing:
			_is_chasing = false
			_is_patrolling = true
			target_player = null

	if _is_chasing:
		_chase_behavior(delta)
	elif _is_patrolling:
		_patrol_behavior(delta)
	else:
		velocity = Vector2.ZERO

	super._physics_process(delta)


func _chase_behavior(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	var dist: float = global_position.distance_to(target_player.global_position)
	# 太近时停止并尝试攻击
	if dist < 35.0:
		velocity = Vector2.ZERO
		if _can_attack:
			_melee_attack()
	else:
		var dir: Vector2 = global_position.direction_to(target_player.global_position)
		velocity = dir * SPEED


func _patrol_behavior(delta: float) -> void:
	_patrol_timer += delta
	if _patrol_timer >= _patrol_switch_interval:
		_patrol_timer = 0.0
		_patrol_direction = Vector2.RIGHT.rotated(randf() * TAU)
	velocity = _patrol_direction * SPEED * 0.5


func _melee_attack() -> void:
	if not _can_attack or is_die or not target_player or not is_instance_valid(target_player):
		return
	_can_attack = false
	is_atk = true
	velocity = Vector2.ZERO
	if anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation("attack"):
		anim.play("attack")
		await anim.animation_finished
	else:
		await get_tree().create_timer(0.3).timeout
	if is_instance_valid(self) and not is_die:
		is_atk = false
		if target_player and is_instance_valid(target_player):
			var dist: float = global_position.distance_to(target_player.global_position)
			if dist < 40.0:
				target_player.onHit(attack_damage)
		await get_tree().create_timer(attack_cooldown).timeout
		if is_instance_valid(self) and not is_die:
			_can_attack = true


func onDie(is_death_effect := true) -> void:
	EventBus.enemy_killed.emit("patrol_guard", global_position)
	super.onDie(is_death_effect)
