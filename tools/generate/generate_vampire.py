#!/usr/bin/env python3
"""
Generate vampire pixel art using Aseprite MCP tools.
This script demonstrates how to use the Aseprite MCP tools programmatically.
"""

import asyncio
import os
import sys

# Add the aseprite-mcp directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'tools', 'aseprite-mcp'))

from aseprite_mcp.tools.canvas import create_canvas, add_layer, set_layer, set_frame
from aseprite_mcp.tools.drawing import draw_rectangle_at, fill_area_at, draw_circle_at
from aseprite_mcp.tools.palette import set_palette
from aseprite_mcp.tools.export import export_sprite

async def generate_vampire():
    """Generate a vampire character sprite."""
    
    # Define the output paths
    source_dir = "assets/source/vampire"
    sprites_dir = "assets/sprites/vampire"
    
    # Create directories if they don't exist
    os.makedirs(source_dir, exist_ok=True)
    os.makedirs(sprites_dir, exist_ok=True)
    
    # Define the filename
    filename = os.path.join(source_dir, "char_vampire_idle_01.aseprite")
    
    print("Creating canvas (32x48)...")
    result = await create_canvas(32, 48, filename)
    print(f"Result: {result}")
    
    if "Failed" in result:
        print("Failed to create canvas!")
        return
    
    # Define colors from the art bible
    colors = [
        "#1A1A2E",  # 深渊黑 - Cape exterior, shadows
        "#2D2D44",  # 暮色灰 - Suit details, secondary shadows
        "#D94A4A",  # 鲜血红 - Eyes, cape lining, blood effects
        "#9B59B6",  # 暗影紫 - Magical glow, aura effects
        "#E0E0E0",  # 月光银 - Shirt, fangs, highlights
        "#E8C84A",  # 命运金 - Button details, accessories
    ]
    
    print("Setting palette...")
    result = await set_palette(filename, colors)
    print(f"Result: {result}")
    
    # Add layers
    print("Adding layers...")
    layers = ["body", "head", "arms", "legs", "outline"]
    for layer in layers:
        result = await add_layer(filename, layer)
        print(f"Added layer '{layer}': {result}")
    
    # Draw the vampire character
    print("Drawing vampire character...")
    
    # Set active layer to body
    await set_layer(filename, "body")
    await set_frame(filename, 1)
    
    # Draw body (torso)
    await draw_rectangle_at(filename, "body", 1, 12, 20, 8, 16, "#1A1A2E", True)
    
    # Draw head
    await set_layer(filename, "head")
    await draw_rectangle_at(filename, "head", 1, 14, 12, 4, 8, "#E0E0E0", True)
    
    # Draw eyes (red glowing)
    await draw_rectangle_at(filename, "head", 1, 15, 14, 1, 1, "#D94A4A", True)
    await draw_rectangle_at(filename, "head", 1, 18, 14, 1, 1, "#D94A4A", True)
    
    # Draw arms
    await set_layer(filename, "arms")
    await draw_rectangle_at(filename, "arms", 1, 8, 22, 4, 4, "#2D2D44", True)
    await draw_rectangle_at(filename, "arms", 1, 20, 22, 4, 4, "#2D2D44", True)
    
    # Draw legs
    await set_layer(filename, "legs")
    await draw_rectangle_at(filename, "legs", 1, 13, 36, 3, 8, "#1A1A2E", True)
    await draw_rectangle_at(filename, "legs", 1, 18, 36, 3, 8, "#1A1A2E", True)
    
    # Draw cape (flowing behind)
    await set_layer(filename, "body")
    await draw_rectangle_at(filename, "body", 1, 10, 18, 12, 20, "#9B59B6", True)
    
    # Draw outline
    await set_layer(filename, "outline")
    await draw_rectangle_at(filename, "outline", 1, 10, 10, 12, 28, "#000000", False)
    
    # Export to PNG
    print("Exporting to PNG...")
    export_path = os.path.join(sprites_dir, "char_vampire_idle_01.png")
    result = await export_sprite(filename, export_path)
    print(f"Export result: {result}")
    
    print("Vampire pixel art generation complete!")
    print(f"Source file: {filename}")
    print(f"Exported PNG: {export_path}")

if __name__ == "__main__":
    asyncio.run(generate_vampire())
