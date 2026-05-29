# UI系统模块学习指导

## 一、核心文件

- `ui/GameUI.gd` - 游戏主界面
- `ui/widgets/Crosshair.gd` - 准星
- `ui/widgets/HitLabel.gd` - 伤害数字

## 二、核心代码解析

### 2.1 游戏UI主界面

```gdscript
extends CanvasLayer

@onready var hp_bar = $HUD/HPBar
@onready var ammo_label = $HUD/AmmoLabel

func _ready():
    PlayerData.onHpChange.connect(updateHpBar)
    PlayerData.onAmmoChange.connect(updateAmmo)

func updateHpBar(hp, max_hp):
    hp_bar.value = hp / max_hp
```

### 2.2 伤害数字

```gdscript
extends Label

func _ready():
    get_tree().create_timer(1.0).timeout.connect(queue_free)

func _process(delta):
    position.y -= 100 * delta
    modulate.a -= delta
```

### 2.3 背包系统

```gdscript
extends Panel

@onready var grid_container = $GridContainer
var items = {}

func toggle():
    visible = !visible

func add_item(item):
    items[item.id] = item
```

## 三、代码练习题

### 练习1：血量条渐变

```gdscript
func updateHpBar(hp, max_hp):
    var percent = hp / max_hp
    hp_bar.value = percent
    
    if percent > 0.5:
        hp_bar.modulate = Color.lerp(Color.GREEN, Color.YELLOW, (0.5 - percent) * 2)
    else:
        hp_bar.modulate = Color.lerp(Color.YELLOW, Color.RED, (0.5 - percent) * 2)
```

### 练习2：经验条

```gdscript
@onready var exp_bar = $HUD/ExpBar

func _ready():
    PlayerData.onPlayerExpChange.connect(updateExpBar)

func updateExpBar(exp, max_exp):
    exp_bar.value = exp / max_exp
```

## 四、扩展方向

1. **动态HUD** - 战斗状态、技能冷却
2. **成就UI** - 成就列表和奖励展示
3. **商城系统** - 商品展示和购买