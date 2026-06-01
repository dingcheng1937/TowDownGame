extends Node2D
## 装备系统DEMO启动器

const CannonPre = preload("res://game/equip/High-Energy Particle Cannon.tscn")

func _ready():
	add_to_group("world")
	await get_tree().process_frame

	Utils.gameStart()
	Utils.player = $PlayerRoot/Hero

	# 在地上创建装备供玩家拾取
	var cannon = CannonPre.instantiate()
	EquipServer.addEquipOnFloor(cannon, Vector2(500, 300))

func addEquip(ins):
	$EquipRoot.add_child(ins)
