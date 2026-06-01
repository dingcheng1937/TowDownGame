
# 诡异类搜打撤游戏 MVP 开发计划

## 一、项目定位与目标

### 1.1 游戏类型融合

| 要素 | 来源 | 说明 |
|-----|------|------|
| 俯视视角射击 | 《Don't Stop》 | 已有的成熟射击系统 |
| 搜索/收集 | 搜打撤核心 | 探索、拾取、管理资源 |
| 撤离机制 | 搜打撤核心 | 限时/条件性撤离 |
| 诡异氛围 | 原创 | 恐怖、诡异、神秘元素 |
| Roguelike 元素 | 《Don't Stop》 | 随机地图、永久死亡 |

### 1.2 MVP 目标
- **验证核心玩法循环**：搜索 → 战斗 → 撤离
- **建立诡异氛围**：视觉、音效、场景设计
- **保留可扩展性**：为后续内容更新预留空间

---

## 二、当前项目可复用系统分析

### 2.1 核心战斗系统（高优先级复用）

| 系统 | 来源文件 | 复用方式 |
|-----|---------|---------|
| 玩家移动 | `game/hero/Hero.gd` | 完全复用，调整手感 |
| 武器系统 | `game/guns/BaseGun.gd` | 完全复用，设计诡异武器 |
| 子弹系统 | `game/bullets/Bullet.gd` | 完全复用 |
| 怪物基础 | `game/monster/BaseMonster.gd` | 完全复用，设计诡异敌人 |

### 2.2 数据管理系统（高优先级复用）

| 系统 | 来源文件 | 复用方式 |
|-----|---------|---------|
| PlayerData | `autoload/PlayerData.gd` | 扩展，增加"背包"、"任务物品" |
| ConfigUtils | `autoload/ConfigUtils.gd` | 完全复用 |
| Utils | `autoload/Utils.gd` | 扩展，增加氛围控制功能 |

### 2.3 UI 系统（中优先级复用）

| UI组件 | 来源 | 复用方式 |
|-------|------|---------|
| 背包UI | `demo/GYM_10_Inventory.tscn` | 重构为"战利品管理" |
| 武器列表 | `demo/GYM_09_WeaponList.tscn` | 完全复用 |
| 伤害数字 | `demo/GYM_08_HitLabel.tscn` | 完全复用 |

### 2.4 需要重构的系统

| 系统 | 当前用途 | 新用途 |
|-----|---------|-------|
| 奖励系统 | `RewardServer.gd` | 改为"战利品系统" |
| 地图系统 | `MapServer.gd` | 改为"随机区域生成" |
| 关卡系统 | `LevelServer.gd` | **直接复用**（已有完整关卡管理实现） |

---

## 三、诡异搜打撤游戏核心玩法设计

### 3.1 核心循环

```
进入区域 → 搜索资源/线索 → 遭遇敌人 → 收集战利品 → 达成撤离条件 → 成功撤离
                    ↓
                （失败 → 永久死亡 → 丢失本次所有收获）
```

### 3.2 新增核心机制

#### 3.2.1 理智系统（Sanity）
**核心概念**：玩家在诡异环境中会逐渐失去理智，影响能力和视觉

**设计参数**：
```gdscript
# 建议扩展到 PlayerData.gd
var max_sanity = 100.0
var current_sanity = 100.0:
    set(value):
        current_sanity = clamp(value, 0, max_sanity)
        if current_sanity &lt;= 0:
            # 完全疯狂效果
        emit_signal("sanity_changed", current_sanity)

# 理智影响
- 75-100：正常状态
- 50-75：视觉出现轻微扭曲
- 25-50：幻听、幻觉增多
- 0-25：严重幻觉、操作受影响
- 0：角色死亡/疯狂
```

#### 3.2.2 撤离系统（Extraction）
**核心概念**：玩家需要满足一定条件才能触发撤离

**撤离条件类型**：
1. **时间条件**：在限定时间内撤离
2. **物品条件**：收集特定任务物品
3. **击杀条件**：消灭指定敌人
4. **综合条件**：多种条件结合

#### 3.2.3 战利品系统（Loot）
**核心概念**：区分"可带出"和"单次使用"的物品

**物品分类**：
```
战利品
├── 消耗品（单次使用）
│   ├── 生命恢复
│   ├── 理智恢复
│   └── 临时强化
├── 武器/装备（带出）
│   ├── 诡异武器
│   └── 护符
└── 特殊物品（带出）
    ├── 档案/线索
    └── 解锁新区域的道具
```

---

## 四、MVP 开发阶段规划

### 阶段一：基础框架搭建（1-2周）

#### 1.1 创建新的自动加载系统
**新增文件**：
```
autoload/server/
├── SanityServer.gd       # 理智系统管理
├── LootServer.gd         # 战利品管理
└── ExtractionServer.gd   # 撤离系统管理
```

**SanityServer.gd 基础实现**：
```gdscript
extends Node

signal sanity_changed(current: float, max: float)
signal insanity_effect_triggered(effect_type: String)

var max_sanity: float = 100.0
var current_sanity: float = 100.0
var passive_drain_rate: float = 0.5  # 每秒自然流失

func _ready():
    pass

func _process(delta):
    if Utils.is_game_started:
        change_sanity(-passive_drain_rate * delta)

func change_sanity(amount: float):
    var old_value = current_sanity
    current_sanity = clamp(current_sanity + amount, 0, max_sanity)
    emit_signal("sanity_changed", current_sanity, max_sanity)
    
    # 触发不同理智水平的效果
    _check_sanity_thresholds(old_value, current_sanity)

func _check_sanity_thresholds(old: float, new: float):
    if old &gt; 75 and new &lt;= 75:
        emit_signal("insanity_effect_triggered", "mild_hallucination")
    elif old &gt; 50 and new &lt;= 50:
        emit_signal("insanity_effect_triggered", "moderate_hallucination")
    # ... 更多阈值
```

#### 1.2 创建诡异环境管理器
**新增文件**：`game/atmosphere/AtmosphereController.gd`
```gdscript
extends Node2D

@onready var world_environment: WorldEnvironment = $WorldEnvironment

func apply_sanity_effect(sanity_level: float):
    if sanity_level &gt; 75:
        # 正常色调
        adjust_color_correction(1.0, 1.0, 1.0)
    elif sanity_level &gt; 50:
        # 轻微偏色
        adjust_color_correction(1.1, 0.9, 0.9)
    elif sanity_level &gt; 25:
        # 强烈偏色 + 饱和度降低
        adjust_color_correction(1.3, 0.7, 0.7)
    else:
        # 极端效果
        adjust_color_correction(1.5, 0.5, 0.5)

func adjust_color_correction(contrast: float, saturation: float, brightness: float):
    # 实现色调调整
    pass
```

### 阶段二：核心玩法实现（2-3周）

#### 2.1 改造现有地图为诡异场景
**目标**：将现有城镇地图改造为"废弃调查现场"

**修改文件**：
- `game/map/mapTown/Town.tscn` → 重命名或复制为 `game/map/AbandonedSite.tscn`
- 添加氛围元素（闪烁灯光、破旧贴图、血迹等）

#### 2.2 创建诡异怪物
**新增怪物类型**：
1. **残影（Shade）**：高速、低血量、造成理智伤害
2. **低语者（Whisperer）**：远程攻击、持续降低周围理智
3. **畸变体（Aberration）**：高血量、物理伤害

**文件结构**：
```
game/monster/weird/
├── Shade.gd
├── Whisperer.gd
└── Aberration.gd
```

#### 2.3 实现撤离点系统
**新增文件**：`game/extraction/ExtractionPoint.gd`
```gdscript
extends Area2D

signal extraction_ready()
signal extraction_activated()

var is_active = false
var required_items = []  # 需要的任务物品
var countdown_timer = 30.0  # 撤离倒计时

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body is Player and is_active:
        emit_signal("extraction_activated")
        start_countdown()

func activate():
    is_active = true
    # 视觉效果：发光、粒子等
    emit_signal("extraction_ready")
```

### 阶段三：UI 和用户体验（1-2周）

#### 3.1 设计新的 UI 系统
**新增 UI**：
```
ui/weird/
├── SanityUI.gd              # 理智条显示
├── LootInventoryUI.gd       # 战利品管理（复用现有背包）
├── ExtractionUI.gd          # 撤离状态显示
└── InsanityOverlay.gd       # 疯狂效果覆盖层
```

#### 3.2 战利品管理界面
**复用现有系统**：
- 基于 `demo/GYM_10_Inventory.tscn` 改造
- 增加"带出/丢弃"选项
- 显示物品稀有度和描述

### 阶段四：测试和平衡（1周）

- 测试游戏流程
- 调整数值平衡（理智消耗、伤害、撤离条件）
- 性能优化

---

## 五、文件结构调整建议

### 5.1 保留原有项目结构
建议**不要直接修改原项目文件**，而是：

1. 复制项目文件夹作为新游戏的基础
2. 或者创建新的命名空间文件夹

**推荐方案**：
```
TowDownGame/ (保留原版)
└── (原样保留)

WeirdLootShooter/ (新项目，复制TowDownGame作为基础)
├── autoload/
│   ├── server/
│   │   ├── SanityServer.gd (新增)
│   │   ├── LootServer.gd (新增)
│   │   └── ExtractionServer.gd (新增)
│   └── ... (原有文件)
├── game/
│   ├── atmosphere/ (新增)
│   ├── extraction/ (新增)
│   ├── monster/weird/ (新增)
│   └── ... (原有文件)
└── ui/weird/ (新增)
```

### 5.2 Git 分支策略
```
main (原版Don't Stop)
  └── weird-loot-shooter (新游戏分支)
       ├── feature/sanity-system
       ├── feature/extraction
       └── ...
```

---

## 六、MVP 功能清单

### 必须实现（P0）
- [ ] 基础理智系统
- [ ] 基础撤离系统
- [ ] 至少1个完整区域（基于现有地图改造）
- [ ] 2-3种诡异敌人
- [ ] 战利品管理（背包+带出机制）
- [ ] 基础诡异氛围（色调+音效）

### 应该实现（P1）
- [ ] 多个撤离条件类型
- [ ] 更多诡异武器
- [ ] 理智效果层次（视觉扭曲、幻觉）
- [ ] 基本存档系统（保留带出的物品）

### 可以实现（P2）
- [ ] 简单剧情/线索系统
- [ ] 更多区域
- [ ] 成就系统

---

## 七、开发优先级建议

### 第1周：基础搭建
1. 创建项目分支/副本
2. 实现 SanityServer
3. 设计并实现基础UI（理智条）

### 第2-3周：核心玩法
4. 改造第一个诡异地图
5. 实现2-3种诡异敌人
6. 实现撤离系统

### 第4-5周：完善体验
7. 战利品系统
8. 氛围效果
9. 测试和平衡

---

## 八、参考代码片段

### 扩展 PlayerData.gd
```gdscript
# 在现有基础上添加
signal sanity_changed(current: float, max: float)
signal loot_added(item: LootItem)
signal loot_removed(item: LootItem)

var max_sanity = 100.0
var current_sanity = 100.0:
    set(value):
        current_sanity = clamp(value, 0, max_sanity)
        emit_signal("sanity_changed", current_sanity, max_sanity)

var extracted_items = []  # 已成功带出的物品
var current_loot = []      # 当前区域收集的物品
```

### 创建 Loot 物品基类
```gdscript
# game/loot/BaseLoot.gd
extends Node
class_name BaseLoot

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var item_name: String = "Unknown Item"
@export var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var can_extract: bool = true  # 是否可以带出
@export var icon: Texture2D

func on_pickup(player: Player):
    # 拾取效果
    pass

func on_use(player: Player):
    # 使用效果
    pass
```

---

## 九、后续扩展方向

1. **剧情系统**：加入调查笔记、录音、剧情分支
2. **更多敌人**：设计更多诡异生物
3. **多个区域**：不同主题的诡异地点
4. **升级系统**：用收集的资源解锁能力
5. **多人合作**：2-4人联机搜打撤

---

## 总结

基于《Don't Stop》的优秀架构，开发诡异搜打撤游戏MVP是完全可行的！核心射击系统可以直接复用，只需要重点开发：
1. 理智系统
2. 撤离机制  
3. 诡异氛围
4. 战利品管理

预计开发周期：4-6周即可完成可玩MVP。
