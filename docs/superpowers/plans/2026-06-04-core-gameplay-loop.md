# 命运卡牌局 - 核心游戏循环实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现完整的核心游戏玩法循环：探索 → 遇敌 → 战斗 → 奖励 → 继续探索

**Architecture:** 基于现有的模块化系统架构，修复关键bug，完善战斗系统，添加敌人实体和NPC交互，实现战斗奖励和区域传送系统。

**Tech Stack:** Godot 4.6, GDScript, 现有系统架构

---

## 范围检查

本计划涵盖以下独立子系统：
1. Bug修复（card_battle.gd中的枚举错误和精灵加载错误）
2. 战斗系统完善（玩家HP、buff/debuff效果、召唤效果、环境效果）
3. 世界地图敌人系统（敌人实体、随机遭遇、触发战斗）
4. NPC交互系统（对话系统、商店系统）
5. 战斗奖励系统（卡牌奖励、金币奖励）
6. 区域传送系统（不同区域之间的切换）
7. 任务系统基础框架

这些子系统相互关联但可以独立实现。建议按顺序实现，每个子系统完成后进行测试。

## 文件结构映射

### 核心文件（需要修改）
- `src/scenes/card_battle.gd` - 战斗场景主逻辑（修复bug，完善系统）
- `src/card-battle-system/card_battle_system.gd` - 战斗系统核心逻辑
- `src/world-exploration-system/world_exploration_manager.gd` - 世界探索管理器
- `src/world-exploration-system/world_explorer.gd` - 世界探索器
- `src/npc-system/npc_manager.gd` - NPC管理器
- `src/dialogue-system/dialogue_manager.gd` - 对话管理器
- `src/save-system/save_system.gd` - 存档系统

### 新建文件
- `src/enemy-system/enemy_entity.gd` - 敌人实体类
- `src/enemy-system/enemy_spawner.gd` - 敌人生成器
- `src/enemy-system/enemy_database.gd` - 敌人数据库
- `src/reward-system/reward_manager.gd` - 奖励管理器
- `src/quest-system/quest_manager.gd` - 任务管理器
- `src/quest-system/quest_data.gd` - 任务数据类
- `src/teleport-system/teleport_manager.gd` - 传送管理器

### 测试文件
- `tests/unit/test_card_battle.gd` - 战斗系统单元测试
- `tests/unit/test_enemy_system.gd` - 敌人系统单元测试
- `tests/unit/test_reward_system.gd` - 奖励系统单元测试

---

## 实现步骤

### Phase 1: Bug修复和基础完善

#### Task 1: 修复card_battle.gd中的枚举错误

**Files:**
- Modify: `src/scenes/card_battle.gd:304,311`

- [ ] **Step 1: 修复CardType.DAMAGE枚举错误**

```gdscript
# 第304行：将 CardEnums.CardType.DAMAGE 改为 CardEnums.CardType.DIRECT_DAMAGE
match card.card_type:
    CardEnums.CardType.DIRECT_DAMAGE:  # 修复：DAMAGE -> DIRECT_DAMAGE
        _execute_damage_card(card)
    CardEnums.CardType.SUMMON:
        _execute_summon_card(card)
    CardEnums.CardType.ENVIRONMENT:
        _execute_environment_card(card)
    CardEnums.CardType.BUFF_DEBUFF:  # 修复：BUFF -> BUFF_DEBUFF
        _execute_buff_card(card)
```

- [ ] **Step 2: 修复CardType.BUFF枚举错误**

```gdscript
# 第311行：将 CardEnums.CardType.BUFF 改为 CardEnums.CardType.BUFF_DEBUFF
CardEnums.CardType.BUFF_DEBUFF:  # 修复：BUFF -> BUFF_DEBUFF
    _execute_buff_card(card)
```

- [ ] **Step 3: 验证枚举修复**

运行游戏，确保卡牌类型匹配正确，不再出现枚举错误。

- [ ] **Step 4: 提交修复**

```bash
git add src/scenes/card_battle.gd
git commit -m "fix: 修复card_battle.gd中的CardType枚举错误"
```

#### Task 2: 修复card.base_damage引用错误

**Files:**
- Modify: `src/scenes/card_battle.gd:347`

- [ ] **Step 1: 修复_damage_calculate函数**

```gdscript
## 计算伤害
func _calculate_damage(card: CardData, target: Dictionary) -> int:
    # 从effects数组中获取基础伤害值
    var base_damage: int = 0
    for effect in card.effects:
        if effect.effect_type == CardEnums.EffectType.DAMAGE:
            base_damage = effect.value
            break
    
    if not damage_calculator:
        return base_damage
    
    # 使用伤害计算器
    var result = damage_calculator.calculate_damage(
        base_damage,
        card.element,
        target.get("element", "none"),
        target.get("defense", 0),
        1.0,  # 暴击率
        1.0   # 暴击伤害
    )
    
    return result.get("final_damage", base_damage)
```

- [ ] **Step 2: 验证伤害计算**

使用火球术等卡牌攻击敌人，确认伤害计算正确。

- [ ] **Step 3: 提交修复**

```bash
git add src/scenes/card_battle.gd
git commit -m "fix: 修复card.base_damage引用，从effects数组获取伤害值"
```

#### Task 3: 修复敌人精灵加载错误

**Files:**
- Modify: `src/scenes/card_battle.gd:175`

- [ ] **Step 1: 添加精灵加载错误处理**

```gdscript
## 创建敌人UI
func _create_enemy_ui() -> void:
    # 清除现有敌人UI
    for child in enemy_container.get_children():
        child.queue_free()
    
    # 创建敌人UI
    for i in range(enemies.size()):
        var enemy = enemies[i]
        
        # 创建敌人容器
        var enemy_ui = VBoxContainer.new()
        enemy_ui.name = "Enemy" + str(i)
        
        # 创建敌人精灵（添加错误处理）
        var sprite = TextureRect.new()
        var sprite_path = enemy.get("sprite", "")
        if sprite_path and ResourceLoader.exists(sprite_path):
            sprite.texture = load(sprite_path)
        else:
            # 使用默认精灵或占位符
            push_warning("[CardBattle] Enemy sprite not found: " + sprite_path)
            # 创建一个占位符ColorRect
            var placeholder = ColorRect.new()
            placeholder.color = Color(0.8, 0.2, 0.2, 0.8)  # 红色占位符
            placeholder.custom_minimum_size = Vector2(128, 128)
            enemy_ui.add_child(placeholder)
        
        sprite.custom_minimum_size = Vector2(128, 128)
        sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        enemy_ui.add_child(sprite)
        
        # 创建生命值条
        var health_bar = ProgressBar.new()
        health_bar.name = "HealthBar"
        health_bar.value = enemy.get("health", 0)
        health_bar.max_value = enemy.get("max_health", 0)
        health_bar.custom_minimum_size = Vector2(128, 20)
        enemy_ui.add_child(health_bar)
        
        # 创建名称标签
        var name_label = Label.new()
        name_label.name = "NameLabel"
        name_label.text = enemy.get("name", "Enemy")
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        enemy_ui.add_child(name_label)
        
        # 添加到容器
        enemy_container.add_child(enemy_ui)
```

- [ ] **Step 2: 验证精灵加载**

运行游戏，确保敌人精灵加载失败时不会崩溃，而是显示占位符。

- [ ] **Step 3: 提交修复**

```bash
git add src/scenes/card_battle.gd
git commit -m "fix: 修复敌人精灵加载错误处理，添加占位符"
```

### Phase 2: 战斗系统完善

#### Task 4: 实现玩家HP系统

**Files:**
- Modify: `src/scenes/card_battle.gd`
- Modify: `src/character-attributes/character_attributes_manager.gd`

- [ ] **Step 1: 添加玩家HP变量**

```gdscript
# 在card_battle.gd中添加玩家HP变量
var player_health: int = 100
var player_max_health: int = 100
var player_defense: int = 0
```

- [ ] **Step 2: 实现_apply_damage_to_player函数**

```gdscript
## 对玩家造成伤害
func _apply_damage_to_player(damage: int) -> void:
    # 计算实际伤害（考虑防御）
    var actual_damage = max(1, damage - player_defense)
    player_health -= actual_damage
    
    # 确保生命值不低于0
    player_health = max(0, player_health)
    
    # 更新UI
    _update_player_ui()
    
    # 添加日志
    _add_log("玩家受到 " + str(actual_damage) + " 点伤害")
    
    # 检查玩家是否死亡
    if player_health <= 0:
        _on_player_defeated()
```

- [ ] **Step 3: 实现玩家死亡处理**

```gdscript
## 玩家被击败
func _on_player_defeated() -> void:
    current_state = BattleState.DEFEAT
    _add_log("玩家被击败...")
    battle_lost.emit()
```

- [ ] **Step 4: 更新玩家UI显示HP**

```gdscript
## 更新玩家UI
func _update_player_ui() -> void:
    # 更新能量显示
    if energy_label:
        energy_label.text = "能量: " + str(player_energy) + "/" + str(player_max_energy)
    
    # 更新生命值条
    if player_health_bar:
        player_health_bar.value = player_health
        player_health_bar.max_value = player_max_health
    
    # 更新生命值标签（如果存在）
    var health_label = $UI/HealthLabel
    if health_label:
        health_label.text = "HP: " + str(player_health) + "/" + str(player_max_health)
```

- [ ] **Step 5: 验证玩家HP系统**

运行战斗，让敌人攻击玩家，确认HP减少和死亡处理正确。

- [ ] **Step 6: 提交实现**

```bash
git add src/scenes/card_battle.gd
git commit -m "feat: 实现玩家HP系统，包含防御和死亡处理"
```

#### Task 5: 实现Buff/Debuff效果系统

**Files:**
- Modify: `src/scenes/card_battle.gd`
- Create: `src/status-effect-system/status_effect.gd`

- [ ] **Step 1: 创建StatusEffect类**

```gdscript
# src/status-effect-system/status_effect.gd
class_name StatusEffect
extends RefCounted

## 效果类型
enum EffectType {
    BUFF,
    DEBUFF
}

## 效果属性
var effect_id: String = ""
var effect_name: String = ""
var effect_type: EffectType = EffectType.BUFF
var value: float = 0.0
var duration: int = 3
var is负面: bool = false

## 获取效果描述
func get_description() -> String:
    var type_str = "增益" if effect_type == EffectType.BUFF else "减益"
    return effect_name + " (" + type_str + "): " + str(value) + " 持续" + str(duration) + "回合"
```

- [ ] **Step 2: 实现_execute_buff_card函数**

```gdscript
## 执行增益卡牌
func _execute_buff_card(card: CardData) -> void:
    # 从effects数组中获取效果
    for effect in card.effects:
        if effect.effect_type == CardEnums.EffectType.BUFF:
            # 应用增益效果
            _apply_buff_effect(effect.value, effect.duration if effect.duration > 0 else 3)
        elif effect.effect_type == CardEnums.EffectType.HEAL:
            # 应用治疗效果
            _apply_heal_effect(effect.value)
```

- [ ] **Step 3: 实现_apply_buff_effect函数**

```gdscript
## 应用增益效果
func _apply_buff_effect(value: float, duration: int) -> void:
    # 创建状态效果
    var status_effect = StatusEffect.new()
    status_effect.effect_id = "buff_" + str(randi())
    status_effect.effect_name = "增益"
    status_effect.effect_type = StatusEffect.EffectType.BUFF
    status_effect.value = value
    status_effect.duration = duration
    
    # 应用效果（例如增加攻击力）
    player_defense += int(value)
    
    # 添加日志
    _add_log("获得增益效果: +" + str(int(value)) + " 防御，持续" + str(duration) + "回合")
```

- [ ] **Step 4: 实现_apply_heal_effect函数**

```gdscript
## 应用治疗效果
func _apply_heal_effect(value: float) -> void:
    var heal_amount = int(value)
    player_health = min(player_max_health, player_health + heal_amount)
    
    # 更新UI
    _update_player_ui()
    
    # 添加日志
    _add_log("恢复 " + str(heal_amount) + " 点生命值")
```

- [ ] **Step 5: 验证Buff/Debuff系统**

使用神圣祝福等卡牌，确认治疗和增益效果正确应用。

- [ ] **Step 6: 提交实现**

```bash
git add src/scenes/card_battle.gd src/status-effect-system/status_effect.gd
git commit -m "feat: 实现Buff/Debuff效果系统"
```

#### Task 6: 实现召唤效果系统

**Files:**
- Modify: `src/scenes/card_battle.gd`
- Create: `src/summon-system/summon_unit.gd`

- [ ] **Step 1: 创建SummonUnit类**

```gdscript
# src/summon-system/summon_unit.gd
class_name SummonUnit
extends RefCounted

## 召唤单位属性
var summon_id: String = ""
var summon_name: String = ""
var base_health: int = 10
var base_attack: int = 5
var element: CardEnums.Element = CardEnums.Element.NONE

## 获取召唤单位信息
func get_info() -> Dictionary:
    return {
        "id": summon_id,
        "name": summon_name,
        "health": base_health,
        "attack": base_attack,
        "element": element
    }
```

- [ ] **Step 2: 实现_execute_summon_card函数**

```gdscript
## 执行召唤卡牌
func _execute_summon_card(card: CardData) -> void:
    # 从effects数组中获取召唤效果
    for effect in card.effects:
        if effect.effect_type == CardEnums.EffectType.SUMMON:
            # 创建召唤单位
            var summon_unit = SummonUnit.new()
            summon_unit.summon_id = "summon_" + str(randi())
            summon_unit.summon_name = card.name + "的召唤物"
            summon_unit.base_health = effect.value
            summon_unit.base_attack = effect.value / 2
            summon_unit.element = card.element
            
            # 添加到召唤管理器
            if summon_manager:
                summon_manager.summon_unit(summon_unit)
            
            # 添加日志
            _add_log("召唤了 " + summon_unit.summon_name + " (HP:" + str(summon_unit.base_health) + " ATK:" + str(summon_unit.base_attack) + ")")
```

- [ ] **Step 3: 验证召唤系统**

使用召唤骷髅等卡牌，确认召唤单位正确创建。

- [ ] **Step 4: 提交实现**

```bash
git add src/scenes/card_battle.gd src/summon-system/summon_unit.gd
git commit -m "feat: 实现召唤效果系统"
```

#### Task 7: 实现环境效果系统

**Files:**
- Modify: `src/scenes/card_battle.gd`
- Create: `src/environment-system/environment_effect.gd`

- [ ] **Step 1: 创建EnvironmentEffect类**

```gdscript
# src/environment-system/environment_effect.gd
class_name EnvironmentEffect
extends RefCounted

## 环境类型
enum EnvironmentType {
    FIRE,
    WATER,
    EARTH,
    WIND,
    LIGHTNING
}

## 环境属性
var environment_id: String = ""
var environment_name: String = ""
var description: String = ""
var environment_type: EnvironmentType = EnvironmentType.FIRE
var duration: int = 3

## 获取环境效果描述
func get_description() -> String:
    return environment_name + ": " + description + " 持续" + str(duration) + "回合"
```

- [ ] **Step 2: 实现_execute_environment_card函数**

```gdscript
## 执行环境卡牌
func _execute_environment_card(card: CardData) -> void:
    # 从effects数组中获取环境效果
    for effect in card.effects:
        if effect.effect_type == CardEnums.EffectType.ENVIRONMENT_CHANGE:
            # 创建环境效果
            var env_effect = EnvironmentEffect.new()
            env_effect.environment_id = "env_" + card.id
            env_effect.environment_name = card.name + "环境"
            env_effect.description = card.description
            env_effect.duration = effect.duration if effect.duration > 0 else 3
            
            # 根据卡牌元素设置环境类型
            match card.element:
                CardEnums.Element.FIRE:
                    env_effect.environment_type = EnvironmentEffect.EnvironmentType.FIRE
                CardEnums.Element.WATER:
                    env_effect.environment_type = EnvironmentEffect.EnvironmentType.WATER
                CardEnums.Element.EARTH:
                    env_effect.environment_type = EnvironmentEffect.EnvironmentType.EARTH
                CardEnums.Element.WIND:
                    env_effect.environment_type = EnvironmentEffect.EnvironmentType.WIND
                CardEnums.Element.LIGHTNING:
                    env_effect.environment_type = EnvironmentEffect.EnvironmentType.LIGHTNING
            
            # 应用环境效果
            if environment_manager:
                environment_manager.set_environment(env_effect)
            
            # 添加日志
            _add_log("改变了战场环境: " + env_effect.environment_name)
```

- [ ] **Step 3: 验证环境系统**

使用暴风雪等环境卡牌，确认环境效果正确应用。

- [ ] **Step 4: 提交实现**

```bash
git add src/scenes/card_battle.gd src/environment-system/environment_effect.gd
git commit -m "feat: 实现环境效果系统"
```

### Phase 3: 世界地图敌人系统

#### Task 8: 创建敌人实体系统

**Files:**
- Create: `src/enemy-system/enemy_entity.gd`
- Create: `src/enemy-system/enemy_database.gd`
- Create: `src/enemy-system/enemy_spawner.gd`

- [ ] **Step 1: 创建EnemyEntity类**

```gdscript
# src/enemy-system/enemy_entity.gd
class_name EnemyEntity
extends Node2D

## 敌人属性
@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export var max_health: int = 50
@export var current_health: int = 50
@export var attack_power: int = 10
@export var defense: int = 5
@export var element: CardEnums.Element = CardEnums.Element.NONE
@export var sprite_path: String = ""

## 信号
signal health_changed(current: int, maximum: int)
signal enemy_defeated()

## 初始化
func _ready() -> void:
    current_health = max_health
    _load_sprite()

## 加载精灵
func _load_sprite() -> void:
    if sprite_path and ResourceLoader.exists(sprite_path):
        var sprite = Sprite2D.new()
        sprite.texture = load(sprite_path)
        add_child(sprite)
    else:
        # 创建占位符
        var placeholder = ColorRect.new()
        placeholder.color = Color(0.8, 0.2, 0.2, 0.8)
        placeholder.size = Vector2(64, 64)
        placeholder.position = Vector2(-32, -32)
        add_child(placeholder)

## 受到伤害
func take_damage(damage: int) -> void:
    var actual_damage = max(1, damage - defense)
    current_health -= actual_damage
    current_health = max(0, current_health)
    
    health_changed.emit(current_health, max_health)
    
    if current_health <= 0:
        _on_defeated()

## 被击败
func _on_defeated() -> void:
    enemy_defeated.emit()
    # 可以在这里添加死亡动画
    queue_free()

## 获取敌人数据
func get_data() -> Dictionary:
    return {
        "id": enemy_id,
        "name": enemy_name,
        "health": current_health,
        "max_health": max_health,
        "attack": attack_power,
        "defense": defense,
        "element": element
    }
```

- [ ] **Step 2: 创建EnemyDatabase类**

```gdscript
# src/enemy-system/enemy_database.gd
class_name EnemyDatabase
extends Node

## 敌人数据缓存
var _enemies: Dictionary = {}

## 初始化
func _ready() -> void:
    _load_default_enemies()

## 加载默认敌人
func _load_default_enemies() -> void:
    # 骷髅战士
    var skeleton = {
        "id": "skeleton",
        "name": "骷髅战士",
        "max_health": 50,
        "attack": 8,
        "defense": 3,
        "element": CardEnums.Element.EARTH,
        "sprite": "res://assets/sprites/characters/enemies/char_enemies_skeleton.png",
        "rewards": {
            "gold": 10,
            "experience": 15,
            "cards": ["shield"]
        }
    }
    _enemies["skeleton"] = skeleton
    
    # 史莱姆
    var slime = {
        "id": "slime",
        "name": "绿色史莱姆",
        "max_health": 30,
        "attack": 5,
        "defense": 1,
        "element": CardEnums.Element.EARTH,
        "sprite": "res://assets/sprites/characters/enemies/char_enemies_slime.png",
        "rewards": {
            "gold": 5,
            "experience": 10,
            "cards": []
        }
    }
    _enemies["slime"] = slime
    
    # 恶魔
    var demon = {
        "id": "demon",
        "name": "恶魔",
        "max_health": 80,
        "attack": 15,
        "defense": 8,
        "element": CardEnums.Element.FIRE,
        "sprite": "res://assets/sprites/characters/enemies/char_enemies_demon.png",
        "rewards": {
            "gold": 25,
            "experience": 30,
            "cards": ["fireball"]
        }
    }
    _enemies["demon"] = demon

## 获取敌人数据
func get_enemy(enemy_id: String) -> Dictionary:
    return _enemies.get(enemy_id, {})

## 获取所有敌人
func get_all_enemies() -> Dictionary:
    return _enemies

## 按区域获取敌人
func get_enemies_by_area(area: String) -> Array:
    var area_enemies = []
    for enemy in _enemies.values():
        # 这里可以根据区域过滤敌人
        area_enemies.append(enemy)
    return area_enemies
```

- [ ] **Step 3: 创建EnemySpawner类**

```gdscript
# src/enemy-system/enemy_spawner.gd
class_name EnemySpawner
extends Node

## 信号
signal enemy_spawned(enemy: EnemyEntity)

## 敌人数据库引用
var enemy_database: EnemyDatabase

## 初始化
func _ready() -> void:
    enemy_database = get_node_or_null("/root/EnemyDatabase")

## 在指定位置生成敌人
func spawn_enemy(enemy_id: String, position: Vector2) -> EnemyEntity:
    if not enemy_database:
        push_error("[EnemySpawner] EnemyDatabase not found")
        return null
    
    var enemy_data = enemy_database.get_enemy(enemy_id)
    if enemy_data.is_empty():
        push_error("[EnemySpawner] Enemy not found: " + enemy_id)
        return null
    
    # 创建敌人实体
    var enemy = EnemyEntity.new()
    enemy.enemy_id = enemy_data.get("id", "")
    enemy.enemy_name = enemy_data.get("name", "")
    enemy.max_health = enemy_data.get("max_health", 50)
    enemy.current_health = enemy.max_health
    enemy.attack_power = enemy_data.get("attack", 10)
    enemy.defense = enemy_data.get("defense", 5)
    enemy.element = enemy_data.get("element", CardEnums.Element.NONE)
    enemy.sprite_path = enemy_data.get("sprite", "")
    
    # 设置位置
    enemy.position = position
    
    # 添加到场景
    add_child(enemy)
    
    # 发送信号
    enemy_spawned.emit(enemy)
    
    return enemy

## 在区域内随机生成敌人
func spawn_random_enemy(area: String, spawn_area: Rect2) -> EnemyEntity:
    if not enemy_database:
        return null
    
    var area_enemies = enemy_database.get_enemies_by_area(area)
    if area_enemies.is_empty():
        return null
    
    # 随机选择敌人
    var random_enemy = area_enemies[randi() % area_enemies.size()]
    
    # 随机位置
    var random_position = Vector2(
        randf_range(spawn_area.position.x, spawn_area.end.x),
        randf_range(spawn_area.position.y, spawn_area.end.y)
    )
    
    return spawn_enemy(random_enemy.get("id", ""), random_position)
```

- [ ] **Step 4: 验证敌人系统**

运行游戏，确认敌人实体正确生成和显示。

- [ ] **Step 5: 提交实现**

```bash
git add src/enemy-system/
git commit -m "feat: 实现敌人实体系统，包含实体、数据库和生成器"
```

#### Task 9: 实现世界地图敌人生成

**Files:**
- Modify: `src/world-exploration-system/world_explorer.gd`
- Modify: `src/scenes/world_exploration.gd`

- [ ] **Step 1: 在世界探索器中添加敌人生成逻辑**

```gdscript
# 在world_explorer.gd中添加
var enemy_spawner: EnemySpawner
var spawn_area: Rect2 = Rect2(100, 100, 1800, 1300)  # 根据地图大小调整
var max_enemies: int = 5
var spawn_interval: float = 10.0
var spawn_timer: float = 0.0

func _ready() -> void:
    # 获取敌人生成器
    enemy_spawner = get_node_or_null("/root/EnemySpawner")

func _process(delta: float) -> void:
    # 定时生成敌人
    spawn_timer += delta
    if spawn_timer >= spawn_interval:
        spawn_timer = 0.0
        _try_spawn_enemy()

func _try_spawn_enemy() -> void:
    if not enemy_spawner:
        return
    
    # 检查当前敌人数量
    var current_enemies = get_tree().get_nodes_in_group("enemies")
    if current_enemies.size() >= max_enemies:
        return
    
    # 获取当前区域
    var world_manager = get_node_or_null("/root/WorldExplorationManager")
    if not world_manager:
        return
    
    var current_area = world_manager.get_current_area()
    
    # 生成敌人
    var enemy = enemy_spawner.spawn_random_enemy(current_area, spawn_area)
    if enemy:
        enemy.add_to_group("enemies")
```

- [ ] **Step 2: 添加敌人碰撞检测**

```gdscript
# 在world_explorer.gd中添加
func _on_enemy_body_entered(body: Node2D) -> void:
    if body.is_in_group("enemies"):
        # 触发战斗
        _start_battle_with_enemy(body)

func _start_battle_with_enemy(enemy: EnemyEntity) -> void:
    # 获取敌人数据
    var enemy_data = enemy.get_data()
    
    # 切换到战斗场景
    var battle_scene = preload("res://src/scenes/card_battle.tscn")
    var battle_instance = battle_scene.instantiate()
    
    # 传递敌人数据
    battle_instance.set_enemies([enemy_data])
    
    # 切换场景
    get_tree().root.add_child(battle_instance)
    get_tree().current_scene = battle_instance
```

- [ ] **Step 3: 验证敌人生成和遭遇**

运行游戏，在世界地图上移动，确认敌人生成和碰撞触发战斗。

- [ ] **Step 4: 提交实现**

```bash
git add src/world-exploration-system/world_explorer.gd
git commit -m "feat: 实现世界地图敌人生成和遭遇系统"
```

### Phase 4: NPC交互系统

#### Task 10: 完善NPC管理器

**Files:**
- Modify: `src/npc-system/npc_manager.gd`
- Modify: `src/npc-system/npc_data.gd`

- [ ] **Step 1: 定义NPC数据结构**

```gdscript
# src/npc-system/npc_data.gd
class_name NPCData
extends Resource

## NPC属性
@export var npc_id: String = ""
@export var npc_name: String = ""
@export var npc_type: String = "merchant"  # merchant, quest_giver, blacksmith
@export var dialogue_id: String = ""
@export var sprite_path: String = ""
@export var position: Vector2 = Vector2.ZERO

## 商店数据（如果是商人）
@export var shop_items: Array[Dictionary] = []

## 任务数据（如果是任务给予者）
@export var quests: Array[String] = []

## 获取NPC信息
func get_info() -> Dictionary:
    return {
        "id": npc_id,
        "name": npc_name,
        "type": npc_type,
        "dialogue_id": dialogue_id,
        "sprite": sprite_path,
        "position": position
    }
```

- [ ] **Step 2: 完善NPC管理器**

```gdscript
# src/npc-system/npc_manager.gd
class_name NPCManager
extends Node

## NPC数据
var _npcs: Dictionary = {}

## 信号
signal npc_interacted(npc_id: String)

## 初始化
func _ready() -> void:
    _load_default_npcs()

## 加载默认NPC
func _load_default_npcs() -> void:
    # 商人
    var merchant = NPCData.new()
    merchant.npc_id = "merchant"
    merchant.npc_name = "神秘商人"
    merchant.npc_type = "merchant"
    merchant.dialogue_id = "merchant_dialogue"
    merchant.sprite_path = "res://assets/sprites/characters/npcs/char_npcs_merchant.png"
    merchant.shop_items = [
        {"id": "fireball", "name": "火球术", "price": 50},
        {"id": "shield", "name": "护盾", "price": 30},
        {"id": "holy_blessing", "name": "神圣祝福", "price": 40}
    ]
    _npcs["merchant"] = merchant
    
    # 任务给予者
    var quest_giver = NPCData.new()
    quest_giver.npc_id = "quest_giver"
    quest_giver.npc_name = "长老"
    quest_giver.npc_type = "quest_giver"
    quest_giver.dialogue_id = "quest_giver_dialogue"
    quest_giver.sprite_path = "res://assets/sprites/characters/npcs/char_npcs_elder.png"
    quest_giver.quests = ["quest_001", "quest_002"]
    _npcs["quest_giver"] = quest_giver
    
    # 铁匠
    var blacksmith = NPCData.new()
    blacksmith.npc_id = "blacksmith"
    blacksmith.npc_name = "铁匠"
    blacksmith.npc_type = "blacksmith"
    blacksmith.dialogue_id = "blacksmith_dialogue"
    blacksmith.sprite_path = "res://assets/sprites/characters/npcs/char_npcs_blacksmith.png"
    _npcs["blacksmith"] = blacksmith

## 获取NPC数据
func get_npc(npc_id: String) -> NPCData:
    return _npcs.get(npc_id)

## 获取所有NPC
func get_all_npcs() -> Dictionary:
    return _npcs

## 与NPC交互
func interact_with_npc(npc_id: String) -> void:
    var npc = get_npc(npc_id)
    if not npc:
        push_warning("[NPCManager] NPC not found: " + npc_id)
        return
    
    npc_interacted.emit(npc_id)
    
    # 根据NPC类型执行不同操作
    match npc.npc_type:
        "merchant":
            _open_shop(npc)
        "quest_giver":
            _open_quest_dialogue(npc)
        "blacksmith":
            _open_blacksmith(npc)

## 打开商店
func _open_shop(npc: NPCData) -> void:
    # 这里会打开商店UI
    print("[NPCManager] Opening shop for: ", npc.npc_name)

## 打开任务对话
func _open_quest_dialogue(npc: NPCData) -> void:
    # 这里会打开任务对话UI
    print("[NPCManager] Opening quest dialogue for: ", npc.npc_name)

## 打开铁匠铺
func _open_blacksmith(npc: NPCData) -> void:
    # 这里会打开铁匠铺UI
    print("[NPCManager] Opening blacksmith for: ", npc.npc_name)
```

- [ ] **Step 3: 验证NPC系统**

运行游戏，确认NPC正确显示和交互。

- [ ] **Step 4: 提交实现**

```bash
git add src/npc-system/
git commit -m "feat: 完善NPC管理器，支持商人、任务给予者和铁匠"
```

#### Task 11: 实现对话系统

**Files:**
- Modify: `src/dialogue-system/dialogue_manager.gd`

- [ ] **Step 1: 定义对话数据结构**

```gdscript
# 在dialogue_manager.gd中添加
class_name DialogueManager
extends Node

## 对话数据
var _dialogues: Dictionary = {}

## 信号
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal dialogue_choice_made(dialogue_id: String, choice_index: int)

## 初始化
func _ready() -> void:
    _load_default_dialogues()

## 加载默认对话
func _load_default_dialogues() -> void:
    # 商人对话
    var merchant_dialogue = {
        "id": "merchant_dialogue",
        "npc_name": "神秘商人",
        "lines": [
            {"speaker": "merchant", "text": "欢迎，旅行者！看看我的商品吧。"},
            {"speaker": "player", "text": "你有什么好东西？"},
            {"speaker": "merchant", "text": "我有各种卡牌和装备，看看吧！"}
        ],
        "choices": [
            {"text": "看看商品", "action": "open_shop"},
            {"text": "离开", "action": "end_dialogue"}
        ]
    }
    _dialogues["merchant_dialogue"] = merchant_dialogue
    
    # 任务给予者对话
    var quest_giver_dialogue = {
        "id": "quest_giver_dialogue",
        "npc_name": "长老",
        "lines": [
            {"speaker": "quest_giver", "text": "年轻人，你终于来了。"},
            {"speaker": "player", "text": "发生了什么事？"},
            {"speaker": "quest_giver", "text": "森林里出现了怪物，我们需要你的帮助。"}
        ],
        "choices": [
            {"text": "接受任务", "action": "accept_quest"},
            {"text": "拒绝", "action": "end_dialogue"}
        ]
    }
    _dialogues["quest_giver_dialogue"] = quest_giver_dialogue

## 开始对话
func start_dialogue(dialogue_id: String) -> void:
    var dialogue = _dialogues.get(dialogue_id)
    if not dialogue:
        push_warning("[DialogueManager] Dialogue not found: " + dialogue_id)
        return
    
    dialogue_started.emit(dialogue_id)
    
    # 显示对话UI
    _show_dialogue_ui(dialogue)

## 显示对话UI
func _show_dialogue_ui(dialogue: Dictionary) -> void:
    # 这里会创建对话UI
    print("[DialogueManager] Showing dialogue: ", dialogue.get("id", ""))

## 结束对话
func end_dialogue(dialogue_id: String) -> void:
    dialogue_ended.emit(dialogue_id)

## 处理对话选择
func make_choice(dialogue_id: String, choice_index: int) -> void:
    var dialogue = _dialogues.get(dialogue_id)
    if not dialogue:
        return
    
    var choices = dialogue.get("choices", [])
    if choice_index < 0 or choice_index >= choices.size():
        return
    
    var choice = choices[choice_index]
    var action = choice.get("action", "")
    
    dialogue_choice_made.emit(dialogue_id, choice_index)
    
    # 执行选择动作
    match action:
        "open_shop":
            # 打开商店
            var npc_manager = get_node_or_null("/root/NPCManager")
            if npc_manager:
                npc_manager._open_shop(null)
        "accept_quest":
            # 接受任务
            var quest_manager = get_node_or_null("/root/QuestManager")
            if quest_manager:
                quest_manager.accept_quest("quest_001")
        "end_dialogue":
            end_dialogue(dialogue_id)
```

- [ ] **Step 2: 验证对话系统**

与NPC交互，确认对话正确显示和选择处理。

- [ ] **Step 3: 提交实现**

```bash
git add src/dialogue-system/dialogue_manager.gd
git commit -m "feat: 实现对话系统，支持对话流程和选择"
```

### Phase 5: 战斗奖励系统

#### Task 12: 实现奖励管理器

**Files:**
- Create: `src/reward-system/reward_manager.gd`

- [ ] **Step 1: 创建RewardManager类**

```gdscript
# src/reward-system/reward_manager.gd
class_name RewardManager
extends Node

## 信号
signal reward_granted(reward_type: String, amount: int)
signal card_rewarded(card_id: String)

## 玩家数据引用
var player_data: Dictionary = {
    "gold": 0,
    "experience": 0,
    "cards": []
}

## 初始化
func _ready() -> void:
    # 从存档系统加载玩家数据
    _load_player_data()

## 加载玩家数据
func _load_player_data() -> void:
    var save_system = get_node_or_null("/root/SaveSystem")
    if save_system:
        var saved_data = save_system.load_game()
        if saved_data:
            player_data = saved_data.get("player_data", player_data)

## 保存玩家数据
func _save_player_data() -> void:
    var save_system = get_node_or_null("/root/SaveSystem")
    if save_system:
        save_system.save_game({"player_data": player_data})

## 授予战斗奖励
func grant_battle_rewards(enemy_id: String) -> void:
    var enemy_database = get_node_or_null("/root/EnemyDatabase")
    if not enemy_database:
        return
    
    var enemy_data = enemy_database.get_enemy(enemy_id)
    if enemy_data.is_empty():
        return
    
    var rewards = enemy_data.get("rewards", {})
    
    # 授予金币
    var gold_reward = rewards.get("gold", 0)
    if gold_reward > 0:
        grant_gold(gold_reward)
    
    # 授予经验
    var exp_reward = rewards.get("experience", 0)
    if exp_reward > 0:
        grant_experience(exp_reward)
    
    # 授予卡牌
    var card_rewards = rewards.get("cards", [])
    for card_id in card_rewards:
        grant_card(card_id)

## 授予金币
func grant_gold(amount: int) -> void:
    player_data["gold"] += amount
    reward_granted.emit("gold", amount)
    _save_player_data()
    print("[RewardManager] Granted ", amount, " gold")

## 授予经验
func grant_experience(amount: int) -> void:
    player_data["experience"] += amount
    reward_granted.emit("experience", amount)
    _save_player_data()
    print("[RewardManager] Granted ", amount, " experience")

## 授予卡牌
func grant_card(card_id: String) -> void:
    if not player_data["cards"].has(card_id):
        player_data["cards"].append(card_id)
        card_rewarded.emit(card_id)
        _save_player_data()
        print("[RewardManager] Granted card: ", card_id)

## 获取玩家金币
func get_gold() -> int:
    return player_data.get("gold", 0)

## 获取玩家经验
func get_experience() -> int:
    return player_data.get("experience", 0)

## 获取玩家卡牌
func get_cards() -> Array:
    return player_data.get("cards", [])
```

- [ ] **Step 2: 在战斗胜利时调用奖励系统**

```gdscript
# 在card_battle.gd的_on_battle_won函数中添加
func _on_battle_won() -> void:
    current_state = BattleState.VICTORY
    _add_log("战斗胜利！")
    print("[CardBattle] Battle won!")
    
    # 授予战斗奖励
    var reward_manager = get_node_or_null("/root/RewardManager")
    if reward_manager:
        # 获取击败的敌人ID
        for enemy in enemies:
            var enemy_id = enemy.get("id", "")
            if enemy_id:
                reward_manager.grant_battle_rewards(enemy_id)
    
    # 显示胜利界面
    _show_victory_screen()
```

- [ ] **Step 3: 实现胜利界面**

```gdscript
# 在card_battle.gd中添加
func _show_victory_screen() -> void:
    # 创建胜利UI
    var victory_ui = VBoxContainer.new()
    victory_ui.name = "VictoryScreen"
    victory_ui.alignment = BoxContainer.ALIGNMENT_CENTER
    
    # 胜利标签
    var victory_label = Label.new()
    victory_label.text = "战斗胜利！"
    victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    victory_ui.add_child(victory_label)
    
    # 奖励显示
    var reward_manager = get_node_or_null("/root/RewardManager")
    if reward_manager:
        var gold_label = Label.new()
        gold_label.text = "获得金币: " + str(reward_manager.get_gold())
        gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        victory_ui.add_child(gold_label)
    
    # 继续按钮
    var continue_button = Button.new()
    continue_button.text = "继续探索"
    continue_button.pressed.connect(_on_continue_exploration)
    victory_ui.add_child(continue_button)
    
    # 添加到UI
    $UI.add_child(victory_ui)

func _on_continue_exploration() -> void:
    # 返回世界地图
    get_tree().change_scene_to_file("res://src/scenes/world_exploration.tscn")
```

- [ ] **Step 4: 验证奖励系统**

完成战斗，确认金币、经验和卡牌奖励正确授予。

- [ ] **Step 5: 提交实现**

```bash
git add src/reward-system/ src/scenes/card_battle.gd
git commit -m "feat: 实现战斗奖励系统，支持金币、经验和卡牌奖励"
```

### Phase 6: 区域传送系统

#### Task 13: 实现传送管理器

**Files:**
- Create: `src/teleport-system/teleport_manager.gd`

- [ ] **Step 1: 创建TeleportManager类**

```gdscript
# src/teleport-system/teleport_manager.gd
class_name TeleportManager
extends Node

## 信号
signal teleport_started(from_area: String, to_area: String)
signal teleport_completed(area: String)

## 传送点数据
var _teleport_points: Dictionary = {}

## 初始化
func _ready() -> void:
    _load_teleport_points()

## 加载传送点
func _load_teleport_points() -> void:
    # 定义传送点
    _teleport_points = {
        "forest_to_castle": {
            "from": "forest",
            "to": "castle",
            "position": Vector2(1800, 750),  # 传送点位置
            "unlock_condition": "defeat_skeleton_king"
        },
        "castle_to_ruins": {
            "from": "castle",
            "to": "ruins",
            "position": Vector2(1800, 750),
            "unlock_condition": "defeat_demon_lord"
        },
        "ruins_to_void": {
            "from": "ruins",
            "to": "void",
            "position": Vector2(1800, 750),
            "unlock_condition": "defeat_ancient_golem"
        }
    }

## 获取传送点
func get_teleport_point(point_id: String) -> Dictionary:
    return _teleport_points.get(point_id, {})

## 获取区域传送点
func get_area_teleport_points(area: String) -> Array:
    var points = []
    for point in _teleport_points.values():
        if point.get("from", "") == area:
            points.append(point)
    return points

## 检查传送点是否解锁
func is_teleport_unlocked(point_id: String) -> bool:
    var point = get_teleport_point(point_id)
    if point.is_empty():
        return false
    
    var condition = point.get("unlock_condition", "")
    if condition.is_empty():
        return true
    
    # 检查解锁条件
    var world_state = get_node_or_null("/root/WorldStateManager")
    if world_state:
        return world_state.is_condition_met(condition)
    
    return false

## 执行传送
func teleport(point_id: String) -> bool:
    var point = get_teleport_point(point_id)
    if point.is_empty():
        push_warning("[TeleportManager] Teleport point not found: " + point_id)
        return false
    
    if not is_teleport_unlocked(point_id):
        push_warning("[TeleportManager] Teleport point not unlocked: " + point_id)
        return false
    
    var from_area = point.get("from", "")
    var to_area = point.get("to", "")
    
    teleport_started.emit(from_area, to_area)
    
    # 切换区域
    var world_manager = get_node_or_null("/root/WorldExplorationManager")
    if world_manager:
        world_manager.set_current_area(to_area)
    
    teleport_completed.emit(to_area)
    
    return true

## 传送到指定区域
func teleport_to_area(area: String) -> bool:
    var world_manager = get_node_or_null("/root/WorldExplorationManager")
    if not world_manager:
        return false
    
    if not world_manager.is_area_unlocked(area):
        push_warning("[TeleportManager] Area not unlocked: " + area)
        return false
    
    world_manager.set_current_area(area)
    teleport_completed.emit(area)
    
    return true
```

- [ ] **Step 2: 在世界地图上添加传送点**

```gdscript
# 在world_explorer.gd中添加
func _create_teleport_points() -> void:
    var teleport_manager = get_node_or_null("/root/TeleportManager")
    if not teleport_manager:
        return
    
    var current_area = get_node_or_null("/root/WorldExplorationManager").get_current_area()
    var teleport_points = teleport_manager.get_area_teleport_points(current_area)
    
    for point in teleport_points:
        var point_id = point.get("id", "")
        var position = point.get("position", Vector2.ZERO)
        
        # 创建传送点实体
        var teleport_entity = Area2D.new()
        teleport_entity.name = "Teleport_" + point_id
        teleport_entity.position = position
        
        # 添加碰撞形状
        var collision = CollisionShape2D.new()
        var shape = CircleShape2D.new()
        shape.radius = 50.0
        collision.shape = shape
        teleport_entity.add_child(collision)
        
        # 添加视觉表示
        var sprite = ColorRect.new()
        sprite.color = Color(0.2, 0.8, 1.0, 0.6)  # 蓝色传送门
        sprite.size = Vector2(100, 100)
        sprite.position = Vector2(-50, -50)
        teleport_entity.add_child(sprite)
        
        # 连接信号
        teleport_entity.body_entered.connect(_on_teleport_entered.bind(point_id))
        
        add_child(teleport_entity)

func _on_teleport_entered(body: Node2D, point_id: String) -> void:
    if body.is_in_group("player"):
        var teleport_manager = get_node_or_null("/root/TeleportManager")
        if teleport_manager:
            teleport_manager.teleport(point_id)
```

- [ ] **Step 3: 验证传送系统**

走到传送点，确认区域切换正确。

- [ ] **Step 4: 提交实现**

```bash
git add src/teleport-system/ src/world-exploration-system/world_explorer.gd
git commit -m "feat: 实现区域传送系统，支持传送点和区域切换"
```

### Phase 7: 任务系统基础框架

#### Task 14: 实现任务管理器

**Files:**
- Create: `src/quest-system/quest_manager.gd`
- Create: `src/quest-system/quest_data.gd`

- [ ] **Step 1: 创建QuestData类**

```gdscript
# src/quest-system/quest_data.gd
class_name QuestData
extends Resource

## 任务状态
enum QuestState {
    NOT_STARTED,
    IN_PROGRESS,
    COMPLETED,
    FAILED
}

## 任务属性
@export var quest_id: String = ""
@export var quest_name: String = ""
@export var description: String = ""
@export var quest_type: String = "main"  # main, side, daily
@export var state: QuestState = QuestState.NOT_STARTED

## 任务目标
@export var objectives: Array[Dictionary] = []

## 任务奖励
@export var rewards: Dictionary = {
    "gold": 0,
    "experience": 0,
    "cards": []
}

## 任务依赖
@export var prerequisites: Array[String] = []

## 获取任务信息
func get_info() -> Dictionary:
    return {
        "id": quest_id,
        "name": quest_name,
        "description": description,
        "type": quest_type,
        "state": state,
        "objectives": objectives,
        "rewards": rewards,
        "prerequisites": prerequisites
    }

## 检查任务是否完成
func is_completed() -> bool:
    for objective in objectives:
        if not objective.get("completed", false):
            return false
    return true

## 更新目标进度
func update_objective(objective_id: String, progress: int = 1) -> void:
    for i in range(objectives.size()):
        if objectives[i].get("id", "") == objective_id:
            objectives[i]["current"] = objectives[i].get("current", 0) + progress
            if objectives[i]["current"] >= objectives[i].get("required", 1):
                objectives[i]["completed"] = true
            break
```

- [ ] **Step 2: 创建QuestManager类**

```gdscript
# src/quest-system/quest_manager.gd
class_name QuestManager
extends Node

## 任务数据
var _quests: Dictionary = {}

## 信号
signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_id: String)

## 初始化
func _ready() -> void:
    _load_default_quests()

## 加载默认任务
func _load_default_quests() -> void:
    # 主线任务1：清除森林威胁
    var quest_001 = QuestData.new()
    quest_001.quest_id = "quest_001"
    quest_001.quest_name = "清除森林威胁"
    quest_001.description = "森林里出现了怪物，击败它们保护村庄。"
    quest_001.quest_type = "main"
    quest_001.objectives = [
        {"id": "defeat_skeletons", "description": "击败骷髅战士", "required": 5, "current": 0, "completed": false},
        {"id": "defeat_slimes", "description": "击败史莱姆", "required": 3, "current": 0, "completed": false}
    ]
    quest_001.rewards = {
        "gold": 100,
        "experience": 50,
        "cards": ["lightning"]
    }
    _quests["quest_001"] = quest_001
    
    # 主线任务2：探索废弃城堡
    var quest_002 = QuestData.new()
    quest_002.quest_id = "quest_002"
    quest_002.quest_name = "探索废弃城堡"
    quest_002.description = "调查废弃城堡中的异常情况。"
    quest_002.quest_type = "main"
    quest_002.objectives = [
        {"id": "reach_castle", "description": "到达废弃城堡", "required": 1, "current": 0, "completed": false},
        {"id": "defeat_demon", "description": "击败恶魔", "required": 1, "current": 0, "completed": false}
    ]
    quest_002.rewards = {
        "gold": 200,
        "experience": 100,
        "cards": ["dark_curse"]
    }
    quest_002.prerequisites = ["quest_001"]
    _quests["quest_002"] = quest_002

## 获取任务
func get_quest(quest_id: String) -> QuestData:
    return _quests.get(quest_id)

## 获取所有任务
func get_all_quests() -> Dictionary:
    return _quests

## 获取活跃任务
func get_active_quests() -> Array:
    var active_quests = []
    for quest in _quests.values():
        if quest.state == QuestData.QuestState.IN_PROGRESS:
            active_quests.append(quest)
    return active_quests

## 接受任务
func accept_quest(quest_id: String) -> bool:
    var quest = get_quest(quest_id)
    if not quest:
        push_warning("[QuestManager] Quest not found: " + quest_id)
        return false
    
    if quest.state != QuestData.QuestState.NOT_STARTED:
        push_warning("[QuestManager] Quest already started: " + quest_id)
        return false
    
    # 检查前置任务
    for prereq in quest.prerequisites:
        var prereq_quest = get_quest(prereq)
        if not prereq_quest or prereq_quest.state != QuestData.QuestState.COMPLETED:
            push_warning("[QuestManager] Prerequisite not met: " + prereq)
            return false
    
    quest.state = QuestData.QuestState.IN_PROGRESS
    quest_accepted.emit(quest_id)
    
    print("[QuestManager] Quest accepted: ", quest.quest_name)
    return true

## 完成任务
func complete_quest(quest_id: String) -> bool:
    var quest = get_quest(quest_id)
    if not quest:
        return false
    
    if quest.state != QuestData.QuestState.IN_PROGRESS:
        return false
    
    if not quest.is_completed():
        push_warning("[QuestManager] Quest objectives not completed: " + quest_id)
        return false
    
    quest.state = QuestData.QuestState.COMPLETED
    quest_completed.emit(quest_id)
    
    # 授予奖励
    _grant_quest_rewards(quest)
    
    print("[QuestManager] Quest completed: ", quest.quest_name)
    return true

## 更新任务目标
func update_quest_objective(quest_id: String, objective_id: String, progress: int = 1) -> void:
    var quest = get_quest(quest_id)
    if not quest or quest.state != QuestData.QuestState.IN_PROGRESS:
        return
    
    quest.update_objective(objective_id, progress)
    quest_objective_updated.emit(quest_id, objective_id)
    
    # 检查任务是否完成
    if quest.is_completed():
        complete_quest(quest_id)

## 授予任务奖励
func _grant_quest_rewards(quest: QuestData) -> void:
    var reward_manager = get_node_or_null("/root/RewardManager")
    if not reward_manager:
        return
    
    var rewards = quest.rewards
    
    # 授予金币
    var gold_reward = rewards.get("gold", 0)
    if gold_reward > 0:
        reward_manager.grant_gold(gold_reward)
    
    # 授予经验
    var exp_reward = rewards.get("experience", 0)
    if exp_reward > 0:
        reward_manager.grant_experience(exp_reward)
    
    # 授予卡牌
    var card_rewards = rewards.get("cards", [])
    for card_id in card_rewards:
        reward_manager.grant_card(card_id)
```

- [ ] **Step 3: 在战斗中更新任务进度**

```gdscript
# 在card_battle.gd的_on_enemy_defeated函数中添加
func _on_enemy_defeated(enemy_index: int) -> void:
    print("[CardBattle] Enemy defeated: ", enemy_index)
    _add_log(enemies[enemy_index].get("name", "敌人") + " 被击败！")
    
    # 更新任务进度
    var quest_manager = get_node_or_null("/root/QuestManager")
    if quest_manager:
        var enemy_id = enemies[enemy_index].get("id", "")
        # 根据敌人类型更新不同任务目标
        match enemy_id:
            "skeleton":
                quest_manager.update_quest_objective("quest_001", "defeat_skeletons")
            "slime":
                quest_manager.update_quest_objective("quest_001", "defeat_slimes")
            "demon":
                quest_manager.update_quest_objective("quest_002", "defeat_demon")
```

- [ ] **Step 4: 验证任务系统**

接受任务，击败敌人，确认任务进度更新和完成。

- [ ] **Step 5: 提交实现**

```bash
git add src/quest-system/
git commit -m "feat: 实现任务系统基础框架，支持任务接受、进度更新和完成"
```

### Phase 8: 系统集成和测试

#### Task 15: 集成所有系统

**Files:**
- Modify: `src/main.gd`
- Modify: `src/scenes/world_exploration.gd`

- [ ] **Step 1: 在main.gd中注册新系统**

```gdscript
# 在_create_system_managers函数中添加
func _create_system_managers() -> void:
    # 现有系统...
    
    # 添加新系统
    _create_manager("EnemyDatabase", "res://src/enemy-system/enemy_database.gd")
    _create_manager("EnemySpawner", "res://src/enemy-system/enemy_spawner.gd")
    _create_manager("RewardManager", "res://src/reward-system/reward_manager.gd")
    _create_manager("QuestManager", "res://src/quest-system/quest_manager.gd")
    _create_manager("TeleportManager", "res://src/teleport-system/teleport_manager.gd")
```

- [ ] **Step 2: 在世界探索场景中集成敌人和NPC**

```gdscript
# 在world_exploration.gd中添加
func _ready() -> void:
    # 初始化系统引用
    _initialize_systems()
    
    # 创建敌人
    _spawn_initial_enemies()
    
    # 创建NPC
    _spawn_npcs()
    
    # 创建传送点
    _create_teleport_points()

func _initialize_systems() -> void:
    # 获取系统引用
    enemy_spawner = get_node_or_null("/root/EnemySpawner")
    npc_manager = get_node_or_null("/root/NPCManager")
    teleport_manager = get_node_or_null("/root/TeleportManager")

func _spawn_initial_enemies() -> void:
    if not enemy_spawner:
        return
    
    var world_manager = get_node_or_null("/root/WorldExplorationManager")
    if not world_manager:
        return
    
    var current_area = world_manager.get_current_area()
    var spawn_area = Rect2(100, 100, 1800, 1300)
    
    # 生成初始敌人
    for i in range(3):
        enemy_spawner.spawn_random_enemy(current_area, spawn_area)

func _spawn_npcs() -> void:
    if not npc_manager:
        return
    
    var world_manager = get_node_or_null("/root/WorldExplorationManager")
    if not world_manager:
        return
    
    var current_area = world_manager.get_current_area()
    var area_npcs = world_manager.get_area_npcs(current_area)
    
    for npc_id in area_npcs:
        var npc_data = npc_manager.get_npc(npc_id)
        if npc_data:
            _create_npc_entity(npc_data)

func _create_npc_entity(npc_data: NPCData) -> void:
    # 创建NPC实体
    var npc_entity = Area2D.new()
    npc_entity.name = "NPC_" + npc_data.npc_id
    npc_entity.position = npc_data.position
    
    # 添加碰撞形状
    var collision = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(64, 64)
    collision.shape = shape
    npc_entity.add_child(collision)
    
    # 添加视觉表示
    var sprite = ColorRect.new()
    sprite.color = Color(0.2, 0.8, 0.2, 0.8)  # 绿色NPC
    sprite.size = Vector2(64, 64)
    sprite.position = Vector2(-32, -32)
    npc_entity.add_child(sprite)
    
    # 添加名称标签
    var name_label = Label.new()
    name_label.text = npc_data.npc_name
    name_label.position = Vector2(-30, -50)
    npc_entity.add_child(name_label)
    
    # 连接信号
    npc_entity.body_entered.connect(_on_npc_interacted.bind(npc_data.npc_id))
    
    add_child(npc_entity)

func _on_npc_interacted(body: Node2D, npc_id: String) -> void:
    if body.is_in_group("player"):
        var npc_manager = get_node_or_null("/root/NPCManager")
        if npc_manager:
            npc_manager.interact_with_npc(npc_id)
```

- [ ] **Step 3: 验证系统集成**

运行游戏，测试完整的游戏循环：探索 → 遇敌 → 战斗 → 奖励 → 继续探索。

- [ ] **Step 4: 提交集成**

```bash
git add src/main.gd src/scenes/world_exploration.gd
git commit -m "feat: 集成所有系统，实现完整游戏循环"
```

#### Task 16: 编写单元测试

**Files:**
- Create: `tests/unit/test_card_battle.gd`
- Create: `tests/unit/test_enemy_system.gd`
- Create: `tests/unit/test_reward_system.gd`

- [ ] **Step 1: 创建战斗系统测试**

```gdscript
# tests/unit/test_card_battle.gd
extends GutTest

var card_battle: CardBattle

func before_each():
    card_battle = CardBattle.new()
    add_child(card_battle)

func after_each():
    card_battle.queue_free()

func test_initial_state():
    assert_eq(card_battle.current_state, CardBattle.BattleState.INITIALIZING)
    assert_eq(card_battle.current_turn, 0)
    assert_eq(card_battle.player_energy, CardBattle.MAX_ENERGY)

func test_player_health_system():
    card_battle.player_health = 100
    card_battle.player_max_health = 100
    card_battle.player_defense = 5
    
    card_battle._apply_damage_to_player(10)
    assert_eq(card_battle.player_health, 95)  # 10 - 5 defense = 5 actual damage

func test_card_type_matching():
    # 测试卡牌类型匹配
    var card = CardData.new()
    card.card_type = CardEnums.CardType.DIRECT_DAMAGE
    
    # 这里应该不会崩溃
    card_battle._execute_card_effect(card)
```

- [ ] **Step 2: 创建敌人系统测试**

```gdscript
# tests/unit/test_enemy_system.gd
extends GutTest

var enemy_database: EnemyDatabase

func before_each():
    enemy_database = EnemyDatabase.new()
    add_child(enemy_database)

func after_each():
    enemy_database.queue_free()

func test_enemy_data_loading():
    var skeleton = enemy_database.get_enemy("skeleton")
    assert_false(skeleton.is_empty())
    assert_eq(skeleton.get("name", ""), "骷髅战士")

func test_enemy_not_found():
    var invalid_enemy = enemy_database.get_enemy("invalid")
    assert_true(invalid_enemy.is_empty())
```

- [ ] **Step 3: 创建奖励系统测试**

```gdscript
# tests/unit/test_reward_system.gd
extends GutTest

var reward_manager: RewardManager

func before_each():
    reward_manager = RewardManager.new()
    add_child(reward_manager)

func after_each():
    reward_manager.queue_free()

func test_grant_gold():
    reward_manager.grant_gold(100)
    assert_eq(reward_manager.get_gold(), 100)

func test_grant_experience():
    reward_manager.grant_experience(50)
    assert_eq(reward_manager.get_experience(), 50)

func test_grant_card():
    reward_manager.grant_card("fireball")
    assert_true(reward_manager.get_cards().has("fireball"))
```

- [ ] **Step 4: 运行测试**

```bash
# 运行所有测试
godot --headless --script tests/run_tests.gd
```

- [ ] **Step 5: 提交测试**

```bash
git add tests/unit/
git commit -m "test: 添加核心系统单元测试"
```

---

## 测试策略

### 单元测试
- 战斗系统：测试玩家HP、伤害计算、卡牌效果
- 敌人系统：测试敌人数据加载、敌人生成
- 奖励系统：测试金币、经验、卡牌奖励

### 集成测试
- 战斗流程：测试完整战斗流程，从开始到胜利/失败
- 世界探索：测试敌人生成、NPC交互、传送系统
- 任务系统：测试任务接受、进度更新、完成

### E2E测试
- 游戏循环：测试完整的游戏循环：探索 → 遇敌 → 战斗 → 奖励 → 继续探索
- 系统集成：测试所有系统协同工作

---

## 风险与缓解

### 风险1：系统依赖复杂
- **描述**：多个系统相互依赖，可能导致循环依赖或初始化顺序问题
- **缓解**：使用依赖注入，确保系统按正确顺序初始化

### 风险2：性能问题
- **描述**：大量敌人实体可能导致性能下降
- **缓解**：实现敌人池化，限制同时存在的敌人数量

### 风险3：存档系统兼容性
- **描述**：新系统添加的数据可能与现有存档不兼容
- **缓解**：实现存档版本控制，添加数据迁移逻辑

---

## 成功标准

- [ ] 修复card_battle.gd中的所有bug
- [ ] 实现完整的玩家HP系统
- [ ] 实现Buff/Debuff、召唤、环境效果系统
- [ ] 实现世界地图敌人生成和遭遇
- [ ] 实现NPC交互和对话系统
- [ ] 实现战斗奖励系统
- [ ] 实现区域传送系统
- [ ] 实现任务系统基础框架
- [ ] 所有系统集成并正常工作
- [ ] 通过单元测试和集成测试
- [ ] 完整的游戏循环可玩：探索 → 遇敌 → 战斗 → 奖励 → 继续探索

---

## 执行选项

**计划完成并保存到 `docs/superpowers/plans/2026-06-04-core-gameplay-loop.md`。两种执行方式：**

**1. 子代理驱动（推荐）** - 我为每个任务分派一个新的子代理，任务之间进行审查，快速迭代

**2. 内联执行** - 在当前会话中使用执行计划执行任务，批量执行并设置检查点

**选择哪种方式？**