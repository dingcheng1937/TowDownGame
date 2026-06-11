# MEMORY.md — 项目长期记忆

## 工作流规则

### 修改后必须验证
每次修改代码或场景文件后——无论是修复错误、重构代码、还是新增功能——都必须通过 `run_project` + `get_debug_output` 运行验证，确认没有新的 ERROR 出现。

流程：
1. 修改文件
2. `mcp__godot__run_project` 启动项目
3. 等待 4-5 秒
4. `mcp__godot__get_debug_output` 检查输出 — 确认 ERROR 为 0
5. `mcp__godot__stop_project` 停止

只有 ERROR 级别的问题才算失败。WARNING 级别的代码风格问题不算阻断。

---

## 叙事设计

### 游戏世界观：《潜渊暗界》
- 世界观：俯视角Roguelite射击，融合克苏鲁风格。主题：人类制度的异化与自我祭祀。
- 核心主题：五大机构（精神病院、学校、工厂、制药、道观）本是同一系统，均受市政厅统一协调。
- 外神定位：回应者，非入侵者。加速人类自身逻辑，让本质显现。
- 玩家角色：无名无台词，以"考古学家"身份拼凑真相。
- 叙事文档位置：`docs/NARRATIVE_DESIGN.md`（完整叙事设计，含角色语音柱石、对话系统、可收集文档内容、环境叙事提案、Gameplay整合矩阵、世界圣典）
- 现有技术对接：SanityServer（理智系统）/ EventBus / CorrectionGameManager / TreatmentDirector（已有Boss）
- 关键Boss台词：治疗主任死亡前说"我只是想……治好他们"——善意与伤害并存，不可推翻。
- 终局关键时刻：市长说出"朱明辉，32号"——第一个被系统消耗者的名字，Tier 3文件线索汇聚点。
