extends Control

## GameSelectMenu : 可滚动的游戏选择界面。
## 动态生成 30 个游戏项，每行包含游戏名称和 PLAY 按钮。
## 点击 PLAY 加载对应场景。

const GameItemScene := preload("res://game_components/main_menu/game_item.tscn")

# ---------- 30 个小游戏数据 ----------
# 后续可在此数组中增删改游戏项
const GAME_LIST: Array[Dictionary] = [
	{name = "GYM 01 - 玩家移动",         path = "res://demo/GYM_01_Movement.tscn"},
	{name = "GYM 02 - 武器射击",         path = "res://demo/GYM_02_Weapon.tscn"},
	{name = "GYM 03 - 怪物AI",          path = "res://demo/GYM_03_Monster.tscn"},
	{name = "GYM 04 - 物品拾取",         path = "res://demo/GYM_04_Item.tscn"},
	{name = "GYM 05 - 装备使用",         path = "res://demo/GYM_05_Equip.tscn"},
	{name = "GYM 06 - 附件安装",         path = "res://demo/GYM_06_Attachment.tscn"},
	{name = "GYM 07 - 准星显示",         path = "res://demo/GYM_07_Crosshair.tscn"},
	{name = "GYM 08 - 伤害数字",         path = "res://demo/GYM_08_HitLabel.tscn"},
	{name = "GYM 09 - 武器切换",         path = "res://demo/GYM_09_WeaponList.tscn"},
	{name = "GYM 10 - 背包界面",         path = "res://demo/GYM_10_Inventory.tscn"},
	{name = "GYM 11 - 诡异搜打撤",        path = "res://demo/GYM_11_WeirdLoot.tscn"},
	{name = "GYM 12 - 近战武器",         path = "res://demo/GYM_12_Melee.tscn"},
	{name = "GYM 13 - 按钮计数器",        path = "res://demo/GYM_13_ButtonCounter.tscn"},
	{name = "GYM 13B - 矫正中心",         path = "res://demo/GYM_13_CorrectionCenter.tscn"},
	{name = "GYM 14 - 生命值演示",        path = "res://demo/GYM_14_HealthDemo.tscn"},
	{name = "GYM 15 - 矫正中心MVP",      path = "res://demo/GYM_15_CorrectionCenter.tscn"},
	{name = "GYM 16 - 矫正生存模式",       path = "res://demo/GYM_16_CorrectionSurvival.tscn"},
	{name = "小游戏 18 - 暂无",           path = ""},
	{name = "小游戏 19 - 暂无",           path = ""},
	{name = "小游戏 20 - 暂无",           path = ""},
	{name = "小游戏 21 - 暂无",           path = ""},
	{name = "小游戏 22 - 暂无",           path = ""},
	{name = "小游戏 23 - 暂无",           path = ""},
	{name = "小游戏 24 - 暂无",           path = ""},
	{name = "小游戏 25 - 暂无",           path = ""},
	{name = "小游戏 26 - 暂无",           path = ""},
	{name = "小游戏 27 - 暂无",           path = ""},
	{name = "小游戏 28 - 暂无",           path = ""},
	{name = "小游戏 29 - 暂无",           path = ""},
	{name = "小游戏 30 - 暂无",           path = ""},
]


func _ready() -> void:
	_populate_game_list()


func _populate_game_list() -> void:
	var container := $VBoxContainer/ScrollContainer/VBoxContainer as VBoxContainer
	if container == null:
		push_error("GameSelectMenu: 未找到游戏列表容器节点")
		return

	# 清除编辑器中预设的占位项
	for child in container.get_children():
		child.queue_free()

	for i: int in GAME_LIST.size():
		var data: Dictionary = GAME_LIST[i]
		var item := GameItemScene.instantiate()
		item.setup(i + 1, data.name, data.path)
		item.game_pressed.connect(_on_game_pressed)
		container.add_child(item)


func _on_game_pressed(scene_path: String) -> void:
	if scene_path.is_empty():
		push_warning("GameSelectMenu: 该游戏暂无场景路径")
		return
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("GameSelectMenu: 加载场景失败 - %s" % scene_path)


func _on_back_pressed() -> void:
	# 返回项目主场景
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene.is_empty():
		push_error("GameSelectMenu: 未配置项目主场景")
		return
	get_tree().change_scene_to_file(main_scene)
