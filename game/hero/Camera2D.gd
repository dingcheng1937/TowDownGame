extends Camera2D

var is_shake = false

var center_horizontal = false
var center_vertical = false
var center_horizontal_pos:int
var center_vertical_pos:int


func _process(_delta:float)->void :
	if Utils.player:
		# 相机是Anchor的子节点，position应为局部偏移
		# 平滑跟随：lerp当前偏移到零偏移（即跟随Anchor/玩家）
		# 使用固定的平滑因子，每帧向零偏移靠近10%
		position = position.lerp(Vector2.ZERO, 0.1)
		# 像素对齐，避免亚像素抖动
		position = Vector2(int(position.x), int(position.y))

	if center_horizontal:
		global_position.x = center_horizontal_pos
	if center_vertical:
		global_position.y = center_vertical_pos

func _ready():
	add_to_group("camera")

func shootShake(_step):
	if int(Utils.shake) == 0:
		return
	if is_shake:
		return
	is_shake = true
	_step *= Utils.shake * 0.3  # 幅度降至30%
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self,"offset",_step,0.05)  # 时长缩短
	tween.tween_property(self,"offset",Vector2.ZERO,0.05)
	tween.tween_callback(func end():
		is_shake = false)
