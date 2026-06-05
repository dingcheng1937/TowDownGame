extends Node2D
## 近战武器系统DEMO启动器

var current_weapon_index = 0
var weapons = []

func _ready():
	await get_tree().process_frame

	# 初始化玩家数据
	PlayerData.player_hp = 100
	PlayerData.player_hp_max = 100

	# 触发游戏启动
	Utils.gameStart()

	# 设置玩家引用
	Utils.player = $PlayerRoot/Hero

	# 给玩家添加基础枪械（用于测试枪械和近战武器切换）
	var uzi = preload("res://game/guns/Uzi.tscn").instantiate()
	PlayerData.add_weapon(uzi)

	# 添加所有近战武器到测试列表
	weapons = [
		preload("res://game/melee/IVStand.tscn"),
		preload("res://game/melee/WoodenChairLeg.tscn"),
		preload("res://game/melee/RestraintStrap.tscn"),
		preload("res://game/melee/Taser.tscn")
	]

	# 给玩家装备第一个近战武器
	_equip_melee_weapon(0)

	# 设置怪物数据
	for monster in $MonstersRoot.get_children():
		monster.setData({
			'speed': 30.0,
			'hurt': 1,
			'hp': 15
		})

	# 添加游戏UI
	_setup_ui()

	# 连接耐久变化信号
	PlayerData.onMeleeDurabilityChange.connect(_on_durability_change)

func _setup_ui():
	var control_ui = $ControlUI
	control_ui.get_node("GameUI").show()
	control_ui.get_node("MainUI").hide()

func _equip_melee_weapon(index: int):
	if index < 0 or index >= weapons.size():
		return

	current_weapon_index = index

	# 移除旧的近战武器
	if Utils.player and Utils.player.melee_weapon:
		Utils.player.melee_weapon.queue_free()

	# 实例化新的近战武器
	var melee_weapon = weapons[index].instantiate()
	var gun_root = Utils.player.get_node_or_null("body/GunRoot")
	if gun_root:
		gun_root.add_child(melee_weapon)
		melee_weapon.setOwner(Utils.player)
		melee_weapon.set_use(true)

	# 更新信息面板
	_update_info_panel()

func _update_info_panel():
	var weapon_names = ["输液架", "木制椅腿", "约束带", "电击棒"]
	var weapon_infos = [
		"低伤害 | 高耐久 | 大攻击范围",
		"中伤害 | 低耐久 | 容易获得",
		"特殊武器 | 可束缚敌人2秒",
		"稀有武器 | 高伤害 | 电击效果"
	]

	var info = "当前武器: " + weapon_names[current_weapon_index] + "\n"
	info += weapon_infos[current_weapon_index] + "\n\n"
	info += "测试内容:\n"
	info += "- V键: 近战攻击\n"
	info += "- Tab键: 切换近战武器\n"
	info += "- 1-4键: 选择特定武器\n"
	info += "- 观察耐久消耗\n"
	info += "- 武器损坏后变废品\n\n"
	info += "控制: WASD移动 | 鼠标瞄准"

	$InfoPanel.content = info

func _on_durability_change(current: float, max_dur: float):
	var percentage = int((current / max_dur) * 100)
	print("近战武器耐久: %d/%d (%d%%)" % [current, max_dur, percentage])

	if current <= 0:
		Utils.showToast("武器已损坏!")

func _input(event: InputEvent):
	# Tab键切换武器
	if event.is_action_pressed("inv"):
		_equip_melee_weapon((current_weapon_index + 1) % weapons.size())

	# 数字键选择武器
	for i in range(1, 5):
		if Input.is_key_pressed(KEY_0 + i) or Input.is_key_pressed(KEY_KP_0 + i):
			if event.is_pressed() and not event.is_echo():
				_equip_melee_weapon(i - 1)
