# 诡异搜打撤 MVP 开发计划

## 现状总结

项目已有完整的核心系统，**不需要从零开发**：

| 系统 | 状态 | 位置 |
|------|------|------|
| 玩家移动/射击/冲刺 | ✅ 完成 | `game/hero/Hero.gd` |
| 武器系统(10种) | ✅ 完成 | `game/guns/` |
| 子弹系统 | ✅ 完成 | `game/bullets/` |
| 普通怪物 | ✅ 完成 | `game/monster/Ghoul/` |
| 诡异怪物(3种) | ✅ 完成 | `game/monster/weird/` |
| 理智系统 | ✅ 完成 | `autoload/server/SanityServer.gd` |
| 战利品系统 | ✅ 完成 | `autoload/server/LootServer.gd` |
| 撤离系统 | ✅ 完成 | `autoload/server/ExtractionServer.gd` |
| 撤离点 | ✅ 完成 | `game/extraction/ExtractionPoint.tscn` |
| 氛围控制器 | ✅ 完成 | `game/atmosphere/AtmosphereController.gd` |
| 战利品物品(3种) | ✅ 完成 | `game/loot/` |
| 诡异UI(理智条/撤离状态/背包) | ✅ 完成 | `ui/weird/` |
| GYM_11验证场景 | ✅ 完成 | `demo/GYM_11_WeirdLoot.tscn` |

**核心差距**：这些系统只在 GYM_11 测试场景中运行，缺少完整的游戏流程场景。

---

## MVP 目标

实现一个**可玩的完整游戏循环**：

```
大厅(准备) → 诡异区域(搜索+战斗+撤离) → 结算(成功/失败) → 大厅
```

---

## 实施步骤

### Step 1: 实现 GameStateServer（游戏状态机）

**新建文件**: `autoload/server/GameStateServer.gd`

- 游戏状态枚举：`LOBBY` / `PLAYING` / `SETTLEMENT` / `DEAD`
- 状态切换方法 + 信号
- 注册为 Autoload（在 `project.godot` 中添加）
- 提供 `transition_to(state)` 方法，切换时发出信号

```gdscript
enum State { LOBBY, PLAYING, SETTLEMENT, DEAD }
signal state_changed(old_state, new_state)
var current_state: State = State.LOBBY
```

### Step 2: 实现 MapServer（场景切换管理）

**修改文件**: `autoload/server/MapServer.gd`（当前为空实现）

- 场景切换方法：
  - `go_to_lobby()` → 加载大厅场景
  - `go_to_weird_zone()` → 加载诡异区域场景
  - `go_to_settlement(success: bool)` → 加载结算场景
- 使用 `get_tree().change_scene_to_file()` 进行场景切换
- 切换前清理/保存必要数据

### Step 3: 创建大厅场景（Lobby）

**新建文件**:
- `game/map/Lobby/Lobby.tscn`
- `game/map/Lobby/Lobby.gd`

场景结构：
```
Lobby (Node2D)
├── Background (Sprite2D / ColorRect)  # 简单背景
├── UIRoot (CanvasLayer)
│   └── LobbyUI (Control)
│       ├── Title (Label)              # 游戏标题
│       ├── LootPreview (VBoxContainer) # 已带出战利品预览
│       └── DeployButton (Button)      # 出发按钮
```

逻辑：
- `_ready()`: 显示已带出战利品（`LootServer.extracted_loot`）
- 点击"出发"按钮：
  1. 重置 `PlayerData`（HP/弹药/武器列表）
  2. 重置 `SanityServer`
  3. 清空 `LootServer.current_loot`
  4. 重置 `ExtractionServer`
  5. `GameStateServer.transition_to(PLAYING)`
  6. `MapServer.go_to_weird_zone()`

### Step 4: 创建诡异区域场景（WeirdZone）

**新建文件**:
- `game/map/WeirdZone/WeirdZone.tscn`
- `game/map/WeirdZone/WeirdZone.gd`
- `game/map/WeirdZone/WeirdMonsterBuilder.gd`

这是 MVP 的**核心场景**，整合所有已有系统。

场景结构（参考 SnowWorld + GYM_11）：
```
WeirdZone (Node2D)
├── Land (TileMap)                     # 复用SnowWorld的TileMap
├── PlayerRoot (Node2D)                # 玩家容器
├── MonsterRoot (Node2D)               # 怪物容器
├── LootRoot (Node2D)                  # 战利品容器
├── EffectRoot (Node2D)                # 特效容器
├── EquipRoot (Node2D)                 # 装备容器
├── ExtractionRoot (Node2D)            # 撤离点容器
├── AtmosphereController               # 氛围控制器
├── WeirdMonsterBuilder (Node2D)       # 诡异怪物生成器
├── CanvasLayer
│   ├── ControlUI                      # 原版HUD（血量/弹药/武器列表）
│   └── Panel                          # 原版开始面板
└── UIRoot (CanvasLayer, layer=2)
    ├── SanityBar                      # 理智条
    ├── ExtractionStatus               # 撤离状态
    └── LootInventoryUI                # 战利品背包(Tab切换)
```

WeirdZone.gd 核心逻辑：
```gdscript
func _ready():
    # 1. 初始化玩家
    PlayerServer.addPlayerToScene($PlayerRoot)
    PlayerServer.setPlayerPosition($CreatePosition.global_position)

    # 2. 初始化撤离系统
    ExtractionServer.reset()
    ExtractionServer.set_conditions(30.0, [], 3)  # 30秒+3击杀

    # 3. 初始化理智系统
    SanityServer.reset_sanity()
    SanityServer.start_drain()

    # 4. 初始化玩家武器
    PlayerData.player_ammo = 9999999
    PlayerData.add_weapon(Utils.weapon_list['0'].instantiate())

    # 5. 生成战利品
    _spawn_loot_items()

    # 6. 启动怪物生成器
    $WeirdMonsterBuilder.start()

    # 7. 启动游戏
    Utils.gameStart()

    # 8. 连接信号
    ExtractionServer.extraction_completed.connect(_on_extraction_success)
    PlayerData.onPlayerDeath.connect(_on_player_death)
    SanityServer.sanity_depleted.connect(_on_sanity_depleted)
```

WeirdMonsterBuilder.gd（参考 MonsterBuilder.gd 改造）：
- 定时生成诡异怪物（Shade/Whisperer/Aberration 随机混合）
- 随时间增加生成频率和怪物强度
- 生成位置基于 TileMap 可用格子，保持与玩家安全距离
- 每次击杀调用 `ExtractionServer.register_kill()`

战利品生成逻辑：
- 地图上随机散落 5-8 个战利品
- 混合 SanityPotion（消耗品，恢复理智）和 MysteriousArtifact/TaintedEssence（可带出）
- 玩家靠近按 E 拾取

撤离流程：
- 达成条件（30秒 + 3击杀）→ 撤离点激活
- 玩家进入撤离点 → 5秒倒计时
- 倒计时完成 → `ExtractionServer.complete_extraction()` → 转移战利品
- 切换到结算场景

死亡/理智归零流程：
- 玩家HP归零 → `PlayerData.onPlayerDeath` 信号
- 理智归零 → `SanityServer.sanity_depleted` 信号
- 清空当前战利品 → `LootServer.clear_current_loot()`
- 切换到结算场景（失败）

### Step 5: 创建结算场景（Settlement）

**新建文件**:
- `game/map/Settlement/Settlement.tscn`
- `game/map/Settlement/Settlement.gd`

场景结构：
```
Settlement (Node2D)
├── Background (Sprite2D / ColorRect)
├── UIRoot (CanvasLayer)
│   └── SettlementUI (Control)
│       ├── ResultTitle (Label)         # "撤离成功" / "行动失败"
│       ├── LootList (VBoxContainer)    # 本次收获/损失的战利品列表
│       ├── StatsLabel (Label)          # 统计信息（击杀数/存活时间/理智）
│       └── ReturnButton (Button)       # 返回大厅按钮
```

逻辑：
- `_ready()`: 根据 `GameStateServer.current_state` 判断成功/失败
- 成功：显示 `LootServer.extracted_loot` 最后添加的物品
- 失败：显示"你迷失在了诡异之中..."
- 统计信息：击杀数（`ExtractionServer.kill_count`）、存活时间（`ExtractionServer.time_in_zone`）
- 点击"返回大厅"：`MapServer.go_to_lobby()`

### Step 6: 修改主场景入口

**修改文件**: `project.godot`

- 将主场景改为 `res://game/map/Lobby/Lobby.tscn`
- 添加 `GameStateServer` 到 Autoload 列表

### Step 7: 整合测试与调优

- 完整流程测试：大厅 → 诡异区域 → 结算 → 大厅
- 数值调整：
  - 理智流失速率（当前 0.5/秒，可能过快）
  - 怪物生成频率
  - 撤离条件（时间/击杀数）
  - 战利品散落数量和分布
- 修复集成问题（信号连接、场景切换时的状态清理等）

---

## 文件变更清单

### 新建文件（7个）
| 文件 | 说明 |
|------|------|
| `autoload/server/GameStateServer.gd` | 游戏状态机 |
| `game/map/Lobby/Lobby.tscn` | 大厅场景 |
| `game/map/Lobby/Lobby.gd` | 大厅逻辑 |
| `game/map/WeirdZone/WeirdZone.tscn` | 诡异区域场景 |
| `game/map/WeirdZone/WeirdZone.gd` | 诡异区域逻辑 |
| `game/map/WeirdZone/WeirdMonsterBuilder.gd` | 诡异怪物生成器 |
| `game/map/Settlement/Settlement.tscn` + `.gd` | 结算场景 |

### 修改文件（2个）
| 文件 | 修改内容 |
|------|---------|
| `autoload/server/MapServer.gd` | 实现场景切换方法 |
| `project.godot` | 添加 GameStateServer Autoload + 修改主场景 |

---

## 技术要点

1. **场景切换时数据保持**：所有关键数据在 Autoload 单例中，场景切换不影响
2. **PlayerServer 跨场景**：已有实现，`addPlayerToScene()` 自动处理玩家实例迁移
3. **理智归零处理**：需要连接 `sanity_depleted` 信号，触发玩家死亡/游戏结束
4. **撤离点交互**：已有完整实现，只需在场景中放置即可
5. **怪物生成**：参考 MonsterBuilder.gd，改造为生成诡异怪物
6. **UI整合**：原版HUD + 诡异UI（理智条/撤离状态/战利品背包）共存

---

## 风险与简化策略

| 风险 | 应对 |
|------|------|
| 场景切换时数据丢失 | 所有数据在 Autoload 中，不受场景切换影响 |
| 地图制作耗时 | MVP 复用 SnowWorld 的 TileMap，仅修改生成逻辑 |
| UI 整合冲突 | 诡异 UI 使用独立 CanvasLayer(layer=2)，与原版 HUD 分离 |
| 理智归零后无处理 | 连接信号后触发玩家死亡流程 |
| 怪物生成位置问题 | 复用 MonsterBuilder 的 TileMap 格子算法 |

**MVP 简化原则**：
- 大厅只做最简UI，不做装备选择/商店
- 诡异区域只有一个，不做多区域选择
- 结算只显示结果，不做详细统计图表
- 先不做存档，每次从大厅开始
- 先不做新武器/新装备，使用现有手枪
