local Assets = {
    sprites = {},
    quads = {},
    fonts = {}
}

local function loadImage(path)
    if love.filesystem and love.filesystem.getInfo then
        if not love.filesystem.getInfo(path) then return nil end
    end
    local ok, img = pcall(love.graphics.newImage, path)
    if not ok or not img then return nil end
    img:setFilter("nearest", "nearest")
    return img
end

local function newFont(path, size)
    -- Keep default hinting: the 5x7 font is already pixel-shaped, and mono
    -- hinting at 8px fattens every stem into unreadable blocks.
    local ok, font = pcall(love.graphics.newFont, path, size)
    if ok and font then
        pcall(font.setFilter, font, "nearest", "nearest")
        return font
    end
    return love.graphics.getFont()
end

local function makeFrames(image, frameW, frameH, row, count)
    local frames = {}
    if not image then return frames end
    local sheetW = image:getWidth()
    local sheetH = image:getHeight()
    local y = (row or 0) * frameH
    for i = 0, (count or 4) - 1 do
        local x = i * frameW
        if x + frameW <= sheetW and y + frameH <= sheetH then
            frames[i + 1] = love.graphics.newQuad(x, y, frameW, frameH, sheetW, sheetH)
        end
    end
    return frames
end

local function makeQuadSet(image, defs)
    local quads = {}
    if not image then return quads end
    local sheetW = image:getWidth()
    local sheetH = image:getHeight()
    for name, def in pairs(defs) do
        local x, y, w, h = def[1], def[2], def[3], def[4]
        quads[name] = {
            quad = love.graphics.newQuad(x, y, w, h, sheetW, sheetH),
            x = x,
            y = y,
            w = w,
            h = h
        }
    end
    return quads
end

local ICON_NAMES = {
    "heart", "blood_drop", "skull", "sword", "shield", "bone", "boot", "fist",
    "magnet", "hourglass", "level", "reroll", "cross", "eye", "flame", "claw",
    "boss", "pause"
}

local PROP_DEFS = {
    tombstone_a    = { 0, 32, 32, 32 },
    tombstone_b    = { 32, 32, 32, 32 },
    tombstone_c    = { 64, 32, 32, 32 },
    cross          = { 96, 32, 32, 32 },
    obelisk        = { 128, 32, 32, 32 },
    urn            = { 160, 32, 32, 32 },
    bone_pile      = { 192, 32, 32, 32 },
    skull_pile     = { 224, 32, 32, 32 },
    dead_tree_a    = { 0, 64, 32, 48 },
    dead_tree_b    = { 32, 64, 32, 48 },
    statue         = { 64, 64, 32, 48 },
    fence          = { 96, 64, 64, 32 },
    brazier        = { 160, 64, 32, 32 },
    broken_column  = { 192, 64, 32, 48 },
    grave_mound    = { 224, 64, 32, 32 }
}

function Assets.load()
    -- Pixel-perfect typography. m5x7 is a 5x7 bitmap-style font; sizes are
    -- deliberately kept at integer-friendly values for the 480x270 canvas.
    local fontPath = "assets/fonts/m5x7.ttf"
    if not (love.filesystem and love.filesystem.getInfo(fontPath)) then
        fontPath = "assets/fonts/font.ttf"
    end

    Assets.fonts.small  = newFont(fontPath, 8)
    Assets.fonts.normal = newFont(fontPath, 8)
    Assets.fonts.medium = newFont(fontPath, 10)
    Assets.fonts.bold   = newFont(fontPath, 12)
    Assets.fonts.title  = newFont(fontPath, 16)
    Assets.fonts.hero   = newFont(fontPath, 24)
    love.graphics.setFont(Assets.fonts.normal)

    local players = {
        guerrero = loadImage("assets/sprites/player_guerrero.png"),
        barbaro = loadImage("assets/sprites/player_barbaro.png"),
        asesino = loadImage("assets/sprites/player_asesino.png")
    }
    Assets.sprites.players = players
    Assets.quads.playerFrames = {}
    for id, image in pairs(players) do
        Assets.sprites[id] = image
        Assets.quads.playerFrames[id] = makeFrames(image, 32, 40, 0, 4)
    end

    Assets.sprites.enemySheet = loadImage("assets/sprites/enemy_skeleton.png")
    Assets.quads.enemyFrames = {
        skeleton_common = makeFrames(Assets.sprites.enemySheet, 32, 40, 0, 4),
        skeleton_tall   = makeFrames(Assets.sprites.enemySheet, 32, 40, 1, 4),
        skeleton_robed  = makeFrames(Assets.sprites.enemySheet, 32, 40, 2, 4),
        zombie          = makeFrames(Assets.sprites.enemySheet, 32, 40, 3, 4)
    }

    Assets.sprites.boss = loadImage("assets/sprites/boss_la_parca.png")
    Assets.quads.bossFrames = makeFrames(Assets.sprites.boss, 48, 64, 0, 4)

    Assets.sprites.tileset = loadImage("assets/sprites/cemetery_tiles.png")
    Assets.quads.props = makeQuadSet(Assets.sprites.tileset, PROP_DEFS)
    Assets.quads.ground = {}
    for i = 0, 5 do
        Assets.quads.ground[i] = {
            quad = love.graphics.newQuad(i * 32, 0, 32, 32, 256, 256),
            w = 32,
            h = 32
        }
    end

    Assets.sprites.limbs = loadImage("assets/sprites/limbs_and_blood.png")
    Assets.quads.limbs = makeQuadSet(Assets.sprites.limbs, {
        head = { 0, 0, 20, 20 },
        skeleton_arm = { 20, 0, 20, 20 },
        zombie_arm = { 40, 0, 20, 20 },
        blood_pool = { 60, 0, 20, 20 },
        bone_shard = { 80, 0, 20, 20 }
    })

    Assets.sprites.icons = loadImage("assets/sprites/ui_icons.png")
    Assets.quads.icons = {}
    if Assets.sprites.icons then
        for i, name in ipairs(ICON_NAMES) do
            local index = i - 1
            local col = index % 8
            local row = math.floor(index / 8)
            Assets.quads.icons[name] = {
                quad = love.graphics.newQuad(col * 16, row * 16, 16, 16,
                    Assets.sprites.icons:getWidth(), Assets.sprites.icons:getHeight()),
                w = 16, h = 16
            }
        end
    end

    Assets.sprites.bloodSplats = loadImage("assets/sprites/blood_splats.png")
    Assets.quads.bloodSplats = {}
    if Assets.sprites.bloodSplats then
        for i = 0, 3 do
            Assets.quads.bloodSplats[i + 1] = love.graphics.newQuad(i * 32, 0, 32, 32,
                Assets.sprites.bloodSplats:getWidth(), Assets.sprites.bloodSplats:getHeight())
        end
    end

    Assets.sprites.menuBg = loadImage("assets/sprites/menu_bg.png")
    Assets.sprites.fog = loadImage("assets/sprites/fog.png")
    Assets.sprites.vignette = loadImage("assets/sprites/vignette.png")
    Assets.sprites.glow = loadImage("assets/sprites/glow.png")
    Assets.sprites.cursor = loadImage("assets/sprites/cursor.png")
end

function Assets.getIcon(name)
    return Assets.quads.icons and Assets.quads.icons[name]
end

return Assets
