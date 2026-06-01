extends Node2D
class_name AtmosphereController
## 氛围控制器 - 根据理智状态调整游戏视觉效果

## 世界环境节点
@export var world_environment: WorldEnvironment

## 当前理智等级
var _current_sanity_level: float = 100.0

## 效果强度
var _effect_intensity: float = 0.0


func _ready() -> void:
	# 连接理智变化信号
	SanityServer.sanity_changed.connect(_on_sanity_changed)
	SanityServer.sanity_threshold_crossed.connect(_on_threshold_crossed)

	_setup_environment()


func _setup_environment() -> void:
	if not world_environment:
		world_environment = WorldEnvironment.new()
		add_child(world_environment)

	# 创建环境资源
	var env = Environment.new()
	world_environment.environment = env


func _on_sanity_changed(current: float, _max_val: float) -> void:
	_current_sanity_level = current
	_update_visual_effects()


func _on_threshold_crossed(threshold: String) -> void:
	# 触发阈值效果
	match threshold:
		"mild":
			_trigger_mild_effects()
		"moderate":
			_trigger_moderate_effects()
		"severe":
			_trigger_severe_effects()
		"recovered_normal":
			_clear_effects()


func _update_visual_effects() -> void:
	var sanity_percent = _current_sanity_level / 100.0

	# 根据理智调整色调
	if sanity_percent > 0.75:
		# 正常状态
		_adjust_environment(1.0, 1.0, 1.0)
		_effect_intensity = 0.0
	elif sanity_percent > 0.5:
		# 轻微影响
		_adjust_environment(1.1, 0.95, 0.95)
		_effect_intensity = 0.25
	elif sanity_percent > 0.25:
		# 中等影响
		_adjust_environment(1.2, 0.85, 0.85)
		_effect_intensity = 0.5
	else:
		# 严重影响
		_adjust_environment(1.4, 0.7, 0.7)
		_effect_intensity = 1.0


func _adjust_environment(contrast: float, saturation: float, brightness: float) -> void:
	# 通过环境设置调整
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.adjustment_enabled = true
		env.adjustment_contrast = contrast
		env.adjustment_saturation = saturation
		env.adjustment_brightness = brightness - 0.1


func _trigger_mild_effects() -> void:
	Utils.showToast("你感到不安...")


func _trigger_moderate_effects() -> void:
	Utils.showToast("幻觉开始出现...")


func _trigger_severe_effects() -> void:
	Utils.showToast("理智即将崩溃！")


func _clear_effects() -> void:
	Utils.showToast("理智恢复正常")
