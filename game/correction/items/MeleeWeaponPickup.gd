extends BaseLoot
class_name MeleeWeaponPickup
## 近战武器地面拾取 - 玩家走近后按E拾取装备近战武器

@export var melee_weapon_scene: PackedScene
@export var weapon_display_name: String = "近战武器"


func _ready() -> void:
	rarity = LootServer.Rarity.UNCOMMON
	can_extract = false
	value = 30
	item_name = weapon_display_name
	super._ready()


func pickup() -> void:
	if is_picked:
		return

	# 实例化武器场景
	if melee_weapon_scene == null:
		push_error("MeleeWeaponPickup: melee_weapon_scene is null")
		return
	var weapon: Node = melee_weapon_scene.instantiate()
	if not weapon is BaseMeleeWeapon:
		push_error("MeleeWeaponPickup: instantiated scene is not a BaseMeleeWeapon")
		weapon.queue_free()
		return

	# 获取玩家引用
	var player: Player = Utils.player as Player
	if not is_instance_valid(player):
		push_error("MeleeWeaponPickup: Utils.player is not valid")
		weapon.queue_free()
		return

	# 查找 gun_root（优先 body/GunRoot，fallback gun_root）
	var gun_root: Node2D = null
	gun_root = player.get_node_or_null("body/GunRoot") as Node2D
	if gun_root == null:
		gun_root = player.get_node_or_null("gun_root") as Node2D
	if gun_root == null:
		push_error("MeleeWeaponPickup: cannot find gun_root on player")
		weapon.queue_free()
		return

	# 所有校验通过，标记已拾取
	is_picked = true

	# 替换旧近战武器
	if is_instance_valid(player.melee_weapon):
		player.melee_weapon.queue_free()

	# 添加新武器到场景
	weapon.name = "melee_0"
	gun_root.add_child(weapon)
	weapon.setOwner(player)
	weapon.set_use(true)

	Utils.showToast("装备了" + weapon_display_name)

	# 添加到战利品系统
	var loot_data: Dictionary = {
		"name": item_name,
		"description": description,
		"rarity": rarity,
		"value": value,
		"icon": icon,
		"can_extract": can_extract
	}
	if LootServer.add_loot(loot_data):
		picked_up.emit()
		queue_free()
