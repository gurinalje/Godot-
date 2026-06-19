#!/usr/bin/env python3
"""
像素艺术生成器 - 为命运卡牌局生成游戏素材
使用PIL/Pillow生成简单的像素艺术占位符
"""

import os
from PIL import Image, ImageDraw

# 颜色定义 - 来自Art Bible的调色板
COLORS = {
    # 主色调
    'dark_purple': (48, 25, 52),
    'deep_blue': (25, 25, 112),
    'gold': (255, 215, 0),
    'crimson': (220, 20, 60),
    'emerald': (0, 128, 0),
    
    # 角色颜色
    'skin': (255, 218, 185),
    'hair_brown': (139, 69, 19),
    'armor_silver': (192, 192, 192),
    'armor_dark': (64, 64, 64),
    'cloak_red': (139, 0, 0),
    
    # 敌人颜色
    'shadow': (28, 28, 28),
    'slime_green': (0, 200, 0),
    'skeleton_white': (240, 240, 240),
    'demon_red': (180, 0, 0),
    
    # NPC颜色
    'merchant_robe': (75, 0, 130),
    'elder_robe': (0, 100, 0),
    
    # UI颜色
    'health_red': (200, 0, 0),
    'mana_blue': (0, 0, 200),
    'exp_green': (0, 200, 0),
    
    # 环境颜色
    'grass_green': (34, 139, 34),
    'stone_gray': (128, 128, 128),
    'wood_brown': (139, 90, 43),
}

def create_pixel_character(width, height, pixels, filename):
    """创建像素角色图像"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    for x, y, color in pixels:
        draw.point((x, y), fill=color)
    
    img.save(filename)
    print(f"Created: {filename}")

def generate_player_character():
    """生成玩家角色精灵 - 16x16像素"""
    width, height = 16, 16
    
    # 玩家角色像素数据（简化版）
    pixels = []
    
    # 头部（金色头发）
    for x in range(5, 11):
        for y in range(2, 5):
            pixels.append((x, y, COLORS['hair_brown']))
    
    # 脸部
    for x in range(6, 10):
        for y in range(4, 7):
            pixels.append((x, y, COLORS['skin']))
    
    # 身体（红色披风）
    for x in range(4, 12):
        for y in range(7, 12):
            pixels.append((x, y, COLORS['cloak_red']))
    
    # 腿部
    for x in range(5, 7):
        for y in range(12, 14):
            pixels.append((x, y, COLORS['armor_dark']))
    for x in range(9, 11):
        for y in range(12, 14):
            pixels.append((x, y, COLORS['armor_dark']))
    
    # 眼睛
    pixels.append((7, 5, (0, 0, 0)))
    pixels.append((9, 5, (0, 0, 0)))
    
    create_pixel_character(width, height, pixels, 'assets/sprites/characters/player.png')

def generate_npc_merchant():
    """生成商人NPC精灵 - 16x16像素"""
    width, height = 16, 16
    pixels = []
    
    # 头部（帽子）
    for x in range(4, 12):
        for y in range(1, 3):
            pixels.append((x, y, COLORS['merchant_robe']))
    
    # 脸部
    for x in range(6, 10):
        for y in range(3, 6):
            pixels.append((x, y, COLORS['skin']))
    
    # 身体（紫色长袍）
    for x in range(4, 12):
        for y in range(6, 12):
            pixels.append((x, y, COLORS['merchant_robe']))
    
    # 眼睛
    pixels.append((7, 4, (0, 0, 0)))
    pixels.append((9, 4, (0, 0, 0)))
    
    create_pixel_character(width, height, pixels, 'assets/sprites/characters/npc_merchant.png')

def generate_enemy_shadow():
    """生成暗影敌人精灵 - 16x16像素"""
    width, height = 16, 16
    pixels = []
    
    # 暗影身体（不对称设计）
    for x in range(3, 10):
        for y in range(4, 12):
            pixels.append((x, y, COLORS['shadow']))
    
    # 尖锐的头部
    for x in range(5, 8):
        for y in range(2, 4):
            pixels.append((x, y, COLORS['shadow']))
    
    # 红色眼睛
    pixels.append((5, 5, COLORS['demon_red']))
    pixels.append((8, 5, COLORS['demon_red']))
    
    create_pixel_character(width, height, pixels, 'assets/sprites/enemies/shadow.png')

def generate_enemy_slime():
    """生成史莱姆敌人精灵 - 16x16像素"""
    width, height = 16, 16
    pixels = []
    
    # 史莱姆身体（圆形）
    for x in range(4, 12):
        for y in range(5, 13):
            # 创建圆形效果
            if abs(x-8) + abs(y-9) < 6:
                pixels.append((x, y, COLORS['slime_green']))
    
    # 眼睛
    pixels.append((6, 7, (0, 0, 0)))
    pixels.append((10, 7, (0, 0, 0)))
    
    create_pixel_character(width, height, pixels, 'assets/sprites/enemies/slime.png')

def generate_card_placeholder():
    """生成卡牌占位符 - 32x48像素"""
    width, height = 32, 48
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 卡牌边框（装饰性）
    draw.rectangle([0, 0, 31, 47], outline=COLORS['gold'], width=2)
    
    # 卡牌背景
    draw.rectangle([2, 2, 29, 45], fill=COLORS['dark_purple'])
    
    # 卡牌类型区域
    draw.rectangle([4, 4, 27, 20], fill=COLORS['deep_blue'])
    
    # 卡牌名称区域
    draw.rectangle([4, 22, 27, 30], fill=COLORS['dark_purple'])
    
    # 卡牌描述区域
    draw.rectangle([4, 32, 27, 43], fill=COLORS['deep_blue'])
    
    img.save('assets/sprites/cards/card_placeholder.png')
    print("Created: assets/sprites/cards/card_placeholder.png")

def generate_ui_elements():
    """生成UI元素"""
    # 生命条背景
    img = Image.new('RGBA', (64, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, 63, 15], fill=COLORS['dark_purple'], outline=COLORS['gold'])
    img.save('assets/sprites/ui/health_bar_bg.png')
    
    # 生命条填充
    img = Image.new('RGBA', (60, 12), COLORS['health_red'])
    img.save('assets/sprites/ui/health_bar_fill.png')
    
    # 法力条填充
    img = Image.new('RGBA', (60, 12), COLORS['mana_blue'])
    img.save('assets/sprites/ui/mana_bar_fill.png')
    
    # 按钮
    img = Image.new('RGBA', (64, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, 63, 31], fill=COLORS['deep_blue'], outline=COLORS['gold'])
    img.save('assets/sprites/ui/button.png')
    
    print("Created: UI elements")

def generate_environment():
    """生成环境元素"""
    # 草地瓦片
    img = Image.new('RGBA', (16, 16), COLORS['grass_green'])
    img.save('assets/sprites/environment/grass.png')
    
    # 石头瓦片
    img = Image.new('RGBA', (16, 16), COLORS['stone_gray'])
    img.save('assets/sprites/environment/stone.png')
    
    # 树木
    img = Image.new('RGBA', (16, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # 树干
    draw.rectangle([6, 16, 9, 31], fill=COLORS['wood_brown'])
    # 树冠
    for x in range(2, 14):
        for y in range(2, 16):
            if abs(x-8) + abs(y-8) < 8:
                draw.point((x, y), fill=COLORS['emerald'])
    img.save('assets/sprites/environment/tree.png')
    
    print("Created: Environment elements")

def main():
    """主函数 - 生成所有素材"""
    print("=== 命运卡牌局 - 像素艺术生成器 ===")
    print("正在生成游戏素材...\n")
    
    # 创建目录
    os.makedirs('assets/sprites/characters', exist_ok=True)
    os.makedirs('assets/sprites/enemies', exist_ok=True)
    os.makedirs('assets/sprites/cards', exist_ok=True)
    os.makedirs('assets/sprites/ui', exist_ok=True)
    os.makedirs('assets/sprites/environment', exist_ok=True)
    
    # 生成角色
    print("1. 生成角色精灵...")
    generate_player_character()
    generate_npc_merchant()
    
    # 生成敌人
    print("\n2. 生成敌人精灵...")
    generate_enemy_shadow()
    generate_enemy_slime()
    
    # 生成卡牌
    print("\n3. 生成卡牌占位符...")
    generate_card_placeholder()
    
    # 生成UI元素
    print("\n4. 生成UI元素...")
    generate_ui_elements()
    
    # 生成环境元素
    print("\n5. 生成环境元素...")
    generate_environment()
    
    print("\n=== 素材生成完成！ ===")
    print(f"总共生成了 10 个素材文件")
    print("\n素材位置：assets/sprites/")

if __name__ == '__main__':
    main()
