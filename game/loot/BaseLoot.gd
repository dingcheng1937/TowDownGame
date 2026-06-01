extends Area2D
class_name BaseLoot
## 战利品基类 - 可以被玩家拾取的物品

signal picked_up()

## 稀有度 - 使用 LootServer 的定义
var rarity: int = LootServer.Rarity.COMMON

@export var item_name: String = "Unknown Item"
@export_multiline var description: String = ""
@export var value: int = 10
@export var can_extract: bool = true  # 是否可以带出
@export var icon: Texture2D

## 是否已被拾取
var is_picked: bool = false

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var _label: Label = get_node_or_null("Label")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_update_appearance()


func _update_appearance() -> void:
	if _sprite and icon:
		_sprite.texture = icon

	if _label:
		_label.text = item_name + " [E]"
		_label.modulate = LootServer.get_rarity_color(rarity)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_picked:
		_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("e") and _label and _label.visible and not is_picked:
		get_viewport().set_input_as_handled()
		pickup()


func pickup() -> void:
	if is_picked:
		return

	is_picked = true

	# 创建战利品数据
	var loot_data = {
		"name": item_name,
		"description": description,
		"rarity": rarity,
		"value": value,
		"icon": icon,
		"can_extract": can_extract
	}

	# 添加到战利品系统
	if LootServer.add_loot(loot_data):
		emit_signal("picked_up")
		_on_pickup_effect()
		queue_free()


func _on_pickup_effect() -> void:
	# 拾取音效和视觉效果
	pass
