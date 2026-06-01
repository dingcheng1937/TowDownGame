extends BaseMonster
class_name Aberration
## 畸变体 - 高血量、高伤害、慢速的诡异怪物

## 冲锋距离
@export var charge_distance: float = 200.0
## 冲锋速度倍率
@export var charge_speed_mult: float = 3.0
## 冲锋冷却
@export var charge_cooldown: float = 5.0

var _charge_timer: float = 0.0
var _is_charging: bool = false


func _ready() -> void:
	super._ready()
	# 畸变体特性：低速度、高血量、高伤害
	SPEED = 30.0
	HP = 15
	hurt = 2
	knockback_def = 10


func _physics_process(delta: float) -> void:
	if is_die:
		return

	_charge_timer -= delta

	if _is_charging:
		move_and_slide()
		return

	super._physics_process(delta)

	# 检查是否可以冲锋
	if target_player != null and _charge_timer <= 0:
		var distance = global_position.distance_to(target_player.global_position)
		if distance > charge_distance:
			_start_charge()


func _start_charge() -> void:
	_is_charging = true
	_charge_timer = charge_cooldown

	# 面向玩家
	var direction = global_position.direction_to(target_player.global_position)
	velocity = direction * SPEED * charge_speed_mult

	anim.play("attack")

	# 冲锋持续时间
	await get_tree().create_timer(0.5).timeout
	_is_charging = false


func onHit(hit_num: float, is_show_label: bool = true, is_death_effect: bool = true) -> void:
	# 畸变体有减伤
	var reduced_damage = hit_num * 0.7
	super.onHit(reduced_damage, is_show_label, is_death_effect)


func onDie(is_death_effect: bool = true) -> void:
	ExtractionServer.register_kill()
	super.onDie(is_death_effect)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_die:
		body.onHit(hurt)
		# 畸变体攻击造成额外理智伤害
		SanityServer.change_sanity(-10.0)
