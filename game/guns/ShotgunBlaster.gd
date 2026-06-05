extends "res://game/guns/BaseGun.gd"


func _shoot():
	super._shoot()
	_apply_recoil()
	var shoot_angle = get_shoot_angle()
	gun_tip.rotation = shoot_angle
	# 捕获bloom值，保持与其他霰弹枪一致的语义
	var captured_bloom = bloom_current
	for i in 3:
		var b = bullet_scene.instantiate()
		b.setOnwer(player)
		b.knockback_speed = knockback_speed
		get_tree().root.add_child(b)
		b.position = gun_tip.global_position
		# 霰弹枪：基础散布 + bloom叠加（使用捕获的bloom值）
		var pellet_spread = deg_to_rad(-15 + i * 15)
		b.rotation = shoot_angle + pellet_spread + deg_to_rad(randf_range(-captured_bloom * 0.3, captured_bloom * 0.3))
		fire(b,true,false)

func _shootAnim():
	super._shootAnim()
	audio.play()
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(self, "position", position, timer.wait_time).from(position + Vector2(-1, -1))
	tween.tween_property($Sprite2D, "scale", Vector2(1,1), timer.wait_time).from(Vector2(0.5, 1.1))

func _on_timer_timeout():
	can_shoot = true
