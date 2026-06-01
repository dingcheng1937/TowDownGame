extends Control
class_name LootSlot
## 战利品槽位 - 显示单个战利品

@onready var _name_label: Label = $VBox/NameLabel
@onready var _value_label: Label = $VBox/ValueLabel

var _loot_data: Dictionary


func set_loot(loot: Dictionary) -> void:
	_loot_data = loot
	_update_display()


func _update_display() -> void:
	if _name_label:
		_name_label.text = _loot_data.get("name", "???")
		var rarity = _loot_data.get("rarity", 0)
		_name_label.modulate = LootServer.get_rarity_color(rarity)

	if _value_label:
		_value_label.text = "价值: %d" % _loot_data.get("value", 0)
