extends BaseMonster
class_name TreatmentDirector
## 治疗主任 - Boss。3阶段 / 3技能。

enum Phase { PHASE_1, PHASE_2, PHASE_3 }

@export var base_hp: float = 20.0
@export var base_speed: float = 40.0
@export var melee_damage: float = 2.0
@export var chase_range: float = 350.0

# 技能参数
var _sedation_slow: float = -0.5
var _sedation_time: float = 4.0
var _restraint_slow: float = -0.8
var _restraint_time: float = 2.0
var _skill_cooldown: float = 3.0
var _skill_ready: bool = true

var _phase: Phase = Phase.PHASE_1
var _aggro: bool = false

## 本地引用避免路径崩溃
var _health_bar: ProgressBar
var _boss_label: Label
var _skill_timer: Timer


func _ready() -> void:
	super._ready()
	is_boss = true
	HP = int(base_hp)
	SPEED = base_speed
	target_player = null
	add_to_group("correction_enemies")
	add_to_group("boss_enemies")
	_phase = Phase.PHASE_1
	_skill_ready = true

	# 查找或创建 UI 节点（不依赖 onready，避免缺少节点崩溃）
	_health_bar = get_node_or_null("HealthBar") as ProgressBar
	_boss_label = get_node_or_null("BossNameLabel") as Label

	if _health_bar:
		_health_bar.max_value = HP
		_health_bar.value = HP
		_health_bar.visible = false

	if _boss_label:
		_boss_label.visible = false

	# 技能冷却定时器
	_skill_timer = Timer.new()
	_skill_timer.one_shot = true
	_skill_timer.wait_time = _skill_cooldown
	_skill_timer.timeout.connect(func(): _skill_ready = true)
	add_child(_skill_timer)


func _physics_process(delta: float) -> void:
	if is_die:
		return

	_update_phase()

	if not _aggro and Utils.player and is_instance_valid(Utils.player):
		var dist: float = global_position.distance_to(Utils.player.global_position)
		if dist < chase_range:
			_aggro = true
			if _health_bar: _health_bar.visible = true
			if _boss_label: _boss_label.visible = true

	if _aggro and Utils.player and is_instance_valid(Utils.player):
		var dist: float = global_position.distance_to(Utils.player.global_position)
		target_player = Utils.player

		if dist < 45.0:
			velocity = Vector2.ZERO
			if _skill_ready:
				_use_skill()
		else:
			var dir: Vector2 = global_position.direction_to(Utils.player.global_position)
			velocity = dir * SPEED
	else:
		velocity = Vector2.ZERO

	if not is_atk and not hit:
		# 手动处理 move_and_slide（不依赖 super 的 _on_velocity_computed）
		move_and_slide()
	else:
		super._physics_process(delta)


func _update_phase() -> void:
	var pct: float = float(HP) / base_hp
	if pct <= 0.3:
		_phase = Phase.PHASE_3
	elif pct <= 0.6:
		_phase = Phase.PHASE_2


func _use_skill() -> void:
	_skill_ready = false
	_skill_timer.wait_time = _skill_cooldown
	_skill_timer.start()

	match _phase:
		Phase.PHASE_1:
			_sedation_injection()
		Phase.PHASE_2:
			if randi() % 2 == 0:
				_sedation_injection()
			else:
				_restraint_bind()
		Phase.PHASE_3:
			var r: int = randi() % 3
			if r == 0: _sedation_injection()
			elif r == 1: _restraint_bind()
			else: _call_reinforcements()


func _sedation_injection() -> void:
	if not Utils.player or not is_instance_valid(Utils.player):
		return
	Utils.showToast("💉 治疗主任使用了镇静针！")
	PlayerData.player_speed += _sedation_slow
	if Utils.player.has_method("updateHero"): Utils.player.updateHero()
	await get_tree().create_timer(_sedation_time).timeout
	if is_instance_valid(Utils.player) and Utils.player.has_method("updateHero"):
		PlayerData.player_speed -= _sedation_slow
		Utils.player.updateHero()


func _restraint_bind() -> void:
	if not Utils.player or not is_instance_valid(Utils.player):
		return
	Utils.showToast("⛓ 治疗主任使用了约束带！")
	PlayerData.player_speed += _restraint_slow
	if Utils.player.has_method("updateHero"): Utils.player.updateHero()
	await get_tree().create_timer(_restraint_time).timeout
	if is_instance_valid(Utils.player) and Utils.player.has_method("updateHero"):
		PlayerData.player_speed -= _restraint_slow
		Utils.player.updateHero()


func _call_reinforcements() -> void:
	Utils.showToast("📟 治疗主任呼叫了支援！")
	var patrol_scene: PackedScene = preload("res://game/correction/enemies/PatrolGuard.tscn")
	if patrol_scene and Utils.player and is_instance_valid(Utils.player):
		for i in range(2):
			var p: PatrolGuard = patrol_scene.instantiate()
			p.global_position = Utils.player.global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
			get_parent().add_child(p)


func onHit(hit_num: float, is_show_label := true, is_death_effect := true) -> void:
	super.onHit(hit_num, is_show_label, is_death_effect)
	if _health_bar: _health_bar.value = HP


func onDie(is_death_effect := true) -> void:
	is_die = true
	EventBus.boss_defeated.emit("treatment_director")
	EventBus.enemy_killed.emit("treatment_director", global_position)
	Utils.showToast("治疗主任被击败！")
	_drop_key_card()
	if is_instance_valid(ExtractionServer):
		ExtractionServer.set_conditions(0.0, ["主任钥匙卡"], 0, 5.0)
		ExtractionServer.update_extraction_state()
	super.onDie(is_death_effect)


func _drop_key_card() -> void:
	var keycard_scene: PackedScene = preload("res://game/correction/items/KeyCardPickup.tscn")
	if keycard_scene:
		var kc: Area2D = keycard_scene.instantiate()
		kc.global_position = global_position + Vector2(0, -20)
		get_parent().add_child(kc)
