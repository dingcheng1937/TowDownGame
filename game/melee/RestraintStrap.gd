extends BaseMeleeWeapon

@export var bind_duration = 2.0

func _ready():
	weapon_name = "约束带"
	weapon_id = 1003
	damage = 5.0
	max_durability = 50.0
	attack_range = 80.0
	attack_rate = 0.6
	attack_duration = 0.25
	weapon_rarity = "SPECIAL"
	weapon_info = "用于保护患者安全。使用记录缺失。"
	
	super._ready()

func _on_apply_damage(monster:BaseMonster):
	monster.onHit(damage)
	
	_apply_bind_effect(monster)
	
	var knockback = (monster.global_position - player.global_position).normalized() * 15
	monster.velocity = knockback
	monster.hit = true
	await get_tree().create_timer(0.1).timeout
	# 检查怪物是否仍然有效
	if is_instance_valid(monster):
		monster.hit = false

func _apply_bind_effect(monster:BaseMonster):
	if monster.state_array.has(Utils.STATE_TYPE.STUN):
		return
	
	monster.state_array.append(Utils.STATE_TYPE.STUN)
	monster.velocity = Vector2.ZERO
	monster.anim.play("idle")
	
	var stun_effect = preload("res://game/effects/StunEffect.tscn").instantiate()
	monster.addEffect(stun_effect)
	
	await get_tree().create_timer(bind_duration).timeout

	# 检查武器和怪物是否仍然有效
	if not is_instance_valid(self) or not is_instance_valid(monster):
		return

	if monster.state_array.has(Utils.STATE_TYPE.STUN):
		monster.state_array.erase(Utils.STATE_TYPE.STUN)

	var effect_root = monster.get_node_or_null("EffectRoot")
	if effect_root:
		for effect in effect_root.get_children():
			if effect.name == "StunEffect":
				effect.queue_free()
				break