# 玩家移动控制DEMO

直接复用原游戏的Hero场景和相机系统。

## 文件说明

- `CorrectDemo.tscn` - DEMO场景
- `DemoStarter.gd` - 启动器脚本，触发游戏启动流程

## 使用方法

1. 打开 `demo/CorrectDemo.tscn`
2. 按F5运行

## 控制

| 按键 | 功能 |
|------|------|
| WASD | 移动 |
| Space | 冲刺 |
| 鼠标 | 控制朝向 |

## 技术说明

复用原游戏架构：
- Hero场景实例化
- 相机系统：Anchor平滑跟随 + Camera2D偏移
- 启动流程：Utils.onGameStart信号
