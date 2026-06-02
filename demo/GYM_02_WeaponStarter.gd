extends Node2D
## 武器系统DEMO启动器

func _ready():
	await get_tree().process_frame

	# 初始化玩家数据
	PlayerData.player_hp = 100
	PlayerData.player_hp_max = 100

	# 触发游戏启动（使用原游戏方式）
	Utils.gameStart()

	# 设置鼠标模式（射击需要，参考 SnowWorld.gd）
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN

	# 设置玩家引用
	Utils.player = $PlayerRoot/Hero

	# 给玩家添加武器（使用原游戏方式）
	var uzi = preload("res://game/guns/Uzi.tscn").instantiate()
	PlayerData.add_weapon(uzi)

	# 设置怪物数据
	for monster in $MonstersRoot.get_children():
		monster.setData({
			'speed': 30.0,
			'hurt': 1,
			'hp': 10
		})

	# 添加游戏UI（准星、弹药、血量等）
	_setup_ui()


func _setup_ui():
	# 场景中已有ControlUI实例，直接使用
	var control_ui = $ControlUI

	# ControlUI会自动设置Utils.canvasLayer并监听信号
	# 显示游戏内UI（隐藏主菜单）
	control_ui.get_node("GameUI").show()
	control_ui.get_node("MainUI").hide()
