# 准星系统实现报告

## 一、当前准星状态

准星已恢复到**原版行为**：鼠标跟随 + 旋转动画。drift/bloom 机制仅影响子弹方向，不影响准星显示。

---

## 二、准星与瞄准系统的关系

### 2.1 数据流

```
鼠标位置 → BaseGun._process() 计算 direction（含drift偏移）
                ↓
        ┌───────┴───────┐
        ↓               ↓
   子弹发射角度      Hero.gd 枪械朝向
  get_shoot_angle()  gun.look_at(dir*1000)
  (drift + bloom)     (仅drift)
        ↓               ↓
   子弹实际飞行方向   枪口视觉朝向
```

### 2.2 准星当前不反映的信息

| 信息 | 当前状态 | 说明 |
|------|---------|------|
| 鼠标位置 | 准星跟随 | 正常 |
| Drift 偏移 | 不显示 | 枪口实际朝向偏离鼠标，准星看不到 |
| Bloom 散布 | 不显示 | 子弹随机散布范围，准星看不到 |
| 实际瞄准点 | 不显示 | drift + bloom 后子弹真正飞向的位置 |

### 2.3 核心问题

**玩家移动鼠标 → 准星跟随鼠标 → 但子弹飞向 drift 偏移后的方向**

这意味着：准星指向的位置 ≠ 子弹飞向的位置。如果不做准星可视化，玩家会感觉"子弹打不准"，因为看不到偏移。

---

## 三、准星可视化方案对比

### 方案 A：准星不动，仅子弹偏移（当前状态）

- 准星始终在鼠标位置
- 子弹朝 drift + bloom 方向飞
- **优点**：准星稳定不抖动，实现简单
- **缺点**：玩家看不到偏移，感觉子弹"打不准"

### 方案 B：准星跟随 drift 偏移

- 准星从鼠标位置偏移到 drift 方向
- bloom 用圆环/扩散表示
- **优点**：准星 = 实际瞄准方向，所见即所得
- **缺点**：准星会偏离鼠标，射击时准星"漂走"可能让玩家不适

### 方案 C：双层准星（推荐）

- 外层准星：跟随鼠标位置（玩家意图）
- 内层准星/点：跟随 drift 偏移（实际瞄准方向）
- Bloom Ring：围绕内层准星的圆环，表示散布范围
- **优点**：同时显示意图和实际，信息完整
- **缺点**：视觉复杂度增加，需要好的美术设计

### 方案 D：代码绘制准星

- 不用图片纹理，用 `_draw()` 绘制圆环、十字线、中心点
- **优点**：完全可控，无需纹理资源，风格统一
- **缺点**：需要编写绘制代码，风格可能与游戏美术不统一

---

## 四、之前 InnerDot/BloomRing 实现的问题

### 4.1 InnerDot 偏移计算错误

```gdscript
# 错误代码
var drift_offset = gun.direction * deg_to_rad(gun.drift_current) * 50
```

问题：
- `gun.direction` 是单位方向向量
- `deg_to_rad(drift_current)` 将度数转弧度，结果是一个 0~0.17 的小数
- 方向向量 × 弧度值 = 方向和大小都在变化的向量
- 当 drift_current 变化时，偏移量变化不线性，导致抖动

**正确做法**：
```gdscript
# drift_current 是度数，直接乘以像素系数
var drift_offset = gun.direction * gun.drift_current * 2.0  # 2.0 = 像素/度
```

### 4.2 BloomRing 缩放抖动

```gdscript
var bloom_scale = 1.0 + (gun.bloom_current / gun.bloom_max) * 2.0
```

问题：
- 每帧 bloom_current 都在变化（射击增加，恢复减少）
- 缩放变化没有平滑过渡，导致 Ring 大小不停跳动

**正确做法**：
```gdscript
# 用 lerp 平滑过渡
var target_scale = 1.0 + (gun.bloom_current / gun.bloom_max) * 2.0
bloom_ring.scale = bloom_ring.scale.lerp(Vector2(target_scale, target_scale), 0.15)
```

### 4.3 InnerDot/BloomRing 无纹理

两个节点都是纯色 TextureRect（白色方块），没有纹理资源，看起来不像准星。

---

## 五、推荐实现路径

1. **先确认方案**：选择 A/B/C/D 之一
2. **如果选 C（双层准星）**：
   - 需要为 InnerDot 和 BloomRing 准备纹理资源（圆点 + 圆环）
   - 或者用方案 D（代码绘制）替代纹理
3. **修复偏移计算**：用 `direction * drift_current * pixel_scale` 替代错误公式
4. **添加平滑过渡**：所有动态缩放/偏移用 lerp 过渡
5. **数值调参**：pixel_scale 系数需要根据准星大小和 drift_max 调整

---

## 六、文件清单

| 文件 | 作用 |
|------|------|
| `ui/widgets/Crosshair.gd` | 准星脚本，控制位置和动态效果 |
| `ui/widgets/Crosshair.tscn` | 准星场景，定义节点结构 |
| `game/guns/BaseGun.gd` | 提供 `drift_current`、`bloom_current`、`direction` 数据 |
| `Sprites/crosshair186.png` | 当前准星纹理 |
