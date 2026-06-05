extends Node2D

@onready var sprite = $Sprite2D

func _ready():
	_play_animation()

func _play_animation():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "scale", Vector2(2.5, 2.5), 0.2)
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(sprite, "modulate:a", 0.5, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)