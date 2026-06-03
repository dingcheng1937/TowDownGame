extends Node2D
## 怪物系统DEMO启动器
## 使用原游戏的动态怪物生成模式

const ControlUIPre = preload("res://ui/ControlUI.tscn")
const MonsterPre = preload("res://game/monster/Monster 2/Monster2.tscn")

## 怪物生成位置列表
var spawn_points: Array[Vector2] = [
	Vector2(200, 200),
	Vector2(600, 200),
	Vector2(200, 400),
	Vector2(600, 400)
]

## 怪物数据（参考 MonsterBuilder.gd 的 level_data）
var monster_data = {
	"hp": 5,
	"speed": 50,
	"hurt": 1
}

## 怪物根节点
var monster_root: Node2D

func _enter_tree():
	# 使用原始项目逻辑：通过 PlayerServer 创建玩家
	PlayerServer.addPlayerToScene($PlayerRoot)
	PlayerServer.setPlayerPosition($CreatePosition.global_position)

func _ready():
	# 初始化玩家数据
	PlayerData.player_hp = 50
	PlayerData.player_hp_max = 100

	# 触发游戏启动
	Utils.gameStart()

	# 获取怪物根节点
	monster_root = $MonstersRoot

	# 动态创建怪物（遵循原游戏模式）
	_spawn_monsters()

	# 添加游戏UI
	_setup_ui()


## 动态生成怪物（参考 MonsterBuilder.gd 的 createMonster）
func _spawn_monsters():
	for spawn_pos in spawn_points:
		var ins = MonsterPre.instantiate()
		ins.setData(monster_data)
		ins.global_position = spawn_pos
		ins.setDeathCallBack(_on_monster_death)
		monster_root.add_child(ins)


## 怪物死亡回调
func _on_monster_death(_monster: BaseMonster):
	# 可在此添加掉落物等逻辑
	pass


func _setup_ui():
	var control_ui = ControlUIPre.instantiate()
	$UIRoot.add_child(control_ui)
	control_ui.get_node("GameUI").show()
	control_ui.get_node("MainUI").hide()
