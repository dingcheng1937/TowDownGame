# TowDownGame 背包系统分析文档

## 一、系统概述

背包系统是 TowDownGame 的核心功能模块，负责管理玩家的武器、配件和装备。该系统采用**信号驱动架构**，实现了数据与UI的解耦，支持武器切换、配件装备/卸下、拖拽操作等核心功能。

## 二、核心架构

### 2.1 系统架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        背包系统架构                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌──────────────┐       ┌──────────────┐       ┌──────────────┐   │
│   │   PlayerData │◄──────│   数据源层   │──────►│   信号中心   │   │
│   │   (全局状态) │       │   (Inventory)│       │   (Signals)  │   │
│   └──────┬───────┘       └──────────────┘       └──────┬───────┘   │
│          │                                             │           │
│          ▼                                             ▼           │
│   ┌──────────────┐       ┌──────────────┐       ┌──────────────┐   │
│   │   GameUI     │       │   Inventory  │       │   EquipServer│   │
│   │  (运行时UI)  │       │   (仓库UI)   │       │   (装备管理) │   │
│   └──────┬───────┘       └──────┬───────┘       └──────────────┘   │
│          │                      │                                  │
│          ▼                      ▼                                  │
│   ┌──────────────┐       ┌──────────────┐                          │
│   │WeaponListItem│       │AttachmentUIItem│                        │
│   │ (武器快捷栏) │       │ (配件列表项)  │                          │
│   └──────────────┘       └──────────────┘                          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 核心文件清单

| 文件路径 | 模块 | 职责 |
|---------|------|------|
| [autoload/PlayerData.gd](file:///d:/projects/TowDownGame/autoload/PlayerData.gd) | 数据层 | 管理玩家背包数据和状态 |
| [ui/Inventory.gd](file:///d:/projects/TowDownGame/ui/Inventory.gd) | UI层 | 仓库界面控制器 |
| [ui/GameUI.gd](file:///d:/projects/TowDownGame/ui/GameUI.gd) | UI层 | 游戏运行时UI控制器 |
| [game/attachments/BaseAttachment.gd](file:///d:/projects/TowDownGame/game/attachments/BaseAttachment.gd) | 数据层 | 配件基类定义 |
| [autoload/server/EquipServer.gd](file:///d:/projects/TowDownGame/autoload/server/EquipServer.gd) | 服务层 | 装备管理服务 |

## 三、数据结构设计

### 3.1 玩家背包数据（PlayerData）

```gdscript
var player_weapon_list = {}  # 武器列表 {weapon_id: BaseGun实例}
var player_am_list = {}      # 配件列表 {attachment_id: BaseAttachment实例}
var player_reward = {}       # 奖励列表
var player_ammo = 100        # 备用子弹数量
var gold = 9999              # 金币数量
```

### 3.2 配件类型定义（BaseAttachment）

| 配件类型 | 枚举值 | 说明 |
|---------|-------|------|
| 光学瞄准镜 | WEAPON_OPTICS | 影响瞄准精度 |
| 枪口 | WEAPON_MUZZLE | 影响后坐力和枪口火焰 |
| 枪管 | WEAPON_BARREL | 影响射程和伤害 |
| 下挂配件 | WEAPON_UNDERBARREL | 如榴弹发射器 |
| 弹药 | WEAPON_AMMUNITION | 特殊弹药类型 |
| 枪托 | WEAPON_STOCK | 影响稳定性 |
| 战术配件 | WEAPON_TACTICAL | 战术装备 |
| 特性 | WEAPON_PERKS | 被动技能 |

### 3.3 武器类型限制

配件通过布尔标志限制可装备的武器类型：

```gdscript
var ASSAULT_RIFLES = false      # 突击步枪
var SUBMACHINE_GUNSRELOAD = false # 冲锋枪
var MACHINE_GUNS = false        # 机枪
var SNIPER_RIFLES = false       # 狙击枪
var SHOTGUNS = false            # 霰弹枪
var LASER_WEAPONS = false       # 激光武器
```

## 四、核心功能实现

### 4.1 武器管理

#### 4.1.1 添加武器

```gdscript
# PlayerData.gd
func add_weapon(weapon:BaseGun):
    if !player_weapon_list.has(weapon.weapon_id):
        player_weapon_list[weapon.weapon_id] = weapon
        emit_signal("playerWeaponListChange")  # 通知UI更新
        return true
    return false
```

#### 4.1.2 切换武器

```gdscript
func changeWeapon(weapon_id:int):
    if is_change_weapon:
        return
    if player_weapon_list.has(weapon_id):
        is_change_weapon = true
        Utils.player.changeWeapon(weapon_id)
```

### 4.2 配件管理

#### 4.2.1 添加配件

```gdscript
func add_attachment(am:BaseAttachment):
    if !player_am_list.has(am.id):
        player_am_list[am.id] = am
        add_child(am)
```

#### 4.2.2 装备配件（拖拽操作）

```gdscript
# Inventory.gd
func onTouchDown(id):
    var am :BaseAttachment = PlayerData.player_am_list[id]
    touch_texture.visible = true 
    touch_texture.texture = am.am_image
    touch_texture.global_position = get_global_mouse_position()
    set_process(true)
    checkTouchState(id)  # 高亮可放置的槽位

func checkTouchState(id):
    var am :BaseAttachment = PlayerData.player_am_list[id]
    for node in weapon_am_nodes:
        # 匹配配件类型且武器类型兼容
        node.setState(am.am_type == node.am_type and am.canUseAm(choose_gun.weapon_type))
```

#### 4.2.3 卸下配件

```gdscript
func checkTouchDown(am:BaseAttachment):
    choose_gun.removeAttachMent(am)
    loadWeaponAm()
    loadBag()
    Utils.showToast("INVENTORY_AM_DOWN")
```

### 4.3 仓库UI生命周期

```gdscript
func _enter_tree() -> void:
    Utils.is_inv_show = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    await get_tree().create_timer(0.1).timeout
    get_tree().paused = true  # 暂停游戏

func _exit_tree() -> void:
    if !Utils.pause_state:
        Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
        get_tree().paused = false
    Utils.is_inv_show = false
```

## 五、信号系统

### 5.1 信号定义（PlayerData）

| 信号名 | 参数 | 触发时机 |
|-------|------|---------|
| playerWeaponListChange | 无 | 武器列表变化 |
| onWeaponChanged | 无 | 切换武器 |
| onWeaponChangeAnim | weapon_id, tag | 武器切换动画 |
| onWeaponBulletsChange | bullet, max_bullet | 弹夹子弹变化 |
| onAmmoChange | ammo | 备用子弹变化 |
| onHpChange | hp, max_hp | 血量变化 |
| onGoldChange | gold | 金币变化 |

### 5.2 信号连接示例

```gdscript
# GameUI.gd
func _ready() -> void:
    PlayerData.playerWeaponListChange.connect(playerWeaponListChange)
    PlayerData.onWeaponChangeAnim.connect(onWeaponChangeAnim)
    PlayerData.onWeaponBulletsChange.connect(onWeaponBulletsChange)
    PlayerData.onHpChange.connect(_on_hp_change_internal)
    PlayerData.onGoldChange.connect(onGoldChange)
```

## 六、UI组件说明

### 6.1 组件层次结构

```
Inventory (Control)
├── ColorRect                    # 半透明背景遮罩
├── Panel                        # 主面板
│   ├── HBoxContainer            # 武器列表容器
│   │   └── WeaponTopItem × N    # 武器项（动态生成）
│   ├── WeaponMain               # 当前选中武器详情区
│   │   ├── iamge                # 武器图片
│   │   ├── Label                # 武器名称
│   │   └── GridContainer        # 配件槽位（8个）
│   │       └── WeaponAmItem × 8
│   └── ScrollContainer          # 附件背包列表
│       └── GridContainer
│           └── AttachmentUIItem × N
├── TouchTexture                 # 拖拽预览
└── Tooltip                      # 悬停提示
```

### 6.2 两个武器列表的区别

| 特性 | WeaponListItem (GameUI) | WeaponTopItem (Inventory) |
|-----|------------------------|--------------------------|
| 位置 | 屏幕左下角 | 背包UI顶部 |
| 交互方式 | 数字键切换 | 点击切换 |
| 显示内容 | 图标 + 数字键提示 | 图标 |
| 使用场景 | 游戏运行时快速切换 | 仓库界面选择编辑 |

## 七、关键交互流程

### 7.1 装备配件流程

```
玩家点击背包中的配件
        ↓
onTouchDown → 显示拖拽预览 + 高亮可用槽位
        ↓
玩家拖拽到槽位上方
        ↓
onTouchUp → 检测鼠标位置是否在有效槽位
        ↓
checkTouchUp → 调用 choose_gun.addAttachMent(am)
        ↓
loadWeaponAm() → 更新槽位显示
        ↓
loadBag() → 刷新背包列表（移除已装备配件）
```

### 7.2 信号驱动更新机制

```
PlayerData数据变化
        ↓
发射对应信号（如 playerWeaponListChange）
        ↓
UI组件监听信号并响应
        ↓
动态更新界面显示
```

## 八、开发注意事项

### 8.1 信号连接时机

**关键原则：UI必须先于数据变化创建并监听信号**

```gdscript
# ✅ 正确顺序
_setup_ui()  # 先创建UI
await get_tree().process_frame  # 等待_ready执行
PlayerData.add_weapons(weapons)  # 再添加数据
```

### 8.2 InputMap配置要求

WeaponListItem 使用动态生成的动作名 `pressed_1` 到 `pressed_9`，必须在项目设置中预定义。

### 8.3 内存泄漏预防

```gdscript
# GameUI.gd - _exit_tree 中断开所有信号连接
if is_instance_valid(PlayerData) and PlayerData.playerWeaponListChange.is_connected(playerWeaponListChange):
    PlayerData.playerWeaponListChange.disconnect(playerWeaponListChange)
```

## 九、总结

背包系统采用**信号驱动架构**，实现了以下核心特性：

1. **数据与UI解耦**：通过信号机制实现状态同步
2. **拖拽交互**：支持配件的直观装备/卸下操作
3. **类型限制**：配件与武器类型的兼容性检查
4. **生命周期管理**：完善的UI创建/销毁流程
5. **响应式更新**：数据变化自动触发UI更新

该系统设计合理，代码结构清晰，便于后续扩展新的武器类型和配件系统。
