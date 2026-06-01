# TowDownGame 开发规则

## 核心原则：复用现有代码

**必须复用项目已有功能，禁止重复造轮子。**

在开发任何功能前，必须先：
1. 搜索项目中是否已有类似实现
2. 理解现有代码的工作方式
3. 基于现有代码进行扩展或调用

### 示例

**错误做法：**
- 需要射击功能 → 自己写一套新的射击系统
- 需要UI组件 → 自己创建新的UI

**正确做法：**
- 需要射击功能 → 查看 `game/guns/BaseGun.gd`，复用现有枪械系统
- 需要UI组件 → 查看 `ui/widgets/` 目录，使用已有组件

---

## 项目架构

### 核心系统
| 系统 | 核心文件 | 说明 |
|------|----------|------|
| 玩家 | `game/hero/Hero.gd` | 玩家控制、状态管理 |
| 武器 | `game/guns/BaseGun.gd` | 武器基类，射击逻辑 |
| 怪物 | `game/monster/BaseMonster.gd` | 怪物基类 |
| 物品 | `game/items/BaseItem.gd` | 物品基类 |
| 装备 | `game/equip/BaseEquip.gd` | 装备基类 |
| 附件 | `game/attachments/BaseAttachment.gd` | 附件基类 |

### UI组件 (`ui/widgets/`)
| 组件 | 用途 |
|------|------|
| `Crosshair.tscn` | 准星 |
| `HitLabel.tscn` | 伤害数字 |
| `InfoPanel.tscn` | 信息面板 |
| `WeaponListItem.tscn` | 武器列表项 |

### 工具类 (`Utils`)
- `Utils.onGameStart` - 游戏启动信号
- `Utils.player` - 玩家引用
- `Utils.showHitLabel()` - 显示伤害数字

### 数据管理 (`PlayerData`)
- `PlayerData.player_hp` - 玩家血量
- `PlayerData.player_weapon_list` - 武器列表
- `PlayerData.player_ammo` - 弹药数量

---

## DEMO场景 (GYM)

位于 `demo/` 目录，命名格式：`GYM_[ID]_[NAME].tscn`

每个GYM必须：
1. 复用原游戏代码（Hero、BaseGun等）
2. 通过 Starter 脚本初始化必要状态
3. 不修改原始游戏文件

---

## 开发验证规范

**每次开发完成后，必须到对应GYM场景验证。**

### 验证步骤

1. 打开相关GYM场景（`demo/GYM_XX_*.tscn`）
2. 运行场景（F5或编辑器播放）
3. 检查控制台日志是否有错误
4. 手动测试相关功能

### GYM场景对照表

| GYM | 验证内容 |
|-----|----------|
| GYM_01_Movement | 玩家移动、冲刺 |
| GYM_02_Weapon | 武器射击、换弹 |
| GYM_03_Monster | 怪物AI、追踪 |
| GYM_04_Item | 物品拾取 |
| GYM_05_Equip | 装备使用 |
| GYM_06_Attachment | 附件安装 |
| GYM_07_Crosshair | 准星显示 |
| GYM_08_HitLabel | 伤害数字 |
| GYM_09_WeaponList | 武器切换 |
| GYM_10_Inventory | 背包界面 |

---

## Git提交规范

- 使用中文提交信息
- 简洁描述做了什么改动
