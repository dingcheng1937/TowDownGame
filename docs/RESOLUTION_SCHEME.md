# 游戏分辨率方案文档

## 1. 当前配置概览

### 1.1 项目设置参数

配置位置：`project.godot` 文件中的 `[display]` 部分

| 参数 | 当前值 | 说明 |
|------|--------|------|
| `window/size/viewport_width` | 410 | 游戏内部渲染宽度（逻辑像素） |
| `window/size/viewport_height` | 230 | 游戏内部渲染高度（逻辑像素） |
| `window/size/window_width_override` | 1536 | 实际显示窗口宽度（屏幕像素） |
| `window/size/window_height_override` | 864 | 实际显示窗口高度（屏幕像素） |
| `window/stretch/mode` | `"canvas_items"` | 缩放模式：内容随窗口缩放 |

### 1.2 关键数值计算

- **缩放比例**：`1536 / 410 ≈ 3.75` 倍
- **宽高比**：`410 : 230 ≈ 16 : 9`（接近标准宽屏比例）
- **窗口宽高比**：`1536 : 864 = 16 : 9`（精确标准宽屏）

### 1.3 像素渲染优化配置

配置位置：`project.godot` 文件中的 `[rendering]` 部分

```
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true
```

这些设置确保精灵移动时对齐到整数像素位置，避免像素抖动或半像素渲染问题。

---

## 2. 设计原理

### 2.1 为什么使用低分辨率+缩放？

这是**像素艺术游戏的标准设计模式**，核心原因：

| 对比项 | 低分辨率渲染+缩放 | 直接高分辨率渲染 |
|--------|------------------|-----------------|
| 像素清晰度 | 清晰锐利，边缘整齐 | 模糊，有半透明边缘 |
| 性能开销 | 渲染计算量低 | 渲染计算量高 |
| 视觉风格 | 复古像素艺术风格 | 失去像素感 |
| 精灵尺寸 | 小精灵即可清晰显示 | 需要大精灵或放大渲染 |

### 2.2 渲染流程图解

```
游戏内部渲染                 窗口实际显示
┌─────────────────┐          ┌───────────────────────────────┐
│   410 × 230     │          │        1536 × 864             │
│   (逻辑像素)    │   3.75x  │       (屏幕像素)              │
│                 │   缩放   │                               │
│  ┌────┐         │   ──→    │   ┌────────────┐              │
│  │4×4│ 精灵像素 │          │   │ 15×15 块   │ 清晰方块显示 │
│  └────┘         │          │   └────────────┘              │
└─────────────────┘          └───────────────────────────────┘
```

每个"逻辑像素"在屏幕上显示为约 `3.75 × 3.75` 的方块，边缘保持清晰锐利。

### 2.3 为什么选择 3.75 倍缩放？

1. **1536×864 是常见桌面窗口尺寸**（接近 1080p 比例，适合大多数显示器）
2. **410×230 设计为游戏最小可玩区域**（足够显示游戏核心内容）
3. **比例接近整数倍**，使像素放大后边缘整齐
4. **16:9 标准宽屏比例**，适配大多数现代显示器

---

## 3. UI布局适配方案

### 3.1 CanvasLayer 分层

UI 使用独立的 `CanvasLayer`（layer=2）渲染，不受相机移动影响。

位置：`ui/ControlUI.tscn`

```
[node name="ControlUI" type="CanvasLayer"]
layer = 2
```

### 3.2 锚点定位策略

| UI组件 | 锚点预设 | 定位方式 |
|--------|---------|---------|
| 顶部HP/UI (hpUI) | 无锚点 | 固定偏移 `offset=(8, 8)` |
| 底部武器栏 (HBoxContainer) | `preset=2` (左下) | `anchor_top=1.0` 固定底部 |
| 底部弹药 (Container) | `preset=3` (右下) | `anchor_left=1.0` 固定右侧 |
| 中央武器切换 (WeaponChangeUI) | `preset=10` (顶部宽) | `anchor_right=1.0` 横向拉伸 |
| 准星 (Crosshair) | 无锚点 | 跟随鼠标位置动态更新 |
| Toast提示 (Control) | `preset=14` (顶部居中) | `anchor_top=0.5` 居中显示 |

### 3.3 关键代码示例

```gdscript
# ui/GameUI.gd - UI入场动画使用相对偏移
func onGameStart():
    var tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_parallel(true)
    tween.tween_property(box_top,"position:y",box_top.position.y,0.3)
        .from(box_top.position.y - box_top.size.y)  # 从上方滑入
    tween.tween_property(bottom_bls,"position:y",bottom_bls.position.y,0.3)
        .from(bottom_bls.position.y + bottom_bls.size.y)  # 从下方滑入
```

---

## 4. 相机系统

### 4.1 相机配置

位置：`game/map/mapTown/Town.tscn` 中的 Camera2D 节点

```
[node name="Camera2D" type="Camera2D"]
process_callback = 0
position_smoothing_enabled = true
```

### 4.2 动态偏移机制

位置：`game/hero/Camera2D.gd`

相机根据鼠标位置轻微偏移，增强瞄准体验：

```gdscript
func _process(_delta):
    var distance = get_global_mouse_position().distance_to(camera_pos)
    var max_distance = 10   # 最大距离阈值
    var max_offset = 5      # 最大偏移量（像素）
    var t = distance / max_distance
    var new_offset = (get_global_mouse_position() - camera_pos).normalized() * max_offset * t
    position = Vector2(int(lerp(position.x, new_offset.x, 0.1)), 
                       int(lerp(position.y, new_offset.y, 0.1)))
```

---

## 5. 修改分辨率操作指南

### 5.1 方案一：调整窗口大小（保持视觉风格）

**适用场景**：想让窗口更大/更小，但保持像素清晰度不变。

**操作步骤**：

1. 打开 `project.godot` 文件
2. 找到 `[display]` 部分
3. 修改窗口覆盖尺寸参数：

```
[display]
window/size/viewport_width=410          # 保持不变
window/size/viewport_height=230         # 保持不变
window/size/window_width_override=1920  # 改为新宽度
window/size/window_height_override=1080 # 改为新高度
```

**常用窗口尺寸参考**：

| 窗口尺寸 | 缩放比例 | 说明 |
|----------|---------|------|
| 1536×864 | ~3.75x | 当前设置，适中 |
| 1920×1080 | ~4.7x | 接近1080p全屏 |
| 1280×720 | ~3.1x | 较小窗口 |
| 800×450 | ~1.95x | 最小可读窗口 |

### 5.2 方案二：调整视口大小（改变显示范围）

**适用场景**：想让玩家看到更多/更少游戏内容。

**操作步骤**：

1. 打开 `project.godot` 文件
2. 找到 `[display]` 部分
3. 修改视口尺寸参数：

```
[display]
window/size/viewport_width=480   # 增大→看到更多内容
window/size/viewport_height=270  # 保持16:9比例
window/size/window_width_override=1536  # 保持窗口不变
window/size/window_height_override=864
```

**效果对比**：

| 视口尺寸 | 显示范围 | 像素视觉 |
|----------|---------|---------|
| 410×230 | 当前 | 当前 |
| 480×270 | 更多内容 | 像素显得略小 |
| 320×180 | 更少内容 | 像素显得更大 |

**注意**：调整视口后需要同步调整：
- UI元素的位置和大小
- TileMap的可见范围
- 相机边界限制

### 5.3 方案三：添加宽高比保持（适配不同屏幕）

**适用场景**：支持不同比例的显示器，避免画面拉伸变形。

**操作步骤**：

1. 打开 `project.godot` 文件
2. 找到 `[display]` 部分
3. 添加宽高比设置：

```
[display]
window/size/viewport_width=410
window/size/viewport_height=230
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"     # 新增：保持宽高比，可能留黑边
```

**宽高比模式说明**：

| 参数值 | 效果 | 适用场景 |
|--------|------|---------|
| `"keep"` | 保持比例，多余区域显示黑边 | 严格保持像素艺术比例 |
| `"keep_width"` | 保持宽度，高度自适应 | 横向扩展视野 |
| `"keep_height"` | 保持高度，宽度自适应 | 竖向扩展视野 |
| `"expand"` | 视口扩展到窗口大小 | 宽屏设备看到更多内容 |

### 5.4 方案四：动态分辨率设置

**适用场景**：让玩家在设置中自定义窗口大小。

**操作步骤**：

1. 创建设置项存储配置：

```gdscript
# autoload/ConfigUtils.gd 已存在配置存储功能
# 添加分辨率配置键
ConfigUtils.setConfig("setting", "resolution_width", 1536)
ConfigUtils.setConfig("setting", "resolution_height", 864)
```

2. 在设置UI添加分辨率选项：

```gdscript
# ui/SettingUI.gd 添加分辨率选项按钮
func _on_resolution_item_selected(index: int) -> void:
    var resolutions = [
        Vector2i(1280, 720),   # 小窗口
        Vector2i(1536, 864),   # 中等
        Vector2i(1920, 1080),  # 大窗口
        Vector2i(2560, 1440),  # 2K
    ]
    var size = resolutions[index]
    get_window().size = size
    ConfigUtils.setConfig("setting", "resolution_width", size.x)
    ConfigUtils.setConfig("setting", "resolution_height", size.y)
```

3. 在游戏启动时读取配置：

```gdscript
# autoload/Utils.gd 或主场景
func _ready():
    var width = ConfigUtils.getConfig("setting", "resolution_width")
    var height = ConfigUtils.getConfig("setting", "resolution_height")
    if width and height:
        get_window().size = Vector2i(width, height)
```

### 5.5 方案五：全屏模式支持

**适用场景**：支持全屏游戏体验。

**操作步骤**：

1. 在设置UI添加全屏选项：

```gdscript
func _on_fullscreen_toggled(is_fullscreen: bool) -> void:
    if is_fullscreen:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    ConfigUtils.setConfig("setting", "fullscreen", is_fullscreen)
```

2. 添加宽高比保持以适配不同全屏分辨率：

```
[display]
window/stretch/aspect="expand"  # 全屏时扩展视野
```

---

## 6. 修改分辨率后的注意事项

### 6.1 需要同步调整的内容

| 修改类型 | 需调整内容 |
|----------|-----------|
| 视口变大 | UI位置、TileMap范围、相机边界、敌人生成区域 |
| 视口变小 | UI可能重叠、游戏内容可能显示不全 |
| 仅窗口变大 | 无需调整（自动缩放） |
| 添加宽高比保持 | 可能需要UI适配黑边区域 |

### 6.2 UI适配检查清单

修改分辨率后，检查以下UI元素：

- [ ] 顶部HP/金币栏是否在正确位置
- [ ] 底部武器列表是否正确显示
- [ ] 底部弹药计数是否正确显示
- [ ] 中央武器切换提示是否居中
- [ ] 准星是否正确跟踪鼠标
- [ ] 设置面板是否完整显示
- [ ] Toast提示是否在正确位置

### 6.3 测试建议

1. 在不同窗口尺寸下测试UI显示
2. 测试全屏模式下的显示效果
3. 测试非16:9比例显示器（如21:9超宽屏）
4. 测试不同缩放比例下的像素清晰度

---

## 7. 配置文件位置速查

| 配置项 | 文件位置 |
|--------|---------|
| 分辨率参数 | `project.godot` → `[display]` |
| 像素渲染优化 | `project.godot` → `[rendering]` |
| UI布局 | `ui/ControlUI.tscn` |
| 相机配置 | `game/map/mapTown/Town.tscn` → Camera2D节点 |
| 相机脚本 | `game/hero/Camera2D.gd` |
| 设置UI | `ui/SettingUI.gd` |
| 配置存储 | `autoload/ConfigUtils.gd` |

---

## 8. 参考资料

- [Godot 官方文档 - 多分辨率支持](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- [Godot 官方文档 - 像素艺术游戏设置](https://docs.godotengine.org/en/stable/tutorials/2d/pixel_art_2d.html)