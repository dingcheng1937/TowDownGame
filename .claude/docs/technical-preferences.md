# Technical Preferences

<!-- Configured for TowDownGame (Godot 4) -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.x
- **Language**: GDScript
- **Rendering**: Forward+ (Vulkan)
- **Physics**: Godot Physics 3D/2D

## Input & Platform

<!-- Configured for TowDownGame -->
<!-- Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Windows, Linux, macOS)
- **Input Methods**: Keyboard/Mouse, Gamepad
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Full (Xbox, PlayStation, Switch Pro)
- **Touch Support**: None
- **Platform Notes**: Desktop-first, controller support as secondary

## Naming Conventions

- **Classes**: PascalCase (e.g., `Hero`, `BaseGun`)
- **Variables**: snake_case (e.g., `player_health`, `current_weapon`)
- **Signals/Events**: PascalCase (e.g., `HealthChanged`, `WeaponFired`)
- **Files**: PascalCase for scripts, snake_case for scenes/resources
- **Scenes/Prefabs**: PascalCase (e.g., `Hero.tscn`, `MainMenu.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`, `GRAVITY`)

## Performance Budgets

- **Target Framerate**: 60 FPS minimum
- **Frame Budget**: ~16ms per frame (60 FPS)
- **Draw Calls**: < 500 on mid-range hardware
- **Memory Ceiling**: < 2 GB VRAM, < 4 GB system RAM

## Testing

- **Framework**: Gut (Godot Unit Testing)
- **Minimum Coverage**: 50% for core systems
- **Required Tests**: Balance formulas, gameplay systems

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- No hardcoded magic numbers in gameplay code
- No direct scene tree traversal without using autoload servers
- No circular dependencies between scenes/classes

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- Gut (included in addons/)
- Any official Godot addons
- Godot AI (included in addons/)

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Configured for Godot 4 -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist
- **Shader Specialist**: godot-shader-specialist
- **UI Specialist**: godot-specialist
- **Additional Specialists**: [None configured]
- **Routing Notes**: Use GDScript specialist for all core gameplay code

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd) | godot-gdscript-specialist |
| Shader / material files (.tres, .shader) | godot-shader-specialist |
| UI / screen files | godot-specialist |
| Scene / prefab / level files (.tscn) | godot-specialist |
| Native extension / plugin files | godot-specialist |
| General architecture review | Primary |
