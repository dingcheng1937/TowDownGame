# 核心系统设计文档

> 基于 TowDownGame (Godot 4.6) 项目分析，涵盖玩家移动、敌人追击、受击、死亡四大系统。

---

## 目录

1. [整体类层次结构](#1-整体类层次结构)
2. [玩家移动系统](#2-玩家移动系统)
3. [敌人追击系统](#3-敌人追击系统)
4. [受击/伤害系统](#4-受击伤害系统)
5. [死亡系统](#5-死亡系统)
6. [系统间连接关系](#6-系统间连接关系)
7. [关键全局单例](#7-关键全局单例)

---

## 1. 整体类层次结构

```
CharacterBody2D
├── Player (Hero.gd)              -- 玩家角色
├── BaseMonster (BaseMonster.gd)  -- 怪物基类
│   ├── Monster1                  -- 基础近战怪物
│   ├── Monster2                  -- 带攻击区域的近战怪物
│   ├── Ghoul                     -- 食尸鬼
│   ├── Aberration                -- 畸变体（诡异怪物，高血量+冲锋）
│   ├── Shade                     -- 残影（诡异怪物，高速+冲刺+理智伤害）
│   └── Whisperer                 -- 低语者（诡异怪物，远程+理智降低光环）
└── Bullet (Bullet.gd)            -- 子弹基类
    └── SmpBullet                 -- 简单子弹

Node2D
├── BaseFrame (BaseFrame.gd)      -- 基础帧，处理冻结帧逻辑
└── BaseGun (BaseGun.gd)          -- 枪械基类
    └── 各种具体枪械

Node
├── BaseReward (BaseReward.gd)    -- 奖励/被动道具基类
├── PlayerData (Autoload)         -- 玩家数据单例
├── Utils (Autoload)              -- 全局工具单例
├── PlayerServer (Autoload)       -- 玩家场景实例管理
└── LevelServer (Autoload)        -- 关卡/回合管理
```

**关键文件路径**：

| 文件 | 路径 |
|------|------|
| BaseFrame | `game/BaseFrame.gd` |
| Player | `game/hero/Hero.gd` |
| BaseMonster | `game/monster/BaseMonster.gd` |
| Bullet | `game/bullets/Bullet.gd` |
| PlayerData | `autoload/PlayerData.gd` |
| Utils | `autoload/Utils.gd` |
| PlayerServer | `autoload/server/PlayerServer.gd` |
| LevelServer | `autoload/server/LevelServer.gd` |

---

## 2. 玩家移动系统

### 类定义

`class_name Player, extends CharacterBody2D` — `game/hero/Hero.gd`

### 输入映射（定义在 project.godot）

| 动作名 | 按键 |
|--------|------|
| `up` | W / 上箭头 |
| `down` | S / 下箭头 |
| `left` | A / 左箭头 |
| `right` | D / 右箭头 |
| `dash` | Shift |
| `shoot` | 鼠标左键 |
| `reload` | R |
| `inv` | Tab |
| `e` | E |

### 核心移动逻辑

#### 基础移动（`_physics_process`）

```gdscript
var direction = Input.get_vector("left", "right", "up", "down")
velocity = direction * SPEED
move_and_slide()
```

- 基础 `SPEED = 100.0`
- 通过 `updateHero()` 受 `PlayerData.player_speed` 加成：`SPEED = 100 * PlayerData.player_speed`

#### 冲刺系统

- 按下 `dash` 键触发，`is_dash = true`
- 冲刺速度固定为 `600`（基础速度的6倍）
- 冲刺持续 `0.06` 秒后自动结束
- 冲刺时生成残影效果（`DashObj` 场景实例），残影使用当前动画帧的纹理

#### 击退系统（`set_knockback` 方法）

```gdscript
func set_knockback(knockback_speed):
    is_knockback = true
    # 击退方向：从玩家朝鼠标位置的反方向
    velocity = -knockback_speed * global_position.direction_to(get_global_mouse_position())
    # 如果同时有移动输入且基础速度 < 击退速度，则部分抵消
    if direction and SPEED < knockback_speed:
        velocity += (SPEED - knockback_speed) * global_position.direction_to(get_global_mouse_position())
    # 击退持续 0.05 秒后恢复
```

#### 朝向系统（`setGunLookat` 方法）

- 枪械始终 `look_at(鼠标位置)`
- 根据鼠标在玩家左侧还是右侧，翻转 `body.scale.x`（1 或 -1）实现角色面朝方向
- 灯光（PointLight2D）也跟随鼠标方向

#### 动画系统（`changeAnim` 方法）

| 状态 | 动画 |
|------|------|
| 冲刺中 | 残影效果 |
| 有方向输入 | `run` 或 `run_back`（背对鼠标时播放倒退动画） |
| 无输入 | `idle` |
| 死亡 | `die` |

#### 启动流程

- `_ready()` 中先 `set_physics_process(false)` 和 `set_process(false)` 禁用处理
- 当 `Utils.onGameStart` 信号发出时，才启用物理和逻辑处理

---

## 3. 敌人追击系统

### 基类定义

`class_name BaseMonster, extends CharacterBody2D` — `game/monster/BaseMonster.gd`

### 核心追踪逻辑（`_physics_process`）

```gdscript
var target_player: Player = Utils.player

func _physics_process(delta):
    if is_atk || is_die:
        return
    if hit:
        move_and_slide()  # 被击中时只保持击退惯性
        return

    # 简单直线追踪（无寻路）
    var current_agent_position = global_position
    var direction = current_agent_position.direction_to(target_player.global_position)
    velocity = direction * SPEED
    move_and_slide()
```

**注意**：代码中有 `NavigationAgent2D` 的声明但实际被注释掉，当前使用**简单直线追踪**。

### 状态控制

| 状态 | 效果 |
|------|------|
| `is_atk` | 攻击中，不移动 |
| `hit` | 被击中，只执行 `move_and_slide()` 保持击退惯性 |
| `STUN`（state_array） | 眩晕，不移动 |
| `is_die` | 死亡，停止一切 |

### 翻转系统（`flip_h` 方法）

根据 `velocity.x` 方向翻转精灵朝向。

### 怪物变体

| 怪物 | 脚本路径 | AI特点 |
|------|----------|--------|
| **Monster1** | `game/monster/Monster 1/Monster1.gd` | 纯追踪，无特殊攻击，仅碰撞伤害 |
| **Monster2** | `game/monster/Monster 2/Monster2.gd` | Area2D检测区域，进入后启动攻击循环（AtkTimer），播放攻击动画，第5帧对玩家造成伤害 |
| **Ghoul** | `game/monster/Ghoul/Ghoul.gd` | 基础追踪 |
| **Aberration** | `game/monster/weird/Aberration.gd` | 低速高血量，距离>200px时**冲锋**（3倍速，0.5s），30%减伤，碰撞造成物理+理智伤害 |
| **Shade** | `game/monster/weird/Shade.gd` | 高速低血量，距离<100px时**冲刺**（2.5倍速，0.3s），碰撞造成物理+理智伤害 |
| **Whisperer** | `game/monster/weird/Whisperer.gd` | 中速中血量，**远程攻击**（投射物，间隔2s），150px范围内持续降低玩家理智（2/秒） |

### 怪物属性注入

```gdscript
func setData(data):
    # data = {'speed': float, 'hp': int, 'hurt': int}
    SPEED = data.speed
    hp = data.hp
    hurt = data.hurt
```

属性由 `LevelServer.monster_attr` 定义，按30个关卡递增。

### 怪物生成系统

- **Town模式**：`LevelServer` 按回合定时生成，通过 `monsterCreate` 信号通知 `Town.gd` 创建 Monster2
- **SnowWorld模式**：`MonsterBuilder.gd` 定时生成 Ghoul，随时间提升等级（每60秒升1级）
- **生成位置**：随机选取地图 TileMap 上的格子，保证与玩家距离 > 200px

---

## 4. 受击/伤害系统

### 4.1 子弹 → 怪物

#### 子弹发射（`Bullet.gd`）

```gdscript
func fire():
    hurt += PlayerData.player_damage  # 加上玩家基础伤害加成
    velocity = Vector2(speed * 2, 0).rotated(rotation)
```

子弹属性：
- `hurt`：伤害值
- `knockback_speed`：击退速度
- `knockback_time`：击退时间

#### 碰撞检测（`Bullet._process`）

```gdscript
var collision = move_and_collide(velocity * delta)
if collision:
    var collider = collision.get_collider()
    if collider is BaseMonster:
        collider.hitFlash(collision, self)
    # 生成烟雾效果
    queue_free()  # 销毁子弹
```

#### 怪物受击（`BaseMonster.hitFlash`）

```gdscript
func hitFlash(collision, bullet):
    # 播放受击音效
    # 计算击退：speed = bullet.knockback_speed - knockback_def（减去击退抵抗）
    # 如果击退速度 > 0：
    #   velocity = 远离玩家方向 * 击退速度
    #   hit = true
    #   击退持续 bullet.knockback_time 秒后恢复
    onHit(bullet.hurt)
```

#### 伤害计算（`BaseMonster.onHit`）

```
1. 暴击判定：randf() < PlayerData.base_aim_enh → 伤害 × 1.5
2. 遍历 "reward" 组中所有 BaseReward：
   - 如果 connect_beforeAtk = true，调用 beforeAtk(monster, hit_num)，累加额外伤害
3. 最终伤害 = 原始伤害 + 额外伤害
4. HP -= 最终伤害
5. 如果 HP <= 0，调用 onDie()
6. 遍历 "reward" 组中所有 BaseReward：
   - 如果 connect_afterAtk = true，调用 afterAtk(monster, hit_num)
```

### 4.2 怪物 → 玩家

#### 近战攻击

- **Monster2**：Area2D 检测玩家进入 → 启动 AtkTimer → 播放攻击动画 → 第5帧调用 `area_player.onHit(hurt)`
- **Aberration/Shade**：`_on_body_entered` 碰撞检测 → 直接调用 `body.onHit(hurt)`

#### 远程攻击

- **Whisperer**：发射 `WhispererProjectile`（extends Area2D），投射物直线飞行，碰到玩家调用 `body.onHit(damage)` + `SanityServer.change_sanity(-sanity_damage)`

#### 玩家受击（`Hero.onHit`）

```
1. 遍历 "reward" 组中所有 BaseReward：
   - 如果 connect_beforePlayerHit = true，调用 beforePlayerHit(hurt)，累加伤害修正
2. hurt += temp_hurt（注意：这里是加上去，即增加受到的伤害）
3. 如果 hurt < 1，强制设为 1（最低伤害）
4. PlayerData.player_hp -= hurt（触发 setter）
5. 显示伤害数字：Utils.showHitLabel(hurt, self)
6. 通知 UI：get_tree().call_group("control", "hit")
7. 触发帧冻结：Utils.freezeFrame(0.1)
8. 遍历 "reward" 组中所有 BaseReward：
   - 如果 connect_afterPlayerHit = true，调用 afterPlayerHit(hurt)
```

#### HP setter（`PlayerData.gd`）

```gdscript
var player_hp = 5:
    set(value):
        player_hp = value
        emit_signal("onHpChange", player_hp, player_hp_max)
        if player_hp <= 0:
            emit_signal("onPlayerDeath")
```

- HP 变化时自动发出 `onHpChange` 信号
- HP ≤ 0 时发出 `onPlayerDeath` 信号

### 4.3 被动道具钩子系统（BaseReward）

| 钩子 | 触发时机 | 用途 |
|------|----------|------|
| `connect_beforeAtk` | 怪物受伤前 | 增加伤害 |
| `connect_afterAtk` | 怪物受伤后 | 攻击后效果 |
| `connect_beforePlayerHit` | 玩家受伤前 | 减少伤害 |
| `connect_afterPlayerHit` | 玩家受伤后 | 受伤后效果 |
| `connect_kill` | 击杀怪物后 | 击杀奖励 |

---

## 5. 死亡系统

### 5.1 玩家死亡

#### 触发链

```
PlayerData.player_hp <= 0
  → PlayerData 发出 onPlayerDeath 信号
```

#### Hero 中的处理（`Hero.onHpChange`）

```gdscript
func onHpChange(hp, max_hp):
    if hp <= 0:
        is_dead = true
        anim.play("die")
```

- 设置 `is_dead = true`
- 播放死亡动画
- `_physics_process` 开头检查 `if is_dead: return`，停止所有移动和输入处理

#### Town 地图中的死亡处理（`Town.onPlayerDeath`）

```gdscript
func onPlayerDeath():
    LevelServer.isPause(true)            # 暂停关卡计时
    var ins = death_borad.instantiate()   # 实例化死亡面板
    ins.setOnClick(func callback(success):
        if success:                       # 花费50金币复活
            LevelServer.isPause(false)
            PlayerData.resurrectPlayer(PlayerData.player_hp_max, 100)
        else:                             # 不花钱复活
            PlayerData.resurrectPlayer(1, 20)
            onRoundEnd()                  # 回合结束，重置位置
    )
    $CanvasLayer.add_child(ins)
```

#### 死亡面板（`DeathBoard.gd`）

- 继承 Control
- `_enter_tree` 时暂停游戏树：`get_tree().paused = true`
- 按钮1（花钱复活）：检查金币 ≥ 50，扣除50金币，回调 `click.call(true)`
- 按钮2（不花钱）：回调 `click.call(false)`
- 复活后取消暂停：`get_tree().paused = false`

#### 复活逻辑（`PlayerData.resurrectPlayer`）

```gdscript
func resurrectPlayer(hp, ammo_percentage):
    if hp >= player_hp_max:
        player_hp = player_hp_max
    else:
        player_hp = hp
    # 补充弹药到指定百分比
    if Utils.player.gun != null:
        var player_ammo_percentage = (player_ammo / Utils.player.gun.bullets_max_count) * 100
        if player_ammo_percentage < ammo_percentage:
            player_ammo = Utils.player.gun.bullets_max_count * ammo_percentage * 0.01
    emit_signal("onPlayerResurrect")
```

| 复活方式 | HP | 弹药 | 额外效果 |
|----------|-----|------|----------|
| 花费50金币 | 满血 | 100% | 无 |
| 不花钱 | 1 | 20% | 回合重置 |

#### Hero 复活处理（`Hero.onPlayerResurrect`）

```gdscript
func onPlayerResurrect():
    is_dead = false
    if anim:
        anim.play("idle")
```

### 5.2 怪物死亡

#### 触发

`BaseMonster.onHit` 中 HP ≤ 0 时调用 `onDie()`

#### 死亡流程（`BaseMonster.onDie`）

```
1. is_die = true
2. PlayerData.player_exp += 1（玩家获得1点经验）
3. 如果有 death_callback，调用它（用于 Town 模式的击杀统计和金币掉落）
4. 遍历 "reward" 组中所有 BaseReward：
   - 如果 connect_kill = true，调用 onKill(self)
5. set_physics_process(false)     -- 停止物理处理
6. 清除所有 EffectRoot 子节点（状态效果）
7. 禁用碰撞形状：CollisionShape2D.set_disabled(true)
8. 播放死亡动画：anim.play("die")
9. 缩小阴影效果（UndeadShadow scale → Vector2.ZERO，0.3秒）
10. 等待动画播放完毕
11. queue_free()                  -- 销毁节点
```

#### 诡异怪物的额外死亡逻辑

Aberration / Shade / Whisperer 死亡时额外调用 `ExtractionServer.register_kill()` 注册击杀（用于撤离系统）。

---

## 6. 系统间连接关系

```
输入系统 (Input Map)
    │ WASD / Shift / 鼠标
    ▼
Player._physics_process()  ──→  移动 + 冲刺
    │ 鼠标方向
    ▼
BaseGun._process()  ──→  射击判定
    │ 创建子弹
    ▼
Bullet._process()  ──→  move_and_collide 碰撞检测
    │ 碰撞 BaseMonster
    ▼
BaseMonster.hitFlash()  ──→  onHit() 伤害计算
    │ HP <= 0
    ▼
BaseMonster.onDie()  ──→  经验 / 掉落 / 销毁

怪物 AI (_physics_process)
    │ 追踪 Utils.player
    ▼
BaseMonster / 子类  ──→  接近 / 攻击玩家
    │ 碰撞 / 攻击动画帧
    ▼
Player.onHit()  ──→  PlayerData.player_hp -= hurt
    │ HP <= 0
    ▼
PlayerData.onPlayerDeath  ──→  Town.onPlayerDeath()
    │ 显示死亡面板
    ▼
DeathBoard  ──→  PlayerData.resurrectPlayer()
    │ 复活
    ▼
Player.onPlayerResurrect()  ──→  is_dead = false

BaseReward (被动道具钩子)
    ↕ beforeAtk / afterAtk / beforePlayerHit / afterPlayerHit / onKill
    贯穿整个伤害计算流程
```

---

## 7. 关键全局单例

| 单例 | 作用 |
|------|------|
| `Utils` | 全局工具、玩家引用（`Utils.player`）、冻结帧、伤害数字显示 |
| `PlayerData` | 玩家所有数据（HP、弹药、等级、经验、武器列表等），通过 setter 自动发信号 |
| `PlayerServer` | 管理 Player 场景实例的创建和位置 |
| `LevelServer` | 关卡回合管理、怪物属性表、计时器 |
| `SanityServer` | 理智系统（诡异怪物专属） |
| `EquipServer` | 装备系统 |
| `LootServer` | 掉落物系统 |
| `RewardServer` | 奖励系统 |
