@tool
extends TextureRect

var rotation_speed = PI

func _ready() -> void:
	set_process(false)
	# 在编辑器模式下不连接信号
	if Engine.is_editor_hint():
		return
	Utils.onGameStart.connect(onGameStart)

func onGameStart():
	set_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN

func _process(delta: float) -> void:
	rotation += rotation_speed * delta
	global_position = get_global_mouse_position() - size  / 2
	
