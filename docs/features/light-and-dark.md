# 光明与黑暗效果系统实现文档

## 概述

本项目中的光明与黑暗效果是一个基于**理智系统（Sanity System）**的动态视觉效果系统。通过玩家理智值的变化，系统会动态调整游戏场景的视觉呈现，营造从正常到诡异、黑暗的氛围转变。

---

## 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    光明与黑暗效果系统                        │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐    ┌──────────────────────┐          │
│  │  SanityServer    │───▶│AtmosphereController │          │
│  │   (理智服务器)    │    │   (氛围控制器)       │          │
│  └──────────────────┘    └──────────┬───────────┘          │
│         │                           │                      │
│         ▼                           ▼                      │
│  ┌──────────────────┐    ┌──────────────────────┐          │
│  │   理智状态信号    │    │    视觉效果调整       │          │
│  │   (Signals)      │    │   (Environment)      │          │
│  └──────────────────┘    └──────────────────────┘          │
│         │                           │                      │
│         ▼                           ▼                      │
│  ┌──────────────────┐    ┌──────────────────────┐          │
│  │   诡异怪物系统    │    │     场景光照系统       │          │
│  │  (Weird Monsters)│    │   (Lighting System)  │          │
│  └──────────────────┘    └──────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

---

## 核心组件详解

### 1. 理智服务器 (SanityServer)

**文件位置**: `autoload/server/SanityServer.gd`

**职责**: 管理玩家理智值的增减、状态判断和信号发射。

**核心实现**:

```gdscript
enum SanityState {
    NORMAL,      # 75-100: 正常状态
    MILD,        # 50-75: 轻微影响
    MODERATE,    # 25-50: 中等影响
    SEVERE,      # 0-25: 严重影响
}

var current_sanity: float = 100.0:
    set(value):
        var old = current_sanity
        current_sanity = clamp(value, 0.0, max_sanity)
        if old != current_sanity:
            emit_signal("sanity_changed", current_sanity, max_sanity)
            _check_thresholds(old, current_sanity)
```

**信号系统**:

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `sanity_changed` | `current: float`, `max: float` | 理智值变化时 |
| `sanity_threshold_crossed` | `threshold: String` | 跨越阈值时 |
| `sanity_depleted` | 无 | 理智完全耗尽时 |

**阈值检测逻辑**:

```gdscript
func _check_thresholds(old: float, new: float) -> void:
    # 下降阈值
    if old >= 75 and new < 75:
        emit_signal("sanity_threshold_crossed", "mild")
    elif old >= 50 and new < 50:
        emit_signal("sanity_threshold_crossed", "moderate")
    elif old >= 25 and new < 25:
        emit_signal("sanity_threshold_crossed", "severe")
    # 回升阈值
    elif old < 75 and new >= 75:
        emit_signal("sanity_threshold_crossed", "recovered_normal")
```

---

### 2. 氛围控制器 (AtmosphereController)

**文件位置**: `game/atmosphere/AtmosphereController.gd`

**职责**: 根据理智状态动态调整游戏视觉效果。

**核心实现**:

```gdscript
func _update_visual_effects() -> void:
    var sanity_percent = _current_sanity_level / 100.0

    if sanity_percent > 0.75:
        # 正常状态：明亮清晰
        _adjust_environment(1.0, 1.0, 1.0)
        _effect_intensity = 0.0
    elif sanity_percent > 0.5:
        # 轻微影响：略微偏红，对比度提升
        _adjust_environment(1.1, 0.95, 0.95)
        _effect_intensity = 0.25
    elif sanity_percent > 0.25:
        # 中等影响：明显偏红，饱和度降低
        _adjust_environment(1.2, 0.85, 0.85)
        _effect_intensity = 0.5
    else:
        # 严重影响：强烈偏红，画面变暗
        _adjust_environment(1.4, 0.7, 0.7)
        _effect_intensity = 1.0
```

**环境调整方法**:

```gdscript
func _adjust_environment(contrast: float, saturation: float, brightness: float) -> void:
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        env.adjustment_enabled = true
        env.adjustment_contrast = contrast
        env.adjustment_saturation = saturation
        env.adjustment_brightness = brightness - 0.1
```

**阈值效果触发**:

| 阈值 | 效果描述 | Toast提示 |
|------|----------|-----------|
| `mild` | 轻微视觉变化 | "你感到不安..." |
| `moderate` | 明显视觉变化 | "幻觉开始出现..." |
| `severe` | 强烈视觉变化 | "理智即将崩溃！" |
| `recovered_normal` | 恢复正常 | "理智恢复正常" |

---

### 3. 场景光照系统

**文件位置**: `game/map/SnowWorld/SnowWorld.tscn`

**场景光照组成**:

| 组件 | 类型 | 作用 |
|------|------|------|
| `WorldEnvironment` | WorldEnvironment | 全局环境设置（发光、背景等） |
| `CanvasModulate` | CanvasModulate | 全局画布颜色调制 |
| `PointLight2D` | PointLight2D | 玩家周围的点光源 |

**环境配置**:

```gdscript
# SnowWorld.tscn 中的环境设置
background_mode = 3  # 颜色背景
glow_enabled = true
glow_intensity = 1.31
glow_blend_mode = 1  # 加性混合
```

**CanvasModulate 设置**:

```gdscript
# 初始偏暗的氛围
color = Color(0.0392157, 0.0392157, 0.0392157, 1)  # 接近纯黑
```

**玩家光源设置**:

```gdscript
# PlayerRoot/Anchor/Camera2D/PointLight2D
energy = 1.2
shadow_enabled = true
texture_scale = 0.5
```

---

### 4. 诡异怪物系统

**文件位置**: `game/monster/weird/`

#### 4.1 残影 (Shade)

**特性**: 高速、低血量、造成理智伤害的诡异怪物

```gdscript
class_name Shade
extends BaseMonster

@export var sanity_damage: float = 5.0  # 每次攻击造成5点理智伤害
@export var dash_multiplier: float = 2.5  # 冲刺速度倍率
@export var dash_distance: float = 100.0  # 冲刺触发距离

func _on_body_entered(body: Node2D) -> void:
    if body is Player and not is_die and not hit:
        hit = true
        body.onHit(hurt)
        SanityServer.change_sanity(-sanity_damage)  # 造成理智伤害
```

#### 4.2 畸变体 (Aberration)

**特性**: 高血量、高伤害、慢速的重型诡异怪物

```gdscript
class_name Aberration
extends BaseMonster

func _on_body_entered(body: Node2D) -> void:
    if body is Player and not is_die and not hit:
        hit = true
        body.onHit(hurt)
        SanityServer.change_sanity(-10.0)  # 造成10点理智伤害（更高）
```

---

## 效果实现流程

### 流程时序图

```
玩家进入场景
    │
    ▼
SanityServer.start_drain()
    │
    ▼ (每帧)
SanityServer.change_sanity(-passive_drain_rate * delta)
    │
    ▼
emit_signal("sanity_changed", current, max)
    │
    ▼
AtmosphereController._on_sanity_changed()
    │
    ▼
AtmosphereController._update_visual_effects()
    │
    ▼
AtmosphereController._adjust_environment()
    │
    ▼
WorldEnvironment 应用新的视觉参数
    │
    ▼
玩家看到变化的视觉效果
```

### 触发条件

| 事件 | 效果 |
|------|------|
| 时间流逝 | 理智自然流失 |
| 残影攻击 | 造成5点理智伤害 |
| 畸变体攻击 | 造成10点理智伤害 |
| 饮用理智药水 | 恢复理智值 |

---

## 视觉效果参数表

### 按理智等级划分的效果参数

| 理智范围 | 状态 | 对比度 | 饱和度 | 亮度 | 效果强度 |
|----------|------|--------|--------|------|----------|
| 75-100 | NORMAL | 1.0 | 1.0 | 1.0 | 0.0 |
| 50-75 | MILD | 1.1 | 0.95 | 0.95 | 0.25 |
| 25-50 | MODERATE | 1.2 | 0.85 | 0.85 | 0.5 |
| 0-25 | SEVERE | 1.4 | 0.7 | 0.7 | 1.0 |

---

## 关键技术点

### 1. 信号机制

系统采用Godot的信号机制实现解耦：

- `SanityServer` 作为数据层，只负责状态管理和信号发射
- `AtmosphereController` 作为表现层，只负责接收信号并调整视觉效果
- 两者之间通过信号连接，无需直接引用

### 2. 环境调整

通过 `WorldEnvironment` 的 `adjustment_*` 属性实现实时视觉调整：

- `adjustment_contrast`: 调整对比度，值越大画面越锐利
- `adjustment_saturation`: 调整饱和度，值越小画面越灰暗
- `adjustment_brightness`: 调整亮度，值越小画面越暗

### 3. 阈值检测

采用双向阈值检测，既检测下降也检测回升：

```gdscript
# 下降检测：触发负面效果
if old >= 25 and new < 25:
    emit_signal("sanity_threshold_crossed", "severe")

# 回升检测：恢复正常效果
elif old < 75 and new >= 75:
    emit_signal("sanity_threshold_crossed", "recovered_normal")
```

---

## 扩展建议

### 潜在优化方向

1. **动态光源效果**: 根据理智值调整玩家光源的亮度和颜色
2. **粒子效果增强**: 添加理智低下时的视觉噪点或扭曲效果
3. **音效配合**: 理智低下时添加环境音效变化
4. **场景元素变化**: 低理智时某些场景元素呈现不同状态
5. **性能优化**: 考虑使用着色器实现更高效的视觉效果

### 代码优化建议

```gdscript
# 当前实现：每帧调整环境参数
# 建议优化：使用Tween实现平滑过渡
func _adjust_environment(contrast: float, saturation: float, brightness: float) -> void:
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        env.adjustment_enabled = true
        
        # 使用Tween实现平滑过渡
        var tween = create_tween()
        tween.tween_property(env, "adjustment_contrast", contrast, 0.3)
        tween.tween_property(env, "adjustment_saturation", saturation, 0.3)
        tween.tween_property(env, "adjustment_brightness", brightness - 0.1, 0.3)
```

---

## 总结

本项目的光明与黑暗效果系统通过**理智系统**作为核心驱动，配合**氛围控制器**实现动态视觉效果调整。系统具有以下特点：

1. **分层架构**: 数据层与表现层分离，易于维护和扩展
2. **渐进式效果**: 根据理智等级逐步调整视觉参数
3. **双向反馈**: 支持理智值下降和回升的完整循环
4. **怪物互动**: 特定怪物可以造成理智伤害，增强游戏玩法

该系统为游戏营造了独特的诡异氛围，增强了玩家的代入感和紧张感。