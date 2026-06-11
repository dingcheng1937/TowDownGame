extends BaseMonster
class_name SurveillanceDrone
## 监察无人机 - 侦查单位。发现玩家后呼叫支援。

@export var detection_range: float = 250.0
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 80.0
@export var reinforce_alert: float = 20.0

var _is_alerted: bool = false
var _alert_timer: float = 0.0
var _call_delay: float = 2.0
var _has_called: bool = false
var _patrol_angle: float = 0.0
var _patrol_origin: Vector2


func _ready() -> void:
	super._ready()
	add_to_group("correction_enemies")
	add_to_group("drone_enemies")
	target_player = null
	SPEED = patrol_speed
	_patrol_origin = global_position


func _physics_process(delta: float) -> void:
	if is_die:
		return

	# 巡逻：圆周运动
	if not _is_alerted:
		_patrol_angle += delta * 0.5
		var target: Vector2 = _patrol_origin + Vector2(cos(_patrol_angle) * 80.0, sin(_patrol_angle) * 50.0)
		var dir: Vector2 = global_position.direction_to(target)
		velocity = dir * patrol_speed
		target_player = null
	else:
		# 追击玩家
		if Utils.player and is_instance_valid(Utils.player):
			var dir: Vector2 = global_position.direction_to(Utils.player.global_position)
			velocity = dir * chase_speed
			target_player = Utils.player
			# 呼叫支援倒计时
			if not _has_called:
				_alert_timer += delta
				if _alert_timer >= _call_delay:
					_call_reinforcements()
		else:
			velocity = Vector2.ZERO

	super._physics_process(delta)

	# 检查玩家是否进入检测范围
	if Utils.player and is_instance_valid(Utils.player) and not _is_alerted:
		var dist: float = global_position.distance_to(Utils.player.global_position)
		if dist < detection_range:
			_is_alerted = true
			Utils.showToast("⚠ 无人机发现你！")


func _call_reinforcements() -> void:
	if _has_called or is_die:
		return
	_has_called = true
	if is_instance_valid(AlertServer):
		AlertServer.add_noise(reinforce_alert, "drone_reinforce")
	Utils.showToast("🚨 无人机呼叫了支援！")
	if Utils.player and is_instance_valid(Utils.player):
		var patrol_scene: PackedScene = preload("res://game/correction/enemies/PatrolGuard.tscn")
		if patrol_scene:
			for i in range(2):
				var offset: Vector2 = Vector2(randf_range(-80, 80), randf_range(-80, 80))
				var patrol: PatrolGuard = patrol_scene.instantiate()
				patrol.global_position = Utils.player.global_position + offset
				get_parent().add_child(patrol)


func onDie(is_death_effect := true) -> void:
	EventBus.enemy_killed.emit("surveillance_drone", global_position)
	super.onDie(is_death_effect)
