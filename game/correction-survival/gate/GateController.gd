extends Area2D
class_name GateController
## 门控制器 — 关键道具解锁 / 封锁节点

signal gate_unlocked(gate_id: String)

enum GateMode { UNLOCK, BLOCK }

@export var gate_mode: GateMode = GateMode.UNLOCK
@export var gate_id: String = ""
@export var required_item_id: String = ""       # 需要的关键道具
@export var hint_text: String = "需要特定道具才能通过"
@export var block_on_boss_alive: NodePath       # 如果设置了Boss路径，Boss存活时封锁

var is_locked: bool = true
var is_blocked: bool = false
var _label: Label

func _ready() -> void:
	_label = get_node_or_null("Label")

func _on_body_entered(body: Node2D) -> void:
	if not (body is Player and is_locked):
		return
	if gate_mode == GateMode.BLOCK:
		if _label:
			_label.text = hint_text
			_label.visible = true
		return
	# UNLOCK模式：检查玩家是否有关键道具
	if required_item_id != "" and not PlayerData.key_items.has(required_item_id):
		if _label:
			_label.text = hint_text
			_label.visible = true
		return
	# 玩家有道具 → 解锁
	unlock()

func _on_body_exited(body: Node2D) -> void:
	if body is Player and _label:
		_label.visible = false

func unlock() -> void:
	if not is_locked:
		return
	is_locked = false
	gate_unlocked.emit(gate_id)
	EventBus.gate_unlocked.emit(gate_id)
	Utils.showToast("门已解锁！")
	if _label:
		_label.text = "已解锁"
	# 隐藏物理碰撞
	var collision: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = true

func set_blocked(val: bool) -> void:
	is_blocked = val
	if val:
		is_locked = true
		var collision: CollisionShape2D = get_node_or_null("CollisionShape2D")
		if collision:
			collision.disabled = false
