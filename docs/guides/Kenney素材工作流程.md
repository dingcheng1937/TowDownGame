# Kenney Game Assets 工作流程

本文档说明如何在 TowDownGame 项目中高效使用 Kenney Game Assets All-in-1 3.5.0 素材包。

---

## 1. 素材包概览

| 属性 | 值 |
|------|-----|
| 路径 | `D:\Projects\Godot\assets\Kenney Game Assets All-in-1 3.5.0` |
| 许可证 | **CC0**（公共领域，可自由商用，无需署名） |
| 分类 | 2D assets / 3D assets / Audio / Icons / UI assets / Other |

### 分类索引

| 分类 | 包数量 | 主要格式 | 适用场景 |
|------|--------|----------|----------|
| 2D assets | ~30+ | PNG, SVG, Spritesheet | 精灵、UI、地图瓦片 |
| 3D assets | ~25+ | GLB, FBX, OBJ | 3D模型（本项目2D，基本不用） |
| Audio | ~12 | OGG | BGM、音效、UI音 |
| Icons | ~3 | PNG | 游戏图标、输入提示 |
| UI assets | ~2 | PNG | 光标、UI面板 |
| Other | 字体8款 + Miniguides | TTF | 像素字体、UI字体 |

---

## 2. 项目已有的 Kenney 资产

项目已集成以下 Kenney 素材，遵循"直接放入目录、保留原始文件名"的模式：

| 资产包 | 项目内位置 | 说明 |
|--------|-----------|------|
| Particle Pack 1.1 | `Sprites/effect/part/` | 粒子贴图（dirt, fire, flame, smoke, spark 等） |
| Sci-Fi Items | `Sprites/All_Icons/` | 科幻风格图标（Blue Axe, Onyx Blade 等） |

---

## 3. 素材包内部结构

### 3.1 2D 资产包的典型结构

大多数 2D 包包含以下子目录：

```
某个 2D Pack/
├── PNG/              # 单独的 PNG 精灵（最常用）
│   ├── sprite_01.png
│   ├── sprite_02.png
│   └── ...
├── Spritesheet/      # 精灵表（合并所有精灵到一张大图）
│   └── spritesheet.png
├── Vector/           # SVG 矢量图（可缩放，Godot 支持导入）
│   ├── sprite_01.svg
│   └── ...
├── License.txt       # CC0 许可证
└── Preview.png       # 预览图
```

**Godot 使用建议**：
- 优先使用 `PNG/` 目录中的单独精灵 → 便于单独引用和动画编排
- `Spritesheet/` 适合需要批量加载的场景 → 用 `AnimatedSprite2D` 或 `Sprite2D.region_enabled` 切割
- `Vector/` (SVG) 适合需要无损缩放的 UI 元素 → Godot 可直接导入但渲染性能略低

### 3.2 3D 资产包的典型结构

```
某个 3D Kit/
├── Models/
│   ├── GLB/           # Godot 推荐格式
│   │   ├── model.glb
│   │   └── Textures/
│   │       └── colormap.png
│   ├── FBX/
│   ├── OBJ/
│   ├── DAE/
│   └── STL/
├── License.txt
└── Preview.png
```

**本项目为 2D 俯视角游戏，3D 资产一般不适用。** 如需使用 3D 模型的渲染图，可在外部工具中渲染为 2D 精灵后导入。

### 3.3 音频包的典型结构

```
某个 Audio Pack/
├── Audio/             # OGG 音频文件
│   ├── sound_01.ogg
│   ├── sound_02.ogg
│   └── ...
├── License.txt
└── Preview.png        # 波形预览图
```

部分音频包（如 Foley Sounds）会按子类别组织：

```
Foley Sounds/
├── Audio/
│   ├── Footsteps/
│   │   ├── step_01.ogg
│   │   └── ...
│   ├── Glass/
│   └── Wood/
```

### 3.4 字体

```
Other/Fonts/
├── Kenney Blocks.ttf
├── Kenney Bold.ttf
├── Kenney Future.ttf
├── Kenney High.ttf
├── Kenney Mini.ttf
├── Kenney Pixel.ttf    # ← 像素风，最契合本项目
├── Kenney Rocket.ttf
├── Kenney Space.ttf
└── Kenney Thick.ttf
```

---

## 4. 导入工作流程

### 4.1 核心原则

1. **只复制需要的文件** — 不要把整个素材包拖入项目，只取用到的
2. **保留原始文件名** — Kenney 的命名清晰规范（如 `dirt_01.png`），无需重命名
3. **放入对应功能目录** — 遵循项目已有的目录组织方式
4. **保留 License.txt** — 虽然是 CC0，但保留许可证是好习惯

### 4.2 导入步骤

```
1. 在素材包中浏览 Preview.png 找到需要的素材
2. 确定素材类型（精灵/音频/字体/UI）
3. 复制到项目对应目录
4. 在 Godot 编辑器中确认导入成功
5. 在代码或场景中引用
```

### 4.3 目标目录映射

| 素材类型 | 项目目标目录 | 示例 |
|----------|-------------|------|
| 游戏精灵（角色、物品、特效） | `Sprites/<用途>/` | `Sprites/monster/` |
| 粒子贴图 | `Sprites/effect/part/` | 已有 |
| 图标 | `Sprites/All_Icons/` | 已有 |
| UI 元素 | `Sprites/ui/` | `Sprites/ui/kenney_panel/` |
| BGM | `audio/bgm/` | `audio/bgm/kenney_loop.ogg` |
| 音效 | `audio/sfx/` | `audio/sfx/kenney_click.ogg` |
| 字体 | `fonts/` | `fonts/Kenney Pixel.ttf` |

### 4.4 2D 精灵导入示例

**场景：需要使用 Tiny Town 的建筑瓦片**

```powershell
# 从素材包复制 PNG 精灵到项目
Copy-Item "D:\Projects\Godot\assets\Kenney Game Assets All-in-1 3.5.0\2D assets\Tiny Town\PNG\*" `
          -Destination "D:\Projects\Godot\TowDownGame\Sprites\map\tiny_town\" `
          -Recurse

# 复制许可证
Copy-Item "D:\Projects\Godot\assets\Kenney Game Assets All-in-1 3.5.0\2D assets\Tiny Town\License.txt" `
          -Destination "D:\Projects\Godot\TowDownGame\Sprites\map\tiny_town\"
```

在 Godot 中引用：

```gdscript
# preload 方式（推荐，编译时加载）
const building_sprite = preload("res://Sprites/map/tiny_town/building_01.png")

# load 方式（运行时加载）
var tree_texture = load("res://Sprites/map/tiny_town/tree_01.png")

# @export 方式（编辑器拖拽赋值，最灵活）
@export var tile_texture: Texture2D
```

### 4.5 音频导入示例

**场景：需要使用 UI Audio 的点击音效**

```powershell
# 创建目标目录
New-Item -ItemType Directory -Path "D:\Projects\Godot\TowDownGame\audio\sfx\ui" -Force

# 复制需要的音效
Copy-Item "D:\Projects\Godot\assets\Kenney Game Assets All-in-1 3.5.0\Audio\UI Audio\Audio\click1.ogg" `
          -Destination "D:\Projects\Godot\TowDownGame\audio\sfx\ui\"

# 复制许可证
Copy-Item "D:\Projects\Godot\assets\Kenney Game Assets All-in-1 3.5.0\Audio\UI Audio\License.txt" `
          -Destination "D:\Projects\Godot\TowDownGame\audio\sfx\ui\"
```

在 Godot 中引用：

```gdscript
# UI 按钮点击音效
@export var click_sound: AudioStream = load("res://audio/sfx/ui/click1.ogg")

func _on_button_pressed():
    $AudioStreamPlayer.stream = click_sound
    $AudioStreamPlayer.play()
```

### 4.6 字体导入示例

```powershell
# 复制像素字体（最契合本项目风格）
Copy-Item "D:\Projects\Godot\assets\Kenney Game Assets All-in-1 3.5.0\Other\Fonts\Kenney Pixel.ttf" `
          -Destination "D:\Projects\Godot\TowDownGame\fonts\"
```

在 Godot 中使用：

```gdscript
# 代码中动态设置字体
var kenney_font = load("res://fonts/Kenney Pixel.ttf")
$Label.add_theme_font_override("font", kenney_font)
```

---

## 5. 素材包推荐使用指南

根据本项目（2D 俯视角射击/搜打撤游戏）的需求，推荐以下素材包：

### 5.1 高优先级

| 素材包 | 类型 | 推荐用途 |
|--------|------|----------|
| **Tiny Town** | 2D | 地图瓦片、建筑、环境装饰 |
| **Tiny Dungeon** | 2D | 室内地图、地牢场景 |
| **UI Pack** | UI | 面板、按钮、滑条等 UI 组件 |
| **UI Audio** | 音频 | 按钮点击、开关切换等 UI 音效 |
| **Music Loops** | 音频 | 背景音乐循环 |
| **Impact Sounds** | 音频 | 击中、爆炸等战斗音效 |
| **Crosshair Pack** | 2D | 准星样式（项目已有准星，可扩展） |
| **Kenney Pixel** | 字体 | 像素风字体，契合项目风格 |

### 5.2 中优先级

| 素材包 | 类型 | 推荐用途 |
|--------|------|----------|
| **Voxel Pack** | 2D | 体素风格精灵，可做特殊视觉效果 |
| **Splat Pack** | 2D | 血迹、涂鸦等地面效果 |
| **Smilies** | 2D | 表情图标，可做状态指示器 |
| **Foley Sounds** | 音频 | 脚步、环境音 |
| **Retro Sounds 1/2** | 音频 | 复古风格音效 |
| **Cursor Pack** | UI | 自定义光标样式 |
| **Game Icons** | Icons | 成就、技能图标 |
| **Input Prompts** | Icons | 手柄/键盘按键提示 |

### 5.3 低优先级（按需使用）

| 素材包 | 类型 | 说明 |
|--------|------|------|
| **Pixel Shmup** | 2D | 像素射击游戏素材，风格可能冲突 |
| **Pirate Pack** | 2D | 海盗主题，与科幻风格不搭 |
| **Racing Pack** | 2D | 赛车主题 |
| **3D assets (全部)** | 3D | 本项目为 2D，基本不适用 |
| **Casino Audio** | 音频 | 赌场音效 |

---

## 6. 精灵表（Spritesheet）处理

部分 Kenney 2D 包提供精灵表而非单独 PNG。在 Godot 中有两种处理方式：

### 方式一：使用 Sprite2D 区域切割（推荐简单场景）

1. 将精灵表 PNG 放入项目
2. 选中 Sprite2D 节点 → Inspector → Texture → 加载精灵表
3. 勾选 `Region Enabled` → 设置 `Region Rect` 的位置和大小

### 方式二：使用 AnimatedSprite2D + SpriteFrames

1. 创建 AnimatedSprite2D 节点
2. SpriteFrames → 新建 SpriteFrames → 添加动画
3. 从精灵表中逐帧添加区域

### 方式三：使用 Godot 的 Sprite 帧编辑器切片

1. 双击精灵表资源打开编辑器
2. 选择 "Slice" → 设置网格大小（如 16x16）
3. 自动切割为独立帧

---

## 7. 纹理导入设置

本项目为像素风低分辨率游戏（视口 410x230），导入 Kenney 纹理时需注意：

### 像素风纹理（如 Tiny Town、Pixel Shmup）

在 Godot 的 Import 面板中设置：
- **Filter**: Nearest（关闭线性过滤，保持像素锐利）
- **Compress**: Lossless（无损压缩）
- **Mipmaps**: 关闭

### 非像素风纹理（如 UI Pack、Icons）

- **Filter**: Linear（默认值，平滑显示）
- **Compress**: VRAM Compressed（节省显存）
- **Mipmaps**: 按需开启

### 批量设置方法

1. 在文件系统中多选需要统一设置的纹理
2. 在 Import 面板中修改参数
3. 点击 "Reimport" 批量应用

---

## 8. assets.json 自动化索引

素材包根目录包含 `assets.json`，记录了所有素材的元数据。可用于编写自动化脚本：

```json
{
  "name": "Tiny Town",
  "type": "2D",
  "tags": ["top-down", "city", "buildings"],
  "files": ["PNG/", "Spritesheet/", "Tilesheet.txt"]
}
```

**潜在用途**：
- 编写脚本按标签搜索素材
- 自动生成素材清单
- 批量复制指定类型的素材

---

## 9. 常见问题

### Q: 需要把整个素材包复制到项目中吗？
**不需要。** 只复制用到的素材文件。整个素材包约数 GB，会严重增加项目体积和 Git 仓库大小。

### Q: SVG 矢量图能在 Godot 中使用吗？
可以。Godot 支持导入 SVG，但渲染性能不如位图。对于需要无损缩放的 UI 元素推荐使用，游戏精灵建议用 PNG。

### Q: Kenney 音频都是 OGG 格式，Godot 支持吗？
完全支持。OGG 是 Godot 推荐的音频格式之一。BGM 用 `AudioStreamOggVorbis`（支持循环），短音效用 `AudioStreamOggVorbis` 即可。

### Q: 如何在 Godot 中预览素材包的 Preview.png？
在 Godot 的文件系统面板中无法直接浏览项目外部文件。建议：
1. 用系统文件管理器浏览素材包的 Preview.png
2. 确定需要的素材后再复制到项目

### Q: 3D 模型能用于 2D 游戏吗？
可以但需要额外步骤：
1. 在 Blender 等工具中打开 GLB 模型
2. 设置正交摄像机，从俯视角渲染
3. 导出为 PNG 精灵序列
4. 导入 Godot 作为 2D 精灵使用

---

## 10. 工作流程速查

```
浏览素材 → Preview.png 找到需要的包
    ↓
确认格式 → PNG（精灵）/ OGG（音频）/ TTF（字体）
    ↓
复制文件 → 只复制需要的文件到项目对应目录
    ↓
导入设置 → 像素风用 Nearest + Lossless，其他用默认
    ↓
代码引用 → preload() / load() / @export
    ↓
GYM 验证 → 在对应 GYM 场景中测试效果
```
