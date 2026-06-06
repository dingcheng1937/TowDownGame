extends Node2D
## 武器列表UI DEMO启动器

const ControlUIPre = preload("res://ui/ControlUI.tscn")

func _ready():
	await get_tree().process_frame

	# 添加游戏UI（必须在添加武器之前，以便GameUI能监听到信号）
	_setup_ui()

	# 触发游戏启动（使用原游戏方式）
	Utils.gameStart()

	Utils.player = $PlayerRoot/Hero

	# 添加所有武器测试（使用原游戏方式）
	var weapons = [
		preload("res://game/guns/ShotgunBlaster.tscn").instantiate(),
		preload("res://game/guns/Sniper.tscn").instantiate(),
		preload("res://game/guns/BabyZapZap.tscn").instantiate(),
		preload("res://game/guns/AlienRifle.tscn").instantiate(),
		preload("res://game/guns/EmpireShotgun.tscn").instantiate(),
		preload("res://game/guns/BoomBoi.tscn").instantiate(),
		preload("res://game/guns/AlienMachine.tscn").instantiate(),
		preload("res://game/guns/RebalShotgun.tscn").instantiate(),
		preload("res://game/guns/Uzi.tscn").instantiate()
	]
	PlayerData.add_weapons(weapons)


func _setup_ui():
	var control_ui = ControlUIPre.instantiate()
	$UIRoot.add_child(control_ui)
	control_ui.get_node("GameUI").show()
	control_ui.get_node("MainUI").hide()
