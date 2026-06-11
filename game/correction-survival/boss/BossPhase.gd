extends Resource
class_name BossPhase
## Boss 阶段数据

@export var hp_threshold: float = 1.0     # HP比例阈值（1.0=100%）
@export var speed_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var phase_name: String = ""
@export var available_skills: Array[String] = []
@export var has_cutscene: bool = false
