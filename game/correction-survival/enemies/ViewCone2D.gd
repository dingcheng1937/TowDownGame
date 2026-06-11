extends Area2D
class_name ViewCone2D
## 视觉锥组件 — 扇形检测区域

signal player_detected(player: Node)
signal player_lost()

@export var cone_angle: float = 120.0       # 扇形角度
@export var cone_radius: float = 200.0      # 检测半径
@export var cone_color: Color = Color(1, 1, 0, 0.15)  # 视锥颜色（debug）

var _targets_in_cone: Array[Node] = []
var _has_player: bool = false
var _polygon: CollisionPolygon2D

func _ready() -> void:
	_polygon = get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if not _polygon:
		_polygon = CollisionPolygon2D.new()
		_polygon.name = "CollisionPolygon2D"
		add_child(_polygon)
	_build_cone_shape()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _build_cone_shape() -> void:
	var points: PackedVector2Array = []
	points.append(Vector2.ZERO)
	var segments: int = 16
	var half_angle: float = deg_to_rad(cone_angle * 0.5)
	for i in range(segments + 1):
		var a: float = -half_angle + (cone_angle / segments) * i
		var p: Vector2 = Vector2(cos(a), sin(a)) * cone_radius
		points.append(p)
	if _polygon:
		_polygon.polygon = points

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_targets_in_cone.append(body)
		_has_player = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_targets_in_cone.erase(body)
		if _targets_in_cone.size() == 0 and _has_player:
			_has_player = false
			player_lost.emit()

func _process(_delta: float) -> void:
	if _has_player:
		for target in _targets_in_cone:
			if is_instance_valid(target):
				player_detected.emit(target)
				return

func is_body_in_cone(body: Node2D) -> bool:
	return _targets_in_cone.has(body)
