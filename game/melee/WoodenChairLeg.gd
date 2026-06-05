extends BaseMeleeWeapon

func _ready():
	weapon_name = "木制椅腿"
	weapon_id = 1002
	damage = 15.0
	max_durability = 30.0
	attack_range = 70.0
	attack_rate = 1.2
	attack_duration = 0.2
	weapon_rarity = "NORMAL"
	weapon_info = "从活动室拆下来的。活动室已经很久没有活动了。"
	
	super._ready()