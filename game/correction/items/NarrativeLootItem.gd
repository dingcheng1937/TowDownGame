extends BaseLoot
class_name NarrativeLootItem
## 高价值叙事战利品 - 含碎片化叙事文本

@export var narrative_id: String = ""
@export var narrative_text: String = ""


func _ready() -> void:
	rarity = LootServer.Rarity.EPIC
	can_extract = true
	value = 50
	super._ready()


func pickup() -> void:
	if is_picked:
		return
	is_picked = true
	# 触发叙事事件
	EventBus.high_value_loot_found.emit(item_name)
	EventBus.lore_fragment_found.emit(narrative_id, narrative_text)
	Utils.showToast(item_name)
	# 走 BaseLoot 标准流程（添加到 LootServer）
	var loot_data: Dictionary = {
		"name": item_name, "description": description,
		"rarity": rarity, "value": value,
		"icon": icon, "can_extract": can_extract
	}
	if LootServer.add_loot(loot_data):
		picked_up.emit()
		queue_free()
