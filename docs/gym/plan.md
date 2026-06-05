# 游戏模块 GYM 拆分计划

按照 `GYM_01_Movement` 的原则，为每个主要模块创建独立的验证GYM。

---

## 模块列表

### 游戏核心模块

#### 1. 玩家移动 ✅
**文件:** `demo/GYM_01_Movement.tscn`
**功能:** 移动、冲刺、相机系统
**状态:** 已完成

#### 2. 武器系统 ✅
**文件:** `demo/GYM_02_Weapon.tscn`
**核心类:** `game/guns/BaseGun.gd`
**状态:** 已完成

#### 3. 怪物系统 ✅
**文件:** `demo/GYM_03_Monster.tscn`
**核心类:** `game/monster/BaseMonster.gd`
**状态:** 已完成

#### 4. 物品系统 ✅
**文件:** `demo/GYM_04_Item.tscn`
**核心类:** `game/items/BaseItem.gd`
**状态:** 已完成

#### 5. 装备系统 ✅
**文件:** `demo/GYM_05_Equip.tscn`
**核心类:** `game/equip/BaseEquip.gd`
**状态:** 已完成

#### 6. 附件系统 ✅
**文件:** `demo/GYM_06_Attachment.tscn`
**核心类:** `game/attachments/` 目录
**状态:** 已完成

#### 7. 诡异搜打撤系统 ✅
**文件:** `demo/GYM_11_WeirdLoot.tscn`
**核心类:** `autoload/server/SanityServer.gd`, `ExtractionServer.gd`, `LootServer.gd`
**验证点:**
- 理智系统（SanityServer）
- 撤离点机制（ExtractionServer）
- 掉落物拾取（LootServer）
- 诡异怪物（Shade, Whisperer, Aberration）
**状态:** 已完成

---

### UI模块

#### 8. 准星UI ✅
**文件:** `demo/GYM_07_Crosshair.tscn`
**核心类:** `ui/widgets/Crosshair.tscn`
**验证点:**
- 准星动画效果
- 准星跟随鼠标
- 射击时准星扩散

#### 9. 伤害数字UI ✅
**文件:** `demo/GYM_08_HitLabel.tscn`
**核心类:** `ui/widgets/HitLabel.tscn`
**验证点:**
- 伤害数字显示
- 数字飘动效果
- 不同颜色区分伤害类型

#### 10. 近战武器系统 ✅
**文件:** `demo/GYM_12_Melee.tscn`
**核心类:** `game/weapons/melee/` 目录
**验证点:**
- 近战攻击动画
- 武器耐久度
- 武器切换
- 武器损坏机制
**状态:** 已完成

#### 11. 武器列表UI ✅
**文件:** `demo/GYM_09_WeaponList.tscn`
**核心类:** `ui/widgets/WeaponListItem.tscn`
**验证点:**
- 武器列表显示
- 武器切换
- 子弹数量显示

#### 12. 背包UI ✅
**文件:** `demo/GYM_10_Inventory.tscn`
**核心类:** `ui/Inventory.tscn`
**验证点:**
- 背包打开/关闭
- 物品格子显示
- 物品拖拽

#### 13. 商店UI ⏳
**计划文件:** `demo/GYM_13_Shop.tscn`
**核心类:** `ui/widgets/ShopPanel.tscn`
**验证点:**
- 商店界面显示
- 购买交互
- 金币扣除

#### 14. 奖励选择UI ⏳
**计划文件:** `demo/GYM_14_Reward.tscn`
**核心类:** `ui/widgets/RewardChoose.tscn`
**验证点:**
- 升级奖励界面
- 奖励选择
- 技能获取

#### 15. 计分板UI ⏳
**计划文件:** `demo/GYM_15_Scoreboard.tscn`
**核心类:** `ui/widgets/Scoreboard.tscn`
**验证点:**
- 分数显示
- 时间显示
- 统计数据

#### 16. 死亡界面UI ⏳
**计划文件:** `demo/GYM_16_Death.tscn`
**核心类:** `ui/widgets/DeathBoard.tscn`
**验证点:**
- 死亡界面显示
- 重试按钮
- 统计显示

---

## 实现优先级

### 高优先级（核心功能）- 已完成 ✅
1. ✅ GYM_01_Movement - 玩家移动
2. ✅ GYM_02_Weapon - 武器系统
3. ✅ GYM_03_Monster - 怪物系统
4. ✅ GYM_04_Item - 物品系统

### 中优先级（UI核心）- 已完成 ✅
5. ✅ GYM_07_Crosshair - 准星UI
6. ✅ GYM_08_HitLabel - 伤害数字UI
7. ✅ GYM_09_WeaponList - 武器列表UI
8. ✅ GYM_10_Inventory - 背包UI

### 扩展功能 - 已完成 ✅
9. ✅ GYM_05_Equip - 装备系统
10. ✅ GYM_06_Attachment - 附件系统

### 待完成 ⏳
11. ⏳ GYM_13_Shop - 商店UI
12. ⏳ GYM_14_Reward - 奖励选择UI
13. ⏳ GYM_15_Scoreboard - 计分板UI
14. ⏳ GYM_16_Death - 死亡界面UI

---

## 已完成模块

### 扩展功能（新增）- 已完成 ✅
11. ✅ GYM_11_WeirdLoot - 诡异搜打撤系统
12. ✅ GYM_12_Melee - 近战武器系统

---

## 目录结构

```
demo/
├── GYM_01_Movement.tscn        # 玩家移动 ✅
├── GYM_02_Weapon.tscn          # 武器系统 ✅
├── GYM_03_Monster.tscn         # 怪物系统 ✅
├── GYM_04_Item.tscn            # 物品系统 ✅
├── GYM_05_Equip.tscn           # 装备系统 ✅
├── GYM_06_Attachment.tscn      # 附件系统 ✅
├── GYM_07_Crosshair.tscn       # 准星UI ✅
├── GYM_08_HitLabel.tscn        # 伤害数字UI ✅
├── GYM_09_WeaponList.tscn      # 武器列表UI ✅
├── GYM_10_Inventory.tscn       # 背包UI ✅
├── GYM_11_WeirdLoot.tscn       # 诡异搜打撤系统 ✅
├── GYM_12_Melee.tscn           # 近战武器系统 ✅
├── GYM_13_Shop.tscn            # 商店UI ⏳
├── GYM_14_Reward.tscn          # 奖励选择UI ⏳
├── GYM_15_Scoreboard.tscn      # 计分板UI ⏳
├── GYM_16_Death.tscn           # 死亡界面UI ⏳
└── README.md                   # 说明文档
```
