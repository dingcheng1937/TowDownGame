extends BaseLoot
class_name KeyCardPickup
## 主任钥匙卡 - Boss掉落品


func _ready() -> void:
	item_name = "主任钥匙卡"
	description = "一张白色门禁卡。\n权限等级：主任办公室。\n\n\"审批状态：继续观察。\""
	rarity = LootServer.Rarity.LEGENDARY
	value = 200
	can_extract = true
	super._ready()


func pickup() -> void:
	if is_picked: return
	is_picked = true
	EventBus.key_item_acquired.emit("director_keycard")
	EventBus.item_collected.emit("director_keycard", item_name)
	Utils.showToast("获得主任钥匙卡 - 可以撤离了！")

	var loot_data: Dictionary = {
		"name": item_name, "description": description,
		"rarity": rarity, "value": value,
		"icon": icon, "can_extract": can_extract
	}
	if LootServer.add_loot(loot_data):
		picked_up.emit()
		queue_free()
	# 检查撤离条件
	if is_instance_valid(ExtractionServer):
		ExtractionServer.update_extraction_state()
