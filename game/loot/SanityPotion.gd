extends BaseLoot
class_name SanityPotion
## 理智药剂 - 消耗品，恢复大量理智


func _ready() -> void:
	super._ready()
	item_name = "理智药剂"
	description = "可以恢复理智的神秘药剂"
	rarity = LootServer.Rarity.UNCOMMON
	value = 50
	can_extract = false  # 单次使用


func pickup() -> void:
	# 直接恢复理智
	SanityServer.change_sanity(30.0)
	Utils.showToast("使用理智药剂，理智+30")
	super.pickup()
