# Godot Deprecated APIs — 4.3 → 4.6

> Last verified: 2026-06-03

## Overview

This document tracks deprecated APIs and their replacements.
Since 4.6.3 is beyond the LLM's training data, this list may be incomplete.

## GDScript Deprecated APIs

### 4.4 Deprecations
- [To be verified against official changelog]

### 4.5 Deprecations
- [To be verified against official changelog]

### 4.6 Deprecations
- [To be verified against official changelog]

## C# Deprecated APIs

### 4.4 Deprecations
- [To be verified against official changelog]

### 4.5 Deprecations
- [To be verified against official changelog]

### 4.6 Deprecations
- [To be verified against official changelog]

## Common Migration Patterns

### Signal Connections
```gdscript
# Old (deprecated)
connect("signal_name", self, "_method_name")

# New
signal_name.connect(_method_name)
```

### Node Access
```gdscript
# Old (deprecated)
get_node("Path/To/Node")

# New (with type safety)
$Path/To/Node as NodeType
```

### String Operations
```gdscript
# Old
"String".begins_with("prefix")

# New
"String".begins_with("prefix")  # No change, still valid
```

## Resources

- [Deprecated API List](https://docs.godotengine.org/en/stable/deprecated.html)
- [Godot Changelog](https://docs.godotengine.org/en/stable/classes/index.html)
