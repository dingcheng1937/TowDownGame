extends Node
## 全局事件总线 - 用于跨场景、解耦的通信
##
## 仅添加真正跨多个场景的事件的信号。
## 单场景内部通信使用组件自身的信号。

## === 玩家生命周期 ===
signal player_died
signal player_extracted
signal player_resurrected

## === 警戒/规则系统 ===
signal alert_threshold_crossed(threshold: int)
signal rule_broken(rule_name: String)

## === 战斗 ===
signal enemy_killed(enemy_type: String, position: Vector2)
signal boss_defeated(boss_name: String)
signal boss_skill_used(skill_name: String)

## === 物品与战利品 ===
signal item_collected(item_id: String, item_name: String)
signal item_used(item_id: String)
signal key_item_acquired(item_id: String)
signal high_value_loot_found(loot_name: String)
signal throwable_count_changed(throwable_type: String, count: int)

## === 区域与探索 ===
signal zone_entered(zone_name: String)
signal zone_exited(zone_name: String)
signal extraction_available
signal extraction_started
signal extraction_completed

## === 叙事 ===
signal narrative_hint(hint_id: String, text: String)
signal lore_fragment_found(fragment_id: String, fragment_text: String)

## === 仓库 ===
signal warehouse_upgraded(upgrade_type: String, new_level: int)

## === 矫正生存 ===
signal stamina_changed(current: float, max: float)
signal gate_unlocked(gate_id: String)
signal cutscene_started(cutscene_id: String)
signal cutscene_finished(cutscene_id: String)
signal door_knocked()
signal door_choice_made(opened: bool)
