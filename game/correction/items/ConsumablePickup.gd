extends Area2D
class_name ConsumablePickup
## 地面消耗品拾取 - 药片/食物/镇静剂

signal consumed

@export var heal_amount: int = 0
@export var sanity_amount: float = 0.0
@export var speed_modifier: float = 0.0
@export var speed_modifier_duration: float = 0.0
@export var item_name: String = "消耗品"
@export_multiline var description: String = ""
@export var narrative_id: String = ""

var _is_consumed: bool = false


func _ready() -> void:
	var label: Label = get_node_or_null("Label") as Label
	if label:
		label.text = item_name + " [E]"
		label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not _is_consumed:
		var label: Label = get_node_or_null("Label") as Label
		if label: label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		var label: Label = get_node_or_null("Label") as Label
		if label: label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	var label: Label = get_node_or_null("Label") as Label
	if event.is_action_pressed("e") and label and label.visible and not _is_consumed:
		get_viewport().set_input_as_handled()
		use()


func use() -> void:
	if _is_consumed: return
	_is_consumed = true
	if heal_amount > 0:
		PlayerData.addPlayerHp(heal_amount)
		Utils.showHitLabelMore("+%d" % heal_amount, Utils.player, Vector2(0, -20), Color.SPRING_GREEN)
	if sanity_amount > 0.0 and is_instance_valid(SanityServer):
		SanityServer.change_sanity(sanity_amount)
	# 速度修正协程
	if speed_modifier != 0.0 and speed_modifier_duration > 0.0:
		_apply_speed_mod()
	else:
		_finish()


func _apply_speed_mod() -> void:
	PlayerData.player_speed += speed_modifier
	if Utils.player and Utils.player.has_method("updateHero"):
		Utils.player.updateHero()
	await get_tree().create_timer(speed_modifier_duration).timeout
	if is_instance_valid(Utils.player) and Utils.player.has_method("updateHero"):
		PlayerData.player_speed -= speed_modifier
		Utils.player.updateHero()
	_finish()


func _finish() -> void:
	if narrative_id != "" and description != "":
		EventBus.lore_fragment_found.emit(narrative_id, description)
	consumed.emit()
	queue_free()
