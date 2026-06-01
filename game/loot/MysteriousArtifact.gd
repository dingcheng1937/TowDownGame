extends BaseLoot
class_name MysteriousArtifact
## 神秘神器 - 稀有战利品，可以恢复理智


func _ready() -> void:
	super._ready()
	item_name = "神秘神器"
	description = "古老的护符，散发着诡异的光芒"
	rarity = Rarity.RARE
	value = 100
	can_extract = true


func pickup() -> void:
	# 拾取时恢复少量理智
	SanityServer.change_sanity(10.0)
	Utils.showToast("获得神秘神器，理智+10")
	super.pickup()
