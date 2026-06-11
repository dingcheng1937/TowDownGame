extends Node
## 警戒值系统 - "禁止制造噪音"规则的核心实现
##
## 奔跑、攻击、打碎物体增加警戒值。
## 警戒值达到阈值触发巡逻员刷新、无人机巡逻。
## 警戒值随时间自然衰减。
##
## 作为Autoload注册，保证全局唯一。

signal alert_changed(current_alert: float, max_alert: float)
signal alert_threshold_crossed(threshold: AlertThreshold)
signal noise_made(noise_amount: float, reason: String)
signal alert_settled()  ## 警戒值降至0时触发

## 警戒阈值枚举
enum AlertThreshold {
	NORMAL,      ## 0-30: 正常状态
	WATCHFUL,    ## 30-60: 警惕 - 巡逻员开始警觉
	ALARM,       ## 60-80: 警报 - 无人机开始巡逻
	LOCKDOWN     ## 80-100: 封锁 - 大量敌人刷新
}

## 警戒等级显示名称
const THRESHOLD_NAMES: Dictionary = {
	AlertThreshold.NORMAL: "正常",
	AlertThreshold.WATCHFUL: "警惕",
	AlertThreshold.ALARM: "警报",
	AlertThreshold.LOCKDOWN: "封锁"
}

## 最大警戒值
const MAX_ALERT: float = 100.0

## 噪声量级常量（方便平衡调整）
const NOISE_RUNNING: float = 5.0       ## 奔跑每tick
const NOISE_MELEE_ATTACK: float = 15.0  ## 近战攻击每次
const NOISE_BREAK_OBJECT: float = 20.0  ## 打碎物体每次
const NOISE_THROW: float = 10.0         ## 投掷物
const NOISE_GUNSHOT: float = 30.0       ## 枪声

## 警戒衰减速率（每秒）
const DECAY_RATE: float = 3.0

## 当前警戒值
var current_alert: float = 0.0:
	set(value):
		var old_value: float = current_alert
		current_alert = clampf(value, 0.0, MAX_ALERT)
		if not is_equal_approx(old_value, current_alert):
			emit_signal("alert_changed", current_alert, MAX_ALERT)
			_check_threshold_transition(old_value)

## 当前阈值级别
var current_threshold: AlertThreshold = AlertThreshold.NORMAL

## 是否启用警戒系统
var is_active: bool = false

var _is_decaying: bool = false
var _decay_timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_decay_timer = Timer.new()
	_decay_timer.wait_time = 1.0
	_decay_timer.timeout.connect(_on_decay_tick)
	add_child(_decay_timer)


## 初始化警戒系统（每局开始调用）
func initialize() -> void:
	current_alert = 0.0
	current_threshold = AlertThreshold.NORMAL
	is_active = true
	_decay_timer.start()


## 停止警戒系统（撤离或死亡时调用）
func stop() -> void:
	is_active = false
	_decay_timer.stop()


## 添加噪声
func add_noise(amount: float, reason: String = "unknown") -> void:
	if not is_active:
		return

	current_alert += amount
	emit_signal("noise_made", amount, reason)
	
	# 如果是大于10的噪声，触发一次冻结帧效果增强反馈
	if amount >= 15.0:
		Utils.freezeFrame(0.05)


## 快速添加常见噪声类型
func add_running_noise() -> void:
	add_noise(NOISE_RUNNING, "running")

func add_melee_attack_noise() -> void:
	add_noise(NOISE_MELEE_ATTACK, "melee_attack")

func add_break_object_noise() -> void:
	add_noise(NOISE_BREAK_OBJECT, "break_object")

func add_throw_noise() -> void:
	add_noise(NOISE_THROW, "throw")

func add_gunshot_noise() -> void:
	add_noise(NOISE_GUNSHOT, "gunshot")


## 获取当前阈值
func get_current_threshold() -> AlertThreshold:
	_update_threshold()
	return current_threshold


## 获取阈值名称（用于UI显示）
func get_threshold_name() -> String:
	return THRESHOLD_NAMES.get(get_current_threshold(), "未知")


## 获取警戒百分比
func get_alert_percent() -> float:
	return current_alert / MAX_ALERT


## 警戒是否处于高危状态（警戒值 >= 60）
func is_high_alert() -> bool:
	return current_alert >= float(AlertThreshold.ALARM) * 30.0 + 30.0


## 检查阈值转换并触发事件
func _check_threshold_transition(old_value: float) -> void:
	_update_threshold()

	# 仅在阈值真正变化时触发事件
	var old_threshold: AlertThreshold = _get_threshold_for_value(old_value)
	if old_threshold != current_threshold:
		# 检查是否上升到了封锁级别
		if current_threshold == AlertThreshold.LOCKDOWN:
			Utils.showToast("⚠ 封锁状态已激活！")
		elif current_threshold == AlertThreshold.ALARM:
			Utils.showToast("⚠ 无人机开始巡逻")
		elif current_threshold == AlertThreshold.WATCHFUL:
			Utils.showToast("⚠ 巡逻员开始警觉")
		elif old_threshold > current_threshold and current_threshold == AlertThreshold.NORMAL:
			Utils.showToast("警戒已解除")
			emit_signal("alert_settled")

		emit_signal("alert_threshold_crossed", current_threshold)


## 根据警戒值获取对应阈值
func _get_threshold_for_value(value: float) -> AlertThreshold:
	if value >= 80.0:
		return AlertThreshold.LOCKDOWN
	elif value >= 60.0:
		return AlertThreshold.ALARM
	elif value >= 30.0:
		return AlertThreshold.WATCHFUL
	else:
		return AlertThreshold.NORMAL


## 更新当前阈值
func _update_threshold() -> void:
	current_threshold = _get_threshold_for_value(current_alert)


## 警戒值每秒衰减
func _on_decay_tick() -> void:
	if not is_active or Utils.player == null:
		return

	# 仅在玩家存活且游戏运行时衰减
	if Utils.player.is_dead:
		return

	if current_alert > 0.0:
		current_alert -= DECAY_RATE
