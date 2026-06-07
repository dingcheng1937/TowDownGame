extends Node2D
## 地上的配件 - 可被玩家拾取并安装到武器

@export var attachment: BaseAttachment

var is_picked = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var area: Area2D = $Area2D

func _ready():
	# 等待一帧确保父节点完成初始化
	await get_tree().process_frame
	_update_display()

func _update_display():
	if attachment and sprite:
		sprite.texture = attachment.am_image
		if label:
			label.text = attachment.am_name + " [E]"

func _unhandled_input(event):
	if event.is_action_pressed("e") and label.visible and not is_picked:
		get_viewport().set_input_as_handled()
		pickup()

## 拾取配件并添加到背包
func pickup():
	if is_picked:
		return
	is_picked = true

	# 检查玩家是否存在
	if Utils.player == null:
		Utils.showToast("NO_PLAYER")
		is_picked = false
		return

	# 将配件添加到背包
	PlayerData.add_attachment(attachment)

	# 显示拾取成功提示
	Utils.showToast("%s added to inventory!" % attachment.am_name)

	# 播放拾取效果后消失
	_play_pickup_effect()

func _play_pickup_effect():
	# 简单的消失动画
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)

func _on_area_2d_body_entered(body):
	if body is Player and not is_picked:
		label.visible = true

func _on_area_2d_body_exited(body):
	if body is Player:
		label.visible = false