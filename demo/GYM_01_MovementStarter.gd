extends Node2D
## DEMO启动器 - 模拟游戏启动流程

func _ready():
	# 等待一帧确保所有节点初始化完成
	await get_tree().process_frame

	# 模拟游戏启动，启用玩家物理处理
	Utils.gameStart()

	# 设置玩家引用（相机需要）
	Utils.player = $PlayerRoot/Hero
