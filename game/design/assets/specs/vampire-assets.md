# Vampire Asset Specification

> **Target**: Vampire Enemy Character  
> **Status**: Needed  
> **Generated**: 2026-06-05  
> **Art Bible Reference**: design/art/art-bible.md

---

## Asset Overview

| Field | Value |
|-------|-------|
| **Asset ID** | ASSET-001 |
| **Name** | vampire-enemy |
| **Category** | Character Sprite |
| **Dimensions** | 32x48 pixels |
| **Format** | .aseprite (source), .png (export) |
| **Naming** | char_vampire_idle_01.png |
| **Status** | Needed |

---

## Visual Description

### Character Concept
A classic vampire enemy with gothic, elegant appearance. The design should convey:
- **Aristocratic elegance** - refined, sophisticated pose
- **Supernatural threat** - glowing red eyes, sharp fangs
- **Dark nobility** - flowing cape, formal attire
- **Mysterious aura** - subtle purple/red glow effects

### Pixel Art Requirements

#### Silhouette
- **Head**: Slightly elongated, with slicked-back hair
- **Body**: Slim, upright posture with broad shoulders
- **Cape**: Flowing cape that extends beyond body width
- **Arms**: One arm extended forward (attack pose), other at side
- **Legs**: Standing position, slight stride

#### Key Visual Elements
1. **Glowing red eyes** - 2-3 pixel bright red dots
2. **Sharp fangs** - 1-2 pixel white highlights
3. **Flowing cape** - Dark purple/black with red inner lining
4. **Formal attire** - Dark suit with white shirt details
5. **Clawed hands** - Sharp, threatening fingers

#### Color Palette (from Art Bible)
| Color | Hex | Usage |
|-------|-----|-------|
| **深渊黑** | #1A1A2E | Cape exterior, shadows |
| **暮色灰** | #2D2D44 | Suit details, secondary shadows |
| **鲜血红** | #D94A4A | Eyes, cape lining, blood effects |
| **暗影紫** | #9B59B6 | Magical glow, aura effects |
| **月光银** | #E0E0E0 | Shirt, fangs, highlights |
| **命运金** | #E8C84A | Button details, accessories |

---

## Animation Frames

### Idle Animation (2-4 frames)
- Frame 1: Neutral pose, slight cape movement
- Frame 2: Cape billows slightly, eyes glow brighter
- Frame 3: Return to neutral
- Frame 4: Optional - subtle breathing movement

### Attack Animation (3-5 frames)
- Frame 1: Wind-up pose, cape flares
- Frame 2: Lunge forward, arms extended
- Frame 3: Strike position, claws extended
- Frame 4: Return to neutral
- Frame 5: Optional - recovery pose

### Death Animation (3-5 frames)
- Frame 1: Stagger back, cape disheveled
- Frame 2: Collapse begins, arms flailing
- Frame 3: Falling to ground
- Frame 4: On ground, dissolving into mist
- Frame 5: Optional - final dissolve

---

## Technical Specifications

### File Naming Convention
```
char_vampire_[animation]_[frame].png

Examples:
char_vampire_idle_01.png
char_vampire_idle_02.png
char_vampire_attack_01.png
char_vampire_death_01.png
```

### Godot Import Settings
```yaml
filter: false  # Nearest neighbor for pixel art
mipmaps: false
compress: 0
process:
  2d/gen_mipmaps: false
```

### Animation Settings
| Animation | Frames | FPS | Loop |
|-----------|--------|-----|------|
| idle | 4 | 6 | Yes |
| attack | 4 | 12 | No |
| death | 4 | 8 | No |

---

## Production Notes

### Layer Structure (Aseprite)
1. **Base Layer** - Body shape, main colors
2. **Details Layer** - Clothing details, accessories
3. **Glow Layer** - Eyes, magical effects (additive blend)
4. **Outline Layer** - 1px dark outline for clarity

### Pixel Art Techniques
- **Dithering** for cape texture
- **Subpixel animation** for cape movement
- **Color ramp** for depth (3-4 shades per color)
- **Anti-aliasing** on key edges (selective)

### Quality Checklist
- [ ] Clear silhouette at 16x16 thumbnail
- [ ] Distinct from other enemy types
- [ ] Readable at game camera distance
- [ ] Consistent with art bible palette
- [ ] Smooth animation transitions
- [ ] Proper layer organization
- [ ] Export at correct dimensions

---

## Dependencies

- **Art Bible**: design/art/art-bible.md (Section 4, 5)
- **Color Palette**: design/art/palette.json (to be created)
- **Character Design Direction**: Art Bible Section 5

---

## Next Steps

1. Generate placeholder art using `/art-generate`
2. Review generated art for quality
3. Refine pixel art if needed
4. Export final assets to `assets/characters/enemies/vampire/`
