extends BaseMonster
class_name OrderlyMonster
## 监护巡逻 AI — 固定路径巡逻 + 视觉锥 + 听觉检测

enum OrderlyState { PATROL, ALERT, CHASE, ATTACK }

@export var patrol_points: Array = []
@export var patrol_speed: float = 30.0
@export var chase_speed: float = 60.0
@export var alert_decay: float = 5.0   # 警觉度衰减/秒
@export var alert_threshold: float = 100.0  # 满值进入CHASE
@export var hearing_range: float = 150.0  # 听觉检测半径

var _state: OrderlyState = OrderlyState.PATROL
var _current_point: int = 0
var _alertness: float = 0.0
var _view_cone: Node
var _player_visible: bool = false

func _ready() -> void:
	super._ready()
	SPEED = patrol_speed
	add_to_group("correction_survival_enemies")
	_view_cone = get_node_or_null("ViewCone")
	if _view_cone:
		_view_cone.player_detected.connect(_on_player_detected)
		_view_cone.player_lost.connect(_on_player_lost)

func _physics_process(delta: float) -> void:
	# 死亡或攻击中时只调用父类更新动画
	if is_die or is_atk:
		super._physics_process(delta)
		return

	match _state:
		OrderlyState.PATROL:
			_patrol(delta)
			_check_hearing()
			# 巡逻时自行移动（父类仅在target_player非null时移动）
			move_and_slide()
		OrderlyState.ALERT:
			_alert_behavior(delta)
			velocity = Vector2.ZERO
			move_and_slide()
		OrderlyState.CHASE:
			_chase_behavior(delta)
			move_and_slide()
		OrderlyState.ATTACK:
			velocity = Vector2.ZERO
			move_and_slide()

	# 调用父类更新动画
	_update_animation()

func _patrol(_delta: float) -> void:
	if patrol_points.size() == 0:
		return
	var target: Vector2 = patrol_points[_current_point]
	var dist: float = global_position.distance_to(target)
	if dist < 10.0:
		_current_point = (_current_point + 1) % patrol_points.size()
	else:
		velocity = global_position.direction_to(target) * SPEED

func _check_hearing() -> void:
	if not Utils.player or not is_instance_valid(Utils.player):
		return
	var dist = global_position.distance_to(Utils.player.global_position)
	# 玩家跑步产生脚步声，在听觉范围内增加警觉度
	if dist < hearing_range and Utils.player.is_run:
		_alertness += 10.0 * get_physics_process_delta_time()
	if _alertness >= alert_threshold:
		_state = OrderlyState.CHASE
		Utils.showToast("监护发现了你！")

func _on_player_detected(_player_node: Node) -> void:
	_player_visible = true
	_alertness += 30.0  # 看到玩家大量增加警觉
	if _state != OrderlyState.CHASE:
		_state = OrderlyState.CHASE
		Utils.showToast("监护发现了你！")

func _on_player_lost() -> void:
	_player_visible = false

func _alert_behavior(delta: float) -> void:
	_alertness = max(0.0, _alertness - alert_decay * delta)
	if _alertness <= 0:
		_state = OrderlyState.PATROL

func _chase_behavior(_delta: float) -> void:
	var player = Utils.player
	if not player or not is_instance_valid(player):
		_state = OrderlyState.ALERT
		return
	var dist = global_position.distance_to(player.global_position)
	if dist < 35.0:
		_melee_attack()
		return
	velocity = global_position.direction_to(player.global_position) * chase_speed
	# 如果看不到玩家，逐渐降低警觉
	if not _player_visible:
		_alertness -= alert_decay * get_physics_process_delta_time()
		if _alertness <= 0:
			_state = OrderlyState.PATROL

func _melee_attack() -> void:
	if is_atk:
		return
	is_atk = true
	_state = OrderlyState.ATTACK
	velocity = Vector2.ZERO
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("attack"):
		anim.play("attack")
		await anim.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self) and not is_die:
		is_atk = false
		var player = Utils.player
		if player and is_instance_valid(player):
			player.onHit(2.0)
		_state = OrderlyState.CHASE

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
	EventBus.enemy_killed.emit("orderly", global_position)
	super.onDie(is_death_effect)
