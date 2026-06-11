extends CanvasLayer
## 简易 Toast 显示层（仅用于GYM验证场景）

var toast_lbl: Label

func _ready() -> void:
	toast_lbl = Label.new()
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.position = Vector2(0, 300)
	toast_lbl.size = Vector2(800, 40)
	toast_lbl.theme = Theme.new()
	add_child(toast_lbl)
	toast_lbl.visible = false

func showToast(msg: String, time: float = 1.0) -> void:
	toast_lbl.text = msg
	toast_lbl.visible = true
	var t := create_tween()
	t.tween_property(toast_lbl, "modulate:a", 1.0, 0.2).from(0.0)
	await get_tree().create_timer(time).timeout
	if is_instance_valid(toast_lbl):
		toast_lbl.visible = false
