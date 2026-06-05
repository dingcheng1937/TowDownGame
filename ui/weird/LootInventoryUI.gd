extends Control
class_name LootInventoryUI
## 战利品背包 UI - 显示当前收集的战利品

@onready var _grid: GridContainer = $Panel/VBox/ScrollContainer/Grid
@onready var _count_label: Label = $Panel/VBox/CountLabel
@onready var _value_label: Label = $Panel/VBox/ValueLabel

var _loot_slot_scene = preload("res://ui/weird/LootSlot.tscn")


func _ready() -> void:
	LootServer.loot_added.connect(_on_loot_added)
	LootServer.loot_removed.connect(_on_loot_removed)
	LootServer.loot_extracted.connect(_on_loot_extracted)

	_update_display()


func _exit_tree() -> void:
	# 断开信号连接，避免内存泄漏
	# 检查autoload是否仍然有效（场景切换时可能已被清理）
	if not is_instance_valid(LootServer):
		return
	if LootServer.loot_added.is_connected(_on_loot_added):
		LootServer.loot_added.disconnect(_on_loot_added)
	if LootServer.loot_removed.is_connected(_on_loot_removed):
		LootServer.loot_removed.disconnect(_on_loot_removed)
	if LootServer.loot_extracted.is_connected(_on_loot_extracted):
		LootServer.loot_extracted.disconnect(_on_loot_extracted)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inv"):
		visible = not visible
		get_viewport().set_input_as_handled()


func _update_display() -> void:
	# 清空现有槽位
	for child in _grid.get_children():
		child.queue_free()

	# 添加当前战利品
	for loot in LootServer.current_loot:
		_add_loot_slot(loot)

	# 更新统计
	_update_stats()


func _add_loot_slot(loot: Dictionary) -> void:
	var slot = _loot_slot_scene.instantiate()
	slot.set_loot(loot)
	_grid.add_child(slot)


func _update_stats() -> void:
	var count = LootServer.current_loot.size()
	var max_slots = LootServer.max_loot_slots
	var total_value = LootServer.get_total_loot_value()

	if _count_label:
		_count_label.text = "容量: %d/%d" % [count, max_slots]
	if _value_label:
		_value_label.text = "总价值: %d" % total_value


func _on_loot_added(_loot: Dictionary) -> void:
	_update_display()


func _on_loot_removed(_loot: Dictionary) -> void:
	_update_display()


func _on_loot_extracted(_loot: Dictionary) -> void:
	_update_display()
