# 瞄准系统重设计（Aim Drift + Bloom）开发可行性分析

## 一、总体评估：可行，需补充细节

设计文档对核心机制的描述清晰，双层偏移模型（Drift + Bloom）逻辑自洽，与现有代码架构兼容度高。但存在若干未覆盖的边界情况和实现细节，需在开发前明确。

---

## 二、逐模块可行性分析

### 2.1 BaseGun.gd — 可行性：高

**现状**：`_process()` 中 `direction = (mouse_pos - gun_tip.global_position).normalized()`，子弹永远精准。

**改动内容**：新增 8 个 `@export` 属性 + 4 个运行时变量 + `_apply_recoil()` / `get_shoot_angle()` 方法 + 修改 `_process()` 恢复逻辑。

**可行性评估**：
- 新增属性和方法：纯增量修改，不影响现有逻辑
- `_process()` 恢复逻辑：`move_toward()` 是 Godot 内置函数，适合此场景
- `get_shoot_angle()` 中 `randf_range(-bloom_current, bloom_current)` 实现简单

**需注意的问题**：

1. **Drift 偏移方向问题**：设计文档写 `drift_angle = base_angle + deg_to_rad(drift_current)`，这会让偏移永远朝逆时针方向。实际应该模拟"后坐力把枪口推偏"，偏移方向应与射击方向一致（即沿射击方向向外推）。建议改为：
   ```gdscript
   # drift 沿射击反方向偏移（模拟后坐力上抬）
   var drift_angle = base_angle - deg_to_rad(drift_current)
   ```
   或者更真实的做法是让 drift 有方向性（如向上偏移），而非单纯角度加减。

2. **`_is_firing` 标记时机**：设计文档在 `_process()` 末尾设 `_is_firing = false`，在 `_apply_recoil()` 中设 `_is_firing = true`。但如果 `_shoot()` 和 `_process()` 不在同一帧执行（`_shoot()` 通过 `call_deferred` 调用），可能导致标记不准确。需确认时序。

3. **武器切换时 drift 不恢复**：`set_use(false)` 会调用 `set_process(false)`，导致 `_process()` 不再执行，drift 无法自然恢复。建议在 `set_use()` 中手动重置 drift/bloom。

### 2.2 各武器脚本 — 可行性：中高

**现状**：所有常规枪械遵循统一模式（计算鼠标方向 → 设置 gun_tip.rotation → 创建子弹 → 设置子弹旋转 → fire）。

**改动内容**：在 `_shoot()` 中调用 `_apply_recoil()`，用 `get_shoot_angle()` 替代直接鼠标方向计算。

**需注意的问题**：

| 枪械 | 问题 | 严重度 |
|------|------|--------|
| **GunSprite.gd** | 未调用 `super._shoot()`，有重复逻辑（自行管理 `can_shoot`/`timer`），需先修复此问题再添加 drift/bloom | 高 |
| **BoomBoi.gd** | 使用 RayCast2D 而非子弹，设计文档未说明激光武器如何应用 drift/bloom | 高 |
| **BabyZapZap.gd** | 三连射，每发间隔 0.15s，drift 应在每发间累积还是仅首发累积？ | 中 |
| **EmpireShotgun.gd** | 两轮连射，间隔 0.2s，同上问题 | 中 |
| **RebalShotgun.gd** | 5 发散弹 + 自动换弹，bloom 叠加逻辑需确认 | 低 |
| 其余枪械 | 统一模式，改动一致 | 低 |

### 2.3 Hero.gd — 可行性：高

**现状**：`gun.look_at(get_global_mouse_position())` 直接朝向鼠标。

**改动内容**：改为 `gun.look_at(gun.global_position + gun.direction * 1000)`，让枪朝向 drift 修正后的方向。

**可行性评估**：
- 逻辑清晰，`gun.direction` 已在 BaseGun._process() 中被 drift 修正
- `setGunLookat()` 也需同步修改参数（从鼠标位置改为 drift 方向），否则角色朝向会与枪朝向不一致

**需注意**：`setGunLookat()` 内部用 `dir.x` 判断角色翻转方向，传入 drift 方向后需确认翻转逻辑仍然正确。

### 2.4 Camera2D.gd — 可行性：高

**现状**：有鼠标偏移逻辑（制造晃动感）和射击震动。

**改动内容**：移除鼠标偏移，弱化射击震动（幅度降至 30%，时长缩短）。

**可行性评估**：改动简单直接，风险低。移除鼠标偏移后相机仅平滑跟随玩家，体验更稳定。

**需注意**：当前相机跟随逻辑每 5 帧更新一次（`Engine.get_process_frames() % 5 == 0`），移除鼠标偏移后应改为每帧更新，否则会有卡顿感。

### 2.5 Crosshair.gd — 可行性：中

**现状**：准星仅一个 TextureRect + AnimationPlayer，无 InnerDot/BloomRing 节点。

**改动内容**：添加 Bloom Ring 可视化（散布范围圆环）和 Inner Dot（实际瞄准点偏移指示）。

**需注意的问题**：
1. **场景文件需修改**：当前 `Crosshair.tscn` 没有 InnerDot 和 BloomRing 子节点，需要添加新节点（可能需要新的纹理资源）
2. **Bloom Ring 纹理**：需要一个圆环纹理来表示散布范围，当前项目可能没有此资源
3. **Inner Dot 偏移计算**：设计文档中 `drift_offset = gun.direction * deg_to_rad(gun.drift_current) * 50`，这个 `50` 是硬编码的像素系数，需要根据实际准星大小调整
4. **AnimationPlayer 冲突**：当前准星有呼吸动画（缩放），新增的 bloom 缩放可能与现有动画冲突

### 2.6 BaseAttachment.gd — 可行性：高

**现状**：配件系统有 `onStart()`/`onDestroy()` 生命周期方法，通过修改 PlayerData 属性影响武器。

**改动内容**：新增 6 个 `@export` 修正属性（百分比修正）。

**可行性评估**：
- 属性添加简单
- 但需在 `BaseGun` 中实现修正计算逻辑（如 `effective_drift_accumulation = drift_accumulation * (1 + sum_of_attachment_mods)`），设计文档未给出此部分实现

---

## 三、设计文档未覆盖的关键问题

### 3.1 激光武器（BoomBoi）的处理

BoomBoi 使用 RayCast2D 而非子弹，drift/bloom 如何影响射线方向？建议方案：
- **方案 A**：激光武器不受 drift/bloom 影响（保持精准，作为武器特色）
- **方案 B**：drift 影响射线方向，bloom 表现为射线宽度/偏移

### 3.2 多发延迟射击的 drift 累积

BabyZapZap（三连射，间隔 0.15s）和 EmpireShotgun（两轮连射，间隔 0.2s）在单次扣扳机中多次发射。drift 应该：
- **方案 A**：每发都累积 drift（更真实，连射惩罚更大）
- **方案 B**：仅首次扣扳机累积一次（更简单，惩罚较小）

### 3.3 GunSprite.gd 的 super._shoot() 缺失

GunSprite 没有调用 `super._shoot()`，且自行管理 `can_shoot` 和 `timer`。添加 drift/bloom 前，需先统一其行为与其他枪械一致。

### 3.4 配件修正值的生效方式

设计文档新增了 6 个 `@export` 修正属性，但未说明 BaseGun 如何读取和应用这些修正。需要在 `BaseGun` 中添加一个方法来汇总所有配件的修正值，并在计算 drift/bloom 时使用修正后的值。

### 3.5 drift 方向的物理合理性

当前实现 `base_angle + deg_to_rad(drift_current)` 始终朝一个方向偏移，不够真实。建议：
- 偏移方向应为射击反方向（模拟后坐力上抬/偏移）
- 或添加轻微随机性，让 drift 方向不完全确定

---

## 四、工作量估算

| 模块 | 改动量 | 复杂度 |
|------|--------|--------|
| BaseGun.gd（核心系统） | ~80 行新增/修改 | 中 |
| Hero.gd | ~5 行修改 | 低 |
| Camera2D.gd | ~15 行修改 | 低 |
| Crosshair.gd + tscn | ~30 行新增 + 场景修改 | 中 |
| 常规枪械脚本（5个） | 每个 ~10 行修改 | 低 |
| 散弹枪脚本（3个） | 每个 ~15 行修改 | 中 |
| 特殊武器（BoomBoi/BabyZapZap） | 每个 ~15 行修改 | 中 |
| GunSprite.gd（需先修复） | ~15 行修改 | 中 |
| BaseAttachment.gd | ~10 行新增 | 低 |
| 配件修正生效逻辑 | ~20 行新增 | 中 |
| **调试可视化** | ~30 行新增 | 低 |

---

## 五、建议开发顺序

1. **先修复 GunSprite.gd**：统一 `super._shoot()` 调用，消除重复逻辑
2. **BaseGun.gd 核心**：添加 drift/bloom 属性、运行时变量、恢复逻辑、`_apply_recoil()` 和 `get_shoot_angle()`
3. **Hero.gd 修改**：枪械朝向改为跟随 `gun.direction`
4. **Camera2D.gd 修改**：移除鼠标偏移，弱化震动
5. **常规枪械适配**：Uzi、Sniper、AlienRifle、AlienMachine、GunSprite
6. **散弹枪适配**：ShotgunBlaster、RebalShotgun、EmpireShotgun
7. **特殊武器适配**：BoomBoi、BabyZapZap（需先确定方案）
8. **Crosshair 可视化**：添加 Bloom Ring 和 Inner Dot
9. **BaseAttachment 扩展**：新增修正属性和生效逻辑
10. **调试可视化**：BaseGun._draw() 辅助线
11. **数值调参**：按文档建议顺序（drift → bloom → recovery）

---

## 六、结论

**开发可行性：可行**，核心机制设计合理，与现有架构兼容。主要风险点：

1. **GunSprite.gd 的非标准实现**需先修复（阻塞项）
2. **BoomBoi 激光武器**的处理方案需明确（设计决策）
3. **多发延迟射击**的 drift 累积策略需明确（设计决策）
4. **Crosshair 场景**需新增节点和纹理资源（资源依赖）
5. **配件修正生效**的具体实现方式需补充（设计补充）

建议在开始开发前，先对上述 5 个风险点做出明确决策。
