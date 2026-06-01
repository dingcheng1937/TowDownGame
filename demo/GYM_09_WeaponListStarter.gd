extends Node2D
## 武器列表UI DEMO启动器

func _ready():
	await get_tree().process_frame

	# 触发游戏启动（使用原游戏方式）
	Utils.gameStart()

	# 设置鼠标模式（射击需要，参考 SnowWorld.gd）
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
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
