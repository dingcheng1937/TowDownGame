extends Node2D
## 武器列表UI DEMO启动器

const ControlUIPre = preload("res://ui/ControlUI.tscn")

func _ready():
	await get_tree().process_frame

	# 触发游戏启动（使用原游戏方式）
	Utils.gameStart()

	Utils.player = $PlayerRoot/Hero

	# 添加多把武器测试（使用原游戏方式）
	var weapons = [
		preload("res://game/guns/Uzi.tscn").instantiate(),
		preload("res://game/guns/Sniper.tscn").instantiate(),
		preload("res://game/guns/ShotgunBlaster.tscn").instantiate(),
		preload("res://game/guns/AlienRifle.tscn").instantiate(),
		preload("res://game/guns/BoomBoi.tscn").instantiate()
	]
	PlayerData.add_weapons(weapons)

	# 添加游戏UI
	_setup_ui()


func _setup_ui():
	var control_ui = ControlUIPre.instantiate()
	$UIRoot.add_child(control_ui)
	control_ui.get_node("GameUI").show()
	control_ui.get_node("MainUI").hide()
