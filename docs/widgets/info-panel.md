# InfoPanel 组件文档

可复用的信息面板UI组件，用于显示教程、游戏提示、测试关卡说明等内容。

---

## 一、概述

### 节点结构

```
InfoPanel (CanvasLayer, layer=10)
└── Panel (Panel)
    └── VBox (VBoxContainer)
        ├── Title (Label)
        ├── HSeparator
        ├── Content (Label)
        ├── HSeparator2
        └── Hint (Label)
```

### 为什么用 CanvasLayer

CanvasLayer 是Godot中实现HUD的正确方式：
- 独立于相机，不受相机移动影响
- 固定在屏幕坐标系中
- 通过 `layer` 属性控制渲染层级
- 比直接挂在Camera2D下更灵活

### 类设计

```gdscript
class_name InfoPanel
extends CanvasLayer
```

**继承链:** CanvasLayer → Node → Object

---

## 二、导出属性

| 属性 | 类型 | 默认值 | 用途 |
|------|------|--------|------|
| `toggle_key` | Key | KEY_H | 显示/隐藏切换按键 |
| `title` | String | "" | 面板标题文本 |
| `content` | String | "" | 主要内容文本（多行） |
| `show_by_default` | bool | true | 场景加载时是否显示 |
| `panel_width` | int | 200 | 面板宽度（像素） |
| `bg_opacity` | float | 0.5 | 背景透明度 (0.0-1.0) |

### Setter实现

使用setter实现属性实时更新，无需等待场景就绪：

```gdscript
@export var title: String = "":
    set(value):
        title = value
        if _title_label:
            _title_label.text = value
```

**关键点:** 检查节点引用是否存在，避免空指针错误。

---

## 三、API方法

### 公开方法

```gdscript
# 切换显示/隐藏
func toggle() -> void

# 显示面板
func show_panel() -> void

# 隐藏面板
func hide_panel() -> void

# 设置标题
func set_title(text: String) -> void

# 设置内容
func set_content(text: String) -> void

# 设置切换按键
func set_toggle_key(key: Key) -> void
```

### 内部方法

```gdscript
func _update_panel_size() -> void   # 更新面板宽度
func _update_hint_text() -> void    # 更新底部提示文本
```

---

## 四、使用方法

### 方式一：场景中实例化

```
[node name="InfoPanel" parent="." instance=ExtResource("uid://infopanel_widget")]
title = "标题"
content = "内容"
toggle_key = 72
show_by_default = true
```

### 方式二：代码动态创建

```gdscript
const InfoPanel = preload("res://ui/widgets/InfoPanel.tscn")

func _ready():
    var panel = InfoPanel.instantiate()
    add_child(panel)
    panel.title = "关卡说明"
    panel.content = "测试内容..."
```

---

## 五、样式调整手册

### 5.1 修改面板尺寸

**文件:** `ui/widgets/InfoPanel.tscn`

**位置:** 第30-35行，`[node name="Panel" type="Panel" parent="."]`

```
offset_left = 10.0      # 左边距
offset_top = 10.0       # 上边距
offset_right = 210.0    # 右边界
offset_bottom = 160.0   # 下边界
```

- **宽度** = `offset_right - offset_left`
- **高度** = `offset_bottom - offset_top`

### 5.2 修改背景透明度

**文件:** `ui/widgets/InfoPanel.tscn`

**位置:** 第5-6行，`[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_panel"]`

```
bg_color = Color(R, G, B, A)
                            ↑
                          透明度
```

| 值 | 透明度 |
|----|--------|
| 0.0 | 完全透明 |
| 0.5 | 50% |
| 1.0 | 完全不透明 |

### 5.3 修改字体大小

**文件:** `ui/widgets/InfoPanel.tscn`

| 元素 | 位置 | 参数 |
|------|------|------|
| 标题 | 第53行 | `theme_override_font_sizes/font_size = 12` |
| 内容 | 第64行 | `theme_override_font_sizes/font_size = 10` |
| 提示 | 第74行 | `theme_override_font_sizes/font_size = 8` |

### 5.4 修改内边距

**文件:** `ui/widgets/InfoPanel.tscn`

**位置:** 第39-46行，`[node name="VBox" type="VBoxContainer" parent="Panel"]`

```
offset_left = 6.0       # 左内边距
offset_top = 6.0        # 上内边距
offset_right = -6.0     # 右内边距（负值）
offset_bottom = -6.0    # 下内边距（负值）
```

### 5.5 修改圆角

**文件:** `ui/widgets/InfoPanel.tscn`

**位置:** 第12-15行

```
corner_radius_top_left = 6
corner_radius_top_right = 6
corner_radius_bottom_right = 6
corner_radius_bottom_left = 6
```

### 5.6 修改默认切换按键

**文件:** `ui/widgets/InfoPanel.gd`

**位置:** 第7行

```gdscript
@export var toggle_key: Key = KEY_H
```

| 按键 | 码值 |
|------|------|
| H | KEY_H (72) |
| F1 | KEY_F1 (290) |
| Tab | KEY_TAB (258) |
| I | KEY_I (73) |

### 5.7 修改字体颜色

**文件:** `ui/widgets/InfoPanel.tscn`

```
# 标题颜色（第53行附近）
theme_override_colors/font_color = Color(0.9, 0.85, 0.7, 1)

# 内容颜色（第64行附近）
theme_override_colors/font_color = Color(0.95, 0.95, 0.9, 1)

# 提示颜色（第74行附近）
theme_override_colors/font_color = Color(0.6, 0.6, 0.65, 0.8)
```

---

## 六、快速查找表

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

---

## 七、单个场景独立配置

每个场景中的InfoPanel实例可以独立配置，不影响其他场景。

**示例：GYM_01_Movement.tscn中的InfoPanel**

```
[node name="InfoPanel" parent="." instance=ExtResource("4_infopanel")]
title = "玩家移动"
content = "控制: WASD移动"
toggle_key = 72
show_by_default = true
panel_width = 180
bg_opacity = 0.4
```

---

## 八、已知限制

1. 不支持富文本（BBCode）
2. 不支持动态内容高度（需手动调整）
3. 不支持动画过渡效果
4. 按键监听使用 `_input`，可能与其他节点冲突

---

## 九、未来改进方向

- [ ] 添加淡入淡出动画
- [ ] 支持富文本
- [ ] 自动计算内容高度
- [ ] 多语言支持
- [ ] 可配置位置（左上/右上/左下/右下）
