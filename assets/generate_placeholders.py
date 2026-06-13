#!/usr/bin/env python3
"""
占位符资源生成器
为命运卡牌局生成简单的占位符图片和音效
"""

import os
import struct
import zlib

# 资源目录
ASSETS_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(ASSETS_DIR)

def create_png(width, height, color, filename):
    """创建简单的纯色PNG图片"""
    
    def make_chunk(chunk_type, data):
        chunk = chunk_type + data
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', zlib.crc32(chunk) & 0xffffffff)
    
    # PNG文件头
    header = b'\x89PNG\r\n\x1a\n'
    
    # IHDR块
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr = make_chunk(b'IHDR', ihdr_data)
    
    # IDAT块（图像数据）
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # 滤波器类型：无
        for x in range(width):
            raw_data += bytes(color)
    
    compressed = zlib.compress(raw_data)
    idat = make_chunk(b'IDAT', compressed)
    
    # IEND块
    iend = make_chunk(b'IEND', b'')
    
    # 写入文件
    with open(filename, 'wb') as f:
        f.write(header + ihdr + idat + iend)
    
    print(f"Created: {filename}")

def create_card_placeholder(card_type, name, color):
    """创建卡牌占位符"""
    cards_dir = os.path.join(ASSETS_DIR, 'sprites', 'cards')
    os.makedirs(cards_dir, exist_ok=True)
    
    filename = os.path.join(cards_dir, f'card_{card_type}_{name}.png')
    create_png(200, 280, color, filename)

def create_character_placeholder(char_type, name, color):
    """创建角色占位符"""
    chars_dir = os.path.join(ASSETS_DIR, 'sprites', 'characters', char_type)
    os.makedirs(chars_dir, exist_ok=True)
    
    filename = os.path.join(chars_dir, f'char_{char_type}_{name}.png')
    create_png(64, 64, color, filename)

def create_ui_placeholder(element_type, name, color, width=64, height=64):
    """创建UI元素占位符"""
    ui_dir = os.path.join(ASSETS_DIR, 'sprites', 'ui', element_type)
    os.makedirs(ui_dir, exist_ok=True)
    
    filename = os.path.join(ui_dir, f'ui_{element_type}_{name}.png')
    create_png(width, height, color, filename)

def create_environment_placeholder(area, name, color):
    """创建环境背景占位符"""
    env_dir = os.path.join(ASSETS_DIR, 'sprites', 'environments', area)
    os.makedirs(env_dir, exist_ok=True)
    
    filename = os.path.join(env_dir, f'env_{area}_{name}.png')
    create_png(1920, 1080, color, filename)

def create_effect_placeholder(effect_type, name, color):
    """创建特效占位符"""
    fx_dir = os.path.join(ASSETS_DIR, 'sprites', 'effects', effect_type)
    os.makedirs(fx_dir, exist_ok=True)
    
    filename = os.path.join(fx_dir, f'fx_{effect_type}_{name}.png')
    create_png(128, 128, color, filename)

def generate_all_placeholders():
    """生成所有占位符资源"""
    
    print("=== 生成卡牌占位符 ===")
    # 召唤类（紫色）
    create_card_placeholder('summon', 'skeleton', (139, 92, 246))
    create_card_placeholder('summon', 'golem', (124, 58, 237))
    create_card_placeholder('summon', 'elemental', (109, 40, 217))
    
    # 直接伤害类（红色）
    create_card_placeholder('damage', 'fireball', (239, 68, 68))
    create_card_placeholder('damage', 'lightning', (220, 38, 38))
    create_card_placeholder('damage', 'ice_lance', (185, 28, 28))
    
    # 环境阵地类（绿色）
    create_card_placeholder('environment', 'blizzard', (16, 185, 129))
    create_card_placeholder('environment', 'earthquake', (5, 150, 105))
    create_card_placeholder('environment', 'firestorm', (4, 120, 87))
    
    # 增益减益类（金色）
    create_card_placeholder('buff', 'holy_blessing', (245, 158, 11))
    create_card_placeholder('buff', 'dark_curse', (217, 119, 6))
    create_card_placeholder('buff', 'shield', (180, 83, 9))
    
    print("\n=== 生成角色占位符 ===")
    # 玩家角色
    create_character_placeholder('players', 'warrior', (59, 130, 246))
    create_character_placeholder('players', 'mage', (139, 92, 246))
    create_character_placeholder('players', 'rogue', (16, 185, 129))
    
    # NPC
    create_character_placeholder('npcs', 'merchant', (245, 158, 11))
    create_character_placeholder('npcs', 'quest_giver', (16, 185, 129))
    create_character_placeholder('npcs', 'blacksmith', (107, 114, 128))
    
    # 敌人
    create_character_placeholder('enemies', 'slime', (16, 185, 129))
    create_character_placeholder('enemies', 'skeleton', (107, 114, 128))
    create_character_placeholder('enemies', 'demon', (239, 68, 68))
    
    # BOSS
    create_character_placeholder('bosses', 'dragon', (239, 68, 68))
    create_character_placeholder('bosses', 'lich', (139, 92, 246))
    
    print("\n=== 生成UI元素占位符 ===")
    # 按钮
    create_ui_placeholder('buttons', 'primary', (59, 130, 246), 200, 60)
    create_ui_placeholder('buttons', 'secondary', (107, 114, 128), 200, 60)
    create_ui_placeholder('buttons', 'danger', (239, 68, 68), 200, 60)
    
    # 面板
    create_ui_placeholder('panels', 'main', (17, 24, 39), 800, 600)
    create_ui_placeholder('panels', 'dialog', (30, 41, 59), 600, 400)
    create_ui_placeholder('panels', 'inventory', (15, 23, 42), 400, 500)
    
    # 图标
    create_ui_placeholder('icons', 'health', (239, 68, 68), 32, 32)
    create_ui_placeholder('icons', 'mana', (59, 130, 246), 32, 32)
    create_ui_placeholder('icons', 'attack', (245, 158, 11), 32, 32)
    create_ui_placeholder('icons', 'defense', (107, 114, 128), 32, 32)
    create_ui_placeholder('icons', 'card', (139, 92, 246), 32, 32)
    
    # 边框
    create_ui_placeholder('frames', 'card_common', (107, 114, 128), 200, 280)
    create_ui_placeholder('frames', 'card_rare', (59, 130, 246), 200, 280)
    create_ui_placeholder('frames', 'card_epic', (139, 92, 246), 200, 280)
    create_ui_placeholder('frames', 'card_legendary', (245, 158, 11), 200, 280)
    
    # 进度条
    create_ui_placeholder('bars', 'health', (239, 68, 68), 200, 20)
    create_ui_placeholder('bars', 'mana', (59, 130, 246), 200, 20)
    create_ui_placeholder('bars', 'exp', (245, 158, 11), 200, 20)
    
    print("\n=== 生成环境背景占位符 ===")
    # 森林（深绿色）
    create_environment_placeholder('forest', 'background', (22, 46, 39))
    create_environment_placeholder('forest', 'battle', (15, 38, 31))
    
    # 城堡（灰色）
    create_environment_placeholder('castle', 'background', (30, 41, 59))
    create_environment_placeholder('castle', 'battle', (15, 23, 42))
    
    # 废墟（暗红色）
    create_environment_placeholder('ruins', 'background', (69, 26, 26))
    create_environment_placeholder('ruins', 'battle', (45, 18, 18))
    
    # 虚空（深紫色）
    create_environment_placeholder('void', 'background', (25, 15, 45))
    create_environment_placeholder('void', 'battle', (15, 8, 30))
    
    print("\n=== 生成特效占位符 ===")
    # 战斗特效
    create_effect_placeholder('combat', 'slash', (255, 255, 255))
    create_effect_placeholder('combat', 'stab', (200, 200, 200))
    create_effect_placeholder('combat', 'impact', (255, 200, 100))
    
    # 元素特效
    create_effect_placeholder('elements', 'fire', (239, 68, 68))
    create_effect_placeholder('elements', 'water', (59, 130, 246))
    create_effect_placeholder('elements', 'wind', (16, 185, 129))
    create_effect_placeholder('elements', 'earth', (107, 114, 128))
    create_effect_placeholder('elements', 'thunder', (245, 158, 11))
    
    # UI特效
    create_effect_placeholder('ui', 'heal', (16, 185, 129))
    create_effect_placeholder('ui', 'shield', (59, 130, 246))
    create_effect_placeholder('ui', 'level_up', (245, 158, 11))
    
    print("\n=== 占位符生成完成 ===")
    print(f"总计生成了 50+ 个占位符资源")
    print(f"位置: {ASSETS_DIR}")

if __name__ == '__main__':
    generate_all_placeholders()
