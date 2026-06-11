extends CanvasLayer
class_name CorrectionHUD
## 精神矫正中心 HUD

func _ready() -> void:
	# 连接安全存在的信号
	AlertServer.alert_changed.connect(_on_alert_changed)
	AlertServer.alert_threshold_crossed.connect(_on_alert_threshold_crossed)
	ExtractionServer.extraction_available.connect(_on_extraction_available)
	ExtractionServer.extraction_started.connect(_on_extraction_started)
	ExtractionServer.extraction_completed.connect(_on_extraction_completed)
	ExtractionServer.countdown_tick.connect(_on_countdown_tick)
	PlayerData.onHpChange.connect(_on_hp_changed)
	EventBus.zone_entered.connect(_on_zone_entered)
	EventBus.lore_fragment_found.connect(_on_lore_fragment_found)
	EventBus.high_value_loot_found.connect(_on_high_value_loot)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	LootServer.loot_added.connect(_on_loot_added)
	EventBus.throwable_count_changed.connect(_on_throwable_count_changed)
	_update_alert_display()
	_update_hp_display()
	_update_throwable_display()


func _on_alert_changed(current: float, _max: float) -> void:
	var bar: TextureProgressBar = get_node_or_null("TopBar/AlertBar") as TextureProgressBar
	if bar: bar.value = current


func _on_alert_threshold_crossed(threshold: int) -> void:
	var names: Dictionary = {0: "正常", 1: "警惕", 2: "警报", 3: "封锁"}
	var label: Label = get_node_or_null("TopBar/ThresholdLabel") as Label
	if label: label.text = names.get(threshold, "未知")


func _on_hp_changed(hp: int, max_hp: int) -> void:
	var bar: TextureProgressBar = get_node_or_null("TopBar/HPBar") as TextureProgressBar
	if bar: bar.value = hp; bar.max_value = max_hp


func _on_loot_added(loot: Dictionary) -> void:
	var list: VBoxContainer = get_node_or_null("BottomBar/LootPanel/LootList") as VBoxContainer
	if not list: return
	var entry: Label = Label.new()
	entry.text = "• %s" % loot.get("name", "?")
	var rarity: int = loot.get("rarity", 0)
	entry.modulate = LootServer.get_rarity_color(rarity)
	list.add_child(entry)


func _update_throwable_display() -> void:
	var keys: Array[String] = ["stone_count", "bottle_count", "plate_count"]
	for key in keys:
		var count: int = 0
		if PlayerData.has_meta(key):
			count = PlayerData.get_meta(key)
		var type: String = key.replace("_count", "")
		_on_throwable_count_changed(type, count)


func _on_throwable_count_changed(type: String, count: int) -> void:
	var label: Label = get_node_or_null("ThrowablePanel/%sCount" % type.capitalize()) as Label
	if label:
		label.text = "x%d" % count
		label.modulate = Color(1, 1, 1, 0.3) if count == 0 else Color(1, 1, 1, 1)


func _on_zone_entered(zone: String) -> void:
	var label: Label = get_node_or_null("TopBar/ZoneLabel") as Label
	if label: label.text = "📍 " + zone


func _on_extraction_available() -> void:
	_set_label_text("ExtractionLabel", "✅ 撤离点已激活", Color.GREEN)


func _on_extraction_started() -> void:
	_set_label_text("ExtractionLabel", "🔄 撤离中...")


func _on_extraction_completed() -> void:
	_set_label_text("ExtractionLabel", "✅ 撤离成功！", Color.GREEN_YELLOW)


func _on_countdown_tick(time: float) -> void:
	var c: Color = Color.RED if time <= 3.0 else Color.YELLOW
	_set_label_text("ExtractionLabel", "撤离: %.1f秒" % time, c)


func _on_lore_fragment_found(_id: String, text: String) -> void:
	_show_narrative(text)


func _on_high_value_loot(name: String) -> void:
	_show_narrative("获得: " + name)


func _on_boss_defeated(name: String) -> void:
	_show_narrative("你击败了" + name)


func _update_alert_display() -> void:
	var bar: TextureProgressBar = get_node_or_null("TopBar/AlertBar") as TextureProgressBar
	if bar and AlertServer.current_alert != null:
		bar.max_value = AlertServer.MAX_ALERT


func _update_hp_display() -> void:
	var bar: TextureProgressBar = get_node_or_null("TopBar/HPBar") as TextureProgressBar
	if bar:
		bar.max_value = PlayerData.player_hp_max
		bar.value = PlayerData.player_hp


func show_item_hint(text: String, duration: float = 2.0) -> void:
	var lbl: Label = get_node_or_null("ItemHint") as Label
	if lbl:
		lbl.text = text
		lbl.visible = true
		await get_tree().create_timer(duration).timeout
		if is_instance_valid(lbl): lbl.visible = false


func _set_label_text(path: String, text: String, color: Color = Color.WHITE) -> void:
	var lbl: Label = get_node_or_null(path) as Label
	if lbl:
		lbl.text = text
		lbl.modulate = color
		lbl.visible = true


func _show_narrative(text: String) -> void:
	var panel: Panel = get_node_or_null("NarrativePanel") as Panel
	var ntext: Label = get_node_or_null("NarrativePanel/NarrativeText") as Label
	if not panel or not ntext: return
	ntext.text = text
	panel.visible = true
	panel.modulate = Color(1, 1, 1, 0)
	var t: Tween = create_tween()
	t.tween_property(panel, "modulate", Color.WHITE, 0.3)
	await get_tree().create_timer(4.0).timeout
	if not is_instance_valid(panel): return
	t = create_tween()
	t.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.5)
	await t.finished
	if is_instance_valid(panel): panel.visible = false
