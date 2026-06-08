extends Node
class_name CorrectionGameManager
## 精神矫正中心 游戏主循环

const ATMOSPHERE_CTRL := preload("res://game/atmosphere/AtmosphereController.gd")

enum GamePhase { LOADING, INTRO, EXPLORATION, BOSS_FIGHT, EXTRACTION, WAREHOUSE, RESULT }

var current_phase: GamePhase = GamePhase.LOADING
var run_stats: Dictionary
var is_dead: bool = false
var extracted_successfully: bool = false
var player: Player
var hud: CorrectionHUD
var extract_point: Node
var atmosphere: AtmosphereController


func _ready() -> void:
	player = Utils.player
	if player:
		PlayerData.onPlayerDeath.connect(_on_player_death)
	EventBus.extraction_completed.connect(_on_extraction_completed)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.item_collected.connect(_on_item_collected)
	EventBus.high_value_loot_found.connect(_on_loot_found)
	_start_new_run()


func _start_new_run() -> void:
	is_dead = false
	extracted_successfully = false
	current_phase = GamePhase.INTRO
	run_stats = {"zones_visited": [], "enemies_killed": 0, "items_collected": 0,
		"loot_value": 0, "boss_defeated": false, "extracted": false, "time_survived": 0.0}
	PlayerData.player_hp = PlayerData.player_hp_max
	if is_instance_valid(AlertServer): AlertServer.initialize()
	if is_instance_valid(ExtractionServer):
		ExtractionServer.reset()
		ExtractionServer.set_conditions(0.0, ["主任钥匙卡"], 0, 5.0)
	if is_instance_valid(SanityServer):
		SanityServer.reset_sanity()
	Utils.gameStart()
	if not is_instance_valid(atmosphere):
		_setup_atmosphere()
	current_phase = GamePhase.EXPLORATION


func _setup_atmosphere() -> void:
	if not is_instance_valid(atmosphere):
		atmosphere = ATMOSPHERE_CTRL.new()
		add_child(atmosphere)


func _process(delta: float) -> void:
	if current_phase == GamePhase.EXPLORATION and not is_dead:
		run_stats.time_survived += delta
		if player and player.is_run and is_instance_valid(AlertServer) and AlertServer.is_active:
			AlertServer.add_running_noise()


func _on_player_death() -> void:
	if is_dead or extracted_successfully: return
	is_dead = true
	current_phase = GamePhase.RESULT
	if is_instance_valid(AlertServer): AlertServer.stop()
	if is_instance_valid(LootServer): LootServer.clear_current_loot()
	Utils.showToast("你死了...")
	await get_tree().create_timer(2.0).timeout
	_show_warehouse()


func _on_extraction_completed() -> void:
	extracted_successfully = true
	current_phase = GamePhase.EXTRACTION
	if is_instance_valid(AlertServer): AlertServer.stop()
	var v: int = 0
	if is_instance_valid(LootServer): v = LootServer.get_total_loot_value()
	PlayerData.gold += v
	run_stats.extracted = true; run_stats.loot_value = v
	Utils.showToast("撤离成功！获得 %d 金币" % v)
	await get_tree().create_timer(1.5).timeout
	_show_warehouse()


func _show_warehouse() -> void:
	current_phase = GamePhase.WAREHOUSE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var ws: Node = preload("res://game/correction/warehouse/WarehouseUpgradeUI.tscn").instantiate()
	add_child(ws)
	if ws.has_signal("warehouse_closed"):
		ws.warehouse_closed.connect(_on_warehouse_closed)


func _on_warehouse_closed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_start_new_run()


func _on_enemy_killed(_type: String, _pos: Vector2) -> void:
	run_stats.enemies_killed += 1
	if is_instance_valid(ExtractionServer): ExtractionServer.register_kill()


func _on_boss_defeated(_name: String) -> void:
	run_stats.boss_defeated = true
	current_phase = GamePhase.BOSS_FIGHT


func _on_item_collected(_id: String, _name: String) -> void:
	run_stats.items_collected += 1


func _on_loot_found(_name: String) -> void:
	run_stats.loot_value += 50
