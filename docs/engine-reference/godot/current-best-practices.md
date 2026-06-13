# Godot Current Best Practices — 4.6.x

> Last verified: 2026-06-03

## Overview

This document captures current best practices for Godot 4.6.x development.
Since 4.6.3 is beyond the LLM's training data, practices may have evolved.

## GDScript Best Practices

### Type Safety
```gdscript
# Always use static typing
var health: int = 100
var player: PlayerController = null

# Use type hints for function signatures
func take_damage(amount: int) -> void:
    health -= amount
```

### Signals
```gdscript
# Define signals with type hints
signal health_changed(old_value: int, new_value: int)

# Emit with arguments
health_changed.emit(old_health, health)
```

### Code Organization
```gdscript
# Use class_name for reusable types
class_name Card
extends Resource

# Group related functionality
@export var card_name: String = ""
@export var card_type: CardType = CardType.ATTACK
```

## C# Best Practices

### Godot Integration
```csharp
// Use partial classes for Godot nodes
public partial class Player : CharacterBody2D
{
    // Use [Export] for inspector properties
    [Export]
    public int Health { get; set; } = 100;
    
    // Use signals with delegates
    [Signal]
    public delegate void HealthChangedEventHandler(int oldHealth, int newHealth);
}
```

### Performance
```csharp
// Cache node references
private AnimatedSprite2D _sprite;

public override void _Ready()
{
    _sprite = GetNode<AnimatedSprite2D>("Sprite");
}
```

## Project Structure

### Recommended Layout
```
project/
├── src/
│   ├── autoload/          # Global singletons
│   ├── cards/             # Card system
│   ├── combat/            # Battle system
│   ├── ui/                # UI components
│   └── worlds/            # World/level scripts
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── resources/         # .tres files
├── scenes/
│   ├── cards/
│   ├── combat/
│   ├── ui/
│   └── worlds/
└── data/
    ├── cards/             # Card data files
    └── balance/           # Balance configs
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `PlayerController` |
| Files | snake_case | `player_controller.gd` |
| Variables | snake_case | `current_health` |
| Functions | snake_case | `take_damage()` |
| Signals | snake_case past tense | `health_changed` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH` |
| Scenes | PascalCase | `PlayerController.tscn` |

## Card System Patterns

### Data-Driven Cards
```gdscript
# card_data.gd
class_name CardData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var type: CardType = CardType.ATTACK
@export var cost: int = 0
@export var effects: Array[CardEffect] = []
```

### Effect System
```gdscript
# card_effect.gd
class_name CardEffect
extends Resource

enum EffectType { DAMAGE, HEAL, SUMMON, BUFF, DEBUFF, ENVIRONMENT }

@export var type: EffectType = EffectType.DAMAGE
@export var value: int = 0
@export var target: TargetType = TargetType.ENEMY
```

## Performance Tips

1. **Use Object Pooling** for frequently created/destroyed objects (cards, projectiles)
2. **Batch Node Operations** when possible
3. **Use Resources** for shared data (card definitions, balance values)
4. **Profile Regularly** with Godot's built-in profiler
5. **Optimize Draw Calls** by batching sprites and using texture atlases

## Testing

### Unit Testing
```gdscript
# Use GUT framework for GDScript testing
func test_card_damage():
    var card = Card.new()
    card.damage = 10
    assert_eq(card.damage, 10)
```

### Integration Testing
- Test card combinations
- Test UI interactions
- Test save/load systems

## Resources

- [Godot Documentation](https://docs.godotengine.org/en/stable/)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [C# in Godot](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp.html)
- [Godot Best Practices](https://docs.godotengine.org/en/stable/contributing/development/best_practices.html)
