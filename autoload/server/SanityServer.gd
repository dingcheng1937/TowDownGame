extends Node
## 理智系统管理服务器
## 管理玩家理智值，触发疯狂效果

signal sanity_changed(current: float, max: float)
signal sanity_threshold_crossed(threshold: String)
signal sanity_depleted()

## 理智状态枚举
enum SanityState {
	NORMAL,      # 75-100: 正常
	MILD,        # 50-75: 轻微影响
	MODERATE,    # 25-50: 中等影响
	SEVERE,      # 0-25: 严重影响
}

var max_sanity: float = 100.0
var current_sanity: float = 100.0:
	set(value):
		var old = current_sanity
		current_sanity = clamp(value, 0.0, max_sanity)
		if old != current_sanity:
			emit_signal("sanity_changed", current_sanity, max_sanity)
			_check_thresholds(old, current_sanity)

var passive_drain_rate: float = 0.5  # 每秒自然流失
var is_draining: bool = false
var current_state: SanityState = SanityState.NORMAL


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if is_draining and Utils.is_game_start:
		change_sanity(-passive_drain_rate * delta)


## 改变理智值
func change_sanity(amount: float) -> void:
	current_sanity += amount


## 设置理智值
func set_sanity(value: float) -> void:
	current_sanity = value


## 重置理智
func reset_sanity() -> void:
	current_sanity = max_sanity
	current_state = SanityState.NORMAL
	is_draining = false


## 开始理智流失
func start_drain() -> void:
	is_draining = true


## 停止理智流失
func stop_drain() -> void:
	is_draining = false


## 获取当前理智状态
func get_sanity_state() -> SanityState:
	if current_sanity >= 75:
		return SanityState.NORMAL
	elif current_sanity >= 50:
		return SanityState.MILD
	elif current_sanity >= 25:
		return SanityState.MODERATE
	else:
		return SanityState.SEVERE


## 获取理智百分比
func get_sanity_percent() -> float:
	return current_sanity / max_sanity


## 检查理智阈值
func _check_thresholds(old: float, new: float) -> void:
	# 检查下降阈值
	if old >= 75 and new < 75:
		current_state = SanityState.MILD
		emit_signal("sanity_threshold_crossed", "mild")
	elif old >= 50 and new < 50:
		current_state = SanityState.MODERATE
		emit_signal("sanity_threshold_crossed", "moderate")
	elif old >= 25 and new < 25:
		current_state = SanityState.SEVERE
		emit_signal("sanity_threshold_crossed", "severe")

	# 检查回升阈值
	elif old < 25 and new >= 25:
		current_state = SanityState.MODERATE
		emit_signal("sanity_threshold_crossed", "recovered_moderate")
	elif old < 50 and new >= 50:
		current_state = SanityState.MILD
		emit_signal("sanity_threshold_crossed", "recovered_mild")
	elif old < 75 and new >= 75:
		current_state = SanityState.NORMAL
		emit_signal("sanity_threshold_crossed", "recovered_normal")

	# 检查完全耗尽
	if new <= 0:
		emit_signal("sanity_depleted")
