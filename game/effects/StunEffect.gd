extends Node2D

@onready var sprite = $Sprite2D

func _ready():
	_play_animation()

func _play_animation():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.3, 0.5)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)