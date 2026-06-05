# TowDownGame 文档索引

> 本索引帮助开发者快速找到所需的文档资源。

---

## 目录结构

```
docs/
├── architecture/      # 架构设计文档（英文命名）
├── guides/           # 教程学习文档（中文命名）
├── features/         # 特性功能文档（英文命名）
├── gym/              # GYM验证系统文档
├── widgets/          # UI组件文档
└── planning/         # 规划分析文档
```

---

## 快速导航

### 架构文档 (`architecture/`)

系统架构设计文档，使用英文命名。

| 文档 | 说明 |
|------|------|
| [core-systems.md](architecture/core-systems.md) | 核心系统：玩家、怪物、伤害、死亡系统详解 |
| [ui-system.md](architecture/ui-system.md) | UI系统架构、信号驱动设计 |
| [resolution-scheme.md](architecture/resolution-scheme.md) | 像素艺术渲染方案 |
| [mouse-mode.md](architecture/mouse-mode.md) | 鼠标处理约定 |
| [aim-system.md](architecture/aim-system.md) | 瞄准系统设计（Aim Drift + Bloom） |

### 教程文档 (`guides/`)

学习教程文档，使用中文命名。

| 文档 | 说明 |
|------|------|
| [学习指导.md](guides/学习指导.md) | 项目学习路线图 |
| [玩家系统.md](guides/玩家系统.md) | Hero类、移动、冲刺、伤害处理 |
| [武器系统.md](guides/武器系统.md) | BaseGun、射击流程、附件 |
| [怪物系统.md](guides/怪物系统.md) | BaseMonster、AI追踪、状态管理 |
| [UI系统.md](guides/UI系统.md) | GameUI、Crosshair、HitLabel |
| [数据管理.md](guides/数据管理.md) | PlayerData、Utils、信号订阅 |
| [Godot学习指南.md](guides/Godot学习指南.md) | Godot引擎学习资料 |
| [攻击与受伤系统.md](guides/攻击与受伤系统.md) | 攻击与受伤机制详解 |

### 特性文档 (`features/`)

特性功能文档，使用英文命名。

| 文档 | 说明 |
|------|------|
| [monster-system.md](features/monster-system.md) | 怪物变体、生成系统、MonsterBuilder |
| [light-and-dark.md](features/light-and-dark.md) | 理智系统、诡异怪物、AtmosphereController |
| [map-lighting.md](features/map-lighting.md) | 地图光照系统 |
| [create-position.md](features/create-position.md) | 玩家生成位置管理 |

### GYM验证系统 (`gym/`)

| 文档 | 说明 |
|------|------|
| [README.md](gym/README.md) | GYM概览 - 12个验证模块 |
| [plan.md](gym/plan.md) | GYM开发计划和状态 |
| [test-report.md](gym/test-report.md) | GYM测试报告 |

### UI组件文档 (`widgets/`)

| 文档 | 说明 |
|------|------|
| [info-panel.md](widgets/info-panel.md) | InfoPanel组件手册 |

### 规划文档 (`planning/`)

| 文档 | 说明 |
|------|------|
| [project-evaluation.md](planning/project-evaluation.md) | 项目架构评估 |
| [weird-loot-shooter-plan.md](planning/weird-loot-shooter-plan.md) | 诡异搜打撤MVP计划 |
| [expansion-analysis.md](planning/expansion-analysis.md) | 扩展方向分析 |

---

## 核心文件入口

| 文件 | 说明 |
|------|------|
| [../CLAUDE.md](../CLAUDE.md) | **核心开发规范** - 必读 |
| [../README.md](../README.md) | 项目概述 |

---

## GYM模块对照表

| GYM | 验证内容 | 核心文件 |
|-----|----------|----------|
| GYM_01_Movement | 玩家移动、冲刺 | `game/hero/Hero.gd` |
| GYM_02_Weapon | 武器射击、换弹 | `game/guns/BaseGun.gd` |
| GYM_03_Monster | 怪物AI、追踪 | `game/monster/BaseMonster.gd` |
| GYM_04_Item | 物品拾取 | `game/items/BaseItem.gd` |
| GYM_05_Equip | 装备使用 | `game/equip/BaseEquip.gd` |
| GYM_06_Attachment | 附件安装 | `game/attachments/BaseAttachment.gd` |
| GYM_07_Crosshair | 准星显示 | `ui/widgets/Crosshair.tscn` |
| GYM_08_HitLabel | 伤害数字 | `ui/widgets/HitLabel.tscn` |
| GYM_09_WeaponList | 武器切换 | `ui/widgets/WeaponListItem.tscn` |
| GYM_10_Inventory | 背包界面 | `ui/Inventory.tscn` |
| GYM_11_WeirdLoot | 诡异搜打撤 | `autoload/server/SanityServer.gd` |
| GYM_12_Melee | 近战武器 | `game/weapons/melee/` |

---

## 核心单例

| 单例 | 路径 | 作用 |
|------|------|------|
| `Utils` | `autoload/Utils.gd` | 全局工具、玩家引用、冻结帧 |
| `PlayerData` | `autoload/PlayerData.gd` | 玩家数据、信号系统 |
| `PlayerServer` | `autoload/server/PlayerServer.gd` | 玩家实例管理 |
| `LevelServer` | `autoload/server/LevelServer.gd` | 关卡回合管理 |
| `SanityServer` | `autoload/server/SanityServer.gd` | 理智系统 |
| `ExtractionServer` | `autoload/server/ExtractionServer.gd` | 撤离系统 |
| `LootServer` | `autoload/server/LootServer.gd` | 掉落物系统 |

---

## 命名规范

### 目录规范
- **architecture/**: 架构设计文档，英文命名，kebab-case
- **guides/**: 教程学习文档，中文命名
- **features/**: 特性功能文档，英文命名，kebab-case
- **gym/**: GYM验证系统文档
- **widgets/**: UI组件文档
- **planning/**: 规划分析文档

### 文件规范
- 英文文档：全小写，kebab-case（如 `core-systems.md`）
- 中文文档：直接使用中文名（如 `玩家系统.md`）
- 避免前缀，通过目录结构表达分类

---

## 开发流程

1. **阅读开发规范** → [CLAUDE.md](../CLAUDE.md)
2. **理解架构** → [core-systems.md](architecture/core-systems.md)
3. **学习模块** → [guides/](guides/) 目录
4. **开发验证** → 对应GYM场景
5. **提交代码** → 遵循Git提交规范
