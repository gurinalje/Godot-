-- Vampire Pixel Art Generation Script for Aseprite
-- This script creates a vampire character sprite

-- Create a new sprite (32x48 pixels, RGB mode)
local spr = Sprite(32, 48, ColorMode.RGB)

-- Define colors from the art bible
local colors = {
    Color(26, 26, 46),     -- 深渊黑 #1A1A2E - Cape exterior, shadows
    Color(45, 45, 68),     -- 暮色灰 #2D2D44 - Suit details, secondary shadows
    Color(217, 74, 74),    -- 鲜血红 #D94A4A - Eyes, cape lining, blood effects
    Color(155, 89, 182),   -- 暗影紫 #9B59B6 - Magical glow, aura effects
    Color(224, 224, 224),  -- 月光银 #E0E0E0 - Shirt, fangs, highlights
    Color(232, 200, 74),   -- 命运金 #E8C84A - Button details, accessories
}

-- Set the palette
local palette = Palette(#colors)
for i, color in ipairs(colors) do
    palette:setColor(i-1, color)
end
spr:setPalette(palette)

-- Create layers
local bodyLayer = spr:newLayer()
bodyLayer.name = "body"

local headLayer = spr:newLayer()
headLayer.name = "head"

local armsLayer = spr:newLayer()
armsLayer.name = "arms"

local legsLayer = spr:newLayer()
legsLayer.name = "legs"

local outlineLayer = spr:newLayer()
outlineLayer.name = "outline"

-- Get the first frame
local frame = spr.frames[1]

-- Create cel for body layer
local bodyCel = spr:newCel(bodyLayer, frame, Image(spr.width, spr.height))
local bodyImage = bodyCel.image

-- Draw body (torso) - dark suit
for x = 12, 19 do
    for y = 20, 35 do
        bodyImage:drawPixel(x, y, colors[1])
    end
end

-- Draw cape (flowing behind) - purple
for x = 10, 21 do
    for y = 18, 37 do
        bodyImage:drawPixel(x, y, colors[4])
    end
end

-- Create cel for head layer
local headCel = spr:newCel(headLayer, frame, Image(spr.width, spr.height))
local headImage = headCel.image

-- Draw head - light skin
for x = 14, 17 do
    for y = 12, 19 do
        headImage:drawPixel(x, y, colors[5])
    end
end

-- Draw eyes - red glowing
headImage:drawPixel(15, 14, colors[3])
headImage:drawPixel(18, 14, colors[3])

-- Draw fangs - white highlights
headImage:drawPixel(16, 18, colors[5])
headImage:drawPixel(17, 18, colors[5])

-- Create cel for arms layer
local armsCel = spr:newCel(armsLayer, frame, Image(spr.width, spr.height))
local armsImage = armsCel.image

-- Draw arms - dark suit
for x = 8, 11 do
    for y = 22, 25 do
        armsImage:drawPixel(x, y, colors[2])
    end
end

for x = 20, 23 do
    for y = 22, 25 do
        armsImage:drawPixel(x, y, colors[2])
    end
end

-- Create cel for legs layer
local legsCel = spr:newCel(legsLayer, frame, Image(spr.width, spr.height))
local legsImage = legsCel.image

-- Draw legs - dark
for x = 13, 15 do
    for y = 36, 43 do
        legsImage:drawPixel(x, y, colors[1])
    end
end

for x = 18, 20 do
    for y = 36, 43 do
        legsImage:drawPixel(x, y, colors[1])
    end
end

-- Create cel for outline layer
local outlineCel = spr:newCel(outlineLayer, frame, Image(spr.width, spr.height))
local outlineImage = outlineCel.image

-- Draw outline - black outline
for x = 10, 21 do
    outlineImage:drawPixel(x, 10, Color(0, 0, 0))
    outlineImage:drawPixel(x, 37, Color(0, 0, 0))
end

for y = 10, 37 do
    outlineImage:drawPixel(10, y, Color(0, 0, 0))
    outlineImage:drawPixel(21, y, Color(0, 0, 0))
end

-- Set frame duration (for animation)
frame.duration = 0.166  -- 6 FPS

-- Save the sprite
local outputPath = "assets/source/vampire/char_vampire_idle_01.aseprite"
spr:saveAs(outputPath)

-- Export to PNG
local exportPath = "assets/sprites/vampire/char_vampire_idle_01.png"
spr:saveCopyAs(exportPath)

print("Vampire pixel art generated successfully!")
print("Source: " .. outputPath)
print("Export: " .. exportPath)
