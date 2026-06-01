extends Node2D
## 准星UI DEMO启动器

func _ready():
	await get_tree().process_frame
	Utils.gameStart()
	Utils.player = $PlayerRoot/Hero
