extends Area2D
## 地面陷阱 - 玩家接触时造成伤害
## 使用 Area2D 检测玩家，玩家可以踩上去

## 造成的伤害值
@export var damage: int = 1

## 伤害冷却时间（秒），防止连续受伤
@export var damage_cooldown: float = 1.0

## 陷阱是否激活
@export var is_active: bool = true

## 冷却计时器
var _damage_timer: float = 0.0


func _ready() -> void:
    # 连接检测信号
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    # 冷却从0开始（首次接触立即造成伤害）
    _damage_timer = 0.0


func _process(delta: float) -> void:
    # 更新冷却计时器
    if _damage_timer > 0.0:
        _damage_timer -= delta


func _on_body_entered(body: Node2D) -> void:
    if not is_active:
        return

    # 检查冷却
    if _damage_timer > 0.0:
        return

    # 只对玩家造成伤害
    if body is Player:
        # 应用伤害
        if Utils.player and not Utils.player.is_dead:
            Utils.player.onHit(damage)

            # 启动冷却
            _damage_timer = damage_cooldown

            # 视觉反馈（闪白）
            _flash_trap()


func _on_body_exited(_body: Node2D) -> void:
    # 玩家离开时的处理（如需要）
    pass


func _flash_trap() -> void:
    # 陷阱激活时的视觉闪烁
    var sprite = get_node_or_null("ColorRect")
    if sprite:
        var original_color = sprite.color
        sprite.color = Color.WHITE
        await get_tree().create_timer(0.1).timeout
        sprite.color = original_color


func reset_cooldown() -> void:
    ## 重置冷却（用于测试）
    _damage_timer = 0.0
