# 精神矫正中心 V2 — 完整 PRD

> 作者：许清楚（产品经理）  
> 日期：2026-06-08  
> 状态：V2 完整设计 — 基于 V1 增量基础上的 6 阶段走廊探索

---

## 目录

1. [审计结论（TL;DR）](#0-审计结论tldr)
2. [6 阶段详细分解](#1-6-阶段详细分解)
3. [关键技术方案](#2-关键技术方案)
4. [新旧系统映射](#3-新旧系统映射)
5. [P0/P1/P2 分级](#4-p0p1p2-分级)
6. [待确认问题](#5-待确认问题)

---

## 0. 审计结论（TL;DR）

**V1 的 MVP 核心已实现并超出预期。** V2 的重点不是推翻重来，而是：

1. **新增"房间→走廊→全域探索"纵向层**：在 V1 的平板 4 区域基础上，加入单个房间的密集战术交互（开门选择、背身靠墙）
2. **引入潜行系统**：从 V1 的"奔跑=噪声"升级到视觉+声音双通道潜行
3. **加入成长循环**：搜刮→升级→更长生存时间→更大探索范围，形成正反馈
4. **地图设计深化**：Boss、节点门禁、捷径、解谜
5. **Boss 演出**：最终 Boss 需要叙事演出

V2 需要**新建**的系统远多于 V1 时代，预计工作量约为 V1 的 1.5-2 倍。

---

## 1. 6 阶段详细分解

### 阶段 1：病房醒来 — 开篇序曲

**场景节点结构：**

```
WardRoom (Node2D)
├── TileMap (病房墙壁/床/窗户/门) [物理碰撞]
├── PlayerSpawnPoint (Marker2D)
├── WardDoor (StaticBody2D + AnimationPlayer)
│   └── CollisionShape2D (初始 enabled=true)
├── InteractionZone (Area2D at door position)
│   └── CollisionShape2D (door area)
├── BackWallCheck (Area2D along wall)
│   └── CollisionShape2D (wall proximity zone)
├── NarratorTrigger (Area2D for intro text)
└── AmbientLight (PointLight2D, dim)
```

**玩家状态/交互：**

| 时刻 | 事件 | 玩家可操作 |
|------|------|-----------|
| 0s | 黑屏渐亮，玩家站在床侧 | 仅移动（无武器） |
| 1s | HUD 提示："你在病房醒来...窗外一片灰暗" | 移动 |
| 3s | **敲门声**（音效 + Toast "有人在敲门..."） | 移动 + 交互提示出现 |
| 3-13s | **开门选择窗口**：玩家走到门前可交互 | 移动 + 交互 |
| 开门 → | 护士进入，3秒缓冲期 | 移动 |
| 不开门 → | 10秒后护士强行破门 | 移动 |

**背身靠墙交互：**  
护士进入后 3 秒内，玩家需要：
- 移动到任意墙壁前（`BackWallCheck` Area2D 检测范围内）
- 玩家朝向 `body.scale.x` 与墙壁法线 **同向**（即背对墙壁，脸朝房间内部）
- 静止 1 秒（`Input.get_vector()` 持续为零）

满足条件后护士放弃攻击，进入巡逻模式。

**胜利条件：** 成功背身靠墙 → 护士转为中立巡逻 → 获得"病房钥匙" → 门解锁  
**失败条件：** 3秒内未靠墙 → 护士触发攻击（2次攻击玩家死亡，因为此阶段无武器）

**需要的新系统：**
- `DoorInteraction` 组件（开门/关门/破门逻辑）
- `BackWallDetection` 组件（朝向+墙壁法线+静止检测）
- `NurseAI` 敌人（行为树：破门→检查→攻击 / 巡逻）
- `IntroSequenceController`（阶段1专用时序控制）

---

### 阶段 2：走廊探索 — 潜行生存

**场景节点结构：**

```
CorridorMain (Node2D)
├── TileMap (走廊墙壁/拐角/房间门/障碍物)
├── PatrolGuard × 3-5 (巡逻员，巡逻路径沿走廊)
├── SurveillanceDrone × 1 (无人机，中心区域圆周巡逻)
├── LootSpawnPoints (Marker2D × N)
│   ├── ConsumablePickup × 2 (药片/镇静剂)
│   ├── ThrowablePickup × 2 (石子/药瓶)
│   ├── MeleeWeaponPickup × 2 (椅腿/输液架)
│   └── NarrativeLootItem × 1 (叙事战利品)
├── SafeRoom × 2 (安全屋，无敌人刷新)
│   ├── RestSpot (Area2D, 进入后理智回升)
│   └── ExtraLoot (额外物资)
├── ShortcutGate_A (locked, 需要"走廊钥匙A"打开捷径)
├── ZoneGate_B (locked, 需要击杀病房区 Boss 才能打开)
└── BossRoomEntrance (到阶段3的过渡门)
```

**玩家状态/交互：**

| 行为 | 警戒影响 | 潜行建议 |
|------|---------|---------|
| 步行 | 0 | 安全 |
| 奔跑 | AlertServer +5/tick | 仅在无敌人时使用 |
| 推开杂物/碰撞发出声响 | AlertServer +10 | 避免 |
| 使用投掷物（石子）引开敌人 | AlertServer +5 | 推荐，主动控场 |
| 近战击杀 | AlertServer +15 | 仅当被包围时 |
| 进入安全屋 | AlertServer 停止增加 | 恢复理智，重新规划路线 |

**索敌与战斗限制：**  
- 走廊中玩家初始仅有 **近战武器**（椅腿）和少量投掷物
- 最多可击杀 **N=3** 个巡逻员（超出后撤离失败或封锁触发大量敌人）
- 无人机**不可击杀**（仅可躲避或投掷物干扰），击杀无人机会立即触发 LOCKDOWN

**胜利条件：** 搜刮到足够物资（至少 1 把近战武器升级 + 3+ 消耗品），抵达 Boss 门  
**失败条件：** 死亡 或 击杀超过 N 个敌人导致封锁

**需要的新系统：**
- **潜行系统**（视觉检测+声音检测，见 §2-C）
- **安全屋系统**（Area2D 触发理智回升+警戒衰减加速）
- **N 敌人限制系统**（计数器，超限触发 LOCKDOWN）
- **捷径/门禁系统**（见 §2-F）

---

### 阶段 3：Boss 房 — 病房主任

**场景节点结构：**

```
BossRoom_WardDirector (Node2D)
├── TileMap (封闭房间，障碍物/掩体)
├── WardDirector (extends BaseMonster, class_name)
│   ├── Phase1_2 skills (投掷病历/束缚带)
│   ├── Phase3 skill (召唤病人幻影 × 2)
│   └── Drop: 主任印章 (KeyItem)
├── ObstacleNodes × 4 (可被 Boss 技能摧毁)
├── BossArenaBoundary (Area2D, 进入后关门)
├── BossIntroCamera (Camera2D, 演出用)
└── PostBossDoor (unlocks after kill)
```

**Boss 设计：**

| 阶段 | HP% | 技能 |
|------|-----|------|
| P1: 权威压制 | 100%-60% | 投掷病历（直线弹道，伤害 1）+ 慢速追击 |
| P2: 束缚治疗 | 60%-30% | + 束缚带（地面AOE，命中后 3 秒定身） |
| P3: 群体控制 | 30%-0% | + 召唤病人幻影（2只弱化 PatrolGuard） |

**胜利条件：** 击败 WardDirector，拾取"主任印章"  
**失败条件：** 死亡  
**演出要求：** Boss 入场有短动画（从办公桌后站起），击败后有掉落+房间解锁动画

**需要的新系统：**
- `WardDirector` Boss 类（基于 BaseMonster 扩展）
- Boss 房间门禁（进入后锁定，击杀后解锁）
- Boss 演出控制器（`BossIntroSequence`）

---

### 阶段 4：治疗区探索 — 成长与节点门禁

**场景节点结构：**

```
TreatmentWing (Node2D)
├── TileMap (更复杂的走廊网络，含多个死胡同)
├── PatrolGuard × 4-6 (巡逻路径更复杂)
├── SedationEnforcer × 2 (慢速但高伤害，守卫关键通道)
├── LootSpawnPoints (更高级别战利品)
│   ├── ConsumablePickup × 3 (包含蓝色药片/镇静剂)
│   ├── MeleeWeaponPickup × 2 (约束带/电击棒)
│   ├── GunPickup × 1 (基础手枪，仅10发弹药)
│   └── LoreItem × 2 (叙事战利品)
├── NodeGate_DoubleLock (需要"主任印章"+"治疗区通行证")
├── Shortcut_OneWay_A (一方向捷径，从治疗区回走廊)
├── PuzzleRoom_Electro (电力解谜房间)
│   ├── Switch_A, Switch_B (两开关)
│   ├── LockedDoor (需通电才开)
│   └── Reward: 武器升级材料
└── BossRoomEntrance_Treatment (到阶段5的门)
```

**玩家状态/交互：**

- 阶段 4 引入了**节点门禁**：部分道路在击杀 WardDirector 之前不可通行（locked until boss kill）
- **捷径设计**：击败区域 Boss 后解锁一方向捷径，方便从后续区域快速返回
- **成长体现**：玩家现在有手枪（但弹药极缺），近战武器升级（电击棒），可以处理更多敌人

**成长循环示例：**

```
搜刮物资 → 获得经验 → 升级 (PlayerData.player_level+)
         → 获得 reward_point → 选择能力增强 (伤害/速度/HP)
         → 更强的生存能力 → 更大探索范围
         → 搜刮更多物资...
```

**解谜房间设计（电力房间）：**

1. 进入房间后，两个开关分别控制两条线路
2. 必须同时开启两开关（或按正确顺序）才能通电
3. 通电后门解锁，获得奖励
4. 若警戒值过高，敌人会被吸引过来（增加压力）

**胜利条件：** 找到"治疗区通行证"并击败足够敌人升级，抵达阶段 5 Boss 门  
**失败条件：** 死亡

**需要的新系统：**
- **升级系统**（`LevelUpUI`，升级时选择能力增强）
- **解谜系统基类**（`BasePuzzle`，可扩展为电力/开关/推箱等）
- **节点门禁系统**（见 §2-F）

---

### 阶段 5：行政办公区 — 高潮推进

**场景节点结构：**

```
AdminWing (Node2D)
├── TileMap (行政办公走廊+科室)
├── SedationEnforcer × 3
├── SurveillanceDrone × 2
├── MidBoss_RestraintChief (约束主管，小Boss)
│   ├── 2阶段：近战重击 + 远程麻醉枪
│   └── Drop: 档案室钥匙
├── ArchiveRoom (叙事房间)
│   ├── 可交互物件（办公桌/档案柜/投影仪）
│   ├── 关键叙事战利品 × 3
│   └── 隐藏道具：实验记录（揭示最终Boss背景）
├── Shortcut_Back_B (行政→治疗区的捷径，需钥匙)
├── PuzzleRoom_Archive (档案排序解谜)
└── FinalBossEntrance (到阶段6)
```

**Boss 演出战 — 最终Boss"院长"：**

| 时刻 | 演出内容 |
|------|---------|
| 进入房间 | 镜头拉远，院长从阴影中走出，独白"你终于来了..." |
| P1 开始 | Boss 名称+HP 条出现（类似 TreatmentDirector 的 UI） |
| P1→P2 (HP 70%) | 屏幕震动，Boss 外形变化（白大褂撕裂，露出机械假肢） |
| P1→P2 演出 | "你以为这里真的是医院吗？" — 揭示实验真相 |
| P2→P3 (HP 30%) | 房间灯光闪烁，周围实验体培养皿爆裂 |
| 击杀 | 慢镜头 + 院长倒下 + 关键叙事战利品掉落（"真相文件"） |

**胜利条件：** 击败院长  
**失败条件：** 死亡  
**撤离：** 击杀后撤离点立即激活，5 秒倒计时

---

### 阶段 6：结果与重玩

**与 V1 的 CorrectionGameManager 完全一致：**

- 撤离成功 → 金币入账 → 仓库升级界面
- 死亡 → 丢失当前背包 → 仓库界面
- 仓库关闭 → 新一轮

**V2 新增：**
- 仓库升级新增 **潜行类升级项**（移动速度/脚步声降低/警戒衰减加速）
- 每一轮结算时显示 **探索百分比/叙事收集进度**

---

## 2. 关键技术方案

### A) 开门选择交互

**方案：** 场景内 HUD 弹窗 + 冻结帧

```
DoorInteraction (Area2D)
├── @export var door_type: DoorType { KNOCKABLE, BREAKABLE, LOCKED }
├── @export var break_time: float = 10.0
├── @onready var door_sprite: Sprite2D
├── @onready var door_collision: CollisionShape2D
├── @onready var anim_player: AnimationPlayer
```

**交互流程：**

1. 玩家走到 `DoorInteraction` 范围内 → 显示按键提示（"按 E 开门"）
2. 按 E → 冻结游戏（`Engine.time_scale = 0`，保留 HUD 层 `process_mode = always`）
3. UI 弹窗："开门 / 不开门" 两个按钮
4. 开门 → `_open_door()` 播放开门动画，`door_collision.disabled = true`
5. 不开门 → 关闭弹窗，恢复 time_scale，启动 `break_timer`（10 秒倒计时）
6. 倒计时结束 → `_break_door()` 强制破门动画
7. 门破后护士进入

**为什么不完全暂停？** 护士需要在破门前有"等待倒计时"的时序逻辑，完全暂停会导致计时器也不走。用 `time_scale = 0` 只冻结物理+玩家，保留 service node 的 timer。

**建议实现位置：** 新建 `game/correction/interaction/DoorInteraction.gd`

---

### B) 背身靠墙检测

**方案：** 独立组件 `BackWallDetector`（Area2D）

**检测条件：**

| 条件 | 检测方式 | 实现 |
|------|---------|------|
| 玩家在墙壁附近 | Area2D 的 `body_entered/body_exited` | 在墙壁 TileMap 前放置 Area2D 子节点 |
| 玩家背对墙壁 | 玩家 `body.scale.x` 符号 vs 墙壁法线方向 | `if sign(body.scale.x) == sign(wall_normal.x)` |
| 玩家静止 | `Input.get_vector()` 持续为零 | Timer 累计静止时间 |
| 持续时间 | 1 秒 | `_still_timer` 达到 1.0 即触发 |

**实现细节：**

```gdscript
class_name BackWallDetector
extends Area2D

@export var wall_normal: Vector2 = Vector2.LEFT  # 墙壁法线（指向房间内）
@export float var still_duration: float = 1.0

var _player_in_range: bool = false
var _still_timer: float = 0.0
var _success: bool = false

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _physics_process(delta):
    if not _player_in_range or _success:
        return
    var player = Utils.player
    if not player: return
    
    # 检查朝向
    var facing_wall = sign(player.body.scale.x) != sign(wall_normal.x)
    # 检查静止
    var is_still = Input.get_vector("left","right","up","down") == Vector2.ZERO
    
    if facing_wall and is_still:
        _still_timer += delta
        if _still_timer >= still_duration:
            _on_success()
    else:
        _still_timer = 0.0
```

**为什么独立组件：** 不修改 Player 类。Player 保持通用。`BackWallDetector` 是场景特定组件，挂在墙壁附近即可。

---

### C) 潜行系统

**方案：** 改造 + 扩展 AlertServer，新增视觉检测通道

**现状：** AlertServer 已经是纯"声音"系统（noise-based）。潜行系统需要在现有的 noise 通道基础上新增 `Visual Detection` 通道。

**双通道设计：**

```
StealthSystem (Autoload, 新建: autoload/server/StealthServer.gd)
├── 声音通道 (委托 AlertServer)
│   ├── 原有 NOISE_* 常量
│   └── 脉冲衰减
├── 视觉通道 (新增)
│   ├── player_visibility: float (0.0=完全隐藏, 1.0=完全暴露)
│   ├── 影响因素:
│   │   ├── 是否在阴影中 (PointLight2D 的遮蔽检测)
│   │   ├── 是否蹲伏/慢走 (新增 input: "crouch")
│   │   ├── 与敌人距离 (越近越容易被看到)
│   │   └── 是否被障碍物遮挡 (PhysicsRayQuery2D)
│   └── 敌人通过 get_player_visibility(pos) 查询
└── 综合威胁等级
    └── threat_level = f(noise_level, visibility, distance, alert_threshold)
```

**敌人 AI 改造：**

在 `BaseMonster` 或新建的 `StealthMonster` 基类中，`_physics_process` 增加：

```gdscript
func can_detect_player() -> bool:
    var dist = global_position.distance_to(player.global_position)
    
    # 声音检测
    if AlertServer.current_alert >= 30 and dist < 200:
        return true
    
    # 视觉检测
    var visibility = StealthServer.get_player_visibility(global_position)
    if visibility > 0.3 and dist < 100:
        return true
    if visibility > 0.6 and dist < 200:
        return true
    
    return false
```

**蹲伏机制（新增到 Player）：**

```gdscript
# 在 Hero.gd _physics_process 中
if Input.is_action_pressed("crouch"):
    SPEED = 100 * PlayerData.player_speed * 0.4  # 40% 速度
    # 标记为蹲伏状态供 StealthServer 读取
    StealthServer.is_crouching = true
else:
    StealthServer.is_crouching = false
```

**操作（新建 vs 改造）：**  
- `StealthServer` — **新建** Autoload，与 AlertServer 协作而非取代
- `BaseMonster` — 不改，新敌人继承时覆盖检测逻辑
- `Player` — 新增 crouch input 绑定

---

### D) 护士 AI

**方案：** 独立类 `NurseAI`，基于 BaseMonster，使用行为树模式

**护士行为树：**

```
[IDLE @ door_position]
    │
    ├─ 玩家开门? ─→ [ENTER]
    │                └─ 3秒倒计时
    │                   ├─ 玩家背身靠墙? ─→ [PATROL]
    │                   └─ 时间到 ─→ [ATTACK]
    │
    └─ 10秒未开门? ─→ [BREAK_DOOR]
                       └─ [ENTER] → [ATTACK]

[PATROL]
    └─ 走廊随机巡逻
       ├─ 看到玩家? ─→ [CHASE] → [ATTACK]
       └─ 听感噪音? ─→ [ALERT] (移动到噪音源)
```

**继承关系：**

```
BaseMonster (game/monster/BaseMonster.gd)
    └── NurseAI (game/correction/enemies/NurseAI.gd)  [新建]
```

**关键参数：**

```gdscript
@export var wait_time_before_attack: float = 3.0  # 3秒缓冲
@export var break_door_time: float = 10.0           # 10秒破门
@export var attack_damage: float = 2.0              # 高伤害（2击致命）
@export var chase_range: float = 150.0
@export var patrol_radius: float = 200.0
```

**与 BaseMonster 的差异：**
- 不直接追踪 `Utils.player`（初始无目标，由行为树分配）
- 额外的 `door_reference` 属性（指向要破的门）
- `state` 改用 enum 而非 `state_array`

---

### E) 搜刮 → 升级

**方案：** 复用 LootServer + 新建 LevelUpSystem

**升级系统设计：**

```
PlayerData 新增字段:
├── player_upgrades: Dictionary  # 已获得的升级
│   ├── "speed_boost": int       # 移速强化等级
│   ├── "vision_range": int      # 视野/检测范围
│   ├── "stealth_silence": bool  # 脚步声降低
│   └── "health_regen": bool     # 缓慢回血
└── onPlayerUpgradeRequest(upgrade_id)  # 新信号
```

**升级方式：**

| 来源 | 说明 | 接口 |
|------|------|------|
| 经验升级（自动） | 每级获得 1 个 `reward_point`，可选能力 | `PlayerData.player_exp` 现有体系 |
| 关键道具拾取 | 如"治疗区通行证"直接解锁新能力 | `LootServer.add_loot()` + 检查 |
| 解谜奖励 | 电力房间给"武器升级材料" | 特殊 ConsumablePickup |
| 武器升级 | 拾取更高级武器替换现有 | 现有 `add_weapon` 体系 |

**升级界面：**

新建 `game/correction/ui/LevelUpPanel.gd`（CanvasLayer 弹窗）：

```
┌─────────────────────────┐
│   升级！选择一项增强      │
├─────────────────────────┤
│ [ ] 移速+10%            │
│ [ ] 最大HP+1            │
│ [ ] 脚步声降低           │
│ [ ] 伤害+15%            │
├─────────────────────────┤
│       [确认]            │
└─────────────────────────┘
```

在 `PlayerData.onPlayerLevelChange` 中弹出此面板（暂停游戏）。

**与 LootServer 的关系：** LootServer 管理"物品战利品"（可带出/换金子），升级系统管理"能力战利品"（跟随本局）。两者独立但触发来源重叠（都是从地图拾取）。

---

### F) 节点门禁

**方案：** 扩展现有 `ZoneTrigger`，新建 `ConditionalGate` 子类

**现有能力（ZoneTrigger）：**
- `required_item` → 需要背包有特定物品
- 单向通过开关

**V2 新增能力（ConditionalGate 扩展）：**

```gdscript
class_name ConditionalGate
extends ZoneTrigger

enum UnlockCondition {
    ITEM,           # 持有物品 (现有)
    BOSS_KILLED,    # 击杀特定Boss
    PLAYER_LEVEL,   # 玩家等级
    PUZZLE_SOLVED,  # 解谜完成
    TIME_SURVIVED,  # 存活时间
    COMBO           # 组合条件
}

@export var unlock_condition: UnlockCondition = UnlockCondition.ITEM
@export var boss_id: String = ""           # 用于 BOSS_KILLED
@export var required_level: int = 1        # 用于 PLAYER_LEVEL
@export var puzzle_id: String = ""         # 用于 PUZZLE_SOLVED
@export var required_time: float = 0.0     # 用于 TIME_SURVIVED
@export var conditions: Array[Dictionary]  # 用于 COMBO

func check_unlock() -> bool:
    match unlock_condition:
        UnlockCondition.BOSS_KILLED:
            return _check_boss_killed()
        UnlockCondition.PLAYER_LEVEL:
            return PlayerData.player_level >= required_level
        UnlockCondition.PUZZLE_SOLVED:
            return _check_puzzle_solved()
        UnlockCondition.TIME_SURVIVED:
            return _get_time_survived() >= required_time
        UnlockCondition.COMBO:
            return _check_all_conditions()
    
    # fallback to ZoneTrigger behavior
    return super.check_unlock()  # ITEM check
```

**Boss 击杀追踪：**  
在 `CorrectionGameManager` 中维护 `var bosses_killed: Array[String]`，Boss 死亡时 push。

**解谜完成追踪：**  
`BasePuzzle` 基类 emit `puzzle_solved(puzzle_id: String)` → `CorrectionGameManager` 或 Autoload 记录。

---

## 3. 新旧系统映射

| 新需求 | 旧系统 | 操作 | 说明 |
|--------|--------|------|------|
| 开门选择交互 | 无 | **新建** `DoorInteraction` | Area2D + UI 弹窗 |
| 背身靠墙检测 | 无 | **新建** `BackWallDetector` | Area2D 检查朝向+法线+静止 |
| 潜行系统（视觉） | `AlertServer`（仅声音） | **新建** `StealthServer` | 新增视觉通道，委托声音给 AlertServer |
| 蹲伏/慢走 | `Hero.gd` Input | **改造** Player | 新增 crouch input，速度调整 |
| 护士AI | `BaseMonster` | **新建** `NurseAI` | 继承 BaseMonster，含破门逻辑 |
| 病房开门时序 | 无 | **新建** `IntroSequenceController` | 阶段1专用 |
| 安全屋 | 无 | **新建** `SafeRoom` Area2D | 理智回升+警戒衰减加速 |
| N敌人击杀限制 | 无 | **新建** `KillLimitSystem` | 超限触发封锁 |
| 升级选择界面 | `PlayerData.reward_point` | **新建** `LevelUpPanel` | 升级时弹出选择面板 |
| 玩家升级属性 | `PlayerData.player_damage/speed/hp_max` | **改造** 扩展属性 | 新增 upgrades 字典 |
| 节点门禁（多条件） | `ZoneTrigger`（仅物品） | **扩展** `ConditionalGate` | 新增条件类型 |
| Boss击杀追踪 | `CorrectionGameManager.run_stats` | **改造** 新增记录 | bosses_killed 数组 |
| 解谜系统 | 无 | **新建** `BasePuzzle` | 基类，可扩展 |
| 电力解谜房 | 无 | **新建** `PuzzleElectroRoom` | 继承 BasePuzzle |
| 档案解谜 | 无 | **新建** `PuzzleArchiveSort` | 继承 BasePuzzle |
| Boss演出系统 | `TreatmentDirector`（无演出） | **新建** `BossIntroSequence` | 镜头动画+对话+阶段转场 |
| WardDirector Boss | `BaseMonster` | **新建** `WardDirector` | 3阶段技能 |
| 约束主管 Boss | `BaseMonster` | **新建** `RestraintChief` | 2阶段技能 |
| 院长最终Boss | `BaseMonster` | **新建** `FacilityDirector` | 3阶段+演出 |
| 走廊捷径 | `ZoneTrigger.one_way` | **复用/改造** | 控制单向+解锁条件 |
| 手枪拾取 | `PlayerData.add_weapon()` | **复用** | 现有武器系统 |
| 叙事收集进度 | `LootServer.extracted_loot` | **新建** UI | 结算时显示 |
| 潜行仓库升级 | `WarehouseUpgradeUI` | **扩展** | 新增潜行类升级项 |
| HUD改造 | `CorrectionHUD` | **改造** | 新增蹲伏指示器、击杀计数 |
| 阶段管理 | `CorrectionGameManager` | **改造** | 新增 V2 GamePhase |

---

## 4. P0/P1/P2 分级

### P0：核心循环阻塞 — 必须先交付

| # | 系统 | 原因 |
|---|------|------|
| P0-1 | **DoorInteraction** | 阶段1入口，无此无法开始 |
| P0-2 | **BackWallDetector** | 阶段1核心交互 |
| P0-3 | **NurseAI** | 阶段1核心敌人 |
| P0-4 | **IntroSequenceController** | 阶段1时序逻辑 |
| P0-5 | **StealthServer（视觉通道）** | 阶段2-5潜行基础 |
| P0-6 | **蹲伏/慢走（Player改造）** | 潜行玩法基础操作 |
| P0-7 | **条件门禁（ConditionalGate）** | 控制探索流程的核心 |
| P0-8 | **WardDirector Boss** | 阶段3核心内容 |
| P0-9 | **FacilityDirector 最终Boss** | 阶段6核心内容 |
| P0-10 | **阶段1病房场景（TileMap+物件）** | 开局体验 |

### P1：增强体验 — 第二批

| # | 系统 | 原因 |
|---|------|------|
| P1-1 | **LevelUpPanel + 升级属性扩展** | 成长正反馈，让搜刮有意义 |
| P1-2 | **安全屋（SafeRoom）** | 压力释放点，改善节奏 |
| P1-3 | **KillLimitSystem** | 限制暴力通关，鼓励潜行 |
| P1-4 | **Boss演出系统（BossIntroSequence）** | Boss战仪式感 |
| P1-5 | **RestraintChief 小Boss** | 阶段5内容密度 |
| P1-6 | **走廊TileMap + 正式地图** | 替代 V1 ColorRect |
| P1-7 | **电力解谜/档案解谜** | 探索趣味性 |
| P1-8 | **Handgun拾取（手枪）** | 阶段4装备升级 |
| P1-9 | **仓库潜行升级项** | 跨局成长 |
| P1-10 | **捷径系统完善** | 地图设计 |

### P2：锦上添花 — 第三批

| # | 系统 | 原因 |
|---|------|------|
| P2-1 | **Boss阶段视觉变化** | 动画/特效/外观变化 |
| P2-2 | **叙事收集进度UI** | 结算时展示探索百分比 |
| P2-3 | **档案室交互叙事物件** | 环境叙事 |
| P2-4 | **环境事件（随机出现）** | 增加重复可玩性 |
| P2-5 | **院长战斗演出细化** | 慢镜头/粒子/屏幕效果 |
| P2-6 | **存档持久化（跨会话）** | 仓库升级状态保存 |

---

## 5. 待确认问题

### Q1: 阶段1是否只有一个"正确"互动方案？

当前设计：开门→背身靠墙是正确方案，不开门→10秒破门→死亡。

**备选方案：** 是否提供其他逃脱方式？如：
- 躲到床底下（需要蹲伏+静止）
- 翻窗逃跑（跳到另一个区域，但损失部分新手引导物资）

### Q2: "最多击杀 N 个敌人"的 N 值？

文档写 N=3，但需要进一步考虑：
- 是否不同区域有不同的击杀上限？
- 击杀 Boss 是否计入？
- 无人机被干扰/击落是否计入？

**建议：** 仅普通巡逻员计入，Boss 和无人机不计入。N 值可在 RuleServer 中按区域配置。

### Q3: 手枪弹药设计？

手枪作为阶段 4 的首把枪，建议：
- 初始 10 发弹药，无法制造/购买额外弹药
- 击杀特定敌人（如 SedationEnforcer）低概率掉落弹药
- 手枪不可带出本局（提取条件：`can_extract=false`）

**备选：** 是否设计"弹药制造台"作为安全屋功能？

### Q4: 护士的角色定位？

设计文档中护士只在阶段1出现。是否考虑后续区域让她再次出现（呼应剧情）？或者护士击败/躲避后就永久消失？

### Q5: 阶段顺序是否强制？

文档描述为线性（阶段1→2→3→4→5→6），但走廊探索（阶段2）和后续探索（阶段4、5）本质上是否可以有一定非线性？例如：
- 阶段2可以分叉：先去安全屋/先去Boss门
- 阶段4和阶段5之间可以有可选的偏厅探索

**建议：** 阶段1固定，阶段2-5在门禁解锁后可以有分支路径，但总体推进方向固定。

### Q6: 使用现有 GYM_15 基础设施还是全新场景？

V1 的 GYM_15 使用 ColorRect 抽象地图。V2 需要改用 TileMap。但 V1 的脚本化初始化模式（`_ready()` 中动态实例化所有内容）值得保留。

**建议：** 新建 `demo/GYM_16_CorrectionCenterV2.tscn`，使用 TileMap 地图，但保持脚本化初始化的灵活性。

---

## 附录 A: V2 文件规划

```
game/correction/
├── enemies/
│   ├── NurseAI.gd              [新建] 护士AI
│   ├── WardDirector.gd         [新建] 病房主任Boss
│   ├── RestraintChief.gd       [新建] 约束主管小Boss
│   └── FacilityDirector.gd     [新建] 院长最终Boss
├── interaction/
│   ├── DoorInteraction.gd      [新建] 开门选择
│   └── BackWallDetector.gd     [新建] 背身靠墙检测
├── puzzles/
│   ├── BasePuzzle.gd           [新建] 解谜基类
│   ├── ElectroPuzzle.gd        [新建] 电力解谜
│   └── ArchivePuzzle.gd        [新建] 档案解谜
├── zones/
│   ├── ConditionalGate.gd      [新建] 条件门禁
│   ├── SafeRoom.gd             [新建] 安全屋
│   └── Shortcut.gd             [新建] 单向捷径
├── ui/
│   ├── LevelUpPanel.gd         [新建] 升级选择
│   ├── DoorDialog.gd           [新建] 开门弹窗
│   ├── BossIntroUI.gd          [新建] Boss演出UI
│   └── StealthIndicator.gd     [新建] 潜行状态指示
└── sequences/
    ├── IntroSequenceController.gd [新建] 阶段1控制器
    └── BossIntroSequence.gd       [新建] Boss演出控制
autoload/
└── server/
    └── StealthServer.gd        [新建] 潜行服务器
```

---

## 附录 B: 系统依赖图 (V2)

```
GYM_16_CorrectionCenterV2Starter
  ├── PlayerServer (获取玩家)
  ├── StealthServer.initialize()      [新增] 潜行系统
  ├── AlertServer.initialize()        [复用] 警戒系统
  ├── ExtractionServer.reset()        [复用] 撤离系统
  ├── SanityServer.reset_sanity()     [复用] 理智系统
  ├── IntroSequenceController         [新增] 阶段1
  ├── 动态实例化:
  │   ├── DoorInteraction × 3        [新增]
  │   ├── ConditionGate × N           [新增]
  │   ├── SafeRoom × 2               [新增]
  │   ├── BackWallDetector × 2       [新增]
  │   ├── NurseAI × 1                [新增]
  │   ├── WardDirector × 1           [新增]
  │   ├── RestraintChief × 1         [新增]
  │   ├── FacilityDirector × 1       [新增]
  │   ├── PatrolGuard × N            [复用]
  │   ├── SedationEnforcer × N       [复用]
  │   ├── SurveillanceDrone × N      [复用]
  │   ├── ConsumablePickup × N       [复用]
  │   ├── ThrowablePickup × N        [复用]
  │   ├── MeleeWeaponPickup × N      [复用]
  │   ├── NarrativeLootItem × N      [复用]
  │   ├── KeyCardPickup × N          [复用]
  │   └── ExtractionPoint × 1        [复用]
  ├── CorrectionHUD (改造)            [复用+改造]
  ├── LevelUpPanel                    [新增]
  ├── EventBus 信号连接
  └── Utils.gameStart()
```
