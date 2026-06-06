extends Node2D
## 背包UI DEMMO启动器

const weapon_inventory = preload("res://ui/Inventory.tscn")

var inv_ui = null

func _ready():
	await get_tree().process_frame

	# 先显示ControlUI（确保GameUI创建并监听信号）
	var control_ui = $ControlUI
	control_ui.get_node("GameUI").show()
	control_ui.get_node("MainUI").hide()

	await get_tree().process_frame

	Utils.gameStart()
	Utils.player = $PlayerRoot/Hero

	# 给玩家添加武器，确保Inventory能正确获取gun引用
	var uzi = preload("res://game/guns/Uzi.tscn").instantiate()
	PlayerData.add_weapon(uzi)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("inv") && Utils.is_game_start && !is_instance_valid(inv_ui):
		if Utils.player.gun == null:
			print("PLEASE PURCHASE A WEAPON FIRST")
		else:
			Utils.crosshairChange(false)
			inv_ui = weapon_inventory.instantiate()
			add_child(inv_ui)
