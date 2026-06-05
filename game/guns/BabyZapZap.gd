extends "res://game/guns/BaseGun.gd"

func _shoot():
	super._shoot()
	_apply_recoil()
	var shoot_angle = get_shoot_angle()
	gun_tip.rotation = shoot_angle
	createBullet()

func createBullet():
	for i in 3:
		# 每发都累积drift（第一发已在_shoot中累积）
		if i > 0:
			_apply_recoil()
		var b = bullet_scene.instantiate()
		b.setOnwer(player)
		get_tree().root.add_child(b)
		b.position = gun_tip.global_position
		# 直接使用get_shoot_angle()，它会读取当前的drift/bloom值
		b.rotation = get_shoot_angle()
		fire(b)
		call_deferred("_shootAnim")
		await get_tree().create_timer(0.15).timeout

func _shootAnim():
	super._shootAnim()
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(self, "position", position, 0.15).from(position + Vector2(-1, -1))
	tween.tween_property($Sprite2D, "scale", Vector2(1,1), 0.15).from(Vector2(0.5, 1.1))

func _on_timer_timeout():
	can_shoot = true
