# Godot 鼠标模式指南

## 概述

Godot 提供了多种鼠标模式，控制鼠标在游戏窗口中的行为。本文档详细说明如何实现鼠标移出窗口的功能，以及相关的方案和注意事项。

## 当前项目状态

项目中的准星组件 (`ui/widgets/Crosshair.gd`) 当前使用了 `MOUSE_MODE_CONFINED_HIDDEN` 模式：

```gdscript
# Crosshair.gd:58
Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
```

这个模式会：
- ✅ 隐藏鼠标光标
- ✅ 将鼠标限制在游戏窗口内
- ❌ 无法移出窗口

## Godot 鼠标模式详解

### 可用的鼠标模式

| 模式 | 说明 | 使用场景 |
|------|------|----------|
| `MOUSE_MODE_VISIBLE` | 默认模式，显示光标，可自由移动 | UI、菜单、普通游戏 |
| `MOUSE_MODE_HIDDEN` | 隐藏光标，可自由移动 | 过场动画、特定视觉效果 |
| `MOUSE_MODE_CAPTURED` | 捕获光标，隐藏并锁定在窗口中心 | 第一人称射击游戏 |
| `MOUSE_MODE_CONFINED` | 限制在窗口内，显示光标 | 策略游戏、模拟游戏 |
| `MOUSE_MODE_CONFINED_HIDDEN` | 限制在窗口内，隐藏光标 | **当前项目使用的模式** |

### 模式对比

```gdscript
# 1. 自由移动（默认）
Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
# 鼠标可以自由移出窗口，光标可见

# 2. 自由移动但隐藏光标
Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
# 鼠标可以自由移出窗口，但光标不可见

# 3. 捕获模式（FPS标准）
Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
# 鼠标锁定在窗口中心，光标隐藏
# 移动鼠标只会产生相对运动事件

# 4. 限制在窗口内，显示光标
Input.mouse_mode = Input.MOUSE_MODE_CONFINED
# 鼠标无法移出窗口，但光标可见

# 5. 限制在窗口内，隐藏光标（当前项目）
Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
# 鼠标无法移出窗口，光标隐藏
```

## 实现鼠标移出窗口的方案

### 方案一：使用 VISIBLE 或 HIDDEN 模式（推荐）

最直接的方案是修改 `Crosshair.gd` 中的鼠标模式：

```gdscript
# 修改前
Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN

# 修改后（如果需要显示光标）
Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# 或者（如果需要隐藏光标）
Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
```

**优点：**
- ✅ 实现简单，只需修改一行代码
- ✅ 鼠标可以自由移出窗口
- ✅ 准星仍然可以跟随鼠标位置

**缺点：**
- ❌ 失去了"锁定在窗口内"的射击游戏沉浸感
- ❌ 玩家可能在紧张时刻意外移出窗口
- ❌ 需要考虑准星在窗口外时的行为

### 方案二：动态切换模式

根据游戏状态动态切换鼠标模式：

```gdscript
# 在战斗时锁定，在暂停/菜单时释放
func set_combat_mode(in_combat: bool):
    if in_combat:
        Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
    else:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# 示例：暂停时
func _on_pause_pressed():
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    # 显示暂停菜单...

# 示例：恢复游戏时
func _on_resume_pressed():
    Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
```

**优点：**
- ✅ 战斗时保持沉浸感
- ✅ 菜单时可以自由操作
- ✅ 灵活性高

**缺点：**
- ❌ 需要在多个地方管理状态
- ❌ 状态切换可能产生延迟感

### 方案三：窗口焦点检测

自动检测窗口焦点，失去焦点时释放鼠标：

```gdscript
func _notification(what):
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        # 窗口失去焦点时释放鼠标
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        # 窗口获得焦点时重新锁定
        if Utils.is_game_start and Utils.player:
            Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
```

**优点：**
- ✅ 用户切换窗口时自动释放鼠标
- ✅ 回到游戏时自动锁定
- ✅ 用户体验好

**缺点：**
- ❌ 需要处理焦点切换的边缘情况
- ❌ 可能在某些平台上表现不一致

### 方案四：添加配置选项

让玩家自己选择鼠标模式：

```gdscript
# 在设置菜单中添加选项
@export var confine_mouse: bool = true

func apply_mouse_mode():
    if confine_mouse:
        Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
    else:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
```

**优点：**
- ✅ 玩家可以根据喜好选择
- ✅ 灵活性最高
- ✅ 适合不同类型的玩家

**缺点：**
- ❌ 需要实现配置系统
- ❌ 增加了开发工作量

## 需要考虑的问题

### 1. 游戏类型和设计理念

**射击游戏标准实践：**
- 第一人称射击游戏（FPS）：通常使用 `MOUSE_MODE_CAPTURED`
- 俯视角射击游戏：通常使用 `MOUSE_MODE_CONFINED_HIDDEN` 或 `MOUSE_MODE_VISIBLE`

**当前项目（俯视角射击）：**
- 使用 `CONFINED_HIDDEN` 是合理的选择
- 但如果需要鼠标移出窗口，可以改为 `VISIBLE` 或 `HIDDEN`

### 2. 玩家体验

**锁定鼠标的优点：**
- 防止玩家在紧张时刻意外移出窗口
- 保持沉浸感
- 更专注的游戏体验

**不锁定鼠标的优点：**
- 多任务友好（可以在玩游戏时查看其他窗口）
- 减少"鼠标卡住"的困惑感
- 更自由的体验

### 3. 准星行为

如果允许鼠标移出窗口，需要考虑：
- 准星是否应该跟随到窗口外？
- 鼠标回到窗口时准星是否应该瞬间跳回？
- 是否需要边界限制？

**示例代码（限制准星在窗口内）：**

```gdscript
func _process(delta):
    var mouse_pos = get_global_mouse_position()
    var viewport_size = get_viewport().get_visible_rect().size
    
    # 限制准星在窗口内
    mouse_pos.x = clamp(mouse_pos.x, 0, viewport_size.x)
    mouse_pos.y = clamp(mouse_pos.y, 0, viewport_size.y)
    
    global_position = mouse_pos - pivot_offset * scale
```

### 4. 多显示器支持

- 玩家可能在多显示器环境下游戏
- `CAPTURED` 模式在多显示器下可能表现不同
- 需要测试不同配置

### 5. 平台差异

不同平台可能有不同的行为：
- Windows: 通常行为一致
- macOS: 可能有额外的权限要求
- Linux: X11 和 Wayland 行为可能不同
- Web: 浏览器可能有额外限制

### 6. 窗口模式

游戏窗口模式也会影响鼠标行为：
- 全屏独占：鼠标完全锁定
- 全屏窗口化：鼠标可能更容易逃逸
- 窗口化：鼠标可以自由移动

## 推荐方案

基于当前项目的特点（俯视角射击游戏），推荐以下方案：

### 优先级 1：动态切换（方案二）

```gdscript
# 在 Crosshair.gd 中添加
func set_mouse_mode(mode: Input.MouseMode):
    Input.mouse_mode = mode
```

在以下情况切换：
- 战斗时：`MOUSE_MODE_CONFINED_HIDDEN`
- 暂停/菜单时：`MOUSE_MODE_VISIBLE`
- 库存界面时：`MOUSE_MODE_VISIBLE`

### 优先级 2：配置选项（方案四）

添加设置选项：
- "锁定鼠标在窗口内"：是/否
- 默认：是（当前的 `CONFINED_HIDDEN` 模式）
- 玩家可以自由选择

### 优先级 3：焦点检测（方案三）

自动处理窗口切换：
- 失去焦点时：自动释放鼠标
- 获得焦点时：恢复之前的模式

## 实现示例

### 完整的鼠标管理系统

创建一个新的单例脚本 `MouseManager.gd`：

```gdscript
# autoload/MouseManager.gd
extends Node

## 鼠标模式配置
enum MouseModeType {
	FREE,        # 自由移动
	CONFINED,    # 限制在窗口内
	COMBAT       # 战斗模式（限制+隐藏）
}

var current_mode: MouseModeType = MouseModeType.FREE
var saved_mode_before_pause: MouseModeType = MouseModeType.FREE

signal mouse_mode_changed(new_mode: MouseModeType)

func _ready():
	# 监听窗口焦点变化
	connect("application_focus_out", _on_focus_out)
	connect("application_focus_in", _on_focus_in)

func set_mode(mode: MouseModeType):
	current_mode = mode
	match mode:
		MouseModeType.FREE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		MouseModeType.CONFINED:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		MouseModeType.COMBAT:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	
	emit_signal("mouse_mode_changed", mode)

func _on_focus_out():
	# 窗口失去焦点时释放鼠标
	saved_mode_before_pause = current_mode
	set_mode(MouseModeType.FREE)

func _on_focus_in():
	# 窗口获得焦点时恢复之前的模式
	set_mode(saved_mode_before_pause)

# 便捷方法
func enter_combat():
	set_mode(MouseModeType.COMBAT)

func exit_combat():
	set_mode(MouseModeType.FREE)

func pause_game():
	saved_mode_before_pause = current_mode
	set_mode(MouseModeType.FREE)

func resume_game():
	set_mode(saved_mode_before_pause)
```

### 在项目配置中注册

在 `project.godot` 中添加：

```ini
[autoload]
MouseManager="*res://autoload/MouseManager.gd"
```

### 在 Crosshair.gd 中使用

```gdscript
# Crosshair.gd
func onGameStart():
	set_process(true)
	# 使用 MouseManager 而不是直接设置
	MouseManager.enter_combat()

func _exit_tree():
	# 不需要手动管理，MouseManager 会处理
	pass
```

## 总结

1. **当前问题**：鼠标被限制在窗口内无法移出
2. **根本原因**：使用了 `MOUSE_MODE_CONFINED_HIDDEN`
3. **解决方案**：根据游戏需求选择合适的鼠标模式
4. **推荐方案**：动态切换 + 配置选项 + 焦点检测的组合
5. **注意事项**：考虑游戏类型、玩家体验、平台差异等因素

## 相关资源

- [Godot 官方文档 - Input.mouse_mode](https://docs.godotengine.org/en/stable/classes/class_input.html#enum-input.mousemode)
- [Godot 官方文档 - 鼠标输入](https://docs.godotengine.org/en/stable/tutorials/inputs/mouse_and_input_coordinates.html)
- 项目文件：`ui/widgets/Crosshair.gd` - 准星组件
- 项目文件：`autoload/Utils.gd` - 工具单例
