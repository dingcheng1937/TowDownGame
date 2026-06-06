extends Node2D
class_name BaseMeleeWeapon

@export var weapon_name:String = "Melee Weapon"
@export var weapon_id = 0
@export var damage = 0.0
@export var max_durability = 100.0
@export var attack_range = 60.0
@export var attack_rate = 1.0
@export var attack_duration = 0.2
@export var image:Texture
@export_multiline var weapon_info = ""

@export_enum("NORMAL", "SPECIAL", "RARE") var weapon_rarity = "NORMAL"

var current_durability = 0.0
var is_broken = false
var can_attack = true
var is_attacking = false
var player:Player
var is_use = false

var attack_timer: Timer
var hitbox: Area2D = null

@onready var weapon_sprite: Sprite2D = $Sprite2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready():
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown)
	add_child(attack_timer)

	current_durability = max_durability
	if weapon_sprite and image:
		weapon_sprite.texture = image
	set_process(false)
	visible = false


func _exit_tree() -> void:
	# 清理可能残留的hitbox，避免内存泄漏
	if hitbox and is_instance_valid(hitbox):
		hitbox.queue_free()
		hitbox = null

func setOwner(p_player):
	self.player = p_player

func set_use(use:bool):
	is_use = use
	visible = use
	set_process(use)
	set_physics_process(use)
	if use && player:
		player.melee_weapon = self
		PlayerData.emit_signal("onWeaponChanged")
		# 确保武器显示在正确位置
		if player.gun:
			position = player.gun.position
			rotation = player.gun.rotation

func _process(_delta):
	if !is_use || is_broken:
		return

	# 只在游戏鼠标模式下允许攻击（UI打开时禁止）
	if not Utils.can_player_act():
		return

	if Input.is_action_just_pressed("melee_attack") && can_attack && !is_attacking:
		_attack()

func _attack():
	if is_broken:
		Utils.showToast("WEAPON_BROKEN")
		return
	
	is_attacking = true
	can_attack = false
	attack_timer.wait_time = 1.0 / max(0.001, attack_rate)
	attack_timer.start()
	
	_play_attack_animation()
	_create_hitbox()

func _play_attack_animation():
	if audio and audio.stream:
		if audio.playing:
			audio.stop()
		audio.play()
	
	if weapon_sprite:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(weapon_sprite, "rotation", deg_to_rad(-45), attack_duration * 0.5)
		tween.tween_property(weapon_sprite, "rotation", deg_to_rad(45), attack_duration * 0.5)

func _create_hitbox():
	if hitbox:
		hitbox.queue_free()
	
	hitbox = Area2D.new()
	hitbox.name = "MeleeHitbox"
	
	var shape = CircleShape2D.new()
	shape.radius = attack_range
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	hitbox.add_child(collision_shape)
	
	hitbox.monitoring = true
	hitbox.monitorable = true
	hitbox.area_entered.connect(_on_hitbox_area)
	hitbox.body_entered.connect(_on_hitbox_body)
	
	# 计算攻击位置 - 使用玩家前方位置
	var attack_pos = global_position
	if player:
		attack_pos = player.global_position
		# 如果有方向，攻击位置在玩家前方
		if player.look_dir:
			attack_pos += player.look_dir * attack_range * 0.5
	hitbox.global_position = attack_pos
	# 将hitbox添加到武器节点下，而非场景根节点，避免场景切换时成为孤儿节点
	add_child(hitbox)
	
	await get_tree().create_timer(attack_duration).timeout
	# 检查武器是否仍然有效（可能在等待期间被丢弃/切换）
	if not is_instance_valid(self):
		return
	if hitbox:
		hitbox.queue_free()
		hitbox = null
	is_attacking = false

func _on_hitbox_area(area):
	var parent = area.get_parent()
	if parent is BaseMonster && !parent.is_die:
		_on_hit_monster(parent)

func _on_hitbox_body(body):
	if body is BaseMonster && !body.is_die:
		_on_hit_monster(body)

func _on_hit_monster(monster:BaseMonster):
	if is_broken:
		return
	
	_on_apply_damage(monster)
	
	current_durability -= 1.0
	if current_durability <= 0:
		_on_weapon_broken()
	
	PlayerData.emit_signal("onMeleeDurabilityChange", current_durability, max_durability)

func _on_apply_damage(monster:BaseMonster):
	monster.onHit(damage)

	# 检查player是否有效（可能在攻击期间失效）
	if not is_instance_valid(player):
		return
	var knockback = (monster.global_position - player.global_position).normalized() * 30
	monster.velocity = knockback
	monster.hit = true
	await get_tree().create_timer(0.1).timeout
	# 检查怪物是否仍然有效（可能在等待期间死亡）
	if is_instance_valid(monster):
		monster.hit = false

func _on_weapon_broken():
	is_broken = true
	if weapon_sprite:
		weapon_sprite.modulate = Color(0.3, 0.3, 0.3)
	Utils.showToast("WEAPON_BROKEN")
	_on_become_junk()

func _on_become_junk():
	pass

func _on_attack_cooldown():
	can_attack = true

func get_durability_percentage():
	return current_durability / max_durability

func _get_effective_damage():
	return damage * (1 + PlayerData.player_damage)