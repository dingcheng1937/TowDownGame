extends BaseMeleeWeapon

@export var shock_duration = 0.5

func _ready():
	weapon_name = "电击棒"
	weapon_id = 1004
	damage = 35.0
	max_durability = 120.0
	attack_range = 65.0
	attack_rate = 0.5
	attack_duration = 0.25
	weapon_rarity = "RARE"
	weapon_info = "非医疗器械。但使用频率远高于医疗器械。"
	
	super._ready()

func _on_apply_damage(monster:BaseMonster):
	monster.onHit(damage)
	
	_apply_shock_effect(monster)
	
	var knockback = (monster.global_position - player.global_position).normalized() * 40
	monster.velocity = knockback
	monster.hit = true
	await get_tree().create_timer(0.1).timeout
	# 检查怪物是否仍然有效
	if is_instance_valid(monster):
		monster.hit = false

func _apply_shock_effect(monster:BaseMonster):
	if monster.state_array.has(Utils.STATE_TYPE.STUN):
		return

	monster.state_array.append(Utils.STATE_TYPE.STUN)
	monster.velocity = Vector2.ZERO
	monster.anim.play("idle")

	var shock_effect = preload("res://game/effects/ShockEffect.tscn").instantiate()
	monster.addEffect(shock_effect)

	await get_tree().create_timer(shock_duration).timeout

	# 检查武器和怪物是否仍然有效
	if not is_instance_valid(self) or not is_instance_valid(monster):
		return

	if monster.state_array.has(Utils.STATE_TYPE.STUN):
		monster.state_array.erase(Utils.STATE_TYPE.STUN)

	var effect_root = monster.get_node_or_null("EffectRoot")
	if effect_root:
		for effect in effect_root.get_children():
			if effect.name == "ShockEffect":
				effect.queue_free()
				break