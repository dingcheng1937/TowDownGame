extends CanvasLayer
class_name SurvivalHUD
## 生存HUD — 血量/体力/武器耐久/警觉度

func _ready() -> void:
	PlayerData.onHpChange.connect(_on_hp_changed)
	StaminaServer.stamina_changed.connect(_on_stamina_changed)
	EventBus.throwable_count_changed.connect(_on_throwable_changed)
	AlertServer.alert_changed.connect(_on_alert_changed)
	_update_all()

func _on_hp_changed(hp: int, max_hp: int) -> void:
	_set_bar("HPBar", hp, max_hp)
	_set_label("HPLabel", "%d/%d" % [hp, max_hp])

func _on_stamina_changed(current: float, max: float) -> void:
	_set_bar("StaminaBar", current, max)
	if current <= 0:
		_set_label("StaminaLabel", "体力耗尽")
	else:
		_set_label("StaminaLabel", "%d/%d" % [current, max])

func _on_throwable_changed(_type: String, _count: int) -> void:
	pass  # 后续扩展

func _on_alert_changed(current: float, max: float) -> void:
	_set_bar("AlertBar", current, max)

func _set_bar(path: String, val: float, max_val: float) -> void:
	var bar: ProgressBar = get_node_or_null(path) as ProgressBar
	if bar:
		bar.value = val
		bar.max_value = max_val

func _set_label(path: String, text: String) -> void:
	var lbl: Label = get_node_or_null(path) as Label
	if lbl:
		lbl.text = text

func _update_all() -> void:
	_on_hp_changed(PlayerData.player_hp, PlayerData.player_hp_max)
	_on_stamina_changed(StaminaServer.current_stamina, StaminaServer.max_stamina)
