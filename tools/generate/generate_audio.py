#!/usr/bin/env python3
"""
音效生成器
为命运卡牌局生成基础音效
"""

import os
import struct
import math
import random

# 音频目录
AUDIO_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'audio')

def create_wav(filename, samples, sample_rate=44100):
    """创建WAV文件"""
    # 确保目录存在
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    # WAV文件参数
    num_channels = 1  # 单声道
    bits_per_sample = 16
    byte_rate = sample_rate * num_channels * bits_per_sample // 8
    block_align = num_channels * bits_per_sample // 8
    
    # 转换为16位整数
    samples_int = [int(s * 32767) for s in samples]
    samples_bytes = struct.pack(f'<{len(samples_int)}h', *samples_int)
    
    # WAV文件头
    header = struct.pack('<4sI4s', b'RIFF', 36 + len(samples_bytes), b'WAVE')
    fmt = struct.pack('<4sIHHIIHH', b'fmt ', 16, 1, num_channels, sample_rate, byte_rate, block_align, bits_per_sample)
    data_header = struct.pack('<4sI', b'data', len(samples_bytes))
    
    # 写入文件
    with open(filename, 'wb') as f:
        f.write(header + fmt + data_header + samples_bytes)
    
    print(f"Created: {filename}")

def generate_tone(frequency, duration, volume=0.5, sample_rate=44100):
    """生成纯音调"""
    samples = []
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        sample = volume * math.sin(2 * math.pi * frequency * t)
        samples.append(sample)
    return samples

def generate_noise(duration, volume=0.3, sample_rate=44100):
    """生成白噪声"""
    samples = []
    for i in range(int(sample_rate * duration)):
        sample = volume * (random.random() * 2 - 1)
        samples.append(sample)
    return samples

def apply_envelope(samples, attack=0.01, decay=0.1, sustain=0.7, release=0.1, sample_rate=44100):
    """应用ADSR包络"""
    total_samples = len(samples)
    attack_samples = int(attack * sample_rate)
    decay_samples = int(decay * sample_rate)
    release_samples = int(release * sample_rate)
    sustain_samples = total_samples - attack_samples - decay_samples - release_samples
    
    if sustain_samples < 0:
        # 如果总长度不够，调整各阶段
        attack_samples = total_samples // 4
        decay_samples = total_samples // 4
        release_samples = total_samples // 4
        sustain_samples = total_samples - attack_samples - decay_samples - release_samples
    
    result = []
    for i in range(total_samples):
        if i < attack_samples:
            # Attack阶段
            envelope = i / attack_samples
        elif i < attack_samples + decay_samples:
            # Decay阶段
            decay_progress = (i - attack_samples) / decay_samples
            envelope = 1.0 - (1.0 - sustain) * decay_progress
        elif i < attack_samples + decay_samples + sustain_samples:
            # Sustain阶段
            envelope = sustain
        else:
            # Release阶段
            release_progress = (i - attack_samples - decay_samples - sustain_samples) / release_samples
            envelope = sustain * (1.0 - release_progress)
        
        result.append(samples[i] * envelope)
    
    return result

def generate_card_draw():
    """生成抽卡音效"""
    # 快速上升音调
    samples = []
    for i in range(4410):  # 0.1秒
        t = i / 44100
        freq = 800 + 400 * t * 10  # 从800Hz上升到1200Hz
        sample = 0.5 * math.sin(2 * math.pi * freq * t)
        samples.append(sample)
    
    return apply_envelope(samples, attack=0.005, decay=0.02, sustain=0.6, release=0.05)

def generate_card_play():
    """生成出牌音效"""
    # 两个快速音调
    samples = []
    for i in range(6615):  # 0.15秒
        t = i / 44100
        freq1 = 600 + 200 * (i / 6615)
        freq2 = 900 + 300 * (i / 6615)
        sample = 0.3 * math.sin(2 * math.pi * freq1 * t) + 0.2 * math.sin(2 * math.pi * freq2 * t)
        samples.append(sample)
    
    return apply_envelope(samples, attack=0.005, decay=0.03, sustain=0.5, release=0.05)

def generate_attack_hit():
    """生成攻击命中音效"""
    # 噪声 + 低频冲击
    noise = generate_noise(0.1, volume=0.4)
    tone = generate_tone(150, 0.1, volume=0.6)
    
    samples = []
    for i in range(len(noise)):
        sample = noise[i] + tone[i]
        samples.append(min(1.0, max(-1.0, sample)))
    
    return apply_envelope(samples, attack=0.001, decay=0.02, sustain=0.3, release=0.05)

def generate_attack_critical():
    """生成暴击音效"""
    # 更强的冲击 + 高频
    noise = generate_noise(0.15, volume=0.5)
    tone1 = generate_tone(200, 0.15, volume=0.7)
    tone2 = generate_tone(800, 0.1, volume=0.3)
    
    samples = []
    for i in range(len(noise)):
        sample = noise[i] + tone1[i]
        if i < len(tone2):
            sample += tone2[i]
        samples.append(min(1.0, max(-1.0, sample)))
    
    return apply_envelope(samples, attack=0.001, decay=0.03, sustain=0.4, release=0.08)

def generate_fire_effect():
    """生成火焰音效"""
    # 噪声 + 低频隆隆声
    noise = generate_noise(0.3, volume=0.4)
    rumble = generate_tone(80, 0.3, volume=0.5)
    
    samples = []
    for i in range(len(noise)):
        # 添加随机波动
        variation = random.random() * 0.2
        sample = noise[i] * (0.8 + variation) + rumble[i]
        samples.append(min(1.0, max(-1.0, sample)))
    
    return apply_envelope(samples, attack=0.05, decay=0.1, sustain=0.6, release=0.1)

def generate_water_effect():
    """生成水元素音效"""
    # 气泡声
    samples = []
    for i in range(13230):  # 0.3秒
        t = i / 44100
        # 多个气泡频率
        freq1 = 400 + 200 * math.sin(t * 20)
        freq2 = 600 + 300 * math.sin(t * 30)
        sample = 0.3 * math.sin(2 * math.pi * freq1 * t) + 0.2 * math.sin(2 * math.pi * freq2 * t)
        samples.append(sample)
    
    return apply_envelope(samples, attack=0.02, decay=0.05, sustain=0.5, release=0.1)

def generate_wind_effect():
    """生成风元素音效"""
    # 呼啸声
    noise = generate_noise(0.2, volume=0.4)
    tone = generate_tone(300, 0.2, volume=0.3)
    
    samples = []
    for i in range(len(noise)):
        # 添加风的波动
        t = i / 44100
        variation = math.sin(t * 50) * 0.3
        sample = noise[i] * (0.7 + variation) + tone[i]
        samples.append(min(1.0, max(-1.0, sample)))
    
    return apply_envelope(samples, attack=0.05, decay=0.05, sustain=0.6, release=0.1)

def generate_earth_effect():
    """生成土元素音效"""
    # 低沉的撞击声
    noise = generate_noise(0.15, volume=0.5)
    tone = generate_tone(100, 0.15, volume=0.7)
    
    samples = []
    for i in range(len(noise)):
        sample = noise[i] + tone[i]
        samples.append(min(1.0, max(-1.0, sample)))
    
    return apply_envelope(samples, attack=0.005, decay=0.03, sustain=0.4, release=0.08)

def generate_thunder_effect():
    """生成雷电音效"""
    # 强烈的噪声爆发
    noise = generate_noise(0.2, volume=0.6)
    tone = generate_tone(120, 0.2, volume=0.5)
    
    samples = []
    for i in range(len(noise)):
        # 添加雷电的随机性
        t = i / 44100
        if random.random() < 0.1:  # 10%概率添加额外冲击
            sample = noise[i] * 1.5 + tone[i]
        else:
            sample = noise[i] + tone[i]
        samples.append(min(1.0, max(-1.0, sample)))
    
    return apply_envelope(samples, attack=0.001, decay=0.02, sustain=0.5, release=0.1)

def generate_button_click():
    """生成按钮点击音效"""
    # 短促的点击声
    samples = []
    for i in range(2205):  # 0.05秒
        t = i / 44100
        freq = 1000 - 500 * (i / 2205)  # 快速下降
        sample = 0.5 * math.sin(2 * math.pi * freq * t)
        samples.append(sample)
    
    return apply_envelope(samples, attack=0.001, decay=0.01, sustain=0.3, release=0.02)

def generate_button_hover():
    """生成按钮悬停音效"""
    # 轻柔的提示音
    samples = []
    for i in range(3307):  # 0.075秒
        t = i / 44100
        freq = 800 + 200 * math.sin(t * 30)
        sample = 0.3 * math.sin(2 * math.pi * freq * t)
        samples.append(sample)
    
    return apply_envelope(samples, attack=0.005, decay=0.02, sustain=0.4, release=0.03)

def generate_confirm():
    """生成确认音效"""
    # 上升的双音
    samples = []
    for i in range(4410):  # 0.1秒
        t = i / 44100
        freq1 = 600 + 400 * (i / 4410)
        freq2 = 900 + 600 * (i / 4410)
        sample = 0.3 * math.sin(2 * math.pi * freq1 * t) + 0.2 * math.sin(2 * math.pi * freq2 * t)
        samples.append(sample)
    
    return apply_envelope(samples, attack=0.005, decay=0.02, sustain=0.5, release=0.03)

def generate_cancel():
    """生成取消音效"""
    # 下降的双音
    samples = []
    for i in range(4410):  # 0.1秒
        t = i / 44100
        freq1 = 1000 - 400 * (i / 4410)
        freq2 = 1500 - 600 * (i / 4410)
        sample = 0.3 * math.sin(2 * math.pi * freq1 * t) + 0.2 * math.sin(2 * math.pi * freq2 * t)
        samples.append(sample)
    
    return apply_envelope(samples, attack=0.005, decay=0.02, sustain=0.5, release=0.03)

def generate_level_up():
    """生成升级音效"""
    # 上升的和弦
    samples = []
    for i in range(13230):  # 0.3秒
        t = i / 44100
        progress = i / 13230
        freq1 = 400 + 800 * progress
        freq2 = 500 + 1000 * progress
        freq3 = 600 + 1200 * progress
        sample = 0.2 * math.sin(2 * math.pi * freq1 * t) + 0.15 * math.sin(2 * math.pi * freq2 * t) + 0.1 * math.sin(2 * math.pi * freq3 * t)
        samples.append(sample)
    
    return apply_envelope(samples, attack=0.01, decay=0.05, sustain=0.6, release=0.1)

def generate_enemy_death():
    """生成敌人死亡音效"""
    # 下降的噪声
    noise = generate_noise(0.3, volume=0.5)
    tone = generate_tone(200, 0.3, volume=0.4)
    
    samples = []
    for i in range(len(noise)):
        t = i / 44100
        # 频率逐渐下降
        freq = 200 - 150 * (i / len(noise))
        sample = noise[i] * (1 - i / len(noise)) + 0.4 * math.sin(2 * math.pi * freq * t)
        samples.append(min(1.0, max(-1.0, sample)))
    
    return apply_envelope(samples, attack=0.01, decay=0.05, sustain=0.4, release=0.15)

def generate_footstep():
    """生成脚步声"""
    # 短促的低频冲击
    samples = []
    for i in range(2205):  # 0.05秒
        t = i / 44100
        freq = 100 + 50 * random.random()
        sample = 0.4 * math.sin(2 * math.pi * freq * t) * (1 - i / 2205)
        samples.append(sample)
    
    return samples

def generate_wind_ambient():
    """生成环境风声"""
    # 持续的呼啸声
    noise = generate_noise(2.0, volume=0.2)
    
    samples = []
    for i in range(len(noise)):
        t = i / 44100
        # 添加缓慢的波动
        variation = math.sin(t * 2) * 0.3 + math.sin(t * 5) * 0.2
        sample = noise[i] * (0.8 + variation)
        samples.append(sample)
    
    return samples

def generate_victory():
    """生成胜利音效"""
    # 欢快的上升和弦
    samples = []
    for i in range(22050):  # 0.5秒
        t = i / 44100
        progress = i / 22050
        
        # 三个音符依次响起
        if progress < 0.33:
            freq = 523  # C5
            volume = progress * 3
        elif progress < 0.66:
            freq = 659  # E5
            volume = 1.0
        else:
            freq = 784  # G5
            volume = 1.0
        
        sample = volume * 0.3 * math.sin(2 * math.pi * freq * t)
        
        # 添加泛音
        sample += volume * 0.15 * math.sin(2 * math.pi * freq * 2 * t)
        sample += volume * 0.1 * math.sin(2 * math.pi * freq * 3 * t)
        
        samples.append(sample)
    
    return apply_envelope(samples, attack=0.01, decay=0.05, sustain=0.7, release=0.2)

def generate_defeat():
    """生成失败音效"""
    # 低沉的下降音
    samples = []
    for i in range(33075):  # 0.75秒
        t = i / 44100
        progress = i / 33075
        
        # 频率逐渐下降
        freq = 400 - 300 * progress
        sample = 0.4 * math.sin(2 * math.pi * freq * t)
        
        # 添加不和谐泛音
        sample += 0.2 * math.sin(2 * math.pi * freq * 1.5 * t)
        
        samples.append(sample)
    
    return apply_envelope(samples, attack=0.01, decay=0.1, sustain=0.5, release=0.3)

def generate_all_sfx():
    """生成所有音效"""
    
    print("=== 生成音效 ===")
    
    # 卡牌音效
    print("\n--- 卡牌音效 ---")
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'combat', 'sfx_card_draw.wav'), generate_card_draw())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'combat', 'sfx_card_play.wav'), generate_card_play())
    
    # 战斗音效
    print("\n--- 战斗音效 ---")
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'combat', 'sfx_attack_hit.wav'), generate_attack_hit())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'combat', 'sfx_attack_critical.wav'), generate_attack_critical())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'combat', 'sfx_enemy_death.wav'), generate_enemy_death())
    
    # 元素音效
    print("\n--- 元素音效 ---")
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'combat', 'sfx_fire_effect.wav'), generate_fire_effect())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'combat', 'sfx_water_effect.wav'), generate_water_effect())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'combat', 'sfx_wind_effect.wav'), generate_wind_effect())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'combat', 'sfx_earth_effect.wav'), generate_earth_effect())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'combat', 'sfx_thunder_effect.wav'), generate_thunder_effect())
    
    # UI音效
    print("\n--- UI音效 ---")
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'ui', 'sfx_button_click.wav'), generate_button_click())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'ui', 'sfx_button_hover.wav'), generate_button_hover())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'ui', 'sfx_confirm.wav'), generate_confirm())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'ui', 'sfx_cancel.wav'), generate_cancel())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'ui', 'sfx_level_up.wav'), generate_level_up())
    
    # 环境音效
    print("\n--- 环境音效 ---")
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'environment', 'sfx_footstep.wav'), generate_footstep())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'environment', 'sfx_wind_ambient.wav'), generate_wind_ambient())
    
    # 结果音效
    print("\n--- 结果音效 ---")
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'ui', 'sfx_victory.wav'), generate_victory())
    create_wav(os.path.join(AUDIO_DIR, 'sfx', 'ui', 'sfx_defeat.wav'), generate_defeat())
    
    print("\n=== 音效生成完成 ===")
    print(f"总计生成了 19 个音效文件")
    print(f"位置: {AUDIO_DIR}")

if __name__ == '__main__':
    generate_all_sfx()
