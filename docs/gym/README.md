# 游戏模块 GYM (Gameplay Yield Modules)

独立验证原游戏各个核心系统的功能。所有GYM遵循 **复用原游戏代码** 原则，不修改任何原始数据。

---

## GYM 列表

### 游戏核心模块

#### GYM_01_Movement - 玩家移动 ✅
**文件:** `GYM_01_Movement.tscn` + `GYM_01_MovementStarter.gd`

**验证内容:**
- WASD移动手感
- Space冲刺效果
- 相机跟随和鼠标偏移
- 相机震动特效

**控制:** WASD移动 | Space冲刺 | 鼠标控制朝向

---

#### GYM_02_Weapon - 武器系统 ✅
**文件:** `GYM_02_Weapon.tscn` + `GYM_02_WeaponStarter.gd`

**验证内容:**
- Uzi自动射击
- 子弹飞行和碰撞
- 怪物受击、击退和死亡
- 换弹机制

**控制:** WASD移动 | 鼠标左键射击 | R换弹

---

#### GYM_03_Monster - 怪物系统 ✅
**文件:** `GYM_03_Monster.tscn` + `GYM_03_MonsterStarter.gd`

**验证内容:**
- Ghoul怪物AI追踪玩家
- 怪物移动和动画
- 怪物朝向翻转

**控制:** WASD移动（怪物会追踪你）

---

#### GYM_04_Item - 物品系统 ✅
**文件:** `GYM_04_Item.tscn` + `GYM_04_ItemStarter.gd`

**验证内容:**
- 金币拾取 (PlayerData.gold增加)
- 血包拾取 (PlayerData.player_hp恢复)
- 物品动画和消失效果

**控制:** WASD移动到物品上拾取

---

#### GYM_05_Equip - 装备系统 ✅
**文件:** `GYM_05_Equip.tscn` + `GYM_05_EquipStarter.gd`

**验证内容:**
- 装备拾取
- 装备使用（Q键）
- 装备CD冷却
- 喷火器效果

**控制:** WASD移动 | Q使用装备

---

#### GYM_06_Attachment - 附件系统 ✅
**文件:** `GYM_06_Attachment.tscn` + `GYM_06_AttachmentStarter.gd`

**验证内容:**
- 附件拾取
- 附件安装到武器
- 附件效果（弹夹扩容等）

**控制:** WASD移动 | 鼠标左键射击

---

### UI模块

#### GYM_07_Crosshair - 准星UI ✅
**文件:** `GYM_07_Crosshair.tscn` + `GYM_07_CrosshairStarter.gd`

**验证内容:**
- 准星跟随鼠标
- 准星旋转动画

**控制:** 移动鼠标查看准星效果

---

#### GYM_08_HitLabel - 伤害数字UI ✅
**文件:** `GYM_08_HitLabel.tscn` + `GYM_08_HitLabelStarter.gd`

**验证内容:**
- 不同伤害数值显示
- 数字飘动效果
- 不同颜色区分

**控制:** 点击鼠标生成伤害数字

---

#### GYM_09_WeaponList - 武器列表UI ✅
**文件:** `GYM_09_WeaponList.tscn` + `GYM_09_WeaponListStarter.gd`

**验证内容:**
- 武器列表显示
- 武器切换 (1-9)
- 子弹数量显示

**控制:** WASD移动 | 1-9切换武器

---

#### GYM_10_Inventory - 背包UI ✅
**文件:** `GYM_10_Inventory.tscn` + `GYM_10_InventoryStarter.gd`

**验证内容:**
- 按Tab打开/关闭背包
- 背包界面显示

**控制:** WASD移动 | Tab开关背包

---

#### GYM_11_WeirdLoot - 诡异搜打撤系统 ✅
**文件:** `GYM_11_WeirdLoot.tscn` + `GYM_11_WeirdLootStarter.gd`

**验证内容:**
- 理智系统（SanityServer）
- 撤离点机制（ExtractionServer）
- 掉落物拾取（LootServer）
- 诡异怪物（Shade、Whisperer、Aberration）

**控制:** WASD移动 | 鼠标左键射击 | E交互

---

#### GYM_12_Melee - 近战武器系统 ✅
**文件:** `GYM_12_Melee.tscn` + `GYM_12_MeleeStarter.gd`

**验证内容:**
- V键近战攻击
- Tab切换武器
- 武器耐久度
- 武器损坏机制

**控制:** WASD移动 | V近战攻击 | Tab切换武器

---

## 技术架构

每个GYM包含：

```
GYM场景
├── PlayerRoot
│   ├── Hero (复用原游戏)
│   └── Anchor (相机平滑跟随)
│       └── Camera2D (复用原游戏脚本)
├── 功能场景节点
└── GYM_XX_Starter (启动器脚本)
```

**启动流程:**
```gdscript
await get_tree().process_frame
Utils.gameStart()  # 触发游戏启动
Utils.player = $PlayerRoot/Hero  # 设置玩家引用
# 其他初始化...
```

---

## InfoPanel 信息面板组件

**文件:** `ui/widgets/InfoPanel.tscn` + `InfoPanel.gd`

可复用的信息面板UI组件，用于教程、游戏提示、测试关卡说明等场景。

### 功能特性

- 按 `H` 键显示/隐藏面板（可自定义按键）
- 支持设置标题和内容
- 可配置面板宽度、透明度
- 默认使用 CanvasLayer，固定在屏幕左上角

### 使用方法

**方式一：直接实例化**
```gdscript
const InfoPanel = preload("res://ui/widgets/InfoPanel.tscn")

func _ready():
    var panel = InfoPanel.instantiate()
    add_child(panel)
    panel.title = "关卡说明"
    panel.content = "这里是说明内容..."
```

**方式二：在场景中放置**
```
[node name="InfoPanel" parent="." instance=ExtResource("uid://infopanel_widget")]
title = "标题"
content = "内容"
toggle_key = 72  # KEY_H
show_by_default = true
```

### 导出属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `toggle_key` | Key | KEY_H | 显示/隐藏按键 |
| `title` | String | "" | 面板标题 |
| `content` | String | "" | 主要内容文本 |
| `show_by_default` | bool | true | 是否默认显示 |
| `panel_width` | int | 340 | 面板宽度 |
| `bg_opacity` | float | 0.85 | 背景透明度 (0.0-1.0) |

### API方法

```gdscript
# 设置标题
panel.set_title("新标题")

# 设置内容
panel.set_content("新内容")

# 设置切换按键
panel.set_toggle_key(KEY_F1)

# 手动控制显示/隐藏
panel.show_panel()
panel.hide_panel()
panel.toggle()
```

---

## 文件结构

```
demo/
├── GYM_01_Movement.tscn          # 玩家移动 ✅
├── GYM_01_MovementStarter.gd
├── GYM_02_Weapon.tscn            # 武器系统 ✅
├── GYM_02_WeaponStarter.gd
├── GYM_03_Monster.tscn           # 怪物系统 ✅
├── GYM_03_MonsterStarter.gd
├── GYM_04_Item.tscn              # 物品系统 ✅
├── GYM_04_ItemStarter.gd
├── GYM_05_Equip.tscn             # 装备系统 ✅
├── GYM_05_EquipStarter.gd
├── GYM_06_Attachment.tscn        # 附件系统 ✅
├── GYM_06_AttachmentStarter.gd
├── GYM_07_Crosshair.tscn         # 准星UI ✅
├── GYM_07_CrosshairStarter.gd
├── GYM_08_HitLabel.tscn          # 伤害数字UI ✅
├── GYM_08_HitLabelStarter.gd
├── GYM_09_WeaponList.tscn        # 武器列表UI ✅
├── GYM_09_WeaponListStarter.gd
├── GYM_10_Inventory.tscn         # 背包UI ✅
├── GYM_10_InventoryStarter.gd
├── GYM_11_WeirdLoot.tscn        # 诡异搜打撤系统 ✅
├── GYM_11_WeirdLootStarter.gd
├── GYM_12_Melee.tscn            # 近战武器系统 ✅
├── GYM_12_MeleeStarter.gd
├── DEMO_PLAN.md                  # 规划文档
└── README.md                     # 本文档
```

**总计：12个独立GYM，完整覆盖游戏核心系统**
