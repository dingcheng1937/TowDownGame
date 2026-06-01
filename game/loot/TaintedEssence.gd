extends BaseLoot
class_name TaintedEssence
## 污浊精华 - 传说战利品，高价值但降低理智


func _ready() -> void:
	super._ready()
	item_name = "污浊精华"
	description = "充满力量的精华，但似乎会影响心智"
	rarity = Rarity.LEGENDARY
	value = 500
	can_extract = true


func pickup() -> void:
	# 拾取时降低理智
	SanityServer.change_sanity(-15.0)
	Utils.showToast("获得污浊精华，理智-15")
	super.pickup()
