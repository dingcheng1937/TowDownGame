# 精神矫正中心 MVP 增量 PRD

> 作者：许清楚（产品经理）
> 日期：2025-07-15
> 状态：增量审计 — 已有大量实现，本文档聚焦差距分析

---

## 0. 审计结论（TL;DR）

**现状：MVP 的核心代码已超出预期完成。** `game/correction/` 目录下已有完整的敌人、物品、UI、Boss、仓库系统，`demo/GYM_15_CorrectionCenter.tscn` 可 F6 独立运行验证完整循环。

本 PRD 的核心任务不是"从零设计"，而是**审计现有实现 vs MVP 需求，标注差距和风险**。

---

## 1. 现有功能 → MVP 需求映射表

### 1.1 核心系统

| MVP 需求 | 现有系统 | 复用方式 | 是否需要新增 |
|----------|---------|---------|------------|
| 警戒值系统（噪音规则） | `autoload/AlertServer.gd` | **直接复用**。已有 NOISE_RUNNING(5)/MELEE_ATTACK(15)/THROW(10) 常量，4级阈值，衰减速率 3/秒 | ❌ 不需要 |
| 警戒值+冲刺挂钩 | `GYM_15` Starter `_input()` 已调用 `AlertServer.add_noise(NOISE_RUNNING, "dash")` | 已在 Starter 中处理 | ❌ 不需要 |
| 警戒值+近战攻击挂钩 | `GYM_15` Starter `_input()` 已调用 `AlertServer.add_melee_attack_noise()` | 已在 Starter 中处理 | ❌ 不需要 |
| 警戒值+投掷挂钩 | `ThrowableItem.throw_in_dir()` 内部调用 `AlertServer.add_noise(noise_amount, "throw")` | 弹体自身触发 | ❌ 不需要 |
| 撤离系统（条件+倒计时） | `autoload/server/ExtractionServer.gd` | **直接复用**。set_conditions(0, ["主任钥匙卡"], 0, 5.0) | ❌ 不需要 |
| 撤离点 | `game/extraction/ExtractionPoint.gd` | **直接复用** | ❌ 不需要 |
| 理智系统 | `autoload/server/SanityServer.gd` | **直接复用**。passive_drain=0.5/秒 | ❌ 不需要 |
| 战利品背包 | `autoload/server/LootServer.gd` | **直接复用**。12格上限，add/extract/has_item | ❌ 不需要 |
| 玩家移动/战斗 | `game/hero/Hero.gd`（Player类） | **直接复用** | ❌ 不需要 |
| 玩家数据 | `autoload/PlayerData.gd` | **直接复用** | ❌ 不需要 |
| 全局事件总线 | `autoload/EventBus.gd` | **直接复用** | ❌ 不需要 |

### 1.2 敌人

| MVP 需求 | 现有系统 | 复用方式 | 是否需要新增 |
|----------|---------|---------|------------|
| 巡逻员（巡逻+追击） | `game/correction/enemies/PatrolGuard.gd` | **已完成**。extend BaseMonster，巡逻（随机方向3秒切换）+ 追击（chase_range=200）+ 近战攻击 | ❌ 不需要 |
| 镇静执行者（追击+减速） | `game/correction/enemies/SedationEnforcer.gd` | **已完成**。chase_range=250，攻击后 player_speed -= 0.3 持续3秒 | ❌ 不需要 |
| 监察无人机（侦查+呼叫支援） | `game/correction/enemies/SurveillanceDrone.gd` | **已完成**。圆周巡逻，detection_range=250，2秒后呼叫2个PatrolGuard + 增加AlertServer警戒值20 | ❌ 不需要 |
| Boss：治疗主任（3阶段3技能） | `game/correction/boss/TreatmentDirector.gd` | **已完成**。HP阈值分阶段(P1>60%>P2>30%>P3)，技能：镇静针/约束带/呼叫支援，掉落KeyCardPickup | ❌ 不需要 |
| 敌人死亡 → ExtractionServer.register_kill() | `CorrectionGameManager._on_enemy_killed()` | **已完成** | ❌ 不需要 |
| Boss死亡 → EventBus.boss_defeated | `TreatmentDirector.onDie()` | **已完成** | ❌ 不需要 |

### 1.3 物品

| MVP 需求 | 现有系统 | 复用方式 | 是否需要新增 |
|----------|---------|---------|------------|
| 近战武器：木制椅腿 | `game/melee/WoodenChairLeg.gd` | **已有。** damage=15, durability=30, range=70 | ❌ 不需要 |
| 近战武器：输液架 | `game/melee/IVStand.gd` | **已有。** 低伤害/高耐久/大范围 | ❌ 不需要 |
| 近战武器：约束带 | `game/melee/RestraintStrap.gd` | **已有。** 束缚敌人2秒 | ❌ 不需要 |
| 近战武器：电击棒 | `game/melee/Taser.gd` | **已有。** damage=35, durability=120, shock(眩晕) | ❌ 不需要 |
| 投掷物：石子 | `game/correction/items/ThrowableItem.gd` STONE | **已完成。** damage=0, lure_enemies=true, noise=5 | ❌ 不需要 |
| 投掷物：药瓶 | `game/correction/items/ThrowableItem.gd` MEDICINE_BOTTLE | **已完成。** damage=5, noise=15 | ❌ 不需要 |
| 投掷物：餐盘 | `game/correction/items/ThrowableItem.gd` PLATE | **已完成。** damage=3, knockback=200, noise=10 | ❌ 不需要 |
| 投掷物地面拾取 | `game/correction/items/ThrowablePickup.gd` | **已完成。** E键拾取，存储到 PlayerData meta | ❌ 不需要 |
| 消耗品：白色药片 | `game/correction/items/ConsumablePickup.gd` | **已完成。** heal=2, 已配置在GYM_15 | ❌ 不需要 |
| 消耗品：蓝色药片 | 同上 | **已完成。** heal=3, sanity=5, speed_mod=-0.2 | ❌ 不需要 |
| 消耗品：镇静剂 | 同上 | **已完成。** heal=5, sanity=10, speed_mod=-0.3 | ❌ 不需要 |
| 消耗品：冷馒头 | 同上 | **已完成。** heal=1 | ❌ 不需要 |
| 叙事战利品：全家福/出院申请/举报信/销毁名单/奖状 | `game/correction/items/NarrativeLootItem.gd` | **已完成。** extend BaseLoot, EPIC rarity, can_extract=true, value=50 | ❌ 不需要 |
| 主任钥匙卡 | `game/correction/items/KeyCardPickup.gd` | **已完成。** LEGENDARY, value=200, 触发ExtractionServer条件检查 | ❌ 不需要 |

### 1.4 区域与UI

| MVP 需求 | 现有系统 | 复用方式 | 是否需要新增 |
|----------|---------|---------|------------|
| 4区域切换触发器 | `game/correction/zones/ZoneTrigger.gd` | **已完成。** 进入触发EventBus.zone_entered，支持required_item门禁 | ❌ 不需要 |
| 区域叙事提示 | ZoneTrigger.narrative_hint_id/text | **已完成。** 每个门有独立叙事文本 | ❌ 不需要 |
| HUD（警戒条/血量/撤离状态/战利品列表） | `game/correction/ui/CorrectionHUD.gd` | **已完成。** 连接AlertServer/ExtractionServer/LootServer/PlayerData/EventBus | ❌ 不需要 |
| 仓库升级界面 | `game/correction/warehouse/WarehouseUpgradeUI.gd` | **已完成。** 3项升级（仓库容量/初始医疗包/石子携带量），gold消费 | ❌ 不需要 |

### 1.5 GYM 场景

| MVP 需求 | 现有系统 | 复用方式 | 是否需要新增 |
|----------|---------|---------|------------|
| GYM_15 完整Demo场景 | `demo/GYM_15_CorrectionCenter.tscn` + `.gd` | **已存在。** 可F6独立运行，包含4区域+物品摆放+敌人+Boss+撤离点 | ❌ 不需要 |
| 游戏主循环管理器 | `game/correction/CorrectionGameManager.gd` | **已完成。** 6阶段状态机，死亡/撤离/仓库流程 | ❌ 不需要 |

---

## 2. 新增功能列表（差距分析）

### P0: 核心循环必需 — 阻塞发布

| # | 问题 | 描述 | 建议方案 |
|---|------|------|---------|
| P0-1 | **近战武器未在GYM_15中装备给玩家** | GYM_15 Starter 没有将椅腿/输液架等近战武器实例化并装备到 Player。玩家在GYM_15中按V无法攻击。参考 GYM_12_MeleeStarter 的模式：`weapon.instantiate() → gun_root.add_child() → setOwner() → set_use(true)` | 在 GYM_15 `_ready()` 末尾添加 `_equip_starting_weapon()` 方法，实例化 WoodenChairLeg 并装备 |
| P0-2 | **近战武器拾取物（地面掉落）不存在** | BaseLoot 子类可以拾取近战武器放到背包，但目前没有 MeleeWeaponPickup 类。当前近战武器只能通过代码 `add_child` 方式装备，无法作为战利品拾取。 | 创建 `MeleeWeaponPickup`（extend BaseLoot），拾取时实例化对应武器并装备到 Player |

### P1: 增强体验

| # | 问题 | 描述 | 建议方案 |
|---|------|------|---------|
| P1-1 | **投掷物存储用 PlayerData.meta 而非 LootServer** | 石子/药瓶/餐盘存储在 `PlayerData.get_meta("stone_count")`，不经过 LootServer，不显示在战利品UI中。设计意图合理（它们是"弹药"不是"战利品"），但缺乏UI反馈 | CorrectionHUD 增加投掷物余量显示（石子图标+数字） |
| P1-2 | **IVStand / RestraintStrap 未在 GYM_15 中使用** | 虽然近战武器代码已写好，但 GYM_15 场景中未放置输液架和约束带。玩家只能靠代码切换获取。 | 在治疗区放置 IVStand 地面拾取物；在病房区放置 RestraintStrap |
| P1-3 | **GYM_15 使用 ColorRect 抽象地图，非正式地图** | 当前 GYM_15 用 4 个 ColorRect（400×400）表示4个区域。MVP设计文档提到使用 `game/map/mapTown/Town.tscn` | 两种方案：(a) 保持GYM抽象风格用于验证，另建 Production 场景使用Town地图；(b) 在GYM中直接替换为TileMap |
| P1-4 | **PatrolGuard 警戒值联动不完整** | 巡逻员的警戒值触发（AlertServer 阈值突破 → 刷新额外敌人）逻辑未在 GYM_15 中实现。AlertServer 发出 `alert_threshold_crossed` 信号但无人监听并生成敌人 | 在 GYM_15 Starter 或 CorrectionGameManager 中监听 `AlertServer.alert_threshold_crossed`，按阈值生成额外敌人 |
| P1-5 | **理智系统视觉效果未接入** | SanityServer 已运行但无视觉反馈（屏幕效果、滤镜等）。GYM_11 有 AtmosphereController 参考 | 在 CorrectionGameManager 中实例化 AtmosphereController 并根据 sanity 状态调整 |

### P2: 锦上添花

| # | 问题 | 描述 | 建议方案 |
|---|------|------|---------|
| P2-1 | **仓库升级状态跨会话不持久** | WarehouseUpgradeUI 用 PlayerData.meta 存储，但 meta 在游戏重启后清空 | 接入存档系统或使用 PlayerData 的持久化字段 |
| P2-2 | **Boss 3阶段缺乏视觉变化** | TreatmentDirector 阶段切换仅改变技能池，无外观/特效变化 | 添加阶段过渡动画 |
| P2-3 | **冷馒头无特殊效果** | heal=1，无其他效果。可加微小 sanity 恢复或速度 buff | 数值调整 |
| P2-4 | **Boss房间缺乏场景叙事** | 行政区目前只有 ColorRect 地板 | 添加环境叙事物件（办公桌、档案柜、散落的文件） |

---

## 3. GYM_15 场景设计

### 3.1 当前结构

```
GYM_15_CorrectionCenter (Node2D) [script: GYM_15_CorrectionCenterStarter.gd]
├── World (Node2D)
│   ├── WardArea (Node2D) @ (-400, 0)
│   │   ├── WardFloor (ColorRect) 400×400
│   │   └── WardLabel: "🏥 病房区"
│   ├── LivingArea (Node2D) @ (0, 0)
│   │   ├── LivingFloor (ColorRect) 400×400
│   │   └── LivingLabel: "🍽 生活区"
│   ├── TreatmentArea (Node2D) @ (400, 0)
│   │   ├── TreatmentFloor (ColorRect) 400×400
│   │   └── TreatmentLabel: "💉 治疗区"
│   └── AdminArea (Node2D) @ (800, 0)
│       ├── AdminFloor (ColorRect) 400×400
│       └── AdminLabel: "🏛 行政区"
```

物品、敌人、Boss、撤离点、ZoneTrigger 全部由 `_ready()` 中的脚本动态实例化。

### 3.2 评价

- ✅ **优势**：纯代码驱动，无场景依赖，F6即跑，适合快速迭代
- ⚠️ **不足**：纯 ColorRect 视觉简陋，无碰撞/墙壁，玩家可自由穿越区域
- ✅ **角色**：作为 GYM 验证场景完全合格

### 3.3 是否需要全新构建？

**不需要。** GYM_15 作为 MVP 验证场景已经足够。建议：

1. **MVP 阶段**：继续用 GYM_15，补齐 P0/P1 差距项
2. **Alpha 阶段**：基于 `game/map/mapTown/Town.tscn` 新建 `CorrectionCenterMap.tscn`，将 GYM_15 的初始化逻辑迁移到正式地图的脚本中

---

## 4. 待确认问题

### Q1: 近战武器获取方式
当前设计：玩家在 GYM_15 中应该从哪里获得近战武器？是出生自带椅腿，还是需要在地面拾取？

**建议**：出生自带木制椅腿（病房醒来叙事），其他近战武器在后续区域地面拾取。需创建 MeleeWeaponPickup 类（P0-2）。

### Q2: 警戒值触发额外敌人的具体规则
AlertServer 阈值突破 → 生成多少敌人？生成位置？生成什么类型？

| 阈值 | 触发 | 建议生成 |
|------|------|---------|
| WATCHFUL (30) | 巡逻员警觉 | 在当前区域边缘生成 1 个 PatrolGuard |
| ALARM (60) | 无人机巡逻 | 生成 1 个 SurveillanceDrone |
| LOCKDOWN (80) | 封锁 | 生成 2 个 PatrolGuard + 1 个 SedationEnforcer |

**建议**：此逻辑写在 GYM_15 Starter 或 CorrectionGameManager 中，监听 `AlertServer.alert_threshold_crossed`。

### Q3: 消耗品是在地图上直接使用还是拾取到背包？
当前实现：ConsumablePickup 拾取即用（heal/sanity/speed_mod 立即生效），不进入 LootServer 背包。

**确认**：这是否符合设计意图？还是应该"拾取到背包，玩家自行决定何时使用"？

**建议**：MVP 阶段保持"拾取即用"，简化交互。Alpha 阶段可改为背包+使用。

### Q4: 6阶段Demo流程是否需要在代码中显式体现？
当前 GYM_15 是无引导的自由探索，6阶段流程（病房→生活区→治疗区→行政区→Boss→撤离）通过地图布局自然引导，无强制顺序。

**确认**：MVP是否需要强制阶段锁（如"必须先击杀生活区巡逻员才能进入治疗区"）？

**建议**：MVP 阶段不做阶段锁，保持自由探索。ZoneTrigger 已支持 `required_item` 参数，后续可配置门禁。

### Q5: 撤离条件确认
当前 GYM_15 中 ExtractionServer.set_conditions(0.0, ["主任钥匙卡"], 0, 5.0)：
- 无最少时间限制
- 需要持有"主任钥匙卡"
- 无击杀数要求
- 5秒倒计时

**确认**：这是否正确？MVP文档提到"获得钥匙卡→立即撤离 vs 继续搜索"的抉择，当前设计支持（钥匙卡获得后撤离点激活，玩家可自行决定何时触发撤离）。

### Q6: PlayerServer 依赖
GYM_15 通过 `PlayerServer.player_scene` 获取玩家引用，如果 `PlayerServer` 未初始化（F6 独立运行且 PlayerServer 未在场景中），代码 fallback 到 `HERO_SCENE.instantiate()`。

**确认**：此 fallback 路径是否经过测试？建议在 GYM_15 启动时确保 PlayerServer 可用。

---

## 5. 实施建议

### Phase 1: 修补 P0（1-2天）
1. 在 GYM_15 Starter 中添加 `_equip_starting_weapon()` 装备木制椅腿
2. 创建 MeleeWeaponPickup 类
3. 验证完整循环（病房醒来→拾取物品→战斗→Boss→撤离→仓库）

### Phase 2: 补齐 P1（2-3天）
1. 监听 AlertServer 阈值信号生成额外敌人
2. HUD 增加投掷物余量
3. 在治疗区/病房区放置 IVStand/RestraintStrap 拾取物
4. 接入 AtmosphereController

### Phase 3: 打磨 P2（按需）
1. Boss 阶段视觉
2. 环境叙事物件
3. 存档持久化

---

## 附录 A: 关键文件索引

| 类别 | 路径 | 说明 |
|------|------|------|
| 玩家 | `game/hero/Hero.gd` | Player 类 |
| 怪物基类 | `game/monster/BaseMonster.gd` | 所有敌人继承此 |
| 战利品基类 | `game/loot/BaseLoot.gd` | 所有拾取物继承此 |
| 近战武器基类 | `game/melee/BaseMeleeWeapon.gd` | 所有近战武器继承此 |
| 警戒系统 | `autoload/AlertServer.gd` | 全局警戒值 |
| 撤离系统 | `autoload/server/ExtractionServer.gd` | 撤离条件+倒计时 |
| 理智系统 | `autoload/server/SanityServer.gd` | 理智值管理 |
| 战利品背包 | `autoload/server/LootServer.gd` | 背包管理 |
| 事件总线 | `autoload/EventBus.gd` | 跨场景信号 |
| 玩家数据 | `autoload/PlayerData.gd` | HP/Gold/Speed等 |
| 玩家管理 | `autoload/server/PlayerServer.gd` | PlayerScene管理 |
| 工具 | `autoload/Utils.gd` | showToast/showHitLabel/freezeFrame |
| GYM_15 场景 | `demo/GYM_15_CorrectionCenter.tscn` | F6 独立运行 |
| GYM_15 脚本 | `demo/GYM_15_CorrectionCenterStarter.gd` | 初始化逻辑 |
| 游戏管理器 | `game/correction/CorrectionGameManager.gd` | 主循环状态机 |

## 附录 B: 系统依赖图

```
GYM_15_CorrectionCenterStarter
  ├── PlayerServer (获取玩家)
  ├── AlertServer.initialize() → 警戒系统
  ├── ExtractionServer.reset() + set_conditions() → 撤离系统
  ├── SanityServer.reset_sanity() → 理智系统
  ├── 动态实例化:
  │   ├── ConsumablePickup × N
  │   ├── ThrowablePickup × N
  │   ├── NarrativeLootItem × N
  │   ├── PatrolGuard × N
  │   ├── SedationEnforcer × 1
  │   ├── SurveillanceDrone × 1
  │   ├── TreatmentDirector (Boss) × 1
  │   ├── ExtractionPoint × 1
  │   └── ZoneTrigger × 3
  ├── CorrectionHUD (CanvasLayer)
  ├── EventBus 信号连接
  └── Utils.gameStart()
```
