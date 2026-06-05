
# 瞄准系统重设计文档：射击累积偏移（Aim Drift + Bloom）

## 一、当前系统问题诊断

### 1.1 现有瞄准链路

```
鼠标位置 → gun.look_at(鼠标) → direction = 鼠标方向 → 子弹沿direction发射
                                                                  ↑
                                                            零偏差，永远精准
```

当前系统中，**子弹永远精确飞向鼠标指针**，不存在任何偏移机制。

### 1.2 现有"后坐力"实际效果

| 机制 | 代码位置 | 实际效果 | 问题 |
|-----|---------|---------|------|
| 玩家击退 | [Hero.gd:103-107](file:///d:/Projects/Godot/TowDownGame/game/hero/Hero.gd#L103-L107) | 玩家角色被推后退 | 对瞄准无影响，仅位移角色 |
| 相机震动 | [Camera2D.gd:33-43](file:///d:/Projects/Godot/TowDownGame/game/hero/Camera2D.gd#L33-L43) | 相机偏移后回弹 | 纯视觉抖动，无游戏意义 |
| 相机鼠标偏移 | [Camera2D.gd:11-23](file:///d:/Projects/Godot/TowDownGame/game/hero/Camera2D.gd#L11-L23) | 相机朝鼠标方向偏移 | 造成"晃动感"，干扰瞄准 |
| 枪械recoil属性 | [BaseGun.gd:23](file:///d:/Projects/Godot/TowDownGame/game/guns/BaseGun.gd#L23) | 触发玩家击退 | 不影响弹道方向 |

**核心问题**：所有"后坐力"效果都作用于玩家位移或相机抖动，**没有任何机制影响子弹飞行方向**。玩家感受就是"画面在晃"但"子弹永远精准"——晃动没有游戏意义。

### 1.3 霰弹枪的固定散布

[ShotgunBlaster.gd:13](file:///d:/Projects/Godot/TowDownGame/game/guns/ShotgunBlaster.gd#L13) 中有唯一的散布机制：

```gdscript
b.rotation = gun_tip.rotation + deg_to_rad(-15 + i * 15)
```

但这是**固定角度**（-15°, 0°, 15°），不会随连续射击变化。

---

## 二、新系统设计：Aim Drift + Bloom

### 2.1 设计理念

**核心原则**：连续射击 → 瞄准点逐渐偏移 → 停止射击 → 瞄准恢复

```
旧系统：鼠标位置 ════════════════> 子弹方向（永远精准）
新系统：鼠标位置 ──> + Aim Drift ──> + Bloom ──> 子弹方向
                   (累积偏移)      (随机散布)
```

### 2.2 双层偏移模型

#### Layer 1：Aim Drift（瞄准漂移）—— 确定性偏移

**定义**：连续射击时，实际瞄准点从鼠标位置逐渐偏移。

**特性**：
- **方向性**：偏移方向沿射击方向向外推（模拟后坐力把枪口推偏）
- **累积性**：连续射击越多，偏移越大
- **有上限**：每把武器有最大偏移量
- **可恢复**：停止射击后，偏移逐渐回归零点
- **可补偿**：玩家可以看到偏移方向，反向移动鼠标来补偿

**为什么是"漂移"而非"随机抖动"**：
- 漂移是可预测的、可学习补偿的 → 有技巧深度
- 随机抖动是不可控的 → 只能靠运气
- 漂移让玩家有"压枪"的操作空间

#### Layer 2：Bloom（弹道散布）—— 随机性偏移

**定义**：在漂移后的瞄准点周围，子弹有随机角度偏移。

**特性**：
- **随机性**：每次射击的偏移角度随机
- **范围扩大**：连续射击使散布范围增大
- **有上限**：最大散布角度受武器限制
- **可恢复**：停止射击后散布范围缩小

**Bloom 与 Drift 的关系**：
- Drift 决定"瞄准点在哪里"
- Bloom 决定"子弹在瞄准点周围多散"

### 2.3 数值模型

```
实际射击方向 = 鼠标方向 + AimDrift偏移角度 + Bloom随机角度

AimDrift:
  drift_current: float    # 当前漂移量（度）
  drift_accumulation: float  # 每发增加的漂移（度/发）
  drift_max: float        # 最大漂移量（度）
  drift_recovery: float   # 恢复速度（度/秒）
  drift_recovery_delay: float  # 停止射击后多久开始恢复（秒）

Bloom:
  bloom_current: float    # 当前散布半径（度）
  bloom_per_shot: float   # 每发增加的散布（度/发）
  bloom_max: float        # 最大散布半径（度）
  bloom_recovery: float   # 恢复速度（度/秒）
  bloom_base: float       # 基础散布（首发也有微小散布）
```

### 2.4 武器差异化参数

| 武器 | drift_accumulation | drift_max | drift_recovery | bloom_per_shot | bloom_max | bloom_base | 手感定位 |
|-----|--------------------|-----------|----------------|----------------|-----------|------------|---------|
| 手枪 GunSprite | 1.5° | 8° | 25°/s | 1.0° | 6° | 0.5° | 精准，适合点射 |
| 霰弹枪 ShotgunBlaster | 2.0° | 10° | 20°/s | 2.0° | 12° | 3.0° | 本身有散布，偏移适中 |
| 狙击枪 Sniper | 3.0° | 6° | 15°/s | 0.5° | 3° | 0.2° | 单发高偏移，低散布 |
| 冲锋枪 Uzi | 0.8° | 15° | 35°/s | 1.5° | 10° | 1.0° | 快速偏移但恢复也快 |
| 外星步枪 AlienRifle | 1.2° | 12° | 28°/s | 1.2° | 8° | 0.8° | 均衡型 |
| 重机枪 AlienMachine | 0.5° | 20° | 20°/s | 0.8° | 15° | 1.5° | 持续压制，偏移缓慢但巨大 |

---

## 三、详细实现方案

### 3.1 BaseGun.gd 修改

**新增导出属性**：

```gdscript
@export_group("Aim Drift")
@export var drift_accumulation: float = 1.5
@export var drift_max: float = 10.0
@export var drift_recovery: float = 25.0
@export var drift_recovery_delay: float = 0.15

@export_group("Bloom")
@export var bloom_per_shot: float = 1.0
@export var bloom_max: float = 8.0
@export var bloom_base: float = 0.5
@export var bloom_recovery: float = 20.0
```

**新增运行时变量**：

```gdscript
var drift_current: float = 0.0
var bloom_current: float = 0.0
var _time_since_last_shot: float = 999.0
var _is_firing: bool = false
```

**修改 `_process` 中的瞄准计算**：

```gdscript
func _process(delta):
    if Utils.freeze_frame:
        delta = 0.0

    _time_since_last_shot += delta

    # 恢复逻辑
    if !_is_firing && _time_since_last_shot > drift_recovery_delay:
        drift_current = move_toward(drift_current, 0.0, drift_recovery * delta)
        bloom_current = move_toward(bloom_current, bloom_base, bloom_recovery * delta)

    _is_firing = false

    # 计算实际瞄准方向 = 鼠标方向 + drift偏移
    var mouse_pos = get_global_mouse_position()
    var base_direction = (mouse_pos - gun_tip.global_position).normalized()
    var base_angle = base_direction.angle()

    # drift 沿射击方向向外偏移（模拟后坐力把枪口推偏）
    var drift_angle = base_angle + deg_to_rad(drift_current)
    direction = Vector2.from_angle(drift_angle)

    # 枪口朝向实际瞄准方向
    gun_tip.rotation = drift_angle

    # 射击输入
    if Input.mouse_mode == Input.MOUSE_MODE_CONFINED_HIDDEN \
        && Input.is_action_pressed("shoot") \
        && can_shoot \
        && !is_reloading:
        can_shoot = false
        timer.start()
        if bullets_count > 0:
            _shoot()
        else:
            reload_ammo()

    if is_use && Input.is_action_pressed("reload"):
        reload_ammo()
```

**修改射击时应用偏移**：

```gdscript
func _apply_recoil():
    # 累积 drift
    drift_current = minf(drift_current + drift_accumulation, drift_max)
    # 累积 bloom
    bloom_current = minf(bloom_current + bloom_per_shot, bloom_max)
    _time_since_last_shot = 0.0
    _is_firing = true

func get_shoot_angle() -> float:
    # 实际射击角度 = 基础方向 + drift + bloom随机偏移
    var mouse_pos = get_global_mouse_position()
    var base_angle = (mouse_pos - gun_tip.global_position).normalized().angle()
    var drift_angle = base_angle + deg_to_rad(drift_current)
    var bloom_offset = deg_to_rad(randf_range(-bloom_current, bloom_current))
    return drift_angle + bloom_offset
```

### 3.2 各武器脚本修改

**Uzi.gd 示例**：

```gdscript
func _shoot():
    super._shoot()
    _apply_recoil()

    var shoot_angle = get_shoot_angle()
    gun_tip.rotation = shoot_angle

    var b = bullet_scene.instantiate()
    b.setOnwer(player)
    get_tree().root.add_child(b)
    b.position = gun_tip.global_position
    b.rotation = shoot_angle
    fire(b)
```

**ShotgunBlaster.gd 示例**：

```gdscript
func _shoot():
    super._shoot()
    _apply_recoil()

    var shoot_angle = get_shoot_angle()
    gun_tip.rotation = shoot_angle

    for i in 3:
        var b = bullet_scene.instantiate()
        b.setOnwer(player)
        get_tree().root.add_child(b)
        b.position = gun_tip.global_position
        # 霰弹枪：基础散布 + bloom叠加
        var pellet_spread = deg_to_rad(-10 + i * 10)
        b.rotation = shoot_angle + pellet_spread + deg_to_rad(randf_range(-bloom_current * 0.3, bloom_current * 0.3))
        fire(b, true, i == 0)
```

### 3.3 Hero.gd 修改

**简化瞄准逻辑**：枪械不再直接 `look_at` 鼠标，而是由 BaseGun._process 中的 drift 计算来决定朝向。

```gdscript
func _physics_process(delta):
    if is_dead:
        return
    if Utils.freeze_frame:
        delta = 0.0
    var direction = Input.get_vector("left", "right", "up", "down")
    if is_knockback:
        if direction != Vector2.ZERO && SPEED < knockback_speed:
            velocity = (SPEED - knockback_speed) * global_position.direction_to(get_global_mouse_position())
        else:
            velocity = -knockback_speed * global_position.direction_to(get_global_mouse_position())
    else:
        velocity = direction * SPEED
    if is_dash:
        velocity = direction * 600
    move_and_slide()
    changeAnim(direction)

    if gun:
        # 枪朝向实际瞄准方向（已包含drift偏移），而非鼠标
        gun.look_at(gun.global_position + gun.direction * 1000)
        setGunLookat(gun.direction)
```

**移除或弱化击退后坐力**：现在后坐力通过 aim drift 体现，角色物理击退可以保留但应大幅减弱。

```gdscript
# BaseGun.fire() 中：
if recoil > 0 && is_bullet:
    # 击退力度减半，因为主要后坐力已转为aim drift
    player.set_knockback(recoil * 0.3)
```

### 3.4 Camera2D.gd 修改

**移除鼠标偏移**：这是造成"晃动感"的主要原因。

```gdscript
func _process(_delta: float) -> void:
    # 移除鼠标偏移逻辑，相机仅平滑跟随玩家
    if Utils.player:
        var target = Utils.player.global_position
        position = position.lerp(target, 0.1)
        position = Vector2(int(position.x), int(position.y))

    if center_horizontal:
        global_position.x = center_horizontal_pos
    if center_vertical:
        global_position.y = center_vertical_pos
```

**弱化射击震动**：保留轻微反馈，但幅度大幅降低。

```gdscript
func shootShake(_step):
    if int(Utils.shake) == 0:
        return
    if is_shake:
        return
    is_shake = true
    _step *= Utils.shake * 0.3  # 幅度降至30%
    var tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
    tween.tween_property(self, "offset", _step, 0.05)  # 时长缩短
    tween.tween_property(self, "offset", Vector2.ZERO, 0.05)
    tween.tween_callback(func end():
        is_shake = false)
```

### 3.5 Crosshair.gd 修改 —— 可视化 Bloom

准星需要展示当前偏移状态：

```gdscript
@tool
extends TextureRect

var rotation_speed = PI

@onready var inner_crosshair: TextureRect = $InnerDot
@onready var bloom_ring: TextureRect = $BloomRing

func _ready() -> void:
    set_process(false)
    Utils.onGameStart.connect(onGameStart)

func onGameStart():
    set_process(true)
    Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN

func _process(delta: float) -> void:
    rotation += rotation_speed * delta

    var gun = Utils.player.gun if Utils.player else null
    if gun:
        # 准星中心跟随鼠标
        global_position = get_global_mouse_position() - size / 2

        # Bloom Ring 大小随当前散布变化
        var bloom_scale = 1.0 + (gun.bloom_current / gun.bloom_max) * 2.0
        if bloom_ring:
            bloom_ring.scale = Vector2(bloom_scale, bloom_scale)

        # Inner Dot 偏移显示实际瞄准点
        if inner_crosshair:
            var drift_offset = gun.direction * deg_to_rad(gun.drift_current) * 50
            inner_crosshair.position = drift_offset
    else:
        global_position = get_global_mouse_position() - size / 2
```

---

## 四、系统行为对比

### 4.1 旧系统 vs 新系统

| 场景 | 旧系统 | 新系统 |
|-----|-------|-------|
| 单发射击 | 子弹精准命中鼠标位置 | 子弹几乎精准（仅bloom_base微小偏移） |
| 连续射击5发 | 子弹全部精准命中，画面在抖 | 瞄准点逐渐偏移，子弹开始偏离鼠标 |
| 长按扫射 | 子弹永远精准，画面剧烈抖动 | 瞄准点大幅偏移+散布增大，需要压枪 |
| 停止射击0.5s | 无变化 | 瞄准逐渐恢复到鼠标位置 |
| 狙击枪连射 | 精准但画面抖 | 大幅偏移，惩罚连射 |
| 冲锋枪扫射 | 精准但画面抖 | 偏移快但恢复也快，适合短点射 |

### 4.2 玩家操作变化

**旧系统**：按住射击键 → 画面抖动 → 无需任何瞄准调整
**新系统**：按住射击键 → 看到准星偏移 → 反向移动鼠标补偿（压枪）→ 或停射击恢复

---

## 五、附件系统扩展

现有配件可以增加影响瞄准的属性：

| 附件 | 新增效果 |
|-----|---------|
| QuickdrawMagazine | drift_recovery +20% |
| UniversalExtendedMagazines | bloom_max +15% |
| 瞄准镜类（未来） | bloom_base -50%, bloom_max -30% |
| 枪口类（未来） | drift_accumulation -20% |
| 枪托类（未来） | drift_max -25%, drift_recovery +15% |

在 `BaseAttachment.gd` 中新增：

```gdscript
@export var drift_accumulation_mod: float = 0.0    # 百分比修正
@export var drift_max_mod: float = 0.0
@export var drift_recovery_mod: float = 0.0
@export var bloom_per_shot_mod: float = 0.0
@export var bloom_max_mod: float = 0.0
@export var bloom_base_mod: float = 0.0
```

---

## 六、修改文件清单

| 文件 | 修改类型 | 修改内容 |
|-----|---------|---------|
| [BaseGun.gd](file:///d:/Projects/Godot/TowDownGame/game/guns/BaseGun.gd) | **核心修改** | 新增drift/bloom系统，修改瞄准计算 |
| [Hero.gd](file:///d:/Projects/Godot/TowDownGame/game/hero/Hero.gd) | 中等修改 | 枪械朝向改为跟随gun.direction，弱化击退 |
| [Camera2D.gd](file:///d:/Projects/Godot/TowDownGame/game/hero/Camera2D.gd) | 中等修改 | 移除鼠标偏移，弱化震动 |
| [Crosshair.gd](file:///d:/Projects/Godot/TowDownGame/ui/widgets/Crosshair.gd) | 中等修改 | 添加bloom可视化 |
| [Uzi.gd](file:///d:/Projects/Godot/TowDownGame/game/guns/Uzi.gd) | 小修改 | 使用get_shoot_angle() |
| [Sniper.gd](file:///d:/Projects/Godot/TowDownGame/game/guns/Sniper.gd) | 小修改 | 使用get_shoot_angle() |
| [ShotgunBlaster.gd](file:///d:/Projects/Godot/TowDownGame/game/guns/ShotgunBlaster.gd) | 小修改 | bloom叠加到固定散布上 |
| 其他武器脚本 | 小修改 | 使用get_shoot_angle() |
| [BaseAttachment.gd](file:///d:/Projects/Godot/TowDownGame/game/attachments/BaseAttachment.gd) | 小修改 | 新增瞄准修正属性 |

---

## 七、调试与平衡建议

### 7.1 调试可视化

开发阶段建议在屏幕上绘制辅助线：

```
- 白线：鼠标方向（期望瞄准方向）
- 红线：实际射击方向（含drift + bloom）
- 绿圈：当前bloom范围
```

可在 BaseGun._draw() 中实现，通过调试开关控制。

### 7.2 平衡调参要点

1. **drift_accumulation** 决定"多快偏移"—— 这是核心手感参数
2. **drift_max** 决定"最差能偏多远"—— 控制惩罚上限
3. **drift_recovery** 决定"恢复多快"—— 影响射击节奏
4. **bloom_base** 决定"首发精准度"—— 0.5°左右让首发几乎必中
5. **bloom_max** 决定"最散能散多远"—— 控制扫射惩罚

**调参原则**：
- 先调drift，让偏移手感对
- 再调bloom，让散布范围合理
- 最后调recovery，让节奏舒服
- 所有数值以"度"为单位，方便直观理解
