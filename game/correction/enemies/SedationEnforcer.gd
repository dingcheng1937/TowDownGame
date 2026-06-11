extends BaseMonster
class_name SedationEnforcer
## 镇静执行者 - 中级敌人。追击并减速玩家。

@export var chase_range: float = 250.0
@export var attack_damage: float = 2.0
@export var slow_duration: float = 3.0
@export var slow_amount: float = -0.3
@export var attack_cooldown: float = 2.0

var _is_chasing: bool = false
var _can_attack: bool = true


func _ready() -> void:
	super._ready()
	add_to_group("correction_enemies")
	target_player = null
	SPEED = 70.0


func _physics_process(delta: float) -> void:
	if is_die or is_atk:
		super._physics_process(delta)
		return

	if Utils.player and is_instance_valid(Utils.player):
		var dist: float = global_position.distance_to(Utils.player.global_position)
		if dist < chase_range:
			_is_chasing = true
			target_player = Utils.player
		elif _is_chasing:
			_is_chasing = false
			target_player = null

	if _is_chasing and target_player and is_instance_valid(target_player):
		var dist: float = global_position.distance_to(target_player.global_position)
		if dist < 40.0:
			velocity = Vector2.ZERO
			if _can_attack:
				_perform_attack()
		else:
			var dir: Vector2 = global_position.direction_to(target_player.global_position)
			velocity = dir * SPEED
	else:
		velocity = Vector2.ZERO

	super._physics_process(delta)


func _perform_attack() -> void:
	if not _can_attack or is_die or not target_player:
		return
	_can_attack = false
	is_atk = true
	velocity = Vector2.ZERO
	anim.play("attack")
	await anim.animation_finished
	if is_instance_valid(self) and not is_die:
		is_atk = false
		if target_player and is_instance_valid(target_player):
			var dist: float = global_position.distance_to(target_player.global_position)
			if dist < 45.0:
				target_player.onHit(attack_damage)
				# 施加减速
				PlayerData.player_speed += slow_amount
				if is_instance_valid(Utils.player) and Utils.player.has_method("updateHero"):
					Utils.player.updateHero()
				Utils.showToast("减速！")
				await get_tree().create_timer(slow_duration).timeout
				if is_instance_valid(Utils.player) and Utils.player.has_method("updateHero"):
					PlayerData.player_speed -= slow_amount
					Utils.player.updateHero()
		await get_tree().create_timer(attack_cooldown).timeout
		if is_instance_valid(self) and not is_die:
			_can_attack = true


func onDie(is_death_effect := true) -> void:
	EventBus.enemy_killed.emit("sedation_enforcer", global_position)
	super.onDie(is_death_effect)
