# 地图光明与黑暗效果实现文档

## 概述

本文档专注于说明游戏地图中光明与黑暗视觉效果的技术实现，涵盖场景光照系统、环境设置、动态视觉调整等方面。

---

## 一、场景光照架构

### 1.1 整体结构

```
┌─────────────────────────────────────────────────────────────┐
│                   地图光照效果系统                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐                                   │
│  │   WorldEnvironment  │  全局环境设置                      │
│  └──────────┬──────────┘                                   │
│             │                                              │
│             ▼                                              │
│  ┌─────────────────────┐     ┌─────────────────────────┐   │
│  │   CanvasModulate    │     │      PointLight2D       │   │
│  │   全局画布颜色调制   │     │      玩家点光源         │   │
│  └─────────────────────┘     └──────────┬──────────────┘   │
│                                         │                  │
│                                         ▼                  │
│                          ┌─────────────────────────┐       │
│                          │  AtmosphereController   │       │
│                          │     氛围动态控制器       │       │
│                          └─────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

## 二、核心组件实现

### 2.1 WorldEnvironment（全局环境）

**文件位置**: `game/map/SnowWorld/SnowWorld.tscn`

**功能**: 提供全局光照和视觉效果设置

**关键配置参数**:

| 参数 | 值 | 作用 |
|------|-----|------|
| `background_mode` | 3 | 使用纯颜色背景 |
| `glow_enabled` | true | 启用发光效果 |
| `glow_intensity` | 1.31 | 发光强度 |
| `glow_blend_mode` | 1 | 加性混合模式 |

**调整属性**:

```gdscript
var env = world_environment.environment
env.adjustment_enabled = true        # 启用调整
env.adjustment_contrast = contrast   # 对比度调整
env.adjustment_saturation = saturation  # 饱和度调整
env.adjustment_brightness = brightness  # 亮度调整
```

### 2.2 CanvasModulate（画布调制）

**文件位置**: `game/map/SnowWorld/SnowWorld.tscn`

**功能**: 对整个场景画面进行颜色叠加

**配置方式**:

```gdscript
# 设置初始暗色调氛围
$CanvasModulate.color = Color(0.039, 0.039, 0.039, 1)  # 接近纯黑

# 动态调整（如天黑效果）
$CanvasModulate.color = Color(0.2, 0.2, 0.3, 0.5)  # 深蓝色半透明叠加
```

**使用场景**:
- 营造夜晚或阴暗场景氛围
- 实现场景过渡时的颜色滤镜效果
- 配合剧情触发特定视觉风格

### 2.3 PointLight2D（玩家光源）

**文件位置**: `game/map/SnowWorld/SnowWorld.tscn` → `PlayerRoot/Anchor/Camera2D/PointLight2D`

**功能**: 为玩家角色提供局部光照，模拟手电筒或视野效果

**关键配置**:

| 参数 | 值 | 说明 |
|------|-----|------|
| `energy` | 1.2 | 光源强度 |
| `shadow_enabled` | true | 启用阴影投射 |
| `texture` | light2.png | 自定义光斑纹理 |
| `texture_scale` | 0.5 | 光斑大小 |

**动态调整示例**:

```gdscript
# 根据场景状态调整光源
var light = $PlayerRoot/Anchor/Camera2D/PointLight2D

# 正常状态
light.energy = 1.2
light.color = Color(1, 1, 1)

# 黑暗状态（光源变暗，颜色偏红）
light.energy = 0.6
light.color = Color(1, 0.7, 0.7)
```

---

## 三、动态氛围控制

### 3.1 AtmosphereController（氛围控制器）

**文件位置**: `game/atmosphere/AtmosphereController.gd`

**功能**: 根据游戏状态动态调整视觉效果

**核心方法**:

```gdscript
func _adjust_environment(contrast: float, saturation: float, brightness: float) -> void:
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        env.adjustment_enabled = true
        env.adjustment_contrast = contrast
        env.adjustment_saturation = saturation
        env.adjustment_brightness = brightness - 0.1
```

**视觉效果等级**:

| 等级 | 对比度 | 饱和度 | 亮度 | 视觉效果描述 |
|------|--------|--------|------|--------------|
| 正常 | 1.0 | 1.0 | 1.0 | 明亮清晰 |
| 轻微 | 1.1 | 0.95 | 0.95 | 略微偏暗，对比度提升 |
| 中等 | 1.2 | 0.85 | 0.85 | 明显偏暗，色彩饱和度降低 |
| 严重 | 1.4 | 0.7 | 0.7 | 强烈暗化，画面偏红 |

### 3.2 过渡动画

**优化建议**: 使用 Tween 实现平滑过渡效果

```gdscript
func _adjust_environment_smooth(contrast: float, saturation: float, brightness: float) -> void:
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        env.adjustment_enabled = true
        
        var tween = create_tween()
        tween.tween_property(env, "adjustment_contrast", contrast, 0.3)
        tween.tween_property(env, "adjustment_saturation", saturation, 0.3)
        tween.tween_property(env, "adjustment_brightness", brightness - 0.1, 0.3)
```

---

## 四、地图场景配置示例

### 4.1 SnowWorld 场景光照配置

**场景结构**:

```
SnowWorld (Node2D)
├── WorldEnvironment           # 全局环境
│   └── Environment            # 环境资源
├── CanvasModulate             # 画布颜色调制
│   └── color = (0.039, 0.039, 0.039, 1)
├── PlayerRoot                 # 玩家根节点
│   └── Anchor
│       └── Camera2D
│           └── PointLight2D   # 玩家光源
├── Land                       # 地面瓦片
├── Ice                        # 冰面瓦片
└── MonsterRoot                # 怪物根节点
```

**环境资源配置** (`SnowWorld.tscn`):

```gdscript
[sub_resource type="Environment" id="Environment_5l1ky"]
background_mode = 3
glow_enabled = true
glow_levels/1 = 1.0
glow_levels/2 = 1.0
glow_levels/4 = 1.0
glow_normalized = true
glow_intensity = 1.31
glow_blend_mode = 1
```

---

## 五、光照效果技术原理

### 5.1 调整层原理

Godot 的 `WorldEnvironment` 通过调整层（Adjustment Layer）实现实时画面调整：

```
原始场景渲染
    │
    ▼
调整层处理（对比度、饱和度、亮度）
    │
    ▼
发光效果处理
    │
    ▼
最终画面输出
```

### 5.2 光源投影

**PointLight2D** 的阴影投射机制：

```gdscript
# 阴影配置
shadow_enabled = true           # 启用阴影
shadow_color = Color(0, 0, 0)   # 阴影颜色
shadow_softness = 1.0          # 阴影柔和度
```

### 5.3 纹理光斑

通过自定义纹理实现个性化光源效果：

```gdscript
# 使用纹理定义光斑形状
light.texture = load("res://Sprites/light2.png")
light.texture_scale = 0.5       # 缩放光斑
light.offset = Vector2(0, 0)    # 光斑偏移
```

---

## 六、扩展实现建议

### 6.1 动态天气效果

```gdscript
# 雨雾效果
func set_rain_intensity(intensity: float):
    var env = world_environment.environment
    env.fog_enabled = true
    env.fog_density = 0.1 + intensity * 0.2
    env.fog_color = Color(0.5, 0.5, 0.6)
```

### 6.2 昼夜循环

```gdscript
# 时间驱动的光照变化
func update_time_of_day(hour: float):
    var normalized_hour = hour / 24.0
    
    # 根据时间调整亮度
    var brightness = 0.3 + sin(normalized_hour * PI * 2) * 0.4
    
    var env = world_environment.environment
    env.adjustment_brightness = brightness
```

### 6.3 区域光照差异

```gdscript
# 不同区域应用不同光照
func enter_dark_area():
    $CanvasModulate.color = Color(0.1, 0.1, 0.2, 0.3)
    $PlayerRoot/Anchor/Camera2D/PointLight2D.energy = 0.8

func enter_light_area():
    $CanvasModulate.color = Color(1, 1, 1, 0)
    $PlayerRoot/Anchor/Camera2D/PointLight2D.energy = 1.5
```

---

## 七、性能优化建议

### 7.1 光照性能

| 优化项 | 说明 |
|--------|------|
| 阴影距离限制 | 设置合理的阴影投射距离 |
| 光源数量控制 | 减少同时激活的光源数量 |
| 纹理分辨率 | 使用合适分辨率的光斑纹理 |

### 7.2 渲染优化

```gdscript
# 禁用不必要的效果
func set_low_quality():
    var env = world_environment.environment
    env.glow_enabled = false           # 关闭发光
    env.adjustment_enabled = false     # 关闭调整层
```

---

## 总结

地图光明与黑暗效果通过以下技术手段实现：

1. **WorldEnvironment**: 全局环境设置，包括背景、发光、调整层
2. **CanvasModulate**: 画布颜色叠加，快速改变整体色调
3. **PointLight2D**: 玩家局部光源，模拟视野和照明效果
4. **AtmosphereController**: 动态效果控制，实现状态驱动的视觉变化

这些组件协同工作，能够营造出从明亮到黑暗的各种氛围效果，增强游戏的沉浸感和视觉表现力。