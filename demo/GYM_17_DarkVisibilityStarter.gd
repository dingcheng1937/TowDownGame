extends Node2D
## GYM_17_DarkVisibility - 黑暗视野系统验证
## 验证：PointLight2D 视野锥、LightOccluder2D 墙壁阴影、理智联动光照、CanvasModulate 暗化

const AtmosphereControllerPre = preload("res://game/atmosphere/AtmosphereController.gd")
const SanityBarPre = preload("res://ui/weird/SanityBar.tscn")
const ShadePre = preload("res://game/monster/weird/Shade.tscn")
const SanityPotionPre = preload("res://game/loot/SanityPotion.tscn")

func _ready():
	add_to_group("world")
	await get_tree().process_frame

	# 初始化游戏
	Utils.gameStart()
	Utils.player = $PlayerRoot/Hero

	# 初始化理智系统
	SanityServer.reset_sanity()
	SanityServer.start_drain()

	# 创建氛围控制器
	var atmosphere = AtmosphereControllerPre.new()
	add_child(atmosphere)

	# 创建UI
	_setup_ui()

	# 创建怪物
	_spawn_monsters()

	# 创建理智药剂
	_spawn_items()


func _spawn_monsters():
	var shade1 = ShadePre.instantiate()
	shade1.global_position = Vector2(500, 200)
	shade1.HP = 3
	shade1.SPEED = 100
	add_child(shade1)

	var shade2 = ShadePre.instantiate()
	shade2.global_position = Vector2(200, 400)
	shade2.HP = 3
	shade2.SPEED = 100
	add_child(shade2)


func _spawn_items():
	var potion1 = SanityPotionPre.instantiate()
	potion1.global_position = Vector2(350, 300)
	add_child(potion1)

	var potion2 = SanityPotionPre.instantiate()
	potion2.global_position = Vector2(600, 450)
	add_child(potion2)


func _setup_ui():
	var ui_root = get_node_or_null("UIRoot")
	if not ui_root:
		push_error("GYM_17: UIRoot node not found!")
		return

	Utils.canvasLayer = ui_root

	# 理智条
	var sanity_bar = SanityBarPre.instantiate()
	sanity_bar.position = Vector2(10, 10)
	ui_root.add_child(sanity_bar)


func _exit_tree():
	if Utils.canvasLayer == get_node_or_null("UIRoot"):
		Utils.canvasLayer = null
