# WorkBuddy ↔ Godot AI MCP 对接配置手册

> 适用版本：Godot 4.6.1 · WorkBuddy · godot-ai v2.6.0  
> 最后更新：2026-06-08

---

## 一、架构总览

对接由 **两层独立的 MCP 通道** 组成，需要分别配置：

```
┌─────────────────────────────────────────────────────────┐
│                    WorkBuddy                             │
│                                                          │
│  ┌─────────────────────────────────────┐                │
│  │  通道 A：godot-mcp (文件级操作)       │                │
│  │  ─────────────────────────────────   │                │
│  │  协议：stdio (子进程)                 │                │
│  │  通信：每次调用启动一次 Godot 无头进程  │                │
│  │  能力：读取项目信息、修改场景文件、       │                │
│  │        运行项目、获取运行日志            │                │
│  └─────────────────────────────────────┘                │
│                                                          │
│  ┌─────────────────────────────────────┐                │
│  │  通道 B：godot-ai (实时编辑器操作)     │                │
│  │  ─────────────────────────────────   │                │
│  │  协议：WebSocket (持久连接)           │                │
│  │  通信：Python MCP 服务器 ↔ Godot 编辑器               │
│  │  能力：实时场景编辑、节点属性修改、       │                │
│  │        脚本读写、截图/控制台捕获        │                │
│  └─────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────┘
```

---

## 二、通道 A：godot-mcp 配置（文件级操作）

### 2.1 安装 godot-mcp

通过 npm 安装 godot-mcp 包：

```bash
npm install -g @coding-solo/godot-mcp
```

或者通过 npx 按需调用（由 WorkBuddy 自动管理）。

### 2.2 配置 WorkBuddy MCP

编辑 WorkBuddy MCP 配置文件：

**文件路径：** `C:\Users\<用户名>\.workbuddy\mcp.json`

添加以下配置：

```json
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": [
        "@coding-solo/godot-mcp"
      ],
      "env": {
        "GODOT_PATH": "D:\\SOFTWARE\\Godot_v4.6.1-stable_win64_console.exe",
        "DEBUG": "true"
      },
      "disabled": false
    }
  }
}
```

| 配置项 | 说明 | 示例值 |
|--------|------|--------|
| `command` | 启动命令 | `"npx"` |
| `args` | 传递给命令的参数包名 | `["@coding-solo/godot-mcp"]` |
| `env.GODOT_PATH` | **必须**：Godot 可执行文件绝对路径 | `"D:\\SOFTWARE\\Godot_v4.6.1-stable_win64_console.exe"` |
| `env.DEBUG` | 可选：启用调试日志 | `"true"` |
| `disabled` | 是否禁用此 MCP 服务器 | `false` |

> **注意**：`GODOT_PATH` 指向的是 Godot 的**控制台版本**（`*_console.exe`），含终端输出日志。如果使用非控制台版本（标准 `*.exe`），某些工具（如 `get_debug_output`）可能无法捕获输出。

### 2.3 验证配置

配置完成后，在 WorkBuddy 中应该能看到 14 个 `mcp__godot__*` 工具可用：

```
mcp__godot__get_godot_version    # 获取 Godot 版本
mcp__godot__get_project_info     # 获取项目信息
mcp__godot__get_uid              # 获取文件 UID
mcp__godot__list_projects        # 列出项目
mcp__godot__launch_editor        # 启动编辑器
mcp__godot__run_project          # 运行项目
mcp__godot__stop_project         # 停止项目
mcp__godot__get_debug_output     # 获取调试输出
mcp__godot__create_scene         # 创建场景
mcp__godot__add_node             # 添加节点
mcp__godot__save_scene           # 保存场景
mcp__godot__load_sprite          # 加载精灵
mcp__godot__export_mesh_library  # 导出网格库
mcp__godot__update_project_uids  # 更新 UID
```

### 2.4 基本操作验证

```bash
# 1. 获取 Godot 版本
# → 应返回 "4.6.1.stable.official.14d19694e"

# 2. 获取项目信息
# → 应返回场景/脚本/资源数量统计

# 3. 获取文件 UID
# → 应返回类似 "uid://c62qppv7d21wk"

# 4. 运行主场景
# → 启动游戏后可使用 get_debug_output 查看输出
```

---

## 三、通道 B：godot-ai 插件配置（实时编辑器操作）

### 3.1 安装 godot-ai Python 服务器

godot-ai 需要 Python MCP 服务器，有两种安装方式：

#### 方式 A：通过 uvx 自动安装（推荐）

```bash
# 安装 uv 包管理器
# Windows (PowerShell):
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# 验证安装
uv --version

# WorkBuddy 的 godot-ai 插件会自动通过以下命令拉起服务器：
# npx uvx --from godot-ai==2.6.0 godot-ai
```

#### 方式 B：通过 pip 系统安装

```bash
pip install godot-ai
```

### 3.2 安装 Godot AI 编辑器插件

1. 打开 Godot 编辑器 → **AssetLib** 标签
2. 搜索 **"Godot AI MCP"** 或 **"godot-ai"**
3. 点击安装 → 勾选启用插件
4. 重启编辑器

或者直接从 GitHub 手动安装：

1. 下载最新版：[godot-ai releases](https://github.com/SingularityAI/godot-ai/releases)
2. 将 `addons/godot_ai/` 解压到项目 `res://addons/godot_ai/`
3. 在 **项目设置 → 插件** 中启用 `godot_ai`
4. 重启编辑器

### 3.3 验证插件状态

启用插件后，启动编辑器应看到以下输出：

```
MCP | adopted managed server (PID 25988, live v2.6.0, WS 9500, plugin v2.6.0)
MCP | plugin loaded
MCP | connected to server
MCP | [event] readiness -> ready
[godot_ai game_helper] registered mcp capture (debugger active=true, logger=true)
```

关键检查点：

| 日志信息 | 含义 |
|----------|------|
| `adopted managed server` | Python MCP 服务器已启动且版本匹配 |
| `plugin loaded` | 编辑器插件初始化完成 |
| `connected to server` | WebSocket 连接成功 |
| `readiness -> ready` | 插件完全就绪 |
| `registered mcp capture` | 游戏进程截图通道就绪 |

### 3.4 端口配置

默认端口：

| 端口 | 用途 | 配置文件 |
|------|------|---------|
| **8000** | HTTP (MCP 工具请求) | `godot_ai/http_port` |
| **9500** | WebSocket (编辑器通信) | `godot_ai/ws_port` |

若端口被占用（如 Hyper-V、WSL2、Docker），可在 **编辑器 → 编辑器设置 → 插件 → godot_ai** 中修改。

> **Windows 用户注意**：Hyper-V / WSL2 / Docker 可能保留 8000 端口，此时控制台会输出 `"MCP | port 8000 is reserved by Windows"`。请在编辑器设置中将 `http_port` 改为其他值（如 8080）。

### 3.5 第三方 AI 客户端对接

godot-ai 插件内置了对以下 AI 编辑器的客户端配置支持，可在插件 Dock 面板中一键配置：

| 客户端 | 配置类型 | 配置文件 |
|--------|---------|----------|
| **Claude Code** | CLI | `claude.json` / `~/.claude.json` |
| **Claude Desktop** | JSON | `claude_desktop_config.json` |
| **Cursor** | JSON | `.cursor/mcp.json` |
| **VS Code (Cline)** | JSON | `.vscode/mcp.json` |
| **VS Code Insiders** | JSON | `.vscode-insiders/mcp.json` |
| **Windsurf** | JSON | `.windsurf/mcp.json` |
| **Zed** | TOML | `.zed/config.json` |
| **Roo Code** | JSON | `.vscode/mcp.json` |
| **Kilo Code** | JSON | `.vscode/mcp.json` |
| **Kimi Code** | CLI | `kimi.json` |
| **Gemini CLI** | CLI | `gemini.json` |
| **Qwen Code** | CLI | `qwen_code.json` |
| **OpenCode** | CLI | `opencode.json` |
| **Codex** | CLI | `codex.json` |
| **Kiro** | JSON | `.kiro/mcp.json` |
| **Trae** | JSON | `.trae/mcp.json` |
| **Antigravity** | CLI | `antigravity.json` |
| **Cherry Studio** | JSON | `mcp_settings.json` |

配置方法（在 Godot 编辑器中）：

1. 打开 **项目 → 工具 → Godot AI MCP**
2. 在 Dock 面板中找到你的客户端
3. 点击 **Configure** 按钮
4. 插件会自动将 MCP 配置写入客户端的配置文件中

> **注意**：WorkBuddy 不需要通过此方式配置——它直接通过 `mcp.json`（见 2.2 节）使用通道 A 的工具。通道 B 的实时编辑能力则通过 godot-ai 插件在编辑器内使用。

---

## 四、完整工作流

### 4.1 日常启动流程

```
1. [手动] 启动 Godot 编辑器
   → 编辑器内 godot-ai 插件自动启动 Python MCP 服务器
   → 输出：MCP plugin loaded, connected to server, readiness -> ready

2. [自动] WorkBuddy 连接通道 A
   → mcp__godot__ 工具可用
   → 无需手动配置，mcp.json 已配置好

3. [可选] 运行游戏
   → 使用 run_project 启动或手动在编辑器按 F5
   → 使用 get_debug_output 查看运行日志
```

### 4.2 可用工具对照表

| 你需要做的事 | 使用的通道 | 关键工具 |
|-------------|-----------|---------|
| 读取项目信息 | A | `get_project_info`, `get_uid` |
| 创建/编辑场景 | A | `create_scene`, `add_node`, `save_scene` |
| 运行游戏 | A | `run_project`, `get_debug_output`, `stop_project` |
| 启动编辑器 | A | `launch_editor` |
| 实时查看编辑器状态 | B | 通过 godot-ai 插件 Dock |
| 实时编辑场景/节点 | B | 通过 godot-ai 插件（AI 客户端） |
| 实时截取游戏画面 | B | 通过 godot-ai 插件（game_helper） |
| 修改游戏内状态 | B | 通过 godot-ai 插件（game_eval） |

### 4.3 故障排查

#### 通道 A 问题

| 症状 | 排查步骤 |
|------|---------|
| `get_godot_version` 失败 | 检查 `mcp.json` 中 `GODOT_PATH` 路径是否正确 |
| `get_project_info` 返回空 | 检查 `projectPath` 是否为绝对路径 |
| `run_project` 无响应 | 检查是否已有编辑器占用项目（只能同时一个进程打开项目） |
| `get_debug_output` 为空 | 确认已调用 `run_project`，且使用控制台版 Godot |

#### 通道 B 问题

| 症状 | 排查步骤 |
|------|---------|
| 无 `MCP plugin loaded` | 检查插件是否已启用（项目设置 → 插件） |
| `port excluded by Windows` | 修改 `http_port` 避开 Hyper-V 保留端口 |
| `version_mismatch` | 更新 Python 服务器：`pip install --upgrade godot-ai` |
| `server crashed` | 查看 `uvx` 是否安装；检查网络能否访问 PyPI |
| `connection_blocked` | 检查端口是否被其他进程占用 |

---

## 五、配置文件参考

### 5.1 WorkBuddy 全局 MCP 配置

**路径：** `C:\Users\<用户名>\.workbuddy\mcp.json`

```json
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["@coding-solo/godot-mcp"],
      "env": {
        "GODOT_PATH": "D:\\SOFTWARE\\Godot_v4.6.1-stable_win64_console.exe",
        "DEBUG": "true"
      },
      "disabled": false
    }
  }
}
```

### 5.2 Godot 项目配置

**路径：** `<项目根>/project.godot` → `[autoload]` 段

```ini
[autoload]

# 游戏运行时 MCP 通信（由 godot_ai 插件自动注册）
_mcp_game_helper="*res://addons/godot_ai/runtime/game_helper.gd"
```

### 5.3 godot-ai 插件配置

**路径：** `<项目根>/addons/godot_ai/plugin.cfg`

```ini
[plugin]
name="Godot AI MCP"
description="MCP server and tools for AI-assisted Godot development"
author="SingularityAI"
version="2.6.0"
```

**编辑器设置路径：** 编辑器 → 编辑器设置 → 插件 → godot_ai

| 设置项 | 默认值 | 说明 |
|--------|--------|------|
| `godot_ai/http_port` | 8000 | MCP HTTP 端口 |
| `godot_ai/ws_port` | 9500 | WebSocket 端口 |
| `godot_ai/telemetry_enabled` | true | 遥测开关 |
| `godot_ai/excluded_domains` | "" | 排除的工具域（逗号分隔） |

---

## 六、附录：关键概念

### 6.1 为什么需要两条通道？

| 特性 | 通道 A (godot-mcp) | 通道 B (godot-ai) |
|------|-------------------|-------------------|
| 架构 | 无状态，每次调用独立子进程 | 持久 WebSocket 连接 |
| 依赖 | Node.js + npm | Python (uvx/pip) |
| 编辑器依赖 | 不需要编辑器运行 | 必须编辑器运行 |
| 实时性 | 低（每次重新启动 Godot） | 高（持久通道） |
| 文件操作 | ✅ 创建/修改场景文件 | ✅ 读写脚本/资源 |
| 运行游戏 | ✅ 启动/停止/查看日志 | ❌ (通过编辑器 Debugger) |
| 编辑器控制 | ❌ | ✅ 实时编辑任意节点 |
| 截图 | ❌ | ✅ 游戏运行画面 |
| 代码评估 | ❌ | ✅ 动态执行 GDScript |

### 6.2 godot-ai MCP 协议架构

```
┌──────────────┐     HTTP/MCP      ┌─────────────────┐
│  AI Client    │ ◄──────────────► │  Python Server   │
│  (Claude,     │    JSON-RPC 2.0  │  (godot-ai)      │
│   Cursor,     │                  │  Port 8000       │
│   WorkBuddy)  │                  │                   │
└──────────────┘                   └────────┬──────────┘
                                            │ WebSocket
                                            │ Port 9500
                                   ┌────────▼──────────┐
                                   │  Godot 编辑器插件   │
                                   │  (plugin.gd)       │
                                   │                    │
                                   │  24 个 Handler:    │
                                   │  Scene / Node /    │
                                   │  Script / Material │
                                   │  Animation / UI    │
                                   │  Camera / Audio    │
                                   │  Particles / etc   │
                                   └────────┬──────────┘
                                            │ Debugger
                                            │ Channel
                                   ┌────────▼──────────┐
                                   │  游戏进程           │
                                   │  (game_helper.gd)  │
                                   │  截图 / 控制台 /   │
                                   │  GDScript 评估    │
                                   └───────────────────┘
```

### 6.3 godot-ai 提供的 24 个工具域

| 域 | 功能 |
|----|------|
| `scene` | 场景创建、打开、保存、变体 |
| `node` | 节点创建、删除、重父级、属性设置 |
| `script` | 脚本创建、读取、修改、应用 GDScript 模式 |
| `resource` | 资源创建、加载、分配 |
| `filesystem` | 文件浏览、预览 |
| `texture` | 纹理加载、精灵分配 |
| `animation` | 动画播放器编辑、轨道添加、关键帧 |
| `material` | 材质创建、着色器参数编辑 |
| `particle` | 粒子系统创建、预设应用 |
| `audio` | 音频播放器、流加载 |
| `camera` | 2D/3D 相机创建、预设 |
| `ui` | UI 控件创建、布局编辑 |
| `input` | 输入映射、动作管理 |
| `editor` | 编辑器设置、视口控制 |
| `project` | 项目设置、导出配置 |
| `environment` | 环境光、氛围编辑 |
| `curve` | 曲线资源编辑 |
| `theme` | 主题资源编辑 |
| `physics_shape` | 物理碰撞形状创建 |
| `signal` | 信号连接/断连 |
| `batch` | 批量节点操作 |
| `control_draw_recipe` | 自定义 UI 绘制方案 |
| `autoload` | Autoload 注册 |
| `test` | GDScript 单元测试 |

---

> **推荐阅读**
> - [godot-mcp GitHub](https://github.com/Coding-Solo/godot-mcp) — 通道 A 工具
> - [godot-ai GitHub](https://github.com/SingularityAI/godot-ai) — 通道 B 插件
> - Godot 4 官方文档：`https://docs.godotengine.org/`
