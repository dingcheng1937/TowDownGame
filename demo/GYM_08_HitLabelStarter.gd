extends Node2D
## 伤害数字UI DEMO启动器

var colors = [Color.WHITE, Color.RED, Color.YELLOW, Color.GREEN, Color.CYAN]

func _ready():
	await get_tree().process_frame
	Utils.gameStart()
	Utils.player = $PlayerRoot/Hero

func _input(_event):
	if _event is InputEventMouseButton and _event.pressed:
		var spawn_point = $SpawnPoint
		var damage = randi_range(1, 99)
		var color = colors[randi() % colors.size()]
		Utils.showHitLabelMore(str(damage), spawn_point, Vector2(randf_range(-30, 30), 0), color)
