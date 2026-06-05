extends Node2D
class_name BaseGun


const particles_pre = preload("res://game/hero/gpu_particles_2d.tscn")

## 武器ID
@export var weapon_id = 0 #枪械ID
@export var image:Texture #枪械图片
@export var weapon_name:String = "Gun" #枪械名称
@export_enum("ASSAULT_RIFLES","SUBMACHINE_GUNSRELOAD","MACHINE_GUNS","SNIPER_RIFLES","SHOTGUNS","LASER_WEAPONS") var weapon_type = "ASSAULT_RIFLES"
@export var bullet_scene : PackedScene #子弹模板
@export var damage = 0.0 #子弹伤害
@export var bullet_speed = 200 #子弹速度
@export var fire_rate = 5.0 #开火速率
@export var bullets_max_count = 10 #子弹数量
@export var change_speed = 1.0 #换弹时间
@export var recoil_duration = 0.2
@export var knockback_speed = 50 #击退速度
@export var knockback_time = 0.1 #击退持续时间
@export var time_scale = 0.1 #帧冻结时间倍数
@export var freeze_frame = 3 #帧冻结帧数
@export var recoil = 0 #后坐力大小
@export var shake_vector = Vector2.ZERO #屏幕晃动大小
@export var reload_stream :AudioStream = load("res://audio/bullet/GUNMech_Insert Clip_01.wav")

@export_group("Aim Drift")
@export var drift_accumulation: float = 1.5 #每发增加的漂移（度/发）
@export var drift_max: float = 10.0 #最大漂移量（度）
@export var drift_recovery: float = 25.0 #恢复速度（度/秒）
@export var drift_recovery_delay: float = 0.15 #停止射击后多久开始恢复（秒）

@export_group("Bloom")
@export var bloom_per_shot: float = 1.0 #每发增加的散布（度/发）
@export var bloom_max: float = 8.0 #最大散布半径（度）
@export var bloom_base: float = 0.5 #基础散布（首发也有微小散布）
@export var bloom_recovery: float = 20.0 #恢复速度（度/秒）

var attachments = {
	"Optics" = null,
	"Muzzle" = null,
	"Barrel" = null,
	"Underbarrel" = null,
	"Ammunition" = null,
	"Stock" = null,
	"Tactical" = null,
	"Perks" = null
}

@onready var anim_player:AnimationPlayer = $AnimationPlayer
@onready var gun_tip = $GunTip
@onready var audio = $AudioStreamPlayer2D
@onready var timer = $shoot_timer
@onready var gun_image = $Sprite2D

var attachments_node = Node.new()
var attachments_dict = {}
var tween:Tween
var direction:Vector2 #朝向
var player:Player #使用玩家
var is_use = false #是否正在使用
var can_shoot = true #是否可以射击
var bullets_count = 0: #剩余子弹
	set(value):
		bullets_count = value
		if is_use:
			PlayerData.emit_signal("onWeaponBulletsChange",bullets_count,bullets_max_count) 
var is_reloading = false #是否正在换子弹
var change_timer = Timer.new()
var audio_reload_ammo = AudioStreamPlayer.new()

# Aim Drift + Bloom 运行时变量
var drift_current: float = 0.0 #当前漂移量（度）
var bloom_current: float = 0.0 #当前散布半径（度）
var _time_since_last_shot: float = 999.0 #距离上次射击的时间
var _is_firing: bool = false #当前帧是否在射击

@export var debug_aim_visualization: bool = false #调试可视化开关

func _init():
	change_timer.one_shot = true
	change_timer.timeout.connect(reload_over)
	
func _ready() -> void:
	add_to_group("guns")
	PlayerData.onPlayerFireRateChange.connect(onPlayerFireRateChange)
	add_child(attachments_node)
	bullets_count = bullets_max_count
	add_child(change_timer)
	audio_reload_ammo.stream = reload_stream
	add_child(audio_reload_ammo)
	gun_image.texture = image
	set_use(false)
	timer.wait_time = 1.0 / fire_rate

func _exit_tree() -> void:
	# 断开信号连接，避免内存泄漏
	if PlayerData.onPlayerFireRateChange.is_connected(onPlayerFireRateChange):
		PlayerData.onPlayerFireRateChange.disconnect(onPlayerFireRateChange)

func onPlayerFireRateChange(rate):
	timer.wait_time = 1.0 / (fire_rate * rate)

#更新枪械配置
func updateGun():
	bullets_max_count = int(bullets_max_count * (1+PlayerData.base_magazine_count))
	timer.wait_time = 1.0 / fire_rate
	PlayerData.emit_signal("onWeaponBulletsChange",bullets_count,bullets_max_count) 

#添加配件
func addAttachMent(am:BaseAttachment):
	if !attachments_node.has_node(str(am.id)):
		attachments_dict[am.am_type] = am
		am.reparent(attachments_node)
		am.onWeaponUp(self)

#移除配件
func removeAttachMent(am:BaseAttachment):
	if attachments_node.has_node(str(am.id)):
		attachments_dict.erase(am.am_type)
		am.reparent(PlayerData)
		am.onWeaponDown()

#子弹装填完毕
func reload_over():
	var ammo = bullets_max_count - bullets_count
	if PlayerData.player_ammo < ammo:
		ammo = PlayerData.player_ammo
		PlayerData.player_ammo = 0
	else:
		PlayerData.player_ammo -= ammo
	bullets_count += ammo
	PlayerData.emit_signal("onWeaponChangeAnim",weapon_id,Utils.GUN_CHANGE_TYPE.RELOAD)
	is_reloading = false

#设置枪械所属
func setOwner(player):
	self.player = player

func _process(delta):
	if Utils.freeze_frame:
		delta = 0.0

	_time_since_last_shot += delta

	# === 偏移系统暂时禁用 ===
	# 恢复逻辑：停止射击后逐渐恢复
	# if !_is_firing && _time_since_last_shot > drift_recovery_delay:
	#	drift_current = move_toward(drift_current, 0.0, _get_effective_drift_recovery() * delta)
	#	bloom_current = move_toward(bloom_current, _get_effective_bloom_base(), _get_effective_bloom_recovery() * delta)

	_is_firing = false

	# 调试可视化刷新
	if debug_aim_visualization:
		queue_redraw()

	# 计算实际瞄准方向 = 鼠标方向 + drift偏移
	var mouse_pos = get_global_mouse_position()
	var base_direction = (mouse_pos - gun_tip.global_position).normalized()
	var base_angle = base_direction.angle()

	# drift 沿射击方向向外偏移（模拟后坐力把枪口推偏）
	# === 偏移系统暂时禁用 ===
	# var drift_angle = base_angle + deg_to_rad(drift_current)
	# direction = Vector2.from_angle(drift_angle)
	# gun_tip.rotation = drift_angle

	# 精确瞄准：方向直接指向鼠标
	direction = base_direction
	gun_tip.rotation = base_angle

	if Input.is_action_pressed("shoot") and can_shoot and !is_reloading:
		can_shoot = false
		timer.start()
		if bullets_count > 0:
			_shoot()
		else:
			reload_ammo()

	if is_use && Input.is_action_pressed("reload"):
		reload_ammo()

#设置是否正在使用
func set_use(use:bool):
	change_timer.stop()
	is_reloading = false
	is_use = use
	set_physics_process(is_use)
	set_process(is_use)
	visible = is_use
	# 切换武器时重置drift/bloom
	drift_current = 0.0
	bloom_current = _get_effective_bloom_base()
	_time_since_last_shot = 999.0
	_is_firing = false
	if player && is_use:
		player.gun = self
		PlayerData.emit_signal("onWeaponChangeAnim",weapon_id)
		if bullets_count == 0:
			reload_ammo()
	PlayerData.emit_signal("onWeaponChanged")

#开火
func fire(bullet:Bullet,is_bullet = true,is_play = true):
	if is_bullet:
		bullets_count -= 1
		if bullets_count < 0:
			can_shoot = false
			bullet.queue_free()
			return
	
	bullet.speed = bullet_speed
	bullet.hurt = damage * (1+PlayerData.base_bullet_damage)
	bullet.knockback_speed = knockback_speed
	bullet.knockback_time = knockback_time
	bullet.gun = self
	if is_bullet:
		bullet.fire()
	if recoil > 0 && is_bullet:
		player.set_knockback(recoil * 0.3)
	if is_play:
		audio.play()

#切换子弹
func reload_ammo():
	if PlayerData.player_ammo == 0:
		Utils.showToast("AMMO_OUT")
		return 
	if !is_reloading && change_timer.is_stopped() && bullets_count < bullets_max_count:
		is_reloading = true
		var local_speed = change_speed * (1-PlayerData.base_reload_speed) 
		anim_player.speed_scale = 1 / local_speed
		change_timer.start(local_speed)
		audio_reload_ammo.play()
		playReload()

#播放切换动画
func playReload():
	anim_player.play("reload")

func _physics_process(delta):
	if Utils.freeze_frame:
		delta = 0.0
	#if Utils.freeze_frame:
		#if Engine.get_physics_frames() % freeze_frame == 0:
			# 暂停一帧
		#	Utils.freeze_frame = false
			# 将时间比例设置为1
		#	Engine.time_scale = 1
		#	return

func _shoot() -> void:
	call_deferred("_shootAnim")

# 累积drift和bloom，射击时调用
func _apply_recoil():
	drift_current = minf(drift_current + _get_effective_drift_accumulation(), _get_effective_drift_max())
	bloom_current = minf(bloom_current + _get_effective_bloom_per_shot(), _get_effective_bloom_max())
	_time_since_last_shot = 0.0
	_is_firing = true

# 获取实际射击角度（含drift + bloom随机偏移）
# === 偏移系统暂时禁用：子弹精确飞向鼠标 ===
func get_shoot_angle() -> float:
	var mouse_pos = get_global_mouse_position()
	var base_angle = (mouse_pos - gun_tip.global_position).normalized().angle()
	# drift + bloom 偏移已禁用
	# var drift_angle = base_angle + deg_to_rad(drift_current)
	# var bloom_offset = deg_to_rad(randf_range(-bloom_current, bloom_current))
	# return drift_angle + bloom_offset
	return base_angle

# 获取配件修正后的drift累积值
func _get_effective_drift_accumulation() -> float:
	var mod = 0.0
	for am in attachments_dict.values():
		mod += am.drift_accumulation_mod
	return drift_accumulation * (1.0 + mod)

# 获取配件修正后的bloom每发增加值
func _get_effective_bloom_per_shot() -> float:
	var mod = 0.0
	for am in attachments_dict.values():
		mod += am.bloom_per_shot_mod
	return bloom_per_shot * (1.0 + mod)

# 获取配件修正后的drift最大值
func _get_effective_drift_max() -> float:
	var mod = 0.0
	for am in attachments_dict.values():
		mod += am.drift_max_mod
	return drift_max * (1.0 + mod)

# 获取配件修正后的drift恢复速度
func _get_effective_drift_recovery() -> float:
	var mod = 0.0
	for am in attachments_dict.values():
		mod += am.drift_recovery_mod
	return drift_recovery * (1.0 + mod)

# 获取配件修正后的bloom最大值
func _get_effective_bloom_max() -> float:
	var mod = 0.0
	for am in attachments_dict.values():
		mod += am.bloom_max_mod
	return bloom_max * (1.0 + mod)

# 获取配件修正后的bloom基础值
func _get_effective_bloom_base() -> float:
	var mod = 0.0
	for am in attachments_dict.values():
		mod += am.bloom_base_mod
	return bloom_base * (1.0 + mod)

# 获取配件修正后的bloom恢复速度
func _get_effective_bloom_recovery() -> float:
	var mod = 0.0
	for am in attachments_dict.values():
		mod += am.bloom_recovery_mod
	return bloom_recovery * (1.0 + mod)

func _shootAnim():
	player.cameraSnake(shake_vector * direction)
	var ins = particles_pre.instantiate()
	ins.position = gun_tip.position
	add_child(ins)

func _draw():
	if !debug_aim_visualization || !is_use:
		return
	var tip_pos = gun_tip.position
	var mouse_pos = to_local(get_global_mouse_position())
	# 白线：鼠标方向（期望瞄准方向）
	draw_line(tip_pos, mouse_pos, Color.WHITE, 1)
	# 红线：实际射击方向（含drift）
	var drift_end = tip_pos + direction * 200
	draw_line(tip_pos, drift_end, Color.RED, 1)
	# 绿圈：当前bloom范围
	var bloom_radius = deg_to_rad(bloom_current) * 200
	draw_arc(tip_pos + direction * 100, bloom_radius, 0, TAU, 32, Color.GREEN, 1)
