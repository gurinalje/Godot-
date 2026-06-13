# Technical Preferences

> Last updated: 2026-06-03

## Engine & Language

- **Engine**: Godot 4.6.3
- **Primary Language**: GDScript (gameplay/UI scripting)
- **Secondary Language**: C# (performance-critical systems)
- **Native Extensions**: C++ via GDExtension (only when needed)
- **Build System**: .NET SDK + Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

## Naming Conventions

### GDScript Files (.gd)
- Classes: PascalCase (e.g., `PlayerController`)
- Variables/functions: snake_case (e.g., `move_speed`)
- Signals: snake_case past tense (e.g., `health_changed`)
- Files: snake_case matching class (e.g., `player_controller.gd`)
- Scenes: PascalCase matching root node (e.g., `PlayerController.tscn`)
- Constants: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

### C# Files (.cs)
- Classes: PascalCase, must be `partial` (e.g., `PlayerController`)
- Public properties/fields: PascalCase (e.g., `MoveSpeed`)
- Private fields: _camelCase (e.g., `_currentHealth`)
- Methods: PascalCase (e.g., `TakeDamage()`)
- Signal delegates: PascalCase + `EventHandler` suffix (e.g., `HealthChangedEventHandler`)
- Files: PascalCase matching class (e.g., `PlayerController.cs`)
- Constants: PascalCase (e.g., `MaxHealth`)

## Input & Platform

- **Target Platforms**: PC (Steam)
- **Input Methods**: Keyboard/Mouse, Gamepad (partial)
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Partial (recommended for card selection)
- **Touch Support**: None
- **Platform Notes**: UI should support both mouse and gamepad navigation

## Performance Budgets

- **Target FPS**: 60
- **Frame Budget**: 16.6ms
- **Draw Call Limit**: 1000 (2D)
- **Memory Budget**: 2GB (PC)
- **Load Time**: < 5 seconds per scene

## Testing

- **Framework**: GUT (Godot Unit Testing)
- **Coverage Target**: 80% for core systems
- **Test Location**: `tests/` directory
- **CI Integration**: GitHub Actions

## Engine Specialists Routing

### Primary
- **godot-specialist** — Architecture decisions, ADR validation, cross-cutting code review

### Language Specialists
- **godot-gdscript-specialist** — All `.gd` files, code quality, signal architecture, static typing
- **godot-csharp-specialist** — All `.cs` files, .csproj management, C#-specific idioms

### Additional Specialists
- **godot-shader-specialist** — `.gdshader` files, VisualShader resources, materials
- **godot-gdextension-specialist** — Native C++ plugins, GDExtension only

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Game code (.cs files) | godot-csharp-specialist |
| Cross-language boundary decisions | godot-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Project config (.csproj, NuGet) | godot-csharp-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |

### Routing Notes

- Invoke **godot-specialist** for architecture decisions, ADR validation, and cross-cutting code review
- Invoke **godot-gdscript-specialist** for `.gd` files — code quality, signal architecture, static typing, GDScript idioms
- Invoke **godot-csharp-specialist** for `.cs` files and `.csproj` management — C#-specific Godot idioms
- Invoke **godot-shader-specialist** for material design and shader code
- Invoke **godot-gdextension-specialist** only when native C++ plugins are involved
- Prefer signals over direct cross-language method calls at the GDScript/C# boundary

## Forbidden Patterns

- [TO BE CONFIGURED]

## Allowed Libraries

- [TO BE CONFIGURED]
