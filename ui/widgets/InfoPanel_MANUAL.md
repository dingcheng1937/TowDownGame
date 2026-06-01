# InfoPanel 调整操作手册

快速调整InfoPanel组件的外观和行为。

---

## 一、修改面板尺寸

### 文件
`ui/widgets/InfoPanel.tscn`

### 位置
第30-35行，`[node name="Panel" type="Panel" parent="."]`

### 参数

```
offset_left = 10.0      # 左边距（屏幕坐标）
offset_top = 10.0       # 上边距（屏幕坐标）
offset_right = 210.0    # 右边界
offset_bottom = 160.0   # 下边界
```

### 计算

- **宽度** = `offset_right - offset_left`
- **高度** = `offset_bottom - offset_top`

### 示例：改为150x100

```
offset_left = 10.0
offset_top = 10.0
offset_right = 160.0    # 160-10=150宽
offset_bottom = 110.0   # 110-10=100高
```

---

## 二、修改背景透明度

### 文件
`ui/widgets/InfoPanel.tscn`

### 位置
第5-6行，`[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_panel"]`

### 参数

```
bg_color = Color(R, G, B, A)
                            ↑
                          透明度
```

### 透明度对照表

| 值 | 透明度 |
|----|--------|
| 0.0 | 完全透明 |
| 0.3 | 30% |
| 0.5 | 50% |
| 0.7 | 70% |
| 1.0 | 完全不透明 |

### 示例：改为30%透明

```
bg_color = Color(0.1, 0.1, 0.15, 0.3)
```

---

## 三、修改字体大小

### 文件
`ui/widgets/InfoPanel.tscn`

### 标题字体
第53行，`[node name="Title" type="Label" parent="Panel/VBox"]`

```
theme_override_font_sizes/font_size = 12
```

### 内容字体
第64行，`[node name="Content" type="Label" parent="Panel/VBox"]`

```
theme_override_font_sizes/font_size = 10
```

### 提示字体
第74行，`[node name="Hint" type="Label" parent="Panel/VBox"]`

```
theme_override_font_sizes/font_size = 8
```

---

## 四、修改内边距

### 文件
`ui/widgets/InfoPanel.tscn`

### 位置
第39-46行，`[node name="VBox" type="VBoxContainer" parent="Panel"]`

### 参数

```
offset_left = 6.0       # 左内边距
offset_top = 6.0        # 上内边距
offset_right = -6.0     # 右内边距（负值）
offset_bottom = -6.0    # 下内边距（负值）
```

### 示例：更紧凑的边距

```
offset_left = 4.0
offset_top = 4.0
offset_right = -4.0
offset_bottom = -4.0
```

---

## 五、修改圆角

### 文件
`ui/widgets/InfoPanel.tscn`

### 位置
第12-15行

### 参数

```
corner_radius_top_left = 6
corner_radius_top_right = 6
corner_radius_bottom_right = 6
corner_radius_bottom_left = 6
```

### 示例：无圆角（方形）

```
corner_radius_top_left = 0
corner_radius_top_right = 0
corner_radius_bottom_right = 0
corner_radius_bottom_left = 0
```

---

## 六、修改默认切换按键

### 文件
`ui/widgets/InfoPanel.gd`

### 位置
第7行

### 参数

```gdscript
@export var toggle_key: Key = KEY_H
```

### 常用按键码

| 按键 | 码值 |
|------|------|
| H | KEY_H (72) |
| F1 | KEY_F1 (290) |
| Tab | KEY_TAB (258) |
| I | KEY_I (73) |
| Escape | KEY_ESCAPE (4194305) |

### 示例：改为F1键

```gdscript
@export var toggle_key: Key = KEY_F1
```

---

## 七、修改默认宽度/透明度

### 文件
`ui/widgets/InfoPanel.gd`

### 位置
第21-31行

### 参数

```gdscript
@export var panel_width: int = 200
@export_range(0.0, 1.0) var bg_opacity: float = 0.5
```

### 示例：更窄更透明

```gdscript
@export var panel_width: int = 150
@export_range(0.0, 1.0) var bg_opacity: float = 0.3
```

---

## 八、修改字体颜色

### 文件
`ui/widgets/InfoPanel.tscn`

### 标题颜色
第53行附近

```
theme_override_colors/font_color = Color(0.9, 0.85, 0.7, 1)
```

### 内容颜色
第64行附近

```
theme_override_colors/font_color = Color(0.95, 0.95, 0.9, 1)
```

### 提示颜色
第74行附近

```
theme_override_colors/font_color = Color(0.6, 0.6, 0.65, 0.8)
```

### 颜色格式

```
Color(R, G, B, A)
     ↑  ↑  ↑  ↑
     红绿蓝 透明度 (0.0-1.0)
```

---

## 九、修改边框样式

### 文件
`ui/widgets/InfoPanel.tscn`

### 位置
第7-10行

### 参数

```
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.4, 0.4, 0.5, 0.6)
```

### 示例：更明显的边框

```
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.6, 0.6, 0.7, 0.8)
```

---

## 十、单个DEMO独立配置

每个DEMO场景中的InfoPanel实例可以独立配置，不影响其他场景。

### 示例：CorrectDemo.tscn中的InfoPanel

```
[node name="InfoPanel" parent="." instance=ExtResource("4_infopanel")]
title = "玩家移动"
content = "控制: WASD移动"
toggle_key = 72
show_by_default = true
panel_width = 180
bg_opacity = 0.4
```

只需在场景文件中修改这些属性即可。

---

## 快速查找表

| 想修改什么 | 文件 | 搜索关键词 |
|-----------|------|-----------|
| 面板尺寸 | InfoPanel.tscn | `[node name="Panel"` |
| 背景透明度 | InfoPanel.tscn | `StyleBoxFlat_panel` |
| 标题字体 | InfoPanel.tscn | `name="Title"` |
| 内容字体 | InfoPanel.tscn | `name="Content"` |
| 提示字体 | InfoPanel.tscn | `name="Hint"` |
| 内边距 | InfoPanel.tscn | `name="VBox"` |
| 圆角 | InfoPanel.tscn | `corner_radius` |
| 边框 | InfoPanel.tscn | `border_width` |
| 默认按键 | InfoPanel.gd | `toggle_key` |
| 默认宽度 | InfoPanel.gd | `panel_width` |
| 默认透明度 | InfoPanel.gd | `bg_opacity` |
