extends BaseMonster
class_name BaseBossMonster
## Boss 基类 — 阶段切换/技能系统/演出触发

signal phase_changed(phase_index: int)
signal skill_used(skill_name: String)

@export var phases: Array[BossPhase] = []
@export var detection_range: float = 400.0

var current_phase_index: int = 0
var _aggro: bool = false
var _skill_cooldowns: Dictionary = {}
var _initial_hp: float = 5.0

func _ready() -> void:
	super._ready()
	is_boss = true
	add_to_group("correction_survival_enemies")
	add_to_group("boss_enemies")
	_initial_hp = HP

func _physics_process(delta: float) -> void:
	if is_die:
		return
	# 检测玩家进入Boss触发范围
	if not _aggro and Utils.player and is_instance_valid(Utils.player):
		if global_position.distance_to(Utils.player.global_position) < detection_range:
			_aggro = true
			_initial_hp = HP  # 记录进入战斗时的HP作为基准
			_on_aggro()
	if _aggro and Utils.player and is_instance_valid(Utils.player):
		target_player = Utils.player
		var dist = global_position.distance_to(Utils.player.global_position)
		if dist < 40.0:
			if not is_atk:
				_basic_attack()
		else:
			velocity = global_position.direction_to(Utils.player.global_position) * SPEED
	# 检查阶段切换
	_check_phase_transition()
	super._physics_process(delta)

func _check_phase_transition() -> void:
	if _initial_hp <= 0:
		return
	var hp_pct: float = float(HP) / _initial_hp
	for i in range(phases.size()):
		if hp_pct <= phases[i].hp_threshold and i > current_phase_index:
			_switch_phase(i)
			break

func _switch_phase(index: int) -> void:
	current_phase_index = index
	var phase: BossPhase = phases[index]
	SPEED *= phase.speed_multiplier
	phase_changed.emit(index)
	if phase.has_cutscene:
		EventBus.cutscene_started.emit("boss_phase_" + str(index))

func _on_aggro() -> void:
	EventBus.cutscene_started.emit("boss_intro")
	Utils.showToast("Boss 战开始！")

func _basic_attack() -> void:
	if is_atk:
		return
	is_atk = true
	if target_player and is_instance_valid(target_player):
		target_player.onHit(hurt)
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(self) and not is_die:
		is_atk = false
