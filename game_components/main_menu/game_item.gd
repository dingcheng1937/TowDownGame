extends HBoxContainer

## GameItem : HBoxContainer 模板，表示一个游戏列表项。
## 包含游戏编号、名称标签和 PLAY 按钮。
## 通过 game_pressed 信号将场景路径传递给父级。

signal game_pressed(scene_path: String)

var scene_path: String = ""

func setup(index: int, game_name: String, path: String) -> void:
	scene_path = path
	$LabelNumber.text = "#%02d" % index
	$LabelTitle.text = game_name
	$ButtonPlay.disabled = path.is_empty()


func _on_play_button_pressed() -> void:
	game_pressed.emit(scene_path)
