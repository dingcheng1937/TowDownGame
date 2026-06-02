extends Node2D
## 怪物系统DEMO启动器

const ControlUIPre = preload("res://ui/ControlUI.tscn")

func _ready():
	await get_tree().process_frame

	# 初始化玩家数据
	PlayerData.player_hp = 50
	PlayerData.player_hp_max = 100

	# 触发游戏启动（使用原游戏方式）
	Utils.gameStart()

	# 设置玩家引用
	Utils.player = $PlayerRoot/Hero

	# 添加游戏UI
	_setup_ui()

	# 怪物会自动追踪 Utils.player


func _setup_ui():
	var control_ui = ControlUIPre.instantiate()
	$UIRoot.add_child(control_ui)
	control_ui.get_node("GameUI").show()
	control_ui.get_node("MainUI").hide()
