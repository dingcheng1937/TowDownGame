extends BaseMeleeWeapon

func _ready():
	weapon_name = "输液架"
	weapon_id = 1001
	damage = 8.0
	max_durability = 150.0
	attack_range = 100.0
	attack_rate = 0.8
	attack_duration = 0.3
	weapon_rarity = "NORMAL"
	weapon_info = "被固定在病床旁。有些人一辈子也没等来输液结束。"
	
	super._ready()

func _on_apply_damage(monster:BaseMonster):
	monster.onHit(damage * 0.8)
	
	var knockback = (monster.global_position - player.global_position).normalized() * 25
	monster.velocity = knockback
	monster.hit = true
	await get_tree().create_timer(0.15).timeout
	# 检查怪物是否仍然有效
	if is_instance_valid(monster):
		monster.hit = false