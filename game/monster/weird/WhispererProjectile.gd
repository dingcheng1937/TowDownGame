extends Area2D
class_name WhispererProjectile
## 低语者投射物

@export var speed: float = 150.0
@export var damage: int = 1
@export var sanity_damage: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 3.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)

	# 设置超时销毁
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _process(delta: float) -> void:
	position += direction * speed * delta

	# 旋转精灵
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.onHit(damage)
		SanityServer.change_sanity(-sanity_damage)
		queue_free()
	elif body is StaticBody2D:
		queue_free()
