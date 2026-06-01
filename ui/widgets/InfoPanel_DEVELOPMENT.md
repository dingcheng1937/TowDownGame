# InfoPanel 开发文档

## 概述

InfoPanel 是一个可复用的信息面板UI组件，用于显示教程、游戏提示、测试关卡说明等内容。

## 技术架构

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

## 导出属性

| 属性 | 类型 | 默认值 | 用途 |
|------|------|--------|------|
| `toggle_key` | Key | KEY_H | 显示/隐藏切换按键 |
| `title` | String | "" | 面板标题文本 |
| `content` | String | "" | 主要内容文本（多行） |
| `show_by_default` | bool | true | 场景加载时是否显示 |
| `panel_width` | int | 200 | 面板宽度（像素） |
| `bg_opacity` | float | 0.5 | 背景透明度 (0.0-1.0) |

## Setter实现

使用setter实现属性实时更新，无需等待场景就绪：

```gdscript
@export var title: String = "":
	set(value):
		title = value
		if _title_label:
			_title_label.text = value
```

**关键点:** 检查节点引用是否存在，避免空指针错误。

## 生命周期

```
_ready()
├── 应用导出属性到子节点
├── 设置初始可见状态
├── 更新面板尺寸
└── 更新提示文本

_input(event)
└── 检测按键 → toggle()

toggle() / show_panel() / hide_panel()
└── 控制 _panel.visible
```

## API方法

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

## 样式系统

### StyleBoxFlat

使用 `StyleBoxFlat` 资源定义面板样式：

```
bg_color = Color(0.1, 0.1, 0.15, 0.5)  # RGBA
border_width_* = 1                      # 边框宽度
border_color = Color(0.4, 0.4, 0.5, 0.6)
corner_radius_* = 6                     # 圆角
```

### 分离的标题样式

标题区域使用独立的StyleBoxFlat，实现不同的背景色和圆角效果。

## 使用模式

### 模式一：场景中实例化

```
[node name="InfoPanel" parent="." instance=ExtResource("uid://infopanel_widget")]
title = "标题"
content = "内容"
toggle_key = 72
show_by_default = true
```

### 模式二：代码动态创建

```gdscript
const InfoPanel = preload("res://ui/widgets/InfoPanel.tscn")

func _ready():
    var panel = InfoPanel.instantiate()
    add_child(panel)
    panel.title = "关卡说明"
    panel.content = "测试内容..."
```

## 与原游戏UI系统的关系

| 方面 | 原游戏 (ControlUI) | InfoPanel |
|------|-------------------|-----------|
| 基类 | CanvasLayer | CanvasLayer |
| layer | 2 | 10 |
| 用途 | 全局游戏UI | 局部场景信息 |
| 生命周期 | 全局单例 | 场景实例 |

## 已知限制

1. 不支持富文本（BBCode）
2. 不支持动态内容高度（需手动调整）
3. 不支持动画过渡效果
4. 按键监听使用 `_input`，可能与其他节点冲突

## 未来改进方向

- [ ] 添加淡入淡出动画
- [ ] 支持富文本
- [ ] 自动计算内容高度
- [ ] 多语言支持
- [ ] 可配置位置（左上/右上/左下/右下）
