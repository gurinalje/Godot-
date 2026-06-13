#!/usr/bin/env python3
"""
童话像素背景生成器
为命运卡牌局生成华丽的暗黑童话风格像素背景
"""

import os
import random
from PIL import Image, ImageDraw

# 来自Art Bible的调色板
COLORS = {
    # 主色调
    'abyss_black': (26, 26, 46),      # 深渊黑
    'twilight_gray': (45, 45, 68),    # 暮色灰
    'moonlight_silver': (224, 224, 224),  # 月光银
    'destiny_gold': (232, 200, 74),   # 命运金
    'blood_red': (217, 74, 74),       # 鲜血红
    'life_green': (74, 217, 74),      # 生命绿
    'magic_blue': (74, 144, 217),     # 魔力蓝
    'shadow_purple': (155, 89, 182),  # 暗影紫
    'flame_orange': (230, 126, 34),   # 烈焰橙
    'ice_cyan': (26, 188, 156),       # 寒冰青
    'earth_brown': (139, 69, 19),     # 大地棕
    'dark_red_brown': (93, 58, 26),   # 暗红棕
    'twilight_pink': (255, 182, 193), # 暮光粉
    'twilight_purple': (195, 155, 211),  # 暮光紫
    'void_blue': (44, 62, 80),        # 虚空蓝
    'platinum': (253, 254, 254),      # 白金
    
    # 森林区域专用色
    'forest_dark': (22, 46, 39),
    'forest_medium': (34, 70, 50),
    'forest_light': (50, 100, 60),
    'forest_highlight': (80, 140, 80),
    
    # 童话元素色
    'fairy_glow': (255, 255, 200),
    'magic_sparkle': (200, 220, 255),
    'mushroom_red': (180, 50, 50),
    'mushroom_white': (240, 240, 240),
}

def create_fairy_tale_background(width=1920, height=1080, filename='assets/sprites/environments/fairy_tale_background.png'):
    """创建童话风格的像素背景"""
    
    # 创建图像
    img = Image.new('RGBA', (width, height), COLORS['abyss_black'])
    draw = ImageDraw.Draw(img)
    
    print("正在生成童话像素背景...")
    
    # 1. 绘制渐变天空背景
    print("1. 绘制天空渐变...")
    for y in range(height):
        # 从深蓝到紫色的渐变
        r = int(26 + (y / height) * 20)
        g = int(26 + (y / height) * 10)
        b = int(46 + (y / height) * 30)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))
    
    # 2. 绘制星空
    print("2. 添加星空...")
    random.seed(42)  # 固定随机种子以确保可重现性
    for _ in range(200):
        x = random.randint(0, width-1)
        y = random.randint(0, height//2)
        brightness = random.randint(150, 255)
        size = random.choice([1, 1, 1, 2])  # 大多数是1像素，偶尔2像素
        color = (brightness, brightness, brightness, brightness)
        if size == 1:
            draw.point((x, y), fill=color)
        else:
            draw.rectangle([x, y, x+1, y+1], fill=color)
    
    # 3. 绘制月亮
    print("3. 绘制月亮...")
    moon_x, moon_y = width - 300, 150
    moon_radius = 80
    
    # 月亮光晕
    for r in range(moon_radius + 30, moon_radius, -1):
        alpha = int(100 * (1 - (r - moon_radius) / 30))
        color = (255, 255, 200, alpha)
        draw.ellipse([moon_x - r, moon_y - r, moon_x + r, moon_y + r], fill=color)
    
    # 月亮主体
    draw.ellipse([moon_x - moon_radius, moon_y - moon_radius, 
                  moon_x + moon_radius, moon_y + moon_radius], 
                 fill=COLORS['fairy_glow'])
    
    # 月亮表面细节（环形山）
    crater_color = (220, 220, 180)
    draw.ellipse([moon_x - 30, moon_y - 20, moon_x - 10, moon_y], fill=crater_color)
    draw.ellipse([moon_x + 10, moon_y + 10, moon_x + 30, moon_y + 30], fill=crater_color)
    draw.ellipse([moon_x - 10, moon_y + 20, moon_x + 10, moon_y + 40], fill=crater_color)
    
    # 4. 绘制远景山脉
    print("4. 绘制远景山脉...")
    mountain_color = (30, 30, 50)
    
    # 第一层山脉（最远）
    points = []
    for x in range(0, width + 100, 100):
        y = height - 300 + random.randint(-50, 50)
        points.append((x, y))
    points.append((width, height))
    points.append((0, height))
    draw.polygon(points, fill=mountain_color)
    
    # 第二层山脉（中远）
    mountain_color2 = (35, 35, 55)
    points2 = []
    for x in range(0, width + 80, 80):
        y = height - 250 + random.randint(-40, 40)
        points2.append((x, y))
    points2.append((width, height))
    points2.append((0, height))
    draw.polygon(points2, fill=mountain_color2)
    
    # 5. 绘制森林背景
    print("5. 绘制森林背景...")
    
    # 远景树木（剪影效果）
    tree_color = (20, 40, 35, 180)
    for i in range(30):
        x = random.randint(0, width)
        tree_height = random.randint(100, 200)
        tree_width = random.randint(30, 60)
        y = height - 200 + random.randint(-20, 20)
        
        # 树干
        trunk_width = tree_width // 4
        draw.rectangle([x - trunk_width//2, y, x + trunk_width//2, y + tree_height//2], 
                      fill=(40, 30, 20, 200))
        
        # 树冠（三角形）
        crown_points = [
            (x, y - tree_height),
            (x - tree_width, y),
            (x + tree_width, y)
        ]
        draw.polygon(crown_points, fill=tree_color)
    
    # 6. 绘制中景森林
    print("6. 绘制中景森林...")
    
    # 更近的树木
    for i in range(15):
        x = random.randint(100, width - 100)
        tree_height = random.randint(150, 250)
        tree_width = random.randint(40, 80)
        y = height - 150 + random.randint(-30, 30)
        
        # 树干
        trunk_width = tree_width // 3
        trunk_color = (60, 40, 25, 220)
        draw.rectangle([x - trunk_width//2, y, x + trunk_width//2, y + tree_height//2], 
                      fill=trunk_color)
        
        # 树冠（多层圆形）
        crown_colors = [
            COLORS['forest_dark'],
            COLORS['forest_medium'],
            COLORS['forest_light'],
        ]
        
        for j, color in enumerate(crown_colors):
            radius = tree_width - j * 10
            offset_y = j * 20
            draw.ellipse([x - radius, y - tree_height + offset_y - radius, 
                         x + radius, y - tree_height + offset_y + radius], 
                        fill=color + (200,))
    
    # 7. 绘制地面
    print("7. 绘制地面...")
    
    # 地面渐变
    ground_y = height - 100
    for y in range(ground_y, height):
        alpha = int(255 * (y - ground_y) / 100)
        color = (30, 50, 30, alpha)
        draw.line([(0, y), (width, y)], fill=color)
    
    # 地面纹理（像素点）
    for _ in range(1000):
        x = random.randint(0, width-1)
        y = random.randint(ground_y, height-1)
        brightness = random.randint(20, 60)
        color = (brightness, brightness + 20, brightness, 200)
        draw.point((x, y), fill=color)
    
    # 8. 添加童话元素
    print("8. 添加童话元素...")
    
    # 发光蘑菇
    mushroom_positions = [(200, height - 120), (500, height - 130), 
                         (800, height - 110), (1200, height - 125),
                         (1600, height - 115)]
    
    for mx, my in mushroom_positions:
        # 蘑菇茎
        draw.rectangle([mx - 3, my, mx + 3, my + 15], fill=COLORS['mushroom_white'])
        
        # 蘑菇帽
        draw.ellipse([mx - 10, my - 10, mx + 10, my + 5], fill=COLORS['mushroom_red'])
        
        # 蘑菇斑点
        draw.ellipse([mx - 5, my - 5, mx - 2, my - 2], fill=COLORS['mushroom_white'])
        draw.ellipse([mx + 2, my - 7, mx + 5, my - 4], fill=COLORS['mushroom_white'])
        
        # 发光效果
        for r in range(15, 5, -1):
            alpha = int(80 * (1 - (r - 5) / 10))
            color = (200, 255, 200, alpha)
            draw.ellipse([mx - r, my - r, mx + r, my + r], fill=color)
    
    # 9. 添加魔法粒子效果
    print("9. 添加魔法粒子...")
    
    for _ in range(50):
        x = random.randint(0, width-1)
        y = random.randint(0, height-1)
        
        # 随机选择粒子颜色
        particle_color = random.choice([
            COLORS['fairy_glow'],
            COLORS['magic_sparkle'],
            COLORS['destiny_gold'],
            COLORS['twilight_pink'],
        ])
        
        # 粒子大小
        size = random.randint(1, 3)
        
        # 绘制粒子
        if size == 1:
            draw.point((x, y), fill=particle_color + (random.randint(100, 200),))
        else:
            draw.ellipse([x - size, y - size, x + size, y + size], 
                        fill=particle_color + (random.randint(100, 200),))
    
    # 10. 添加装饰性边框（符合美术圣经的装饰性边框原则）
    print("10. 添加装饰性边框...")
    
    # 顶部装饰边框
    border_color = COLORS['destiny_gold']
    border_thickness = 3
    
    # 顶部边框
    draw.rectangle([0, 0, width, border_thickness], fill=border_color)
    
    # 底部边框
    draw.rectangle([0, height - border_thickness, width, height], fill=border_color)
    
    # 左边框
    draw.rectangle([0, 0, border_thickness, height], fill=border_color)
    
    # 右边框
    draw.rectangle([width - border_thickness, 0, width, height], fill=border_color)
    
    # 角落装饰
    corner_size = 30
    corner_color = COLORS['destiny_gold']
    
    # 左上角
    draw.rectangle([0, 0, corner_size, border_thickness], fill=corner_color)
    draw.rectangle([0, 0, border_thickness, corner_size], fill=corner_color)
    
    # 右上角
    draw.rectangle([width - corner_size, 0, width, border_thickness], fill=corner_color)
    draw.rectangle([width - border_thickness, 0, width, corner_size], fill=corner_color)
    
    # 左下角
    draw.rectangle([0, height - border_thickness, corner_size, height], fill=corner_color)
    draw.rectangle([0, height - corner_size, border_thickness, height], fill=corner_color)
    
    # 右下角
    draw.rectangle([width - corner_size, height - border_thickness, width, height], fill=corner_color)
    draw.rectangle([width - border_thickness, height - corner_size, width, height], fill=corner_color)
    
    # 11. 添加命运符号（符合美术圣经的符号化构图原则）
    print("11. 添加命运符号...")
    
    # 在天空中添加星座图案
    constellation_points = [
        (width - 400, 100), (width - 350, 120), (width - 300, 90),
        (width - 250, 130), (width - 200, 110)
    ]
    
    # 绘制星座连线
    for i in range(len(constellation_points) - 1):
        x1, y1 = constellation_points[i]
        x2, y2 = constellation_points[i + 1]
        draw.line([(x1, y1), (x2, y2)], fill=COLORS['magic_sparkle'] + (150,), width=1)
    
    # 绘制星座点
    for x, y in constellation_points:
        draw.ellipse([x - 3, y - 3, x + 3, y + 3], fill=COLORS['fairy_glow'])
    
    # 保存图像
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    img.save(filename)
    print(f"\n童话像素背景已生成: {filename}")
    print(f"图像尺寸: {width}x{height}")
    
    return filename

def main():
    """主函数"""
    print("=== 命运卡牌局 - 童话像素背景生成器 ===")
    print("视觉风格: 华丽的暗黑童话\n")
    
    # 生成童话背景
    create_fairy_tale_background()
    
    print("\n=== 生成完成！ ===")
    print("背景特点:")
    print("1. 暗黑童话风格的渐变天空")
    print("2. 神秘的星空和月亮")
    print("3. 远景山脉和森林剪影")
    print("4. 发光的童话蘑菇")
    print("5. 魔法粒子效果")
    print("6. 装饰性边框（符合美术圣经原则）")
    print("7. 命运符号和星座图案")

if __name__ == '__main__':
    main()