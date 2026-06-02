extends Node2D
## GYM_11_WeirdLoot - 诡异搜打撤系统验证
## 验证：理智系统、战利品系统、撤离系统、诡异怪物

const ShadePre = preload("res://game/monster/weird/Shade.tscn")
const WhispererPre = preload("res://game/monster/weird/Whisperer.tscn")
const AberrationPre = preload("res://game/monster/weird/Aberration.tscn")
const ExtractionPointPre = preload("res://game/extraction/ExtractionPoint.tscn")
const SanityPotionPre = preload("res://game/loot/SanityPotion.tscn")
const MysteriousArtifactPre = preload("res://game/loot/MysteriousArtifact.tscn")
const SanityBarPre = preload("res://ui/weird/SanityBar.tscn")
const ExtractionStatusPre = preload("res://ui/weird/ExtractionStatus.tscn")
const LootInventoryUIPre = preload("res://ui/weird/LootInventoryUI.tscn")
const AtmosphereControllerPre = preload("res://game/atmosphere/AtmosphereController.gd")

func _ready():
	add_to_group("world")
	await get_tree().process_frame

	# 初始化游戏
	Utils.gameStart()
	Utils.player = $PlayerRoot/Hero

	# 初始化撤离系统
	ExtractionServer.reset()
	ExtractionServer.set_conditions(30.0, [], 0)  # 待够30秒可撤离

	# 初始化理智系统
	SanityServer.reset_sanity()
	SanityServer.start_drain()

	# 创建撤离点
	var extraction_point = ExtractionPointPre.instantiate()
	extraction_point.position = Vector2(600, 300)
	add_child(extraction_point)

	# 创建诡异怪物
	_spawn_weird_monsters()

	# 创建战利品
	_spawn_loot_items()

	# 创建UI
	_setup_ui()

	# 创建氛围控制器
	var atmosphere = AtmosphereControllerPre.new()
	add_child(atmosphere)


func _spawn_weird_monsters():
	# 创建残影
	var shade1 = ShadePre.instantiate()
	shade1.global_position = Vector2(200, 200)
	shade1.HP = 2
	shade1.SPEED = 120
	add_child(shade1)

	var shade2 = ShadePre.instantiate()
	shade2.global_position = Vector2(300, 400)
	shade2.HP = 2
	shade2.SPEED = 120
	add_child(shade2)

	# 创建低语者
	var whisperer = WhispererPre.instantiate()
	whisperer.global_position = Vector2(500, 150)
	whisperer.HP = 4
	whisperer.SPEED = 50
	add_child(whisperer)

	# 创建畸变体
	var aberration = AberrationPre.instantiate()
	aberration.global_position = Vector2(150, 350)
	aberration.HP = 15
	aberration.SPEED = 30
	add_child(aberration)


func _spawn_loot_items():
	# 创建理智药剂
	var potion1 = SanityPotionPre.instantiate()
	potion1.global_position = Vector2(350, 300)
	add_child(potion1)

	var potion2 = SanityPotionPre.instantiate()
	potion2.global_position = Vector2(450, 400)
	add_child(potion2)

	# 创建神秘神器
	var artifact = MysteriousArtifactPre.instantiate()
	artifact.global_position = Vector2(250, 250)
	add_child(artifact)


func _setup_ui():
	var ui_root = get_node_or_null("UIRoot")
	if not ui_root:
		push_error("GYM_11: UIRoot node not found!")
		return

	# 理智条
	var sanity_bar = SanityBarPre.instantiate()
	sanity_bar.position = Vector2(10, 10)
	ui_root.add_child(sanity_bar)

	# 撤离状态
	var extraction_status = ExtractionStatusPre.instantiate()
	ui_root.add_child(extraction_status)

	# 战利品背包
	var loot_inventory = LootInventoryUIPre.instantiate()
	ui_root.add_child(loot_inventory)


func _process(_delta):
	# 定期检查撤离条件
	ExtractionServer.update_extraction_state()
