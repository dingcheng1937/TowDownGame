extends Area2D
class_name ZoneTrigger
## 区域切换触发器 - 玩家进入后触发区域转换或解锁
##
## 用于连接不同区域（病房区→生活区→治疗区→行政区）

signal zone_transition_triggered(zone_name: String)

## 目标区域名称
@export var target_zone_name: String = ""

## 是否需要特定物品才能通过
@export var required_item: String = ""

## 通过后的提示文本
@export var zone_hint: String = ""

## 是否为一方向（不可返回）
@export var one_way: bool = false

## 进入区域时触发的叙事碎片
@export var narrative_hint_id: String = ""
@export var narrative_hint_text: String = ""

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D

var _is_locked: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if label:
		label.text = target_zone_name
		if required_item != "":
			label.text += "\n需要: " + required_item


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	
	# 检查是否需要特定物品
	if required_item != "":
		if not LootServer.has_item(required_item):
			Utils.showToast("需要: " + required_item)
			return
	
	# 触发区域过渡
	EventBus.zone_entered.emit(target_zone_name)
	emit_signal("zone_transition_triggered", target_zone_name)
	
	if zone_hint != "":
		Utils.showToast(zone_hint)
	
	# 叙事碎片提示
	if narrative_hint_id != "" and narrative_hint_text != "":
		EventBus.narrative_hint.emit(narrative_hint_id, narrative_hint_text)
