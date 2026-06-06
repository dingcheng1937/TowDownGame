# 装备UI与仓库UI实现文档

## 概述

本文档详细说明TowDownGame中**装备UI系统**和**仓库UI系统**的实现细节。两个系统协同工作，支持武器配件的查看、装备和卸下操作。

---

## ⚠️ 重要：信号连接时机

在开发GYM场景时发现的关键问题：**UI必须先于数据变化创建并监听信号**。

### 错误示例

```gdscript
# ❌ 错误：先添加数据，后创建UI
PlayerData.add_weapons(weapons)  # 发射 playerWeaponListChange 信号
_setup_ui()  # GameUI还不存在，无法接收信号
```

### 正确示例

```gdscript
# ✅ 正确：先创建UI，后添加数据
_setup_ui()  # GameUI创建并连接信号
await get_tree().process_frame  # 等待UI初始化完成
PlayerData.add_weapons(weapons)  # 发射信号，GameUI已准备好接收
```

### 原因分析

1. `GameUI._ready()` 在 `_setup_ui()` 创建 ControlUI 后才会执行
2. `playerWeaponListChange` 信号在 `GameUI._ready()` 中才连接
3. 如果先发射信号，GameUI 还未连接，无法响应

---

## 系统架构

```
┌─────────────────────────────────────────────────────────────────┐
│                       仓库UI (Inventory)                          │
│  负责显示玩家背包中的附件和已装备武器的配件槽位                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │ 拖拽操作
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     装备系统 (EquipSystem)                        │
│  BaseEquip ←→ EquipServer ←→ PlayerData                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 一、仓库UI系统 (Inventory)

**核心文件：**
- [ui/Inventory.gd](file:///d:/projects/TowDownGame/ui/Inventory.gd) - 主控制器
- [ui/Inventory.tscn](file:///d:/projects/TowDownGame/ui/Inventory.tscn) - 场景结构
- [ui/widgets/WeaponTopItem.tscn](file:///d:/projects/TowDownGame/ui/widgets/WeaponTopItem.tscn) - 武器列表项
- [ui/widgets/AttachmentUIItem.tscn](file:///d:/projects/TowDownGame/ui/widgets/AttachmentUIItem.tscn) - 附件列表项

### 1.1 场景结构

```
Inventory (Control)
├── ColorRect                    # 半透明黑色背景
├── Panel                        # 主面板
│   ├── HBoxContainer           # 武器列表容器
│   │   └── WeaponTopItem × N  # 武器项（动态生成）
│   ├── WeaponMain              # 武器详情区
│   │   ├── iamge              # 武器图片
│   │   ├── Label              # 武器名称
│   │   └── GridContainer      # 配件槽位（8个固定槽）
│   │       └── WeaponAmItem × 8
│   └── ScrollContainer         # 附件背包列表
│       └── GridContainer       # 附件网格
│           └── AttachmentUIItem × N
├── TouchTexture                 # 拖拽中的附件预览
└── Tooltip                      # 鼠标悬停提示
```

### 1.2 核心数据结构

```gdscript
# Inventory.gd
@onready var weapon_lsit_node = $Panel/HBoxContainer      # 武器列表容器
@onready var am_list_node = $Panel/ScrollContainer/GridContainer  # 附件背包
@onready var choose_image = $Panel/WeaponMain/iamge        # 当前选中武器图片
@onready var touch_texture = $TouchTexture                 # 拖拽纹理

var choose_gun :BaseGun = Utils.player.gun               # 当前选中武器
```

### 1.3 生命周期管理

```gdscript
func _enter_tree() -> void:
    Utils.is_inv_show = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE           # 显示鼠标
    await get_tree().create_timer(0.1).timeout
    get_tree().paused = true                              # 暂停游戏

func _exit_tree() -> void:
    if !Utils.pause_state:
        Input.mouse_mode = Input.MOUSE_MODE_HIDDEN       # 隐藏鼠标
        get_tree().paused = false                        # 恢复游戏
    Utils.is_inv_show = false
```

### 1.4 武器列表加载

```gdscript
func _ready() -> void:
    # 为8个配件槽位绑定事件
    for node in weapon_am_nodes:
        node.mouseEvent.connect(mouseEvent)
        node.checkTouchDown.connect(checkTouchDown)

    # 动态生成武器列表
    for item in PlayerData.player_weapon_list:
        if !weapon_lsit_node.has_node(str(item)):
            var ins = weapon_item_pre.instantiate()
            ins.weapon_click.connect(weapon_click)
            ins.name = str(item)
            ins.local_id = item
            weapon_lsit_node.add_child(ins)

    loadBag()
    if choose_gun:
        setWeaponChoose()
        loadWeaponAm()
```

---

## 一（补充）、游戏运行时武器列表 (GameUI)

**核心文件：**
- [ui/GameUI.gd](file:///d:/projects/TowDownGame/ui/GameUI.gd) - 游戏运行时UI控制器
- [ui/widgets/WeaponListItem.gd](file:///d:/projects/TowDownGame/ui/widgets/WeaponListItem.gd) - 武器快捷切换列表项
- [ui/widgets/WeaponListItem.tscn](file:///d:/projects/TowDownGame/ui/widgets/WeaponListItem.tscn) - 场景结构

### 1.1-G 场景结构

```
GameUI (Control)
├── HBoxContainer                 # 武器快捷切换列表（左下角）
│   └── WeaponListItem × N      # 武器项（动态生成）
│       ├── image               # 武器图标
│       └── Label               # 数字键提示（1-9）
├── Container                     # 弹药显示区
│   ├── BulletHbox              # 当前弹夹子弹可视化
│   ├── Label                   # 当前弹夹数量
│   └── all_ammo                # 总弹药数量
├── WeaponChangeUI               # 武器切换动画
│   └── WeaponImage
│       └── Label               # 武器名称
└── hpUI                          # 生命值/等级/金币显示
```

### 1.2-G 信号监听机制

**关键：GameUI 通过信号驱动武器列表更新**

```gdscript
func _ready() -> void:
    # 监听游戏启动信号
    Utils.onGameStart.connect(onGameStart)

    # 监听武器列表变化信号
    PlayerData.playerWeaponListChange.connect(playerWeaponListChange)

    # 监听武器切换信号
    PlayerData.onWeaponChangeAnim.connect(onWeaponChangeAnim)

    # 监听弹药变化信号
    PlayerData.onWeaponBulletsChange.connect(onWeaponBulletsChange)

    # 监听血量/金币/等级等其他信号
    PlayerData.onHpChange.connect(_on_hp_change_internal)
    PlayerData.onGoldChange.connect(onGoldChange)
    ...
```

### 1.3-G 武器列表动态生成

```gdscript
func playerWeaponListChange():
    # 遍历 PlayerData.player_weapon_list 字典
    for item in PlayerData.player_weapon_list:
        # 检查是否已存在该武器的UI项
        if !weapon_lsit_node.has_node(str(item)):
            var ins = weapon_item_pre.instantiate()
            ins.name = str(item)  # 节点名 = weapon_id
            ins.local_id = item   # 传递武器ID给组件
            weapon_lsit_node.add_child(ins)
```

**注意事项：**
1. `PlayerData.player_weapon_list` 是字典，key = weapon_id，value = BaseGun 实例
2. 每个武器只能添加一次（通过节点名检查避免重复）
3. 信号发射时机必须在 GameUI 创建之后（参见"信号连接时机"章节）

### 1.4-G WeaponListItem 组件

**文件：** [ui/widgets/WeaponListItem.gd](file:///d:/projects/TowDownGame/ui/widgets/WeaponListItem.gd)

```gdscript
extends TextureRect

@onready var image = $image
@onready var press_label = $Label

var local_id = 0          # 武器ID
var pressed_name = ""     # 输入动作名（动态生成）

func _ready() -> void:
    # 连接武器切换信号（高亮当前武器）
    PlayerData.onWeaponChanged.connect(onWeaponChanged)

    # 根据索引生成数字键提示和动作名
    var pressed_index = get_index() + 1
    press_label.text = str(pressed_index)
    pressed_name = "pressed_%s" % pressed_index

    # 加载武器图标
    var gun : BaseGun = PlayerData.player_weapon_list[local_id]
    image.texture = gun.image

func _input(event: InputEvent) -> void:
    # 监听对应的数字键切换武器
    if !pressed_name.is_empty() && event.is_action_pressed(pressed_name):
        PlayerData.changeWeapon(local_id)

func onWeaponChanged():
    # 高亮当前武器
    if Utils.player.gun && Utils.player.gun.weapon_id == local_id:
        self_modulate = Color("#83e0ff")
    else:
        self_modulate = Color.WHITE
```

**关键特性：**
1. **动态动作名**：根据索引生成 `pressed_1` 到 `pressed_9`
2. **信号驱动高亮**：监听 `onWeaponChanged` 信号自动更新视觉效果
3. **数字键切换**：通过 `_input` 监听对应按键触发 `PlayerData.changeWeapon()`

### 1.5-G InputMap 配置要求

**重要：必须在项目设置中预定义输入动作**

WeaponListItem 使用动态生成的动作名（`pressed_1` 到 `pressed_9`），这些动作必须在 `project.godot` 中预定义：

```gdscript
# 通过 Godot MCP 工具添加
mcp__godot-ai__input_map_manage(op="add_action", params={"action": "pressed_8", "deadzone": 0.5})
mcp__godot-ai__input_map_manage(op="bind_event", params={"action": "pressed_8", "event_type": "key", "keycode": "8"})

mcp__godot-ai__input_map_manage(op="add_action", params={"action": "pressed_9", "deadzone": 0.5})
mcp__godot-ai__input_map_manage(op="bind_event", params={"action": "pressed_9", "event_type": "key", "keycode": "9"})
```

**已配置的动作：**
- `pressed_1` → 数字键 1
- `pressed_2` → 数字键 2
- `pressed_3` → 数字键 3
- `pressed_4` → 数字键 4
- `pressed_5` → 数字键 5
- `pressed_6` → 数字键 6
- `pressed_7` → 数字键 7
- `pressed_8` → 数字键 8（新增）
- `pressed_9` → 数字键 9（新增）

**如果动作缺失，运行时会报错：**
```
The InputMap action "pressed_8" doesn't exist. Did you mean "pressed_1"?
```

### 1.5 背包附件加载

```gdscript
func loadBag():
    # 清空现有附件
    for item in am_list_node.get_children():
        item.queue_free()
    am_list_node.get_children().clear()
    await get_tree().create_timer(0.01).timeout
    
    # 只加载未装备的附件（gun == null）
    for item in PlayerData.player_am_list:
        if !am_list_node.has_node(str(item)) && PlayerData.player_am_list[item].gun == null:
            var ins = attachmont_item_pre.instantiate()
            ins.mouseEvent.connect(mouseEvent)
            ins.onTouchDown.connect(onTouchDown)
            ins.onTouchUp.connect(onTouchUp)
            ins.name = str(item)
            ins.local_id = item
            am_list_node.add_child(ins)
```

### 1.6 拖拽操作流程

仓库UI支持**拖拽操作**来装备/卸下附件：

#### 装备附件（从背包到武器）

```gdscript
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
        # 只高亮匹配类型的槽位
        node.setState(am.am_type == node.am_type and am.canUseAm(choose_gun.weapon_type))

func onTouchUp(id):
    touch_texture.visible = false 
    touch_texture.texture = null
    set_process(false)
    
    # 检查是否释放在槽位上
    for item in weapon_am_nodes:
        if item.get_global_rect().has_point(get_global_mouse_position()):
            checkTouchUp(id, item)
            break
    
    for node in weapon_am_nodes:
        node.setState(true)

func checkTouchUp(id, node:WeaponAmItem):
    var am :BaseAttachment = PlayerData.player_am_list[id]
    if node.state:  # 槽位可用
        choose_gun.addAttachMent(am)  # 添加附件
        loadWeaponAm()
        Utils.showToast("INVENTORY_AM_UP")
        loadBag()  # 刷新背包
```

#### 卸下附件（从武器到背包）

```gdscript
func checkTouchDown(am:BaseAttachment):
    choose_gun.removeAttachMent(am)  # 移除附件
    loadWeaponAm()
    loadBag()
    Utils.showToast("INVENTORY_AM_DOWN")
```

### 1.7 武器配件槽位 (WeaponAmItem)

**文件：** [ui/WeaponAmItem.gd](file:///d:/projects/TowDownGame/ui/WeaponAmItem.gd)

配件槽位类型枚举：
- `WEAPON_OPTICS` - 光学瞄准镜
- `WEAPON_MUZZLE` - 枪口
- `WEAPON_BARREL` - 枪管
- `WEAPON_UNDERBARREL` - 下挂配件
- `WEAPON_AMMUNITION` - 弹药
- `WEAPON_STOCK` - 枪托
- `WEAPON_TACTICAL` - 战术配件
- `WEAPON_PERKS` - 特性

```gdscript
func setData(am:BaseAttachment):
    self.am = am
    if am != null:
        $Button.visible = true
        item_image.texture = am.am_image
    else:
        $Button.visible = false
        item_image.texture = null

func setState(state):
    self.state = state
    if !state:
        modulate = Color("#474747")  # 不可用时变灰
    else:
        modulate = Color.WHITE
```

---

## 二、装备UI系统 (EquipTexture)

**核心文件：**
- [ui/snow/EquipTexture.gd](file:///d:/projects/TowDownGame/ui/snow/EquipTexture.gd) - 装备纹理组件
- [ui/snow/EquipTexture.tscn](file:///d:/projects/TowDownGame/ui/snow/EquipTexture.tscn) - 场景结构

### 2.1 场景结构

```
EquipTexture (Panel)
├── TextureRect           # 装备图标
├── TextureProgressBar    # 冷却进度条（目前未使用）
├── Label                 # 按键提示（隐藏）
└── Key                   # 按键图标
```

### 2.2 组件功能

```gdscript
var equip :BaseEquip

func _ready():
    if equip:
        equip_image.texture = equip.equip_image
        match equip.equip_quick_key:
            "q": equip_key.texture = load("res://Sprites/ui/key/tile_0085.png")
            "mouse_right": equip_key.texture = load("res://Sprites/ui/key/tile_0112.png")
            "space": equip_key.texture = load("res://Sprites/ui/key/tile_0235.png")

func setEquip(equip):
    self.equip = equip
```

---

## 三、装备基类 (BaseEquip)

**文件：** [game/equip/BaseEquip.gd](file:///d:/projects/TowDownGame/game/equip/BaseEquip.gd)

### 3.1 属性定义

```gdscript
@export var equip_name = ""                    # 武器名称
@export var equip_image :Texture              # 武器图片
@export var equip_info = ""                   # 武器说明
@export_enum("q", "space", "mouse_right") var equip_quick_key = "q"  # 快捷键
@export var cd_time = 60                      # 冷却时间

var temp_cd = 0                               # 当前冷却计时
var in_equ = false                            # 是否已装备
var timer = Timer.new()
var equip_texture_ins                         # UI实例引用
```

### 3.2 生命周期与UI注册

```gdscript
func _enter_tree():
    in_equ = true
    if !equip_texture_ins:
        # 实例化装备纹理UI并注册到EquipServer
        equip_texture_ins = equip_texture_pre.instantiate()
        equip_texture_ins.name = equip_name
        equip_texture_ins.setEquip(self)
        EquipServer.addUI(equip_texture_ins)

func _exit_tree():
    in_equ = false
    if equip_texture_ins:
        EquipServer.removeUI(equip_texture_ins)
```

### 3.3 快捷键触发

```gdscript
func _input(event):
    if Input.is_action_pressed(equip_quick_key) && temp_cd <= 0:
        temp_cd = cd_time
        timer.start()
        openFire()

func on_timeout():
    if temp_cd > 0:
        temp_cd -= 0.1
        if temp_cd == 0:
            timer.stop()
```

---

## 四、装备服务器 (EquipServer)

**文件：** [autoload/server/EquipServer.gd](file:///d:/projects/TowDownGame/autoload/server/EquipServer.gd)

### 4.1 功能说明

EquipServer是装备系统的**中央管理器**，负责：
1. 在场景中生成地面装备
2. 管理已装备UI的注册/注销
3. 提供装备添加/移除的信号通知

### 4.2 核心实现

```gdscript
const equip_touch_pre = preload("res://game/equip/EquipOnFloor.tscn")

signal onEquipAdd(ins)
signal onEquipRemove(ins)

# 在指定位置生成地面装备
func addEquipOnFloor(equip:BaseEquip, position:Vector2):
    var ins = equip_touch_pre.instantiate()
    ins.global_position = position
    ins.equip = equip
    get_tree().call_group("world", "addEquip", ins)

# 添加装备到玩家
func addEquipToPlayer(equip:BaseEquip):
    Utils.player.addEquip(equip)

# UI注册
func addUI(ins):
    emit_signal("onEquipAdd", ins)

func removeUI(ins):
    emit_signal("onEquipRemove", ins)
```

---

## 五、附件系统 (BaseAttachment)

**相关文件：**
- [game/attachments/BaseAttachment.gd](file:///d:/projects/TowDownGame/game/attachments/BaseAttachment.gd)

附件具有以下关键属性：
- `am_type` - 附件类型（对应槽位类型）
- `gun` - 当前绑定的武器（null表示在背包中）
- `am_image` - 附件图标

---

## 六、Widget组件详解

### 6.1 WeaponTopItem（武器列表项）

**文件：** [ui/widgets/WeaponTopItem.gd](file:///d:/projects/TowDownGame/ui/widgets/WeaponTopItem.gd)

```gdscript
extends Button

signal weapon_click(gun)

func _ready() -> void:
    PlayerData.onWeaponChanged.connect(onWeaponChanged)
    press_label.text = str(get_index() + 1)  # 显示序号1-9
    var gun : BaseGun = PlayerData.player_weapon_list[local_id]
    image.texture = gun.image

func onWeaponChanged():
    if Utils.player.gun && Utils.player.gun.weapon_id == local_id:
        self_modulate = Color("#83e0ff")  # 高亮当前武器
    else:
        self_modulate = Color.WHITE
```

### 6.2 AttachmentUIItem（附件列表项）

**文件：** [ui/widgets/AttachmentUIItem.gd](file:///d:/projects/TowDownGame/ui/widgets/AttachmentUIItem.gd)

```gdscript
extends Control

signal mouseEvent(show, am)
signal onTouchDown(id)
signal onTouchUp(id)

func _on_button_button_down():
    emit_signal("onTouchDown", local_id)

func _on_button_button_up():
    emit_signal("onTouchUp", local_id)

func _on_mouse_entered():
    emit_signal("mouseEvent", true, PlayerData.player_am_list[local_id])
```

---

## 七、操作流程图

### 装备附件流程

```
玩家点击背包中的附件
        ↓
onTouchDown → 显示拖拽预览 + 高亮可用槽位
        ↓
玩家拖拽到槽位
        ↓
onTouchUp → 检测是否在有效槽位上
        ↓
checkTouchUp → 调用 choose_gun.addAttachMent(am)
        ↓
loadWeaponAm() → 更新槽位显示
        ↓
loadBag() → 刷新背包列表
```

### 卸下附件流程

```
玩家点击武器槽位上的附件
        ↓
checkTouchDown → emit_signal("checkTouchDown", am)
        ↓
Inventory.gd 接收信号
        ↓
choose_gun.removeAttachMent(am)
        ↓
loadWeaponAm() → 更新槽位显示
        ↓
loadBag() → 刷新背包列表
```

---

## 八、相关文件索引

| 文件路径 | 说明 |
|---------|------|
| [ui/GameUI.gd](file:///d:/projects/TowDownGame/ui/GameUI.gd) | **游戏运行时UI主控制器**（左下角武器列表） |
| [ui/widgets/WeaponListItem.gd](file:///d:/projects/TowDownGame/ui/widgets/WeaponListItem.gd) | **游戏运行时武器列表项**（数字键切换） |
| [ui/widgets/WeaponListItem.tscn](file:///d:/projects/TowDownGame/ui/widgets/WeaponListItem.tscn) | WeaponListItem 场景 |
| [ui/Inventory.gd](file:///d:/projects/TowDownGame/ui/Inventory.gd) | **仓库UI主控制器**（配件装备界面） |
| [ui/Inventory.tscn](file:///d:/projects/TowDownGame/ui/Inventory.tscn) | 仓库UI场景 |
| [ui/widgets/WeaponTopItem.gd](file:///d:/projects/TowDownGame/ui/widgets/WeaponTopItem.gd) | **仓库中武器列表项**（点击切换） |
| [ui/widgets/AttachmentUIItem.gd](file:///d:/projects/TowDownGame/ui/widgets/AttachmentUIItem.gd) | 附件背包列表项 |
| [ui/WeaponAmItem.gd](file:///d:/projects/TowDownGame/ui/WeaponAmItem.gd) | 武器配件槽位组件 |
| [ui/snow/EquipTexture.gd](file:///d:/projects/TowDownGame/ui/snow/EquipTexture.gd) | 装备纹理组件 |
| [game/equip/BaseEquip.gd](file:///d:/projects/TowDownGame/game/equip/BaseEquip.gd) | 装备基类 |
| [autoload/server/EquipServer.gd](file:///d:/projects/TowDownGame/autoload/server/EquipServer.gd) | 装备服务器 |
| [game/attachments/BaseAttachment.gd](file:///d:/projects/TowDownGame/game/attachments/BaseAttachment.gd) | 附件基类 |

---

## 九、开发经验总结

### 9.1 GYM场景开发注意事项

基于 GYM_09 开发过程中发现的问题：

#### 问题1：武器列表不显示

**现象：** 添加武器后，GameUI 的 HBoxContainer 中没有武器列表项。

**根本原因：** 执行顺序错误导致信号丢失：
```gdscript
# 错误顺序
Utils.gameStart()           # → 发射 onGameStart
PlayerData.add_weapons()    # → 发射 playerWeaponListChange
_setup_ui()                 # GameUI 还不存在
```

**解决方案：** 调整执行顺序：
```gdscript
# 正确顺序
_setup_ui()                 # 先创建 UI 并连接信号
await get_tree().process_frame  # 等待 _ready 执行
Utils.gameStart()           # 再发射信号
PlayerData.add_weapons()
```

#### 问题2：InputMap 动作缺失

**现象：** 按数字键 8、9 时报错：
```
The InputMap action "pressed_8" doesn't exist.
```

**原因：** WeaponListItem 使用动态动作名（`pressed_N`），但项目只预定义了 `pressed_1` 到 `pressed_7`。

**解决方案：** 补充缺失的输入映射：
```gdscript
# 添加 pressed_8 和 pressed_9
PlayerData.player_weapon_list 支持 1-9 把武器
→ 需要对应的 pressed_1 到 pressed_9 输入动作
```

### 9.2 两个武器列表的区别

| 特性 | WeaponListItem (GameUI) | WeaponTopItem (Inventory) |
|-----|------------------------|--------------------------|
| **位置** | 屏幕左下角 | 背包UI顶部 |
| **类型** | TextureRect | Button |
| **交互** | 数字键切换 | 点击切换 |
| **显示** | 武器图标 + 数字 | 武器图标 + 名称 |
| **触发** | `_input` 监听动作 | `pressed` 信号 |
| **用途** | 游戏运行时快速切换 | 背包界面选择编辑 |

### 9.3 信号驱动设计要点

1. **信号必须在接收方准备好后发射**
   - UI 创建 → 连接信号 → 数据变化
   - 不是：数据变化 → UI 创建（信号已丢失）

2. **组件间解耦**
   - GameUI 不直接调用 WeaponListItem 的方法
   - 通过 PlayerData 信号广播状态变化
   - 各组件独立响应信号更新自身

3. **生命周期管理**
   - `_enter_tree` / `_exit_tree` 管理资源
   - `_ready` 初始化和信号连接
   - 退出时断开信号避免内存泄漏

### 9.4 调试技巧

使用 Godot MCP 工具调试运行时状态：

```gdscript
# 检查武器列表项数量
mcp__godot-ai__editor_manage(op="game_eval", params={
    "code": "var hbox = get_node('/root/Scene/HBoxContainer'); return hbox.get_child_count()"
})

# 检查 PlayerData 状态
mcp__godot-ai__editor_manage(op="game_eval", params={
    "code": "return PlayerData.player_weapon_list.keys()"
})

# 手动发射信号测试
mcp__godot-ai__editor_manage(op="game_eval", params={
    "code": "PlayerData.emit_signal('playerWeaponListChange'); return true"
})
```
