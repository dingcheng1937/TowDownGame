extends Node
## 撤离系统管理
## 管理撤离条件、撤离点和撤离流程

signal extraction_available()
signal extraction_started()
signal extraction_completed()
signal extraction_failed(reason: String)
signal countdown_tick(time_remaining: float)

## 撤离条件类型
enum ExtractionCondition {
	TIME,        # 时间条件：在限定时间内撤离
	ITEM,        # 物品条件：收集特定物品
	KILL,        # 击杀条件：消灭指定数量敌人
	CUSTOM,      # 自定义条件
}

## 撤离状态
enum ExtractionState {
	UNAVAILABLE,  # 不可撤离
	AVAILABLE,    # 可以撤离
	IN_PROGRESS,  # 撤离中
	COMPLETED,    # 撤离完成
}

## 当前撤离状态
var current_state: ExtractionState = ExtractionState.UNAVAILABLE

## 撤离条件配置
var conditions: Dictionary = {
	"min_time": 30.0,       # 最少待够30秒
	"required_items": [],   # 需要的物品
	"required_kills": 0,    # 需要的击杀数
}

## 撤离倒计时
var countdown_time: float = 5.0
var initial_countdown_time: float = 5.0  # 存储初始倒计时时间
var countdown_timer: Timer

## 时间统计
var time_in_zone: float = 0.0
var kill_count: int = 0

## 撤离点引用
var extraction_points: Array[Node] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_timer()


func _setup_timer() -> void:
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 0.1
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)


func _process(delta: float) -> void:
	if Utils.is_game_start and current_state != ExtractionState.COMPLETED:
		time_in_zone += delta


## 检查撤离条件是否满足
func check_extraction_conditions() -> bool:
	# 检查时间条件
	if time_in_zone < conditions.get("min_time", 0):
		return false

	# 检查物品条件
	var required_items = conditions.get("required_items", [])
	for item_name in required_items:
		if not LootServer.has_item(item_name):
			return false

	# 检查击杀条件
	if kill_count < conditions.get("required_kills", 0):
		return false

	return true


## 更新撤离状态
func update_extraction_state() -> void:
	if current_state == ExtractionState.COMPLETED:
		return

	var was_available = current_state == ExtractionState.AVAILABLE
	var now_available = check_extraction_conditions()

	if now_available and not was_available:
		current_state = ExtractionState.AVAILABLE
		emit_signal("extraction_available")
		_activate_extraction_points()
	elif not now_available and was_available:
		current_state = ExtractionState.UNAVAILABLE
		_deactivate_extraction_points()


## 开始撤离倒计时
func start_extraction() -> void:
	if current_state != ExtractionState.AVAILABLE:
		emit_signal("extraction_failed", "撤离条件不满足")
		return

	current_state = ExtractionState.IN_PROGRESS
	countdown_timer.start()
	emit_signal("extraction_started")


## 取消撤离
func cancel_extraction() -> void:
	if current_state == ExtractionState.IN_PROGRESS:
		countdown_timer.stop()
		current_state = ExtractionState.AVAILABLE
		countdown_time = initial_countdown_time


## 完成撤离
func complete_extraction() -> void:
	countdown_timer.stop()
	current_state = ExtractionState.COMPLETED

	# 转移所有战利品
	LootServer.extract_all_loot()

	emit_signal("extraction_completed")


## 撤离失败
func fail_extraction(reason: String) -> void:
	countdown_timer.stop()
	current_state = ExtractionState.UNAVAILABLE
	emit_signal("extraction_failed", reason)


## 倒计时tick
func _on_countdown_tick() -> void:
	countdown_time -= 0.1
	emit_signal("countdown_tick", countdown_time)

	if countdown_time <= 0:
		complete_extraction()


## 注册击杀
func register_kill() -> void:
	kill_count += 1
	update_extraction_state()


## 注册撤离点
func register_extraction_point(point: Node) -> void:
	extraction_points.append(point)


## 激活撤离点
func _activate_extraction_points() -> void:
	for point in extraction_points:
		if point.has_method("activate"):
			point.call("activate")


## 停用撤离点
func _deactivate_extraction_points() -> void:
	for point in extraction_points:
		if point.has_method("deactivate"):
			point.call("deactivate")


## 重置撤离系统（新局开始时调用）
func reset() -> void:
	current_state = ExtractionState.UNAVAILABLE
	time_in_zone = 0.0
	kill_count = 0
	countdown_time = initial_countdown_time
	countdown_timer.stop()
	extraction_points.clear()


## 设置撤离条件
func set_conditions(min_time: float = 30.0, required_items: Array = [], required_kills: int = 0, countdown: float = 5.0) -> void:
	conditions = {
		"min_time": min_time,
		"required_items": required_items,
		"required_kills": required_kills,
	}
	initial_countdown_time = countdown
	countdown_time = countdown
