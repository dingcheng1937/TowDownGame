extends Node2D
## 附件系统DEMO启动器

const ControlUIPre = preload("res://ui/ControlUI.tscn")

func _ready():
	await get_tree().process_frame

	# 先添加UI（确保GameUI创建并监听信号）
	_setup_ui()

	await get_tree().process_frame

	# 触发游戏启动（使用原游戏方式）
	Utils.gameStart()

	Utils.player = $PlayerRoot/Hero

	# 给玩家添加武器（使用原游戏方式）
	var uzi = preload("res://game/guns/Uzi.tscn").instantiate()
	PlayerData.add_weapon(uzi)

	# 等待武器初始化完成
	await get_tree().process_frame

	# 设置地上的配件
	_setup_attachments()


func _setup_ui():
	var control_ui = $ControlUI
	control_ui.get_node("GameUI").show()
	control_ui.get_node("MainUI").hide()


## 配置地上的配件实例
func _setup_attachments():
	# 获取地上的配件节点
	var floor1 = $AttachmentsRoot/AttachmentOnFloor
	var floor2 = $AttachmentsRoot/AttachmentOnFloor2

	if floor1 and floor2:
		# 创建配件数据并添加为子节点
		var attachment1 = preload("res://game/attachments/UniversalExtendedMagazines.tscn").instantiate()
		var attachment2 = preload("res://game/attachments/UniversalExtendedMagazines.tscn").instantiate()

		# 添加配件到场景（作为临时存储）
		add_child(attachment1)
		add_child(attachment2)

		# 设置引用
		floor1.attachment = attachment1
		floor2.attachment = attachment2

		# 更新显示
		floor1._update_display()
		floor2._update_display()
