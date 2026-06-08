extends Node2D
## GYM_15_CorrectionCenter - 精神矫正中心 MVP 验证
## F6 独立运行即可体验完整循环

const HERO_SCENE := preload("res://game/hero/Hero.tscn")
const HUD_SCENE := preload("res://game/correction/ui/CorrectionHUD.tscn")

# 物品
const THROWABLE_ITEM := preload("res://game/correction/items/ThrowableItem.tscn")
const THROWABLE_PICKUP := preload("res://game/correction/items/ThrowablePickup.tscn")
const CONSUMABLE := preload("res://game/correction/items/ConsumablePickup.tscn")
const NARRATIVE := preload("res://game/correction/items/NarrativeLootItem.tscn")

# 近战武器
const STARTING_MELEE := preload("res://game/melee/WoodenChairLeg.tscn")
const MELEE_PICKUP := preload("res://game/correction/items/MeleeWeaponPickup.tscn")

# 氛围
const ATMOSPHERE_CTRL := preload("res://game/atmosphere/AtmosphereController.gd")

# 敌人
const PATROL := preload("res://game/correction/enemies/PatrolGuard.tscn")
const ENFORCER := preload("res://game/correction/enemies/SedationEnforcer.tscn")
const DRONE := preload("res://game/correction/enemies/SurveillanceDrone.tscn")
const BOSS := preload("res://game/correction/boss/TreatmentDirector.tscn")

# 区域
const ZONES := {
	"ward": Vector2(-400, 0),
	"living": Vector2(0, 0),
	"treatment": Vector2(400, 0),
	"admin": Vector2(800, 0),
}

var player: Player
var hud: CorrectionHUD
var extract_point: Node
var ready_flag: bool = false
var _spawned_thresholds: Array[int] = []


func _ready() -> void:
	_spawn_player()
	_equip_starting_weapon()
	_spawn_hud()
	_init_state()
	_place_items()
	_place_melee_pickups()
	_place_enemies()
	_place_boss()
	_place_extraction()
	_place_gates()
	_connect_signals()
	_setup_atmosphere()
	Utils.gameStart()
	ready_flag = true


# -- setup --

func _spawn_player() -> void:
	player = PlayerServer.player_scene
	if player:
		# 从场景中移除再添加
		if player.get_parent():
			player.get_parent().remove_child(player)
		add_child(player)
	else:
		player = HERO_SCENE.instantiate()
		add_child(player)
		Utils.player = player
	player.global_position = ZONES["ward"] + Vector2(0, 50)
	player.SPEED = 100.0
	PlayerData.player_hp_max = 5
	PlayerData.player_hp = 5
	PlayerData.gold = 100


func _spawn_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)


func _init_state() -> void:
	if is_instance_valid(AlertServer): AlertServer.initialize()
	if is_instance_valid(ExtractionServer):
		ExtractionServer.reset()
		ExtractionServer.set_conditions(0.0, ["主任钥匙卡"], 0, 5.0)
	if is_instance_valid(SanityServer): SanityServer.reset_sanity()
	if is_instance_valid(SanityServer): SanityServer.start_drain()
	PlayerData.set_meta("stone_count", 0)


func _place_items() -> void:
	# 病房区 - 白色药片 x2
	_cons("白色药片", ZONES["ward"] + Vector2(-30, -30), 2, 0, 0, 0, "请按时服用。")
	_cons("白色药片", ZONES["ward"] + Vector2(30, 30), 2, 0, 0, 0, "请按时服用。")
	# 生活区 - 蓝色药片 + 冷馒头 + 石子x3 + 餐盘x1
	_cons("蓝色药片", ZONES["living"] + Vector2(-50, -50), 3, 5, -0.2, 5, "副作用栏被撕掉了。")
	_cons("冷馒头", ZONES["living"] + Vector2(50, 50), 1, 0, 0, 0, "与昨日完全相同。")
	for i in range(3): _throw_pickup(ThrowableItem.ThrowableType.STONE, ZONES["living"] + Vector2(randf_range(-60, 60), randf_range(-40, 40)))
	_throw_pickup(ThrowableItem.ThrowableType.PLATE, ZONES["living"] + Vector2(80, -20))
	# 治疗区 - 镇静剂 + 药瓶x2
	_cons("镇静剂", ZONES["treatment"] + Vector2(-40, -60), 5, 10, -0.3, 8, "患者明显安静。")
	for i in range(2): _throw_pickup(ThrowableItem.ThrowableType.MEDICINE_BOTTLE, ZONES["treatment"] + Vector2(randf_range(-50, 50), randf_range(-40, 40)))
	# 叙事战利品
	_narr("全家福照片", "等你回来。", "family_photo", ZONES["living"] + Vector2(-70, -80))
	_narr("优秀单位奖状", "连续十五年零事故。", "award", ZONES["living"] + Vector2(70, 80))
	_narr("出院申请书", "审批状态：继续观察。", "discharge", ZONES["treatment"] + Vector2(-60, 70))
	_narr("举报信", "请勿重复提交。", "report", ZONES["treatment"] + Vector2(60, -70))
	_narr("销毁名单", "部分姓名已被涂黑。", "destruction", ZONES["admin"] + Vector2(-80, 0))


func _cons(name: String, pos: Vector2, heal: int, sanity: float, sm: float, sd: float, desc: String) -> void:
	var c: ConsumablePickup = CONSUMABLE.instantiate()
	c.item_name = name; c.global_position = pos; c.heal_amount = heal
	c.sanity_amount = sanity; c.speed_modifier = sm; c.speed_modifier_duration = sd
	c.description = desc; c.narrative_id = "cons_" + name
	add_child(c)


func _throw_pickup(type: ThrowableItem.ThrowableType, pos: Vector2) -> void:
	var tp: ThrowablePickup = THROWABLE_PICKUP.instantiate()
	tp.throwable_type = type; tp.global_position = pos
	match type:
		ThrowableItem.ThrowableType.STONE: tp.item_name = "石子"; tp.description = "很多人都试过。"
		ThrowableItem.ThrowableType.MEDICINE_BOTTLE: tp.item_name = "药瓶"; tp.description = "标签已经脱落。"
		ThrowableItem.ThrowableType.PLATE: tp.item_name = "餐盘"; tp.description = "今日菜单：无。"
	add_child(tp)


func _narr(name: String, desc: String, id: String, pos: Vector2) -> void:
	var n: NarrativeLootItem = NARRATIVE.instantiate()
	n.item_name = name; n.description = desc; n.narrative_id = id; n.narrative_text = desc
	n.global_position = pos
	add_child(n)


func _place_enemies() -> void:
	# 生活区
	for i in range(2):
		var p: PatrolGuard = PATROL.instantiate()
		p.global_position = ZONES["living"] + Vector2(randf_range(-80, 80), randf_range(-60, 60))
		p.SPEED = 40.0; p.HP = 3
		add_child(p)
	# 治疗区
	var p2: PatrolGuard = PATROL.instantiate()
	p2.global_position = ZONES["treatment"] + Vector2(-50, 0)
	p2.SPEED = 50.0; p2.HP = 4
	add_child(p2)
	var e: SedationEnforcer = ENFORCER.instantiate()
	e.global_position = ZONES["treatment"] + Vector2(80, 20)
	e.SPEED = 70.0; e.HP = 6
	add_child(e)
	var d: SurveillanceDrone = DRONE.instantiate()
	d.global_position = ZONES["treatment"] + Vector2(0, -120)
	add_child(d)


func _place_boss() -> void:
	var b: TreatmentDirector = BOSS.instantiate()
	b.global_position = ZONES["admin"] + Vector2(0, -20)
	b.HP = 20
	add_child(b)


func _place_extraction() -> void:
	extract_point = preload("res://game/extraction/ExtractionPoint.tscn").instantiate()
	extract_point.global_position = ZONES["admin"] + Vector2(150, 0)
	if extract_point.has_method("set_countdown"):
		extract_point.set("countdown_duration", 5.0)
	add_child(extract_point)


func _place_gates() -> void:
	var gt: PackedScene = preload("res://game/correction/zones/ZoneTrigger.tscn")

	var g1: ZoneTrigger = gt.instantiate()
	g1.global_position = Vector2(-200, 0); g1.target_zone_name = "生活区"
	g1.zone_hint = "你来到了生活区"; g1.narrative_hint_id = "living_intro"
	g1.narrative_hint_text = "食堂空旷无人。\n墙上的菜单写着同样的日期。"
	add_child(g1)

	var g2: ZoneTrigger = gt.instantiate()
	g2.global_position = Vector2(200, 0); g2.target_zone_name = "治疗区"
	g2.zone_hint = "空气中弥漫着消毒水的气味"; g2.narrative_hint_id = "treatment_intro"
	g2.narrative_hint_text = "走廊两侧是紧闭的门。\n隐约可以听到低语声。"
	add_child(g2)

	var g3: ZoneTrigger = gt.instantiate()
	g3.global_position = Vector2(600, 0); g3.target_zone_name = "行政区"
	g3.zone_hint = "你进入了行政区"; g3.narrative_hint_id = "admin_intro"
	g3.narrative_hint_text = "宽敞的走廊。\n尽头的门牌上写着「主任办公室」。"
	add_child(g3)


func _connect_signals() -> void:
	PlayerData.onPlayerDeath.connect(_on_death)
	EventBus.extraction_completed.connect(_on_extraction_completed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	AlertServer.alert_threshold_crossed.connect(_on_alert_threshold_crossed)


# -- equipment & pickups --

func _equip_starting_weapon() -> void:
	if not player:
		return
	var weapon: BaseMeleeWeapon = STARTING_MELEE.instantiate()
	var gun_root: Node2D = player.get_node_or_null("body/GunRoot") as Node2D
	if not gun_root:
		gun_root = player.get_node_or_null("gun_root") as Node2D
	if not gun_root:
		weapon.queue_free()
		return
	weapon.name = "melee_0"
	gun_root.add_child(weapon)
	weapon.setOwner(player)
	weapon.set_use(true)


func _place_melee_pickups() -> void:
	var iv_pickup: MeleeWeaponPickup = MELEE_PICKUP.instantiate()
	iv_pickup.melee_weapon_scene = preload("res://game/melee/IVStand.tscn")
	iv_pickup.weapon_display_name = "输液架"
	iv_pickup.position = ZONES["treatment"] + Vector2(-80, 40)
	add_child(iv_pickup)

	var strap_pickup: MeleeWeaponPickup = MELEE_PICKUP.instantiate()
	strap_pickup.melee_weapon_scene = preload("res://game/melee/RestraintStrap.tscn")
	strap_pickup.weapon_display_name = "束缚带"
	strap_pickup.position = ZONES["ward"] + Vector2(50, -30)
	add_child(strap_pickup)


# -- atmosphere --

func _setup_atmosphere() -> void:
	var atmosphere: Node = ATMOSPHERE_CTRL.new()
	add_child(atmosphere)


# -- alert spawns --

func _on_alert_threshold_crossed(threshold: AlertServer.AlertThreshold) -> void:
	if _spawned_thresholds.has(threshold):
		return
	_spawned_thresholds.append(threshold)
	match threshold:
		AlertServer.AlertThreshold.WATCHFUL:
			_spawn_alert_enemy("PatrolGuard", 1)
		AlertServer.AlertThreshold.ALARM:
			_spawn_alert_enemy("SurveillanceDrone", 1)
		AlertServer.AlertThreshold.LOCKDOWN:
			_spawn_alert_enemy("PatrolGuard", 2)
			_spawn_alert_enemy("SedationEnforcer", 1)
	Utils.showToast("⚠ 增援已抵达")


func _spawn_alert_enemy(enemy_type: String, count: int) -> void:
	for _i in range(count):
		var enemy_scene_path: String = "res://game/correction/enemies/%s.tscn" % enemy_type
		if not ResourceLoader.exists(enemy_scene_path):
			continue
		var enemy: Node = load(enemy_scene_path).instantiate()
		var pos: Vector2 = Vector2(randf_range(-80, 80), randf_range(-80, 80))
		if player:
			pos += player.position
		enemy.position = pos
		add_child(enemy)


# -- gameplay --

func _input(event: InputEvent) -> void:
	if not ready_flag or not player or player.is_dead: return
	if event.is_action_pressed("q"): _try_throw()
	if event.is_action_pressed("melee_attack"):
		if is_instance_valid(AlertServer) and AlertServer.is_active: AlertServer.add_melee_attack_noise()
	if event.is_action_pressed("dash"):
		if is_instance_valid(AlertServer) and AlertServer.is_active:
			AlertServer.add_noise(AlertServer.NOISE_RUNNING, "dash")


func _try_throw() -> void:
	var cnt: int = 0
	if PlayerData.has_meta("stone_count"): cnt = PlayerData.get_meta("stone_count")
	if cnt <= 0: Utils.showToast("没有石子"); return
	PlayerData.set_meta("stone_count", cnt - 1)
	EventBus.throwable_count_changed.emit("stone", cnt - 1)
	var s: ThrowableItem = ThrowableItem.create(ThrowableItem.ThrowableType.STONE, player.global_position)
	add_child(s)
	await get_tree().process_frame
	if is_instance_valid(s) and player:
		var mp: Vector2 = get_global_mouse_position()
		var d: Vector2 = (mp - player.global_position).normalized()
		s.throw_in_dir(d)
		if is_instance_valid(AlertServer) and AlertServer.is_active: AlertServer.add_throw_noise()


func _on_boss_defeated(_name: String) -> void:
	if extract_point and extract_point.has_method("activate"): extract_point.activate()


func _on_extraction_completed() -> void:
	var v: int = 0
	if is_instance_valid(LootServer): v = LootServer.get_total_loot_value()
	PlayerData.gold += maxi(v, 50)
	Utils.showToast("撤离成功！获得 %d 金币" % maxi(v, 50))
	await get_tree().create_timer(1.0).timeout
	_show_warehouse()


func _on_death() -> void:
	Utils.showToast("你死了...")
	await get_tree().create_timer(1.5).timeout
	_show_warehouse()


func _show_warehouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var ws: Node = preload("res://game/correction/warehouse/WarehouseUpgradeUI.tscn").instantiate()
	add_child(ws)
	if ws.has_signal("warehouse_closed"):
		ws.warehouse_closed.connect(func():
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			get_tree().reload_current_scene()
		)
