extends Node2D
## 附件系统DEMO启动器

func _ready():
	await get_tree().process_frame

	# 触发游戏启动（使用原游戏方式）
	Utils.gameStart()

	# 设置鼠标模式（射击需要，参考 SnowWorld.gd）
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	Utils.player = $PlayerRoot/Hero

	# 给玩家添加武器（使用原游戏方式）
	var uzi = preload("res://game/guns/Uzi.tscn").instantiate()
	PlayerData.add_weapon(uzi)
