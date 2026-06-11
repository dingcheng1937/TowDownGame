extends Control
class_name WarehouseUI
## 仓库成长界面 - 两局之间的仓库升级系统
##
## 成功撤离后显示，允许玩家用本局获取的资源升级仓库。
##
## 升级项：
## - 仓库扩容（10→20→30格）
## - 初始医疗包（1→2→3个）
## - 石子携带量（5→10→15个）

signal upgrades_applied
signal warehouse_closed

## 仓库最大容量等级（格子数：10, 20, 30）
var storage_level: int = 1

## 初始医疗包等级（数量：1, 2, 3）
var medkit_level: int = 1

## 石子携带量等级（数量：5, 10, 15）
var stone_carry_level: int = 1

## 各升级项当前等级的显示值
var storage_capacity: int = 10
var medkit_count: int = 1
var stone_carry: int = 5

## 升级费用
const UPGRADE_COSTS: Dictionary = {
	"storage": [0, 50, 150],      # 1→2, 2→3
	"medkit": [0, 30, 100],
	"stone_carry": [0, 20, 80],
}

## 升级后的值
const UPGRADE_VALUES: Dictionary = {
	"storage": [10, 20, 30],
	"medkit": [1, 2, 3],
	"stone_carry": [5, 10, 15],
}

@onready var storage_label: Label = $VBoxContainer/StorageContainer/ValueLabel
@onready var medkit_label: Label = $VBoxContainer/MedkitContainer/ValueLabel
@onready var stone_label: Label = $VBoxContainer/StoneContainer/ValueLabel

@onready var storage_cost_label: Label = $VBoxContainer/StorageContainer/CostLabel
@onready var medkit_cost_label: Label = $VBoxContainer/MedkitContainer/CostLabel
@onready var stone_cost_label: Label = $VBoxContainer/StoneContainer/CostLabel

@onready var storage_button: Button = $VBoxContainer/StorageContainer/UpgradeButton
@onready var medkit_button: Button = $VBoxContainer/MedkitContainer/UpgradeButton
@onready var stone_button: Button = $VBoxContainer/StoneContainer/UpgradeButton

@onready var gold_label: Label = $GoldLabel
@onready var description_label: Label = $DescriptionLabel


func _ready() -> void:
	_load_saved_levels()
	_update_all_displays()
	
	if storage_button:
		storage_button.pressed.connect(_on_upgrade_storage)
	if medkit_button:
		medkit_button.pressed.connect(_on_upgrade_medkit)
	if stone_button:
		stone_button.pressed.connect(_on_upgrade_stone)
	
	_update_gold_display()


func _load_saved_levels() -> void:
	# 从玩家数据中加载已保存的等级（使用PlayerData作为持久存储）
	if PlayerData.has_meta("warehouse_storage_level"):
		storage_level = PlayerData.get_meta("warehouse_storage_level")
	if PlayerData.has_meta("warehouse_medkit_level"):
		medkit_level = PlayerData.get_meta("warehouse_medkit_level")
	if PlayerData.has_meta("warehouse_stone_level"):
		stone_carry_level = PlayerData.get_meta("warehouse_stone_level")
	
	# 更新实际值
	storage_capacity = UPGRADE_VALUES["storage"][storage_level - 1]
	medkit_count = UPGRADE_VALUES["medkit"][medkit_level - 1]
	stone_carry = UPGRADE_VALUES["stone_carry"][stone_carry_level - 1]


func _save_levels() -> void:
	PlayerData.set_meta("warehouse_storage_level", storage_level)
	PlayerData.set_meta("warehouse_medkit_level", medkit_level)
	PlayerData.set_meta("warehouse_stone_level", stone_carry_level)


func _update_all_displays() -> void:
	_update_single_display(storage_label, storage_cost_label, storage_button, 
		"仓库容量", storage_capacity, storage_level, "storage")
	_update_single_display(medkit_label, medkit_cost_label, medkit_button,
		"初始医疗包", medkit_count, medkit_level, "medkit")
	_update_single_display(stone_label, stone_cost_label, stone_button,
		"石子携带量", stone_carry, stone_carry_level, "stone_carry")


func _update_single_display(
	value_label: Label, cost_label: Label, button: Button,
	name: String, current_value: int, level: int, upgrade_key: String
) -> void:
	if value_label:
		value_label.text = "%s: %d" % [name, current_value]
	
	var costs: Array = UPGRADE_COSTS[upgrade_key]
	var values: Array = UPGRADE_VALUES[upgrade_key]
	
	# 检查是否满级
	if level >= costs.size():
		if value_label:
			value_label.text = "%s: %d (已满级)" % [name, current_value]
		if cost_label:
			cost_label.text = "已满级"
		if button:
			button.disabled = true
		return
	
	var cost: int = costs[level]
	var next_value: int = values[level] if level < values.size() else current_value
	
	if cost_label:
		cost_label.text = "费用: %d金币" % cost
	
	if button:
		button.disabled = PlayerData.gold < cost
		button.text = "升级 → %d" % next_value


func _can_afford(cost: int) -> bool:
	return PlayerData.gold >= cost


func _spend_gold(cost: int) -> void:
	PlayerData.gold -= cost


func _on_upgrade_storage() -> void:
	_perform_upgrade("storage", storage_level, storage_capacity,
		func(): storage_level += 1; storage_capacity = UPGRADE_VALUES["storage"][storage_level - 1],
		storage_label, storage_cost_label, storage_button,
		"仓库容量")


func _on_upgrade_medkit() -> void:
	_perform_upgrade("medkit", medkit_level, medkit_count,
		func(): medkit_level += 1; medkit_count = UPGRADE_VALUES["medkit"][medkit_level - 1],
		medkit_label, medkit_cost_label, medkit_button,
		"初始医疗包")


func _on_upgrade_stone() -> void:
	_perform_upgrade("stone_carry", stone_carry_level, stone_carry,
		func(): stone_carry_level += 1; stone_carry = UPGRADE_VALUES["stone_carry"][stone_carry_level - 1],
		stone_label, stone_cost_label, stone_button,
		"石子携带量")


func _perform_upgrade(
	upgrade_key: String, level: int, _current_value: int,
	apply_func: Callable,
	value_label: Label, cost_label: Label, button: Button,
	display_name: String
) -> void:
	var costs: Array = UPGRADE_COSTS[upgrade_key]
	if level >= costs.size():
		return  # 已满级
	
	var cost: int = costs[level]
	if not _can_afford(cost):
		Utils.showToast("金币不足！")
		return
	
	_spend_gold(cost)
	apply_func.call()
	_save_levels()
	
	EventBus.warehouse_upgraded.emit(upgrade_key, level)
	Utils.showToast("%s 升级成功！" % display_name)
	
	_update_all_displays()
	_update_gold_display()


func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "金币: %d" % PlayerData.gold


func _on_continue_pressed() -> void:
	emit_signal("warehouse_closed")
	queue_free()
