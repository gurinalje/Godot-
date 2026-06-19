# 游戏资源规范

> **游戏**: 命运卡牌局
> **视觉风格**: 华丽的暗黑童话
> **最后更新**: 2026-06-03

---

## 资源命名规范

### 格式
```
[类别]_[名称]_[变体].[扩展名]
```

### 示例
```
card_fireball_basic.png
char_player_idle.png
ui_button_primary_normal.png
env_forest_background.png
fx_attack_slash.png
sfx_card_play.ogg
bgm_forest_battle.ogg
```

---

## 卡牌图片规范

### 尺寸
- **卡牌基础尺寸**: 200x280px
- **卡牌缩略图**: 100x140px
- **卡牌大图预览**: 400x560px

### 格式
- **文件格式**: PNG (透明背景)
- **颜色深度**: 32位 RGBA

### 四种卡牌类型

| 类型 | 主色调 | 边框样式 | 示例文件 |
|------|--------|----------|----------|
| **召唤类** | 紫色 (#8B5CF6) | 螺旋边框 | card_summon_skeleton.png |
| **直接伤害类** | 红色 (#EF4444) | 火焰边框 | card_damage_fireball.png |
| **环境阵地类** | 绿色 (#10B981) | 自然边框 | card_environment_blizzard.png |
| **增益减益类** | 金色 (#F59E0B) | 光环边框 | card_buff_holy_blessing.png |

### 稀有度边框

| 稀有度 | 颜色 | 边框宽度 |
|--------|------|----------|
| 普通 | 灰色 (#9CA3AF) | 2px |
| 稀有 | 蓝色 (#3B82F6) | 3px |
| 史诗 | 紫色 (#8B5CF6) | 4px |
| 传说 | 金色 (#F59E0B) | 5px + 发光效果 |

---

## 角色立绘规范

### 玩家角色
- **尺寸**: 64x64px (像素艺术)
- **动画帧**: 4帧 (待机), 6帧 (行走), 8帧 (攻击)
- **格式**: PNG 精灵图集

### NPC
- **尺寸**: 64x64px
- **表情**: 4种 (普通、高兴、悲伤、惊讶)
- **格式**: PNG 精灵图集

### 敌人
- **尺寸**: 64x64px (普通), 96x96px (精英), 128x128px (BOSS)
- **动画帧**: 4帧 (待机), 6帧 (攻击), 4帧 (受伤), 8帧 (死亡)
- **格式**: PNG 精灵图集

---

## UI元素规范

### 按钮
- **尺寸**: 200x60px (标准), 300x80px (大), 150x45px (小)
- **状态**: 普通、悬停、按下、禁用
- **格式**: PNG 9宫格切片

### 面板
- **背景**: 透明渐变
- **边框**: 4px 描边
- **格式**: PNG 9宫格切片

### 图标
- **尺寸**: 32x32px (小), 48x48px (中), 64x64px (大)
- **格式**: PNG (透明背景)

---

## 环境背景规范

### 区域背景
- **尺寸**: 1920x1080px (16:9)
- **格式**: PNG 或 JPG (高质量)
- **分层**: 前景、中景、背景分离

### 四个区域风格

| 区域 | 主色调 | 氛围 | 参考 |
|------|--------|------|------|
| **森林** | 深绿、棕色 | 神秘、幽暗 | 黑暗之魂的森林 |
| **城堡** | 灰色、金色 | 庄严、腐朽 | 恶魔城系列 |
| **废墟** | 暗红、橙色 | 荒凉、危险 | 暗黑破坏神 |
| **虚空** | 深紫、黑色 | 异界、诡异 | 魔法少女小圆 |

---

## 特效动画规范

### 战斗特效
- **尺寸**: 128x128px (小), 256x256px (中), 512x512px (大)
- **帧率**: 12fps
- **格式**: PNG 序列帧 或 GIF

### 元素特效

| 元素 | 颜色 | 形状 | 示例 |
|------|------|------|------|
| **火** | 红色、橙色 | 火焰 | fx_fire_explosion.png |
| **水** | 蓝色、青色 | 水滴 | fx_water_splash.png |
| **风** | 绿色、白色 | 旋风 | fx_wind_slash.png |
| **土** | 棕色、黄色 | 岩石 | fx_rock_smash.png |
| **雷** | 黄色、紫色 | 闪电 | fx_thunder_strike.png |

---

## 音频规范

### 音效 (SFX)
- **格式**: OGG Vorbis
- **采样率**: 44100Hz
- **比特率**: 128kbps
- **时长**: 0.1-2秒

### 背景音乐 (BGM)
- **格式**: OGG Vorbis
- **采样率**: 44100Hz
- **比特率**: 192kbps
- **时长**: 2-4分钟 (循环)

### 音效分类

| 类别 | 数量 | 示例 |
|------|------|------|
| **卡牌音效** | 8 | 抽卡、出牌、弃牌、升级 |
| **战斗音效** | 10 | 攻击、暴击、格挡、死亡 |
| **元素音效** | 5 | 火、水、风、土、雷 |
| **UI音效** | 6 | 按钮、选择、确认、取消 |
| **环境音效** | 4 | 脚步、风声、水流、雷声 |

---

## 资源清单

### 卡牌图片 (4张基础)
- [ ] card_summon_skeleton.png
- [ ] card_damage_fireball.png
- [ ] card_environment_blizzard.png
- [ ] card_buff_holy_blessing.png

### 角色立绘 (8个)
- [ ] char_player_idle.png
- [ ] char_npc_merchant.png
- [ ] char_npc_quest_giver.png
- [ ] char_enemy_slime.png
- [ ] char_enemy_skeleton.png
- [ ] char_enemy_demon.png
- [ ] char_boss_dragon.png
- [ ] char_boss_lich.png

### UI元素 (15个)
- [ ] ui_button_primary.png
- [ ] ui_button_secondary.png
- [ ] ui_panel_main.png
- [ ] ui_panel_dialog.png
- [ ] ui_icon_health.png
- [ ] ui_icon_mana.png
- [ ] ui_icon_attack.png
- [ ] ui_icon_defense.png
- [ ] ui_frame_card.png
- [ ] ui_frame_portrait.png
- [ ] ui_bar_health.png
- [ ] ui_bar_mana.png
- [ ] ui_bar_exp.png
- [ ] ui_bg_menu.png
- [ ] ui_bg_battle.png

### 环境背景 (4个)
- [ ] env_forest_background.png
- [ ] env_castle_background.png
- [ ] env_ruins_background.png
- [ ] env_void_background.png

### 特效动画 (10个)
- [ ] fx_attack_slash.png
- [ ] fx_attack_stab.png
- [ ] fx_fire_explosion.png
- [ ] fx_water_splash.png
- [ ] fx_wind_slash.png
- [ ] fx_rock_smash.png
- [ ] fx_thunder_strike.png
- [ ] fx_heal_green.png
- [ ] fx_shield_blue.png
- [ ] fx_level_up.png

### 音效 (25个)
- [ ] sfx_card_draw.ogg
- [ ] sfx_card_play.ogg
- [ ] sfx_card_discard.ogg
- [ ] sfx_card_upgrade.ogg
- [ ] sfx_attack_hit.ogg
- [ ] sfx_attack_critical.ogg
- [ ] sfx_attack_block.ogg
- [ ] sfx_enemy_death.ogg
- [ ] sfx_fire_effect.ogg
- [ ] sfx_water_effect.ogg
- [ ] sfx_wind_effect.ogg
- [ ] sfx_earth_effect.ogg
- [ ] sfx_thunder_effect.ogg
- [ ] sfx_button_click.ogg
- [ ] sfx_button_hover.ogg
- [ ] sfx_confirm.ogg
- [ ] sfx_cancel.ogg
- [ ] sfx_level_up.ogg
- [ ] sfx_reward.ogg
- [ ] sfx_footstep.ogg
- [ ] sfx_wind_ambient.ogg
- [ ] sfx_water_flow.ogg
- [ ] sfx_thunder_ambient.ogg
- [ ] sfx_victory.ogg
- [ ] sfx_defeat.ogg

### 背景音乐 (5首)
- [ ] bgm_menu.ogg
- [ ] bgm_forest_exploration.ogg
- [ ] bgm_forest_battle.ogg
- [ ] bgm_castle_exploration.ogg
- [ ] bgm_castle_battle.ogg

---

## 资源生成工具

### 推荐工具
1. **Aseprite** - 像素艺术和动画
2. **Photoshop/GIMP** - 背景和UI
3. **Audacity** - 音频编辑
4. **LMMS/BFXR** - 音效生成

### AI生成资源
- 使用 Midjourney 或 Stable Diffusion 生成概念图
- 使用 Aseprite MCP 生成像素艺术
- 使用 BFXR 生成8位音效

---

## 下一步行动

1. 使用 Aseprite MCP 生成卡牌图片
2. 使用 AI 生成环境背景概念图
3. 使用 BFXR 生成基础音效
4. 创建 UI 元素的 9 宫格切片
