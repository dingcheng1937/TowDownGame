extends Node2D
## 物品系统DEMO启动器

func _ready():
	await get_tree().process_frame

	# 初始化玩家数据
	PlayerData.player_hp = 50
	PlayerData.player_hp_max = 100
	PlayerData.gold = 0

	# 触发游戏启动（使用原游戏方式）
	Utils.gameStart()

	# 设置玩家引用
	Utils.player = $PlayerRoot/Hero

	# 设置血包参数
	var hppack = $ItemsRoot/HpPack
	if hppack:
		hppack.hp = 25
