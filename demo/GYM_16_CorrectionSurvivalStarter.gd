extends Node
## GYM_16 矫正生存 MVP 白盒验证场景
##
## 流程：房间醒来 → 敲门 → 开门/不开门 → 护士对峙(背身靠墙/攻击) → 
##       存活开门 → 走廊潜行 → 搜刮资源 → 门禁解锁 → 撤离

const HERO_SCENE := preload("res://game/hero/Hero.tscn")
const ROOM_W = 500
const ROOM_H = 500

var player
var hud

func _ready() -> void:
	_init_toast()
	_init_player()
	_init_autoloads()
	_build_whitebox()
	_init_hud()
	Utils.gameStart()
	print("GYM_16 矫正生存白盒已启动")
	print("流程: 等待4秒敲门 → E开门/等待10秒破门 → 护士对峙 → 存活出门 → 走廊潜行")


# ── 白盒场景 ──────────────────────────────────────

func _build_whitebox() -> void:
	var world := Node2D.new()
	world.name = "World"
	add_child(world)

	var room_x = -float(ROOM_W)/2 - 50
	var corridor_x = float(ROOM_W)/2 + 50

	# ── 房间（左） ──
	_add_floor(world, "RoomFloor", room_x, 0, ROOM_W, ROOM_H, Color(0.15, 0.15, 0.2))
	_add_wall(world, "RoomWall_N", room_x, -float(ROOM_H)/2, ROOM_W, 16)
	_add_wall(world, "RoomWall_S", room_x, float(ROOM_H)/2, ROOM_W, 16)
	_add_wall(world, "RoomWall_W", room_x - float(ROOM_W)/2, 0, 16, ROOM_H)
	
	# 房间东侧门墙（初始封锁，护士走后移除）
	var door_wall := _add_wall(world, "RoomDoorWall", room_x + float(ROOM_W)/2, 0, 16, 120)
	door_wall.name = "RoomDoorWall"

	# ── 走廊（右） ──
	var corr_w = 700
	var corr_h = 300
	_add_floor(world, "CorridorFloor", corridor_x, 0, corr_w, corr_h, Color(0.18, 0.18, 0.15))
	_add_wall(world, "CorridorWall_N", corridor_x, -corr_h/2, corr_w, 16)
	_add_wall(world, "CorridorWall_S", corridor_x, corr_h/2, corr_w, 16)
	_add_wall(world, "CorridorWall_E", corridor_x + corr_w/2, 0, 16, corr_h)

	# ── 房间内陈设（白盒） ──
	_add_crate(world, "Bed", room_x - 120, -80, Vector2(80, 40), Color(0.6, 0.6, 0.55))
	_add_crate(world, "Cabinet", room_x + 80, -120, Vector2(30, 20), Color(0.5, 0.4, 0.3))

	# ── 走廊陈设 ──
	_add_crate(world, "Desk1", corridor_x - 200, -60, Vector2(40, 20), Color(0.4, 0.35, 0.3))
	_add_crate(world, "Desk2", corridor_x + 100, 60, Vector2(40, 20), Color(0.4, 0.35, 0.3))
	_add_crate(world, "Vending", corridor_x + 250, -80, Vector2(20, 40), Color(0.3, 0.5, 0.7))

	# ── 玩家出生点 ──
	var spawn := Marker2D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector2(room_x - 60, 0)
	world.add_child(spawn)

	# ── DoorInteraction ──
	var door = preload("res://game/correction-survival/interaction/DoorInteraction.tscn").instantiate()
	door.position = Vector2(room_x + float(ROOM_W)/2 - 30, -60)
	door.room_exit_wall = "RoomDoorWall"
	door.room_door_wall = NodePath("../../World/RoomDoorWall")
	world.add_child(door)

	# ── NurseSpawn 标记 ──
	if door.has_node("NurseSpawn"):
		door.get_node("NurseSpawn").position = Vector2(float(ROOM_W)/2 + 20, 0)

	# ── 走廊巡逻 Orderly ──
	var orderly = preload("res://game/correction-survival/enemies/OrderlyMonster.tscn").instantiate()
	orderly.position = Vector2(corridor_x, 0)
	orderly.patrol_points = [
		Vector2(corridor_x - 200, -80),
		Vector2(corridor_x + 200, -80),
		Vector2(corridor_x + 200, 80),
		Vector2(corridor_x - 200, 80),
	]
	orderly.SPEED = 25.0
	_add_minimal_sprite_frames(orderly)
	world.add_child(orderly)

	# ── 走廊尽头门禁 ──
	var gate = preload("res://game/correction-survival/gate/GateController.tscn").instantiate()
	gate.position = Vector2(corridor_x + corr_w/2, 0)
	gate.gate_id = "corridor_exit"
	gate.required_item_id = "key_card"
	gate.hint_text = "需要门禁卡才能通过"
	world.add_child(gate)

	# 初始化玩家位置
	if player:
		player.position = spawn.position


func _add_floor(parent: Node, name: String, x: float, y: float, w: float, h: float, color: Color) -> void:
	var rect := ColorRect.new()
	rect.name = name
	rect.position = Vector2(x - w/2, y - h/2)
	rect.size = Vector2(w, h)
	rect.color = color
	parent.add_child(rect)


func _add_wall(parent: Node, name: String, x: float, y: float, w: float, h: float) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.name = name
	wall.position = Vector2(x, y)
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(w, h)
	wall.add_child(shape)
	# 可视化
	var vis := ColorRect.new()
	vis.position = Vector2(-w/2, -h/2)
	vis.size = Vector2(w, h)
	vis.color = Color(0.3, 0.3, 0.35)
	wall.add_child(vis)
	parent.add_child(wall)
	return wall


func _add_crate(parent: Node, name: String, x: float, y: float, size: Vector2, color: Color) -> void:
	var crate := StaticBody2D.new()
	crate.name = name
	crate.position = Vector2(x, y)
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = size
	crate.add_child(shape)
	var vis := ColorRect.new()
	vis.position = -size / 2
	vis.size = size
	vis.color = color
	crate.add_child(vis)
	parent.add_child(crate)


# ── 玩家 ──────────────────────────────────────────

func _init_player() -> void:
	if PlayerServer.player_scene and is_instance_valid(PlayerServer.player_scene):
		player = PlayerServer.player_scene
		if player.get_parent():
			player.get_parent().remove_child(player)
	else:
		player = HERO_SCENE.instantiate()
		Utils.player = player
		PlayerServer.player_scene = player
	add_child(player)
	PlayerData.player_hp_max = 5
	PlayerData.player_hp = 5
	PlayerData.gold = 0


# ── 系统初始化 ──────────────────────────────────

func _init_autoloads() -> void:
	if is_instance_valid(AlertServer):
		AlertServer.initialize()
	StaminaServer.reset()
	if is_instance_valid(SanityServer):
		SanityServer.reset_sanity()


func _init_toast() -> void:
	var cl := preload("res://ui/GYMToastLayer.gd").new()
	cl.name = "ToastLayer"
	cl.layer = 128
	add_child(cl)
	cl.set_script(preload("res://ui/GYMToastLayer.gd"))
	cl._ready()
	Utils.canvasLayer = cl


func _init_hud() -> void:
	hud = preload("res://game/correction-survival/ui/SurvivalHUD.tscn").instantiate()
	add_child(hud)


func _add_minimal_sprite_frames(enemy) -> void:
	var sf := SpriteFrames.new()
	for anim in ["run", "idle", "attack"]:
		sf.add_animation(anim)
		sf.set_animation_speed(anim, 6.0)
		sf.add_frame(anim, AtlasTexture.new())
	if enemy and enemy.anim:
		enemy.anim.sprite_frames = sf
