extends Node
## 战利品管理系统
## 管理当前区域收集的物品和已成功带出的物品

signal loot_added(loot_item: Dictionary)
signal loot_removed(loot_item: Dictionary)
signal loot_extracted(loot_item: Dictionary)

## 战利品稀有度
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

## 当前区域收集的战利品（未撤离会丢失）
var current_loot: Array[Dictionary] = []

## 已成功带出的战利品
var extracted_loot: Array[Dictionary] = []

## 最大携带数量
var max_loot_slots: int = 12


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## 添加战利品到当前背包
func add_loot(item: Dictionary) -> bool:
	if current_loot.size() >= max_loot_slots:
		Utils.showToast("背包已满")
		return false

	current_loot.append(item)
	emit_signal("loot_added", item)
	return true


## 从当前背包移除战利品
func remove_loot(item: Dictionary) -> void:
	var idx = current_loot.find(item)
	if idx >= 0:
		current_loot.remove_at(idx)
		emit_signal("loot_removed", item)


## 清空当前背包（撤离失败时调用）
func clear_current_loot() -> void:
	current_loot.clear()


## 成功撤离，将战利品转移到永久背包
func extract_all_loot() -> void:
	for item in current_loot:
		extracted_loot.append(item)
		emit_signal("loot_extracted", item)
	current_loot.clear()


## 获取当前战利品总价值
func get_total_loot_value() -> int:
	var total = 0
	for item in current_loot:
		total += item.get("value", 0)
	return total


## 获取指定稀有度的战利品数量
func get_loot_count_by_rarity(rarity: Rarity) -> int:
	var count = 0
	for item in current_loot:
		if item.get("rarity", Rarity.COMMON) == rarity:
			count += 1
	return count


## 检查是否有指定物品
func has_item(item_name: String) -> bool:
	for item in current_loot:
		if item.get("name", "") == item_name:
			return true
	return false


## 获取稀有度颜色
func get_rarity_color(rarity: Rarity) -> Color:
	match rarity:
		Rarity.COMMON:
			return Color.WHITE
		Rarity.UNCOMMON:
			return Color.GREEN
		Rarity.RARE:
			return Color.BLUE
		Rarity.EPIC:
			return Color.PURPLE
		Rarity.LEGENDARY:
			return Color.GOLD
		_:
			return Color.WHITE


## 获取稀有度名称
func get_rarity_name(rarity: Rarity) -> String:
	match rarity:
		Rarity.COMMON:
			return "普通"
		Rarity.UNCOMMON:
			return "优秀"
		Rarity.RARE:
			return "稀有"
		Rarity.EPIC:
			return "史诗"
		Rarity.LEGENDARY:
			return "传说"
		_:
			return "未知"


## 创建战利品数据
static func create_loot(name: String, description: String, rarity: Rarity, value: int, icon: Texture2D = null, can_extract: bool = true) -> Dictionary:
	return {
		"name": name,
		"description": description,
		"rarity": rarity,
		"value": value,
		"icon": icon,
		"can_extract": can_extract
	}
