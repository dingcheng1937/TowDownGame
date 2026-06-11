extends Node2D
## GYM_14 Health Demo - 演示玩家血量系统交互
## - 按键扣血（J键）
## - 地面陷阱扣血
## - 拾取品回血
## - 使用项目已有UI显示血条

## 复用项目UI组件
const ControlUIPre = preload("res://ui/ControlUI.tscn")

## 按键扣血冷却时间（秒）
const DAMAGE_KEY_COOLDOWN: float = 0.5

## 上次扣血时间（用于冷却）
var _last_damage_time: float = 0.0

## 玩家引用
@onready var _player: Player = $PlayerRoot/Hero


func _ready() -> void:
	# 等待一帧确保所有节点初始化完成
	await get_tree().process_frame

	# 添加游戏UI（使用项目已有UI）
	_setup_ui()

	# 初始化玩家数据
	PlayerData.player_hp = 5
	PlayerData.player_hp_max = 10

	# 启动游戏系统
	Utils.gameStart()

	# 设置玩家引用
	Utils.player = _player

	# 配置血包
	_setup_health_packs()


func _setup_ui() -> void:
	## 使用项目已有的ControlUI
	var control_ui = ControlUIPre.instantiate()
	$UIRoot.add_child(control_ui)
	control_ui.get_node("GameUI").show()
	control_ui.get_node("MainUI").hide()


func _process(delta: float) -> void:
	# 检测 J 键扣血
	if Input.is_key_pressed(KEY_J):
		_apply_damage_from_key(delta)


func _apply_damage_from_key(delta: float) -> void:
	# 冷却检测
	_last_damage_time += delta
	if _last_damage_time < DAMAGE_KEY_COOLDOWN:
		return

	_last_damage_time = 0.0

	# 对玩家造成伤害
	if Utils.player and not Utils.player.is_dead:
		Utils.player.onHit(1)


func _setup_health_packs() -> void:
	# 配置血包实例的治疗值
	var items_root = $ItemsRoot
	if items_root:
		for child in items_root.get_children():
			if "hp" in child:
				if child.name == "HpPack1":
					child.hp = 1
				elif child.name == "HpPack2":
					child.hp = 2
