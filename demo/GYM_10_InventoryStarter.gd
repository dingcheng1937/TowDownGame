extends Node2D
## 背包UI完整测试启动器

const weapon_inventory = preload("res://ui/Inventory.tscn")
const attachment_floor_pre = preload("res://game/attachments/AttachmentOnFloor.tscn")

# 测试武器预设（覆盖不同武器类型）
const TEST_WEAPONS = [
	"res://game/guns/Uzi.tscn",           # SUBMACHINE_GUNSRELOAD
	"res://game/guns/Sniper.tscn",        # SNIPER_RIFLES
	"res://game/guns/ShotgunBlaster.tscn" # SHOTGUNS
]

# 测试配件预设（覆盖不同槽位和兼容性）
const TEST_ATTACHMENTS = [
	"res://game/attachments/UniversalExtendedMagazines.tscn",  # WEAPON_AMMUNITION - 所有武器兼容
	"res://game/attachments/SubmachineGunMagazine.tscn",       # WEAPON_AMMUNITION - 冲锋枪专用
	"res://game/attachments/ShotgunShellPouch.tscn",           # WEAPON_AMMUNITION - 霰弹枪专用
	"res://game/attachments/GrenadeLauncher.tscn",             # WEAPON_UNDERBARREL
	"res://game/attachments/QuickdrawMagazine.tscn",           # WEAPON_AMMUNITION
	"res://game/attachments/SuperUniversalMagazine.tscn"       # WEAPON_AMMUNITION
]

var inv_ui = null

func _ready():
	await get_tree().process_frame

	# 1. 先显示ControlUI（确保GameUI创建并监听信号）
	var control_ui = $ControlUI
	control_ui.get_node("GameUI").show()
	control_ui.get_node("MainUI").hide()

	await get_tree().process_frame

	# 2. 初始化游戏状态
	Utils.gameStart()
	Utils.player = $PlayerRoot/Hero

	# 3. 添加测试武器
	_add_test_weapons()

	# 4. 添加测试配件到背包
	_add_test_attachments()

	# 5. 在场景中生成地面配件（用于拾取测试）
	_spawn_floor_attachments()

	# 6. 更新 InfoPanel 说明
	_update_info_panel()

func _add_test_weapons():
	for path in TEST_WEAPONS:
		if ResourceLoader.exists(path):
			var weapon = load(path).instantiate()
			PlayerData.add_weapon(weapon)

func _add_test_attachments():
	for path in TEST_ATTACHMENTS:
		if ResourceLoader.exists(path):
			var attachment = load(path).instantiate()
			PlayerData.add_attachment(attachment)

func _spawn_floor_attachments():
	# 在玩家附近生成 2 个地面配件用于拾取测试（玩家初始位置 400, 300）
	var player_pos = Vector2(400, 300)
	var floor_positions = [
		player_pos + Vector2(-80, -50),  # 左上方
		player_pos + Vector2(80, 50)     # 右下方
	]

	for i in range(floor_positions.size()):
		# 使用不同的配件类型
		var attachment_path = TEST_ATTACHMENTS[i % TEST_ATTACHMENTS.size()]
		if ResourceLoader.exists(attachment_path):
			var attachment = load(attachment_path).instantiate()
			var floor_attachment = attachment_floor_pre.instantiate()
			floor_attachment.attachment = attachment
			floor_attachment.global_position = floor_positions[i]
			get_tree().current_scene.add_child(floor_attachment)

func _update_info_panel():
	var info_panel = $InfoPanel
	info_panel.title = "背包系统完整测试"
	info_panel.content = "测试内容:
- Tab 打开/关闭背包
- 点击顶部武器切换
- 拖拽配件到槽位装备
- 点击槽位卸下配件
- 观察配件类型匹配高亮
- 按 E 拾取地面配件

武器类型测试:
- Uzi (冲锋枪)
- Sniper (狙击枪)
- ShotgunBlaster (霰弹枪)

配件兼容性测试:
- 通用弹匣: 所有武器
- 冲锋枪弹匣: 仅Uzi
- 霰弹枪弹袋: 仅ShotgunBlaster

控制:
WASD 移动
Tab 开关背包
1-3 数字键切换武器
E 拾取地面配件"

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("inv") && Utils.is_game_start && !is_instance_valid(inv_ui):
		if Utils.player.gun == null:
			Utils.showToast("PLEASE PURCHASE A WEAPON FIRST")
		else:
			Utils.crosshairChange(false)
			inv_ui = weapon_inventory.instantiate()
			add_child(inv_ui)
