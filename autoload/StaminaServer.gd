extends Node
## 体力系统 — 跑步消耗/站立恢复/归零不能冲刺

signal stamina_changed(current: float, max: float)

@export var max_stamina: float = 100.0
@export var consume_rate: float = 20.0   # 每秒消耗
@export var recover_rate: float = 10.0   # 每秒恢复

var current_stamina: float = 100.0:
	set(val):
		current_stamina = clampf(val, 0.0, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)
		PlayerData.stamina = current_stamina

var is_exhausted: bool:
	get: return current_stamina <= 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if Utils.player and Utils.player.is_run and not is_exhausted:
		current_stamina -= consume_rate * delta
	elif not (Utils.player and Utils.player.is_run):
		current_stamina += recover_rate * delta

func reset() -> void:
	current_stamina = max_stamina
