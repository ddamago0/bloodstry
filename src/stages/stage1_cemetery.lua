local Class = require("lib.classic")
local Enemy = require("src.entities/enemy")
local LaParca = require("src.entities/bosses/la_parca")
local Assets = require("src.core.assets")
local Theme = require("src.ui.theme")

local Stage1Cemetery = Class:extend()

local TILE = 32
local BOUND = 1000

-- Small deterministic PRNG so the cemetery layout is stable between runs
-- without touching the global math.random stream used by combat.
local function newRng(seed)
    local state = seed % 2147483647
    if state <= 0 then state = state + 2147483646 end
    return function()
        state = (state * 16807) % 2147483647
        return (state - 1) / 2147483646
    end
end

local function hash2(ix, iy, seed)
    local n = math.sin(ix * 127.1 + iy * 311.7 + (seed or 0) * 74.7) * 43758.5453
    return n - math.floor(n)
end

function Stage1Cemetery:new()
    self.name = "El Cementerio"
    self.subtitle = "El Turno de Guardia"

    self.palette = {
        darkGround = { 0x1A / 255, 0x1C / 255, 0x2C / 255, 1 },
        stone = { 0x33 / 255, 0x3C / 255, 0x57 / 255, 1 },
        mist = { 0x56 / 255, 0x6C / 255, 0x86 / 255, 0.15 },
        boneWhite = { 0xF4 / 255, 0xF4 / 255, 0xF4 / 255, 1 },
        gravePurple = { 0x5D / 255, 0x27 / 255, 0x5D / 255, 1 },
        bloodRed = { 0xB1 / 255, 0x3E / 255, 0x53 / 255, 1 }
    }

    self.bounds = { minX = -BOUND, minY = -BOUND, maxX = BOUND, maxY = BOUND }
    self.timeElapsed = 0

    -- Wave spawning state
    self.spawnTimer = 0
    self.spawnInterval = 1.0
    self.bossSpawned = false
    self.bossInstance = nil
    self.bossIntroTimer = 0
    self.bossIntroDuration = 4.2

    self.props = {}
    self.groundDecals = {}
    self:generateDecorations()
end

function Stage1Cemetery:generateDecorations()
    self.props = {}
    self.groundDecals = {}
    self.occupied = {}

    local rng = newRng(20261031)
    local function rand(a, b)
        return a + (b - a) * rng()
    end

    local function blocked(x, y, radius)
        radius = radius or 10
        -- Spawn clearing around the player.
        local spawnR = 150
        if x * x + y * y < spawnR * spawnR then return true end

        -- Ceremonial path from the crypt door to the spawn point.
        if math.abs(x) < 42 and y > -115 and y < 78 then return true end
        -- Courtyard in front of the crypt.
        if math.abs(x) < 82 and y > -160 and y < -8 then return true end

        for i = 1, #self.occupied do
            local o = self.occupied[i]
            local dx = x - o.x
            local dy = y - o.y
            local minDist = (o.r + radius) * 0.62
            if dx * dx + dy * dy < minDist * minDist then
                return true
            end
        end
        return false
    end

    local function add(kind, x, y, scale, radius, flip)
        table.insert(self.props, {
            type = kind,
            x = x,
            y = y,
            scale = scale or 1,
            flip = flip == nil and (rng() < 0.5) or flip
        })
        table.insert(self.occupied, { x = x, y = y, r = radius or 12 })
    end

    -- Central desecrated crypt: the visual landmark behind the player.
    table.insert(self.props, {
        type = "central_crypt",
        x = 0, y = -48, w = 84, h = 64, scale = 1
    })
    table.insert(self.occupied, { x = 0, y = -48, r = 62 })

    -- Rows of graves. The jitter and alternate row offset break the grid
    -- without losing the "cemetery plots" layout.
    for row = -9, 9 do
        local gy = row * 92 + rand(-5, 5)
        local offset = (row % 2 == 0) and 0 or 28
        for col = -12, 12 do
            local gx = col * 74 + offset + rand(-6, 6)
            if rng() < 0.66 and not blocked(gx, gy, 9) then
                local roll = rng()
                local kind
                if roll < 0.30 then
                    kind = "tombstone_a"
                elseif roll < 0.55 then
                    kind = "tombstone_b"
                elseif roll < 0.69 then
                    kind = "tombstone_c"
                elseif roll < 0.78 then
                    kind = "cross"
                elseif roll < 0.84 then
                    kind = "obelisk"
                elseif roll < 0.89 then
                    kind = "urn"
                else
                    kind = "grave_mound"
                end
                add(kind, gx, gy, rand(0.9, 1.18), 10)
            end
        end
    end

    -- Dead trees: the large occluders that sell the 2.5D depth.
    local trees = 0
    for _ = 1, 900 do
        if trees >= 34 then break end
        local x, y = rand(-BOUND + 40, BOUND - 40), rand(-BOUND + 40, BOUND - 40)
        if (x * x + y * y) > 255 * 255 and not blocked(x, y, 34) then
            add(rng() < 0.5 and "dead_tree_a" or "dead_tree_b",
                x, y, rand(0.9, 1.45), 22)
            trees = trees + 1
        end
    end

    -- Angel statues around the oldest plots.
    local statues = 0
    for _ = 1, 400 do
        if statues >= 9 then break end
        local x, y = rand(-BOUND + 60, BOUND - 60), rand(-BOUND + 60, BOUND - 60)
        if (x * x + y * y) > 300 * 300 and not blocked(x, y, 22) then
            add("statue", x, y, rand(0.95, 1.2), 16)
            statues = statues + 1
        end
    end

    -- Iron fences enclosing some plots.
    local fences = 0
    for _ = 1, 300 do
        if fences >= 22 then break end
        local x, y = rand(-BOUND + 80, BOUND - 80), rand(-BOUND + 80, BOUND - 80)
        if (x * x + y * y) > 180 * 180 and not blocked(x, y, 26) then
            add("fence", x, y, rand(0.85, 1.05), 28)
            fences = fences + 1
        end
    end

    -- Broken columns and urns.
    for _ = 1, 18 do
        local x, y = rand(-BOUND + 50, BOUND - 50), rand(-BOUND + 50, BOUND - 50)
        if not blocked(x, y, 14) then
            add("broken_column", x, y, rand(0.9, 1.2), 13)
        end
    end

    -- Braziers flanking the ceremonial path. Glow pools are drawn separately.
    local braziers = {
        { -88, -22 }, { 88, -22 },
        { -88, 64 }, { 88, 64 },
        { -162, 18 }, { 162, 18 },
        { -162, 154 }, { 162, 154 }
    }
    for i = 1, #braziers do
        add("brazier", braziers[i][1], braziers[i][2], 1, 10, false)
    end
    for _ = 1, 8 do
        local x, y = rand(-BOUND + 100, BOUND - 100), rand(-BOUND + 100, BOUND - 100)
        if not blocked(x, y, 12) then
            add("brazier", x, y, 1, 10, false)
        end
    end

    -- Scattered bones and skull offerings.
    for _ = 1, 150 do
        local x, y = rand(-BOUND + 30, BOUND - 30), rand(-BOUND + 30, BOUND - 30)
        if not blocked(x, y, 5) and (x * x + y * y) > 120 * 120 then
            add(rng() < 0.6 and "bone_pile" or "skull_pile", x, y, rand(0.75, 1.05), 6)
        end
    end

    -- Tiny non-sorted ground marks (grass tufts, cracks, pebbles).
    for _ = 1, 420 do
        local x, y = rand(-BOUND + 20, BOUND - 20), rand(-BOUND + 20, BOUND - 20)
        table.insert(self.groundDecals, {
            x = math.floor(x), y = math.floor(y),
            kind = rng() < 0.55 and "grass" or "crack",
            len = math.floor(rand(2, 6))
        })
    end
end

function Stage1Cemetery:update(dt, player, enemiesList, camera)
    self.timeElapsed = self.timeElapsed + dt
    self.spawnTimer = self.spawnTimer - dt

    if self.bossIntroTimer > 0 then
        self.bossIntroTimer = math.max(0, self.bossIntroTimer - dt)
    end

    -- Difficulty scaling: spawn interval shrinks as time passes.
    self.spawnInterval = math.max(0.22, 1.2 - (self.timeElapsed / 120) * 0.9)

    if self.spawnTimer <= 0 and #enemiesList < 350 then
        self.spawnTimer = self.spawnInterval
        self:spawnWavePack(player, enemiesList)
    end

    if not self.bossSpawned and self.timeElapsed >= 150 then
        self:spawnBoss(player, enemiesList, camera)
    end
end

function Stage1Cemetery:spawnWavePack(player, enemiesList)
    local packSize = math.random(2, 4 + math.floor(self.timeElapsed / 40))
    for _ = 1, packSize do
        local angle = math.random() * math.pi * 2
        local dist = math.random(320, 420)
        local sx = player.x + math.cos(angle) * dist
        local sy = player.y + math.sin(angle) * dist

        sx = math.max(self.bounds.minX + 30, math.min(self.bounds.maxX - 30, sx))
        sy = math.max(self.bounds.minY + 30, math.min(self.bounds.maxY - 30, sy))

        local eType = Enemy.TYPES.SKELETON_COMMON
        local roll = math.random()
        if self.timeElapsed > 45 and roll < 0.25 then
            eType = Enemy.TYPES.SKELETON_TALL
        elseif self.timeElapsed > 80 and roll < 0.45 then
            eType = Enemy.TYPES.SKELETON_ROBED
        end

        table.insert(enemiesList, Enemy(sx, sy, eType))
    end
end

function Stage1Cemetery:spawnBoss(player, enemiesList, camera)
    if self.bossSpawned then return end
    self.bossSpawned = true
    self.bossIntroTimer = self.bossIntroDuration

    if camera then camera:shake(12, 1.2) end

    local bx = player.x
    local by = player.y - 120
    local boss = LaParca(bx, by)
    self.bossInstance = boss
    table.insert(enemiesList, boss)
end

-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------
function Stage1Cemetery:drawGround(camera)
    local tileset = Assets.sprites.tileset
    local viewW = camera.viewWidth or 480
    local viewH = camera.viewHeight or 270

    -- Void beyond the consecrated ground.
    love.graphics.setColor(0.020, 0.021, 0.032, 1)
    love.graphics.rectangle("fill", 0, 0, viewW, viewH)

    if tileset and Assets.quads.ground then
        local left = camera.x - viewW / 2
        local top = camera.y - viewH / 2
        local ix0 = math.floor(left / TILE) - 1
        local ix1 = math.floor((left + viewW) / TILE) + 1
        local iy0 = math.floor(top / TILE) - 1
        local iy1 = math.floor((top + viewH) / TILE) + 1

        for iy = iy0, iy1 do
            for ix = ix0, ix1 do
                local idx = math.floor(hash2(ix, iy, 7) * 6)
                local quad = Assets.quads.ground[idx]
                if quad then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(tileset, quad.quad, ix * TILE, iy * TILE)
                end
            end
        end

        -- Fine ground detail: grass tufts and hairline cracks.
        love.graphics.setColor(0.11, 0.13, 0.11, 0.65)
        for i = 1, #self.groundDecals do
            local d = self.groundDecals[i]
            if d.kind == "grass" then
                love.graphics.line(d.x, d.y, d.x - 1, d.y - d.len)
                love.graphics.line(d.x + 1, d.y, d.x + 1, d.y - d.len + 1)
            else
                love.graphics.line(d.x, d.y, d.x + d.len, d.y - 1)
            end
        end
    end

    -- Consecrated boundary.
    love.graphics.setColor(0.14, 0.15, 0.20, 0.55)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.bounds.minX, self.bounds.minY,
        self.bounds.maxX - self.bounds.minX, self.bounds.maxY - self.bounds.minY)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function Stage1Cemetery:drawGlows()
    if not Assets.sprites.glow then return end
    local t = love.timer.getTime()
    for i = 1, #self.props do
        local p = self.props[i]
        if p.type == "brazier" then
            local flicker = 0.82 + 0.18 * math.sin(t * 9 + p.x * 0.7)
            Theme.drawGlow(p.x, p.y - 20 * (p.scale or 1), 28,
                { 1.0, 0.58, 0.24, 1 }, 0.11 * flicker)
        end
    end
    -- Broken seal bleeding light from the crypt door.
    local sealPulse = 0.7 + 0.3 * math.sin(t * 2.2)
    Theme.drawGlow(0, -78, 46, { 0.72, 0.10, 0.20, 1 }, 0.075 * sealPulse)
end

function Stage1Cemetery:drawCrypt(p)
    local x, y = p.x, p.y
    local s = p.scale or 1
    local w = (p.w or 84) * s
    local h = (p.h or 64) * s

    local stoneDark = { 0.105, 0.115, 0.165, 1 }
    local stone = { 0.185, 0.205, 0.290, 1 }
    local stoneLight = { 0.280, 0.305, 0.405, 1 }
    local moss = { 0.200, 0.285, 0.215, 1 }
    local roofDark = { 0.120, 0.085, 0.145, 1 }
    local roof = { 0.215, 0.145, 0.245, 1 }
    local roofLight = { 0.335, 0.235, 0.370, 1 }
    local door = { 0.020, 0.020, 0.030, 1 }

    -- Ground shadow.
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.ellipse("fill", x, y - 2, w * 0.56, 7 * s)

    -- Steps.
    love.graphics.setColor(stoneDark)
    love.graphics.rectangle("fill", x - w * 0.56, y - 7 * s, w * 1.12, 7 * s)
    love.graphics.setColor(stone)
    love.graphics.rectangle("fill", x - w * 0.50, y - 13 * s, w * 1.00, 6 * s)
    love.graphics.setColor(stoneLight)
    love.graphics.rectangle("fill", x - w * 0.50, y - 13 * s, w * 1.00, 1)

    -- Main body.
    local bodyTop = y - h
    love.graphics.setColor(stoneDark)
    love.graphics.rectangle("fill", x - w * 0.46, bodyTop + 6 * s, w * 0.92, h - 18 * s)
    love.graphics.setColor(stone)
    love.graphics.rectangle("fill", x - w * 0.44, bodyTop + 8 * s, w * 0.88, h - 22 * s)

    -- Stone block seams.
    Theme.setColor(stoneDark, 0.75)
    for sy = bodyTop + 14 * s, y - 16 * s, 8 * s do
        love.graphics.line(x - w * 0.43, sy, x + w * 0.43, sy)
    end
    for row = 0, 8 do
        local sy = bodyTop + 12 * s + row * 8 * s
        local off = (row % 2 == 0) and -w * 0.18 or w * 0.10
        love.graphics.line(x + off, sy, x + off, math.min(sy + 8 * s, y - 14 * s))
    end
    Theme.setColor(stoneLight, 0.8)
    love.graphics.line(x - w * 0.44, bodyTop + 8 * s, x - w * 0.44, y - 14 * s)

    -- Flanking columns.
    for _, dir in ipairs({ -1, 1 }) do
        local cx = x + dir * (w * 0.42)
        love.graphics.setColor(stoneDark)
        love.graphics.rectangle("fill", cx - 4 * s, bodyTop + 12 * s, 8 * s, h - 28 * s)
        love.graphics.setColor(stoneLight)
        love.graphics.rectangle("fill", cx - 3 * s, bodyTop + 13 * s, 1, h - 30 * s)
    end

    -- Door with a pointed arch and iron gate.
    local doorBottom = y - 14 * s
    local doorH = h * 0.56
    local doorTop = doorBottom - doorH
    local doorW = w * 0.25
    love.graphics.setColor(door)
    love.graphics.rectangle("fill", x - doorW / 2, doorTop, doorW, doorH)
    love.graphics.arc("fill", x, doorTop, doorW / 2, math.pi, math.pi * 2)

    love.graphics.setColor({ 0.32, 0.34, 0.42, 1 })
    for bx = -3, 3 do
        local bxPos = x + bx * 4 * s
        if math.abs(bxPos - x) < doorW / 2 then
            love.graphics.rectangle("fill", bxPos, doorTop + 2 * s, 1, doorH - 4 * s)
        end
    end
    love.graphics.rectangle("fill", x - doorW / 2 + 1, doorTop + doorH * 0.42, doorW - 2, 1)
    love.graphics.rectangle("fill", x - doorW / 2 + 1, doorTop + doorH * 0.72, doorW - 2, 1)

    -- Blood seal above the door.
    local sealY = doorTop - 2 * s
    love.graphics.setColor(0.42, 0.05, 0.10, 1)
    love.graphics.circle("fill", x, sealY, 10 * s)
    love.graphics.setColor(0.95, 0.18, 0.24, 0.9)
    love.graphics.circle("line", x, sealY, 9 * s)
    love.graphics.setColor(0.72, 0.08, 0.14, 1)
    love.graphics.line(x, sealY - 6 * s, x, sealY + 6 * s)
    love.graphics.line(x - 5 * s, sealY - 2 * s, x + 5 * s, sealY - 2 * s)

    -- Cornice and roof.
    love.graphics.setColor(stoneLight)
    love.graphics.rectangle("fill", x - w * 0.50, bodyTop + 3 * s, w, 5 * s)
    love.graphics.setColor(roofDark)
    love.graphics.polygon("fill",
        x - w * 0.56, bodyTop + 6 * s,
        x, bodyTop - 22 * s,
        x + w * 0.56, bodyTop + 6 * s)
    love.graphics.setColor(roof)
    love.graphics.polygon("fill",
        x - w * 0.48, bodyTop + 6 * s,
        x, bodyTop - 16 * s,
        x + w * 0.48, bodyTop + 6 * s)
    Theme.setColor(roofLight, 0.9)
    love.graphics.line(x - w * 0.47, bodyTop + 6 * s, x, bodyTop - 16 * s)
    love.graphics.setColor({ 0.45, 0.25, 0.48, 1 })
    love.graphics.line(x, bodyTop - 18 * s, x, bodyTop + 4 * s)

    -- Moss and weathering.
    love.graphics.setColor(moss)
    love.graphics.rectangle("fill", x - w * 0.44, y - 16 * s, w * 0.30, 2)
    love.graphics.rectangle("fill", x + w * 0.10, bodyTop + 12 * s, 6 * s, 2)
    love.graphics.setColor(1, 1, 1, 1)
end

function Stage1Cemetery:drawProp(p)
    if p.type == "central_crypt" then
        self:drawCrypt(p)
        return
    end

    local asset = Assets.quads.props and Assets.quads.props[p.type]
    local sheet = Assets.sprites.tileset
    if not (asset and sheet) then
        -- Fallback marker so a missing asset is obvious but non-fatal.
        love.graphics.setColor(0.22, 0.24, 0.32, 1)
        love.graphics.rectangle("fill", p.x - 5, p.y - 10, 10, 10)
        return
    end

    local s = p.scale or 1
    local w = asset.w * s
    local h = asset.h * s

    love.graphics.setColor(0, 0, 0, 0.34)
    love.graphics.ellipse("fill", p.x, p.y - 1, w * 0.30, math.max(2, 3 * s + h * 0.03))

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sheet, asset.quad, p.x, p.y, 0,
        p.flip and -s or s, s, asset.w / 2, asset.h)
end

function Stage1Cemetery:drawFog(viewWidth, viewHeight, time, camera)
    local fog = Assets.sprites.fog
    if not fog then return end
    viewWidth = viewWidth or 480
    viewHeight = viewHeight or 270
    time = time or 0

    local camX = camera and camera.x or 0
    local camY = camera and camera.y or 0

    local ox = -((camX * 0.40 + time * 5) % 256)
    local oy = -((camY * 0.40 + time * 2) % 128)
    love.graphics.setColor(0.66, 0.72, 0.88, 0.12)
    for gy = -128, viewHeight + 128, 128 do
        for gx = -256, viewWidth + 256, 256 do
            love.graphics.draw(fog, gx + ox, gy + oy)
        end
    end

    local ox2 = -((camX * 0.72 + time * 9 + 128) % 256)
    local oy2 = -((camY * 0.72 + time * 4 + 64) % 128)
    love.graphics.setColor(0.54, 0.48, 0.72, 0.09)
    for gy = -128, viewHeight + 128, 128 do
        for gx = -256, viewWidth + 256, 256 do
            love.graphics.draw(fog, gx + ox2, gy + oy2)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Stage1Cemetery
