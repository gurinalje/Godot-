# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | 4.6.3 |
| **Project Pinned** | 2026-06-03 |
| **LLM Knowledge Cutoff** | May 2025 |
| **Risk Level** | MEDIUM — version is near the edge of LLM training data |

## Version Timeline

| Version | Release Date | Training Data Coverage |
|---------|--------------|------------------------|
| 4.3 | ~2024 | ✅ Covered |
| 4.4 | ~2025 | ⚠️ Partially covered |
| 4.5 | ~2025 | ❌ May not be covered |
| 4.6.x | May 2026 | ❌ Beyond training data |

## Note

Godot 4.6.3 is slightly beyond the LLM's training data cutoff. Engine reference
docs have been created to ensure accurate code suggestions. If agents suggest
incorrect APIs, run `/setup-engine refresh` to update reference docs.

## Key Features in 4.6.x

- Improved GDScript type system
- Enhanced C# integration with .NET 8+
- New rendering features for 2D
- Performance improvements
- Updated UI system

## Recommended Actions

1. Verify API suggestions against official docs when in doubt
2. Use `godot-specialist` agent for architecture decisions
3. Use `godot-gdscript-specialist` for GDScript code quality
4. Use `godot-csharp-specialist` for C# code quality
5. Run `/setup-engine refresh` if you encounter API issues
