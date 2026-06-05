@tool
extends TextureRect
class_name Crosshair

## ===== 系统切换开关 =====
## 使用新系统（_draw绘制）- 当前禁用，因为偏移系统已关闭
@export var use_new_system: bool = false
## 调试模式：同时显示新旧系统对比
@export var debug_show_both: bool = false

## ===== 新系统参数 =====
## 内层中心点半径（像素）
@export var inner_dot_radius: float = 3.0
## 内层中心点颜色
@export var inner_dot_color: Color = Color(1, 1, 1, 0.9)
## 散布圆环线宽
@export var bloom_ring_width: float = 1.5
## 散布圆环颜色
@export var bloom_ring_color: Color = Color(1, 1, 1, 0.4)
## 散布圆环基础半径
@export var bloom_ring_base_radius: float = 20.0
## 散布圆环最大额外半径
@export var bloom_ring_max_extra: float = 40.0
## 平滑过渡速度
@export var smooth_speed: float = 10.0

## ===== 旧系统参数（保留） =====
# rotation_speed 已移除（旋转动画不再使用）

## ===== 运行时变量 =====
# 新系统平滑过渡用的变量
var _smoothed_drift_offset: Vector2 = Vector2.ZERO
var _smoothed_bloom_radius: float = 0.0

# 旧系统节点引用（可选，用于对比）
var old_inner_crosshair: TextureRect = null
var old_bloom_ring: TextureRect = null

func _ready() -> void:
	# 尝试获取旧系统节点（可能不存在）
	old_inner_crosshair = get_node_or_null("InnerDot")
	old_bloom_ring = get_node_or_null("BloomRing")

	set_process(false)
	if Engine.is_editor_hint():
		return
	Utils.onGameStart.connect(onGameStart)


func _exit_tree() -> void:
	# 信号连接会在节点释放时自动断开，无需手动断开
	# Utils 是 autoload，场景切换时可能已部分销毁，直接访问信号可能导致错误
	# 2024-06-05: 移除手动断开逻辑，依赖 Godot 自动清理
	pass

func onGameStart():
	set_process(true)
	# 仅隐藏鼠标光标，不限制在窗口内（玩家可将鼠标移出窗口）
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(delta: float) -> void:
	# 外层准星中心对准鼠标位置
	var mouse_pos = get_global_mouse_position()
	global_position = mouse_pos - pivot_offset * scale

	var gun = Utils.player.gun if Utils.player else null
	if gun:
		# ===== 新系统：计算漂移和散布（仅在启用时） =====
		if use_new_system or debug_show_both:
			var gun_pos = gun.global_position
			var base_direction = (mouse_pos - gun_pos).normalized()
			var base_angle = base_direction.angle()

			var drift_angle_rad = deg_to_rad(gun.drift_current)
			var actual_aim_angle = base_angle + drift_angle_rad
			var actual_aim_direction = Vector2.from_angle(actual_aim_angle)

			var visual_distance = 30.0
			var drift_max = gun._get_effective_drift_max()
			var drift_ratio = abs(gun.drift_current) / drift_max if drift_max > 0 else 0.0
			var target_offset = actual_aim_direction * visual_distance * drift_ratio

			var bloom_max = gun._get_effective_bloom_max() if gun._get_effective_bloom_max() > 0 else 1.0
			var bloom_ratio = gun.bloom_current / bloom_max
			var target_bloom_radius = bloom_ring_base_radius + bloom_ratio * bloom_ring_max_extra

			_smoothed_drift_offset = _smoothed_drift_offset.lerp(target_offset, smooth_speed * delta)
			_smoothed_bloom_radius = lerp(_smoothed_bloom_radius, target_bloom_radius, smooth_speed * delta)

			queue_redraw()

		# ===== 旧系统逻辑 =====
		if not use_new_system or debug_show_both:
			_update_old_system(gun)

func _update_old_system(gun: BaseGun) -> void:
	"""旧系统逻辑（保留对比）"""
	if old_bloom_ring:
		var bloom_max = gun._get_effective_bloom_max() if gun._get_effective_bloom_max() > 0 else 1.0
		var bloom_scale = 1.0 + (gun.bloom_current / bloom_max) * 2.0
		old_bloom_ring.scale = Vector2(bloom_scale, bloom_scale)

	if old_inner_crosshair:
		# 旧系统的偏移计算（有问题的版本，保留对比）
		var mouse_pos = get_global_mouse_position()
		var gun_pos = gun.global_position
		var aim_direction = (mouse_pos - gun_pos).normalized()
		var aim_angle = aim_direction.angle()

		var drift_angle_rad = deg_to_rad(gun.drift_current)
		var visual_distance = 30.0
		var perpendicular_angle = aim_angle + PI / 2
		var offset = Vector2(cos(perpendicular_angle), sin(perpendicular_angle)) * tan(drift_angle_rad) * visual_distance
		old_inner_crosshair.position = offset

func _draw() -> void:
	# 偏移系统已禁用，不再需要绘制散布圆环和内层中心点
	# 如果需要恢复，取消下面的注释
	return

	# ===== 以下代码暂时禁用 =====
	# if not use_new_system and not debug_show_both:
	# 	return
	#
	# var gun = Utils.player.gun if Utils.player else null
	# if not gun:
	# 	return
	#
	# # 准星中心点（纹理中心）
	# var center = size / 2
	#
	# # ===== 新系统绘制 =====
	# # 绘制内层中心点（实际瞄准方向）
	# var dot_pos = center + _smoothed_drift_offset
	# draw_circle(dot_pos, inner_dot_radius, inner_dot_color)
	#
	# # 绘制散布圆环（空心圆，跟随内层中心点）
	# var ring_center = dot_pos  # 圆环跟随中心点（实际瞄准位置）
	# # 使用draw_arc绘制空心圆环
	# var points = 32
	# var arc_points = []
	# for i in range(points + 1):
	# 	var angle = i * TAU / points
	# 	var point = ring_center + Vector2(cos(angle), sin(angle)) * _smoothed_bloom_radius
	# 	arc_points.append(point)
	# # 绘制圆环线条
	# for i in range(points):
	# 	draw_line(arc_points[i], arc_points[i + 1], bloom_ring_color, bloom_ring_width)
	#
	# # ===== 调试模式：绘制更多信息 =====
	# if debug_show_both:
	# 	# 绘制鼠标位置标记（小十字）
	# 	var mouse_marker_color = Color(0, 1, 0, 0.5)  # 绿色半透明
	# 	draw_line(center - Vector2(5, 0), center + Vector2(5, 0), mouse_marker_color, 1)
	# 	draw_line(center - Vector2(0, 5), center + Vector2(0, 5), mouse_marker_color, 1)
	#
	# 	# 绘制期望瞄准方向（白线）
	# 	var mouse_pos = get_global_mouse_position()
	# 	var gun_pos = gun.global_position
	# 	var base_direction = (mouse_pos - gun_pos).normalized()
	# 	# 在准星范围内绘制方向线
	# 	draw_line(center, center + base_direction * 20, Color(1, 1, 1, 0.3), 1)
