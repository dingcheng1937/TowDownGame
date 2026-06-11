extends BaseMonster
class_name NurseMonster
## 护士 AI — 开门线(3s窗口+背身靠墙检测)/不开门线(直接攻击)

enum NurseState { ENTERING, DETECTION_WINDOW, ATTACKING, STUNNED }

@export var detection_window: float = 3.0   # 检测窗口时长
@export var stand_still_time_needed: float = 1.0  # 需要静止1秒
@export var attack_damage: float = 3.0
@export var attack_cooldown: float = 1.5   # 攻击冷却秒数

var _state: NurseState = NurseState.ENTERING
var _door_opened: bool = true
var _stand_still_timer: float = 0.0
var _window_timer: float = 0.0
var _attack_timer: float = 0.0

# — RayCast 节点 —
var _wall_ray: RayCast2D

func _ready() -> void:
	super._ready()
	SPEED = 60.0
	add_to_group("correction_survival_enemies")
	_wall_ray = get_node_or_null("WallRay") as RayCast2D
	if not _wall_ray:
		_wall_ray = RayCast2D.new()
		_wall_ray.name = "WallRay"
		_wall_ray.target_position = Vector2(0, -30)
		_wall_ray.enabled = false
		add_child(_wall_ray)

func set_door_opened(opened: bool) -> void:
	_door_opened = opened

func _physics_process(delta: float) -> void:
	if is_die:
		return
	if _attack_timer > 0.0:
		_attack_timer -= delta

	match _state:
		NurseState.ENTERING:
			_process_entering(delta)
		NurseState.DETECTION_WINDOW:
			_process_detection_window(delta)
		NurseState.ATTACKING:
			_process_attacking(delta)
		NurseState.STUNNED:
			velocity = Vector2.ZERO
			if _attack_timer <= 0.0:
				_state = NurseState.ATTACKING
			move_and_slide()

	# 更新动画（不调用父类，避免父类覆盖 velocity）
	_update_animation()

func _process_entering(_delta: float) -> void:
	var player = Utils.player
	if not player or not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist: float = global_position.distance_to(player.global_position)
	if _door_opened and dist < 100.0:
		_state = NurseState.DETECTION_WINDOW
		_window_timer = 0.0
		_stand_still_timer = 0.0
		velocity = Vector2.ZERO
		Utils.showToast("护士盯着你...静止！")
	elif _door_opened:
		velocity = global_position.direction_to(player.global_position) * SPEED
	else:
		# 破门线直接攻击
		_state = NurseState.ATTACKING
		velocity = Vector2.ZERO
		Utils.showToast("护士破门而入！")
	move_and_slide()

func _process_detection_window(delta: float) -> void:
	velocity = Vector2.ZERO
	_window_timer += delta

	if _is_player_stealthing():
		_stand_still_timer += delta
		if _stand_still_timer >= stand_still_time_needed:
			Utils.showToast("护士没发现你...")
			# 通知 DoorInteraction 开门
			var door := get_tree().get_first_node_in_group("door_interaction")
			if door and door.has_method("on_player_survived"):
				door.on_player_survived()
			queue_free()
			return
	else:
		_stand_still_timer = 0.0

	if _window_timer >= detection_window:
		_state = NurseState.ATTACKING
		Utils.showToast("护士发现你了！")

	move_and_slide()

func _process_attacking(_delta: float) -> void:
	var player = Utils.player
	if not player or not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist: float = global_position.distance_to(player.global_position)
	if dist < 40.0 and _attack_timer <= 0.0:
		player.onHit(attack_damage)
		_attack_timer = attack_cooldown
		_state = NurseState.STUNNED
	else:
		velocity = global_position.direction_to(player.global_position) * SPEED
	move_and_slide()

func _is_player_stealthing() -> bool:
	"""检测玩家是否背身+靠墙+静止"""
	var player = Utils.player
	if not player or not is_instance_valid(player):
		return false
	# 1. 检测静止 — 玩家速度接近0
	if player.velocity.length() > 5.0:
		return false
	# 2. 检测背身
	var facing_right: bool = player.body.scale.x >= 0 if player.get("body") else true
	var facing_direction: Vector2 = Vector2.RIGHT if facing_right else Vector2.LEFT
	# 3. 检测靠墙
	if _wall_ray:
		_wall_ray.global_position = player.global_position
		_wall_ray.target_position = facing_direction * 20.0
		_wall_ray.enabled = true
		_wall_ray.force_raycast_update()
		if _wall_ray.is_colliding():
			return true
	return false

func _update_animation() -> void:
	if anim and anim.sprite_frames:
		if velocity.length() > 1.0:
			if anim.sprite_frames.has_animation("run"):
				if anim.animation != "run":
					anim.play("run")
			if velocity.x > 0:
				flip_h(false)
			elif velocity.x < 0:
				flip_h(true)
		else:
			if anim.sprite_frames.has_animation("idle"):
				if anim.animation != "idle":
					anim.play("idle")

func onDie(is_death_effect := true) -> void:
	EventBus.enemy_killed.emit("nurse", global_position)
	super.onDie(is_death_effect)
