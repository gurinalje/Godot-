# 命运卡牌局游戏代码完整性修复计划

本计划旨在修复游戏中所有导致运行时崩溃的致命错误、逻辑漏洞以及未实现的系统关联，以使游戏能在 Godot 4.6 中正常跑通并恢复完整的实机体验。

## 使用者审查要求

> [!IMPORTANT]
> **系统交互大重构**：本修复将修改 15+ 个核心 GDScript 文件，将原有的直接挂载于 `/root` 的 Autoload 获取方式全部重构为通过 `GameManager.get_system("SystemName")` 动态获取。这会大幅提升系统的健壮性，但也是一项重大的架构调整。

> [!WARNING]
> **QuestSystem 任务系统集成**：由于项目中的 `QuestSystem` 原本未被实例化，我们将在 `GameManager` 的系统列表中动态注册它（路径：`res://src/systems/quest_system.gd`）。这意味着它将作为 GameManager 的子节点被统一管理，其状态数据也可以被正确存档。

## 待决策/开放问题

> [!NOTE]
> **音频总线配置**：由于项目根目录下没有自定义的 `default_bus_layout.tres`，将音频播放器的总线设为 `"Music"` 和 `"SFX"` 会导致报错。我们将在修复中把默认总线指向 `"Master"`。后续如果你在 Godot 编辑器中手动添加了这两个总线，本修复的代码也将兼容。

---

## 拟定变更

### 1. 核心系统管理与启动逻辑 (GameManager & Main)

#### [MODIFY] [game_manager.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/autoload/game_manager.gd)
*   在 `_initialize_systems()` 中注册 `QuestSystem`：
    ```gdscript
    _create_system("QuestSystem", "res://src/systems/quest_system.gd")
    ```
*   在 `reset_game()` 中，重新加载系统前，通过 `queue_free()` 彻底清理旧的子系统节点，并清空 `systems` 字典，避免内存泄漏和节点重复：
    ```gdscript
    for system in systems.values():
        system.queue_free()
    systems.clear()
    ```

#### [MODIFY] [main.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/main.gd)
*   修复 `_initialize_systems()` 结束时发射 `systems_initialized` 信号：
    ```gdscript
    systems_initialized.emit()
    ```
*   在 `_ready()` 中等待 `GameManager` 初始化前，先检查其是否已初始化，避免由于时序问题导致加载界面死锁：
    ```gdscript
    if game_manager and not game_manager.is_initialized():
        await game_manager.game_initialized
    ```

---

### 2. 战斗与伤害计算系统 (CardBattle & DamageCalculator)

#### [MODIFY] [card_battle_system.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/card-battle-system/card_battle_system.gd)
*   将 `_ready()` 中所有 `/root/` 的子系统获取路径全部改写为通过 `GameManager`：
    ```gdscript
    damage_calculator = GameManager.get_system("DamageCalculator")
    combo_manager = GameManager.get_system("ComboChainManager")
    # ... 其余系统同理
    ```
*   修正对 `damage_calculator.calculate_damage()` 的调用，传足 6 个参数，并调整读取的返回键（从 `damage` 改为 `final_damage`）。

#### [MODIFY] [damage_calculator.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/damage-calculation/damage_calculator.gd)
*   或者更新 `calculate_damage` 的接口，使其支持 4 参数的简易调用，作为安全重载。

#### [MODIFY] [card_battle.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/scenes/card_battle.gd)
*   将所有 `effect.has("duration")` 等 Resource 上的 `has` 误用改为 `"duration" in effect`。

---

### 3. 选择与存档系统 (Choice & Save)

#### [MODIFY] [save_slot_manager.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/save-system/save_slot_manager.gd)
*   将 `_collect_game_state` 和 `_restore_game_state` 中获取 `QuestSystem` 的代码修改为：
    ```gdscript
    var quest_system = game_manager.get_system("QuestSystem")
    ```

#### [MODIFY] [choice_manager.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/choice-system/choice_manager.gd)
*   在 `_add_story_mark` 中，修改获取故事印记系统的代码：
    ```gdscript
    var story_mark_system = GameManager.get_system("StoryMarkManager")
    ```

#### [MODIFY] [choice_system.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/choice-system/choice_system.gd)
*   将所有道德与剧情后果处理中获取 `StoryMarkManager` 和 `NarrativeManager` 的代码，统一修改为通过 `GameManager` 获取。

---

### 4. 背包、商店与卡组系统 (NPC, Deck & Exploration)

#### [MODIFY] [npc_interaction_system.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/npc-system/npc_interaction_system.gd)
*   将 `_add_card_to_deck` 中获取 `CardDatabase` 和 `DeckBuildingManager` 的节点获取方式改为 `GameManager.get_system()`。

#### [MODIFY] [deck_builder.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/deck-building-system/deck_builder.gd)
*   修改 `_initialize_available_cards` 和 `_get_card_data`，将 `/root/CardDatabase` 的获取修改为通过 `GameManager` 获取。

#### [MODIFY] [deck_building_manager.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/deck-building-system/deck_building_manager.gd)
*   修改 `/root/CardDatabase` 获取方式。

#### [MODIFY] [world_explorer.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/world-exploration-system/world_explorer.gd)
*   修改获取 `WorldStateManager` 的方式。

---

### 5. 音频与连锁系统细节 (Audio & Combo)

#### [MODIFY] [audio_manager.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/audio-system/audio_manager.gd)
*   重构 `_scan_audio_directory()` 逻辑，使其支持递归读取子文件夹下的音效文件。
*   将默认总线引用设为安全退守的 `"Master"`（除非用户在此之前手动创建了对应的 Bus 布局）。

#### [MODIFY] [combo_chain.gd](file:///d:/ziyuan/Games/OpenCodeGameStudios-master/src/combo-chain-system/combo_chain.gd)
*   修改 L241 行 `from_dict()` 里的字典默认值从 `[]` 改为 `{}`：
    ```gdscript
    chain.trigger_conditions = data.get("trigger_conditions", {})
    ```

---

## 验证计划

### 自动化测试
*   运行游戏的主场景（`res://src/main.tscn`），检查从启动、加载到主菜单的整个生命周期是否有红字报错。

### 手动验证
1.  **启动测试**：启动游戏，观察 loading 条和过渡动画是否正确加载，确认主菜单正常显示并点击“新游戏”。
2.  **游戏探索与 NPC 商店测试**：进入探索场景，与地图上的 NPC 交互，进入商店并尝试购买卡牌，确认卡牌能成功加入玩家卡组（不再提示 CardDatabase 未找到）。
3.  **战斗伤害计算测试**：触发卡牌战斗，打出伤害卡，确认伤害数值在控制台和 UI 上被正确计算并正常结算，不发生空引用崩溃。
4.  **存档槽测试**：尝试保存游戏并退出，再次进入时载入自动存档，核对玩家血量、金币以及任务数据是否恢复。
