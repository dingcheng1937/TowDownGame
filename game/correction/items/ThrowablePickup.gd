extends Area2D
class_name ThrowablePickup
## 投掷物地面拾取 - 石子/药瓶/餐盘

signal picked_up(item_type: int, item_name: String)

@export var throwable_type: ThrowableItem.ThrowableType = ThrowableItem.ThrowableType.STONE
@export var item_name: String = "石子"
@export_multiline var description: String = ""

var _is_picked: bool = false


func _ready() -> void:
	var label: Label = get_node_or_null("Label") as Label
	if label:
		label.text = item_name + " [E]"
		label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not _is_picked:
		var label: Label = get_node_or_null("Label") as Label
		if label: label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		var label: Label = get_node_or_null("Label") as Label
		if label: label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	var label: Label = get_node_or_null("Label") as Label
	if event.is_action_pressed("e") and label and label.visible and not _is_picked:
		get_viewport().set_input_as_handled()
		pickup()


func pickup() -> void:
	if _is_picked: return
	_is_picked = true
	var key: String = _get_storage_key()
	var current: int = 0
	if PlayerData.has_meta(key):
		current = PlayerData.get_meta(key)
	PlayerData.set_meta(key, current + 1)
	EventBus.throwable_count_changed.emit(_get_type_string(), current + 1)
	picked_up.emit(throwable_type, item_name)
	Utils.showToast("获得" + item_name)
	if description != "":
		EventBus.lore_fragment_found.emit("throwable_" + item_name, description)
	queue_free()


func _get_storage_key() -> String:
	match throwable_type:
		ThrowableItem.ThrowableType.STONE: return "stone_count"
		ThrowableItem.ThrowableType.MEDICINE_BOTTLE: return "bottle_count"
		ThrowableItem.ThrowableType.PLATE: return "plate_count"
	return "stone_count"


func _get_type_string() -> String:
	match throwable_type:
		ThrowableItem.ThrowableType.STONE:
			return "stone"
		ThrowableItem.ThrowableType.MEDICINE_BOTTLE:
			return "bottle"
		ThrowableItem.ThrowableType.PLATE:
			return "plate"
		_:
			return "stone"
