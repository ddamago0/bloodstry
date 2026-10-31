--[[
    Deterministic 30-second concept trailer recorder.

    Enable with:
        BLOODSTY_TRAILER=1 love .

    The game advances in fixed 1/30 s steps and every drawn frame is written
    to LOVE's save directory as trailer_frames/frame_XXXXX.png. Encode with:

        ffmpeg -framerate 30 -i frame_%05d.png -c:v libx264 ...

    The only fully playable stage is Fase 1 (El Cementerio); Fases 2-4 are
    shown as clearly labelled concept cards instead of simulated gameplay.
]]

local Theme = require("src.ui.theme")
local Input = require("src.core.input")
local Enemy = require("src.entities/enemy")
local Limb = require("src.combat.limb")
local SkillsData = require("src.progression/skills_data")

local Trailer = {
    enabled = false,
    dt = 1 / 30,
    totalFrames = 900
}

local push
local machine
local frame = 0
local events = {}
local nextEvent = 1
local banner
local held = {}
local pressed = {}
local aim = -math.pi / 2
local realGetTime

local DT = Trailer.dt

-- ---------------------------------------------------------------------------
-- Small math helpers
-- ---------------------------------------------------------------------------
local function clamp01(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

local function smooth(v)
    v = clamp01(v)
    return v * v * (3 - 2 * v)
end

local function fadeWindow(t, t0, t1, ramp)
    ramp = ramp or 0.16
    if t < t0 or t > t1 then return 0 end
    return math.min(1, (t - t0) / ramp, (t1 - t) / ramp)
end

-- ---------------------------------------------------------------------------
-- Scripted actions
-- ---------------------------------------------------------------------------
local function playState()
    local state = machine and machine.current
    if state and state.player and state.enemies then
        return state
    end
end

local function add(at, fn)
    events[#events + 1] = { at = at, fn = fn }
end

local function showBanner(t0, t1, kicker, title, color, mode)
    banner = { t0 = t0, t1 = t1, kicker = kicker, title = title, color = color, mode = mode or "bottom" }
end

local function spawn(dx, dy, kind)
    local play = playState()
    if not play then return nil end
    local enemy = Enemy(play.player.x + dx, play.player.y + dy, kind)
    table.insert(play.enemies, enemy)
    return enemy
end

local function clearEnemies(play)
    if not play then return end
    play.enemies = {}
    play.enemyProjectiles = {}
end

local function teleport(dx, dy)
    local play = playState()
    if not play then return end
    play.player.x = play.player.x + dx
    play.player.y = play.player.y + dy
    play.camera.x = play.player.x
    play.camera.y = play.player.y
end

-- ---------------------------------------------------------------------------
-- Timeline
-- ---------------------------------------------------------------------------
local function buildTimeline()
    events = {}
    nextEvent = 1

    -- Class selection: cycle through the three classes, then confirm the
    -- Guerrero (its sacrifice passive grants the bone shield demo).
    add(2.50, function()
        local state = machine.current
        if state and state.selectedIndex ~= nil then
            state.selectedIndex = 2
        end
    end)
    add(3.20, function()
        local state = machine.current
        if state and state.selectedIndex ~= nil then
            state.selectedIndex = 3
        end
    end)
    add(3.95, function()
        local state = machine.current
        if state and state.selectedIndex ~= nil then
            state.selectedIndex = 1
        end
    end)
    add(4.85, function()
        local state = machine.current
        if state and state.selectedIndex ~= nil then
            state:confirmSelection()
        end
    end)

    -- Fase 1 horde.
    add(5.30, function()
        local play = playState()
        if not play then return end
        local p = play.player
        p.takeDamage = function() return 0 end
        p.hp = p.maxHp
        -- Keep the trailer on the battlefield: natural level-ups would freeze
        -- the action behind the upgrade menu mid-horde.
        p.pointsToNextLevel = 1e9
        p.bloodPoints = 0
        p.pendingLevelUps = 0
        p.level = 1

        local ring = {
            { -54, 34, Enemy.TYPES.SKELETON_COMMON },
            { 42, 40, Enemy.TYPES.SKELETON_COMMON },
            { -20, 62, Enemy.TYPES.SKELETON_COMMON },
            { 70, 20, Enemy.TYPES.SKELETON_COMMON },
            { -82, 12, Enemy.TYPES.SKELETON_TALL },
            { 84, 58, Enemy.TYPES.SKELETON_TALL },
            { -34, 92, Enemy.TYPES.SKELETON_ROBED },
            { 52, 90, Enemy.TYPES.SKELETON_ROBED },
            { 0, -66, Enemy.TYPES.SKELETON_ROBED },
            { -70, -42, Enemy.TYPES.SKELETON_COMMON },
            { 96, -18, Enemy.TYPES.SKELETON_COMMON },
            { 18, 118, Enemy.TYPES.SKELETON_TALL }
        }
        for _, def in ipairs(ring) do
            spawn(def[1], def[2], def[3])
        end
        play.bloodCanvas:splatter(p.x - 30, p.y + 14, 10, 26, { 0.55, 0.04, 0.07, 0.75 })
        play.bloodCanvas:splatter(p.x + 44, p.y - 18, 8, 20, { 0.55, 0.04, 0.07, 0.70 })
        showBanner(5.35, 7.25, "FASE 1 · EL CEMENTERIO", "LA HORDA DESPIERTA",
            Theme.colors.bloodBright, "bottom")
    end)
    add(7.55, function()
        for i = 1, 5 do
            local angle = (i / 5) * math.pi * 2
            spawn(math.cos(angle) * 130, math.sin(angle) * 110, Enemy.TYPES.SKELETON_COMMON)
        end
        spawn(120, -60, Enemy.TYPES.SKELETON_TALL)
    end)
    add(8.85, function()
        for i = 1, 6 do
            local angle = (i / 6) * math.pi * 2 + 0.4
            spawn(math.cos(angle) * 120, math.sin(angle) * 100, Enemy.TYPES.SKELETON_ROBED)
        end
        showBanner(8.95, 10.25, "HORDA DE FASE 1",
            "ESQUELETOS · CULTISTAS · MUTADOS", Theme.colors.bone, "bottom")
    end)

    -- Limbs, sacrifice and the bone shield.
    add(10.32, function()
        local play = playState()
        if not play then return end
        clearEnemies(play)
        local p = play.player
        p.hp = p.maxHp
        p:equipLimb(Limb(Limb.TYPES.SKELETON_ARM, 99))
        spawn(46, -6, Enemy.TYPES.SKELETON_COMMON)
        spawn(62, 18, Enemy.TYPES.SKELETON_COMMON)
        spawn(30, 30, Enemy.TYPES.SKELETON_ROBED)
        spawn(-52, 6, Enemy.TYPES.SKELETON_TALL)
        showBanner(10.45, 11.85, "HABILIDAD · EXTREMIDADES",
            "LÁTIGO DE HUESO", Theme.colors.steelBright, "bottom")
    end)
    add(11.92, function()
        local play = playState()
        if not play then return end
        local p = play.player
        p:equipLimb(Limb(Limb.TYPES.ZOMBIE_ARM, 8))
        clearEnemies(play)
        for i = 1, 6 do
            local angle = (i / 6) * math.pi * 2
            spawn(math.cos(angle) * 40, math.sin(angle) * 36, Enemy.TYPES.SKELETON_COMMON)
        end
    end)
    add(12.10, function()
        pressed.sacrifice = true
        showBanner(12.15, 13.60, "SACRIFICIO · LAST DITCH",
            "ESCUDO ÓSEO", Theme.colors.goldBright, "bottom")
    end)

    -- Curses / pact menu.
    add(13.60, function()
        local play = playState()
        if not play then return end
        clearEnemies(play)
        local menu = play.upgradeMenu
        play.player.level = 3
        play.player.pendingLevelUps = 1
        play.player.bloodPoints = 0
        menu.active = true
        menu.cards = {
            SkillsData.pacts[1],
            SkillsData.pacts[2],
            SkillsData.pacts[3]
        }
        menu.selectedIndex = 1
        menu.rerollsLeft = 2
        showBanner(13.70, 15.25, "", "MALDICIONES · EL PRECIO DE LA CARNE",
            Theme.colors.purpleBright, "menu")
    end)
    add(14.20, function()
        local play = playState()
        if play then play.upgradeMenu.selectedIndex = 2 end
    end)
    add(15.28, function()
        local play = playState()
        if not play then return end
        play.upgradeMenu:selectCard(2, play.player)
        play.upgradeMenu.active = false
        play.player.pendingLevelUps = 0
        local p = play.player
        p.hp = p.maxHp
        for i = 1, 7 do
            local angle = (i / 7) * math.pi * 2 + 0.3
            spawn(math.cos(angle) * 62, math.sin(angle) * 54, Enemy.TYPES.SKELETON_COMMON)
        end
        spawn(78, -50, Enemy.TYPES.SKELETON_ROBED)
        showBanner(15.35, 16.95, "FRENESÍ CIEGO",
            "-50% VISIÓN · +100% FUERZA", Theme.colors.purpleBright, "bottom")
    end)

    -- La Parca.
    add(16.98, function()
        local play = playState()
        if not play then return end
        clearEnemies(play)
        play.player.hp = play.player.maxHp
        play.stage:spawnBoss(play.player, play.enemies, play.camera)
        play.stage.bossIntroTimer = 2.0
        local boss = play.stage.bossInstance
        if boss then
            boss.x = play.player.x + 6
            boss.y = play.player.y - 70
        end
    end)
    add(17.85, function()
        local play = playState()
        if not play then return end
        play.player.visionRadiusMult = 1.0
        play.camera:shake(5, 0.35)
    end)
    add(19.85, function()
        local play = playState()
        if not play then return end
        local boss = play.stage.bossInstance
        if boss and boss.alive then
            boss.hp = boss.maxHp * 0.5
            boss.summonDone = false
        end
        showBanner(19.90, 21.25, "FASE II", "INVOCA SU ESCOLTA ÓSEA",
            Theme.colors.bloodBright, "top")
    end)
    add(21.05, function()
        local play = playState()
        if not play then return end
        local boss = play.stage.bossInstance
        if boss and boss.alive then
            boss.hp = 1
            boss:takeDamage(9999, 0, 0)
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Per-frame direction / aim
-- ---------------------------------------------------------------------------
local function updateAim()
    local play = playState()
    if not play then return end
    local p = play.player
    local target = nil
    local best = 200 * 200

    local boss = play.stage.bossInstance
    if boss and boss.alive then
        target = boss
    else
        for i = 1, #play.enemies do
            local e = play.enemies[i]
            if e.alive then
                local dx, dy = e.x - p.x, e.y - p.y
                local d = dx * dx + dy * dy
                if d < best then
                    best = d
                    target = e
                end
            end
        end
    end

    if target then
        aim = math.atan2(target.y - (p.y - 14), target.x - p.x)
    else
        local t = frame * DT
        aim = -math.pi / 2 + math.sin(t * 1.4) * 0.45
    end
end

local function updateHeld()
    held = {}
    local t = frame * DT
    local pid = function()
        return playState() ~= nil
    end

    if not pid() then return end

    if t >= 5.30 and t < 10.30 then
        local slot = math.floor(t / 0.85) % 4
        if slot == 0 then held.right = true
        elseif slot == 1 then held.up = true
        elseif slot == 2 then held.left = true
        else held.down = true end
        held.attack = true
    elseif t >= 10.35 and t < 11.90 then
        if math.floor(t / 0.6) % 2 == 0 then held.right = true else held.left = true end
        held.limb_attack = true
    elseif t >= 12.15 and t < 13.55 then
        if math.floor(t / 0.5) % 2 == 0 then held.left = true else held.right = true end
        held.attack = true
    elseif t >= 15.35 and t < 16.95 then
        if math.floor(t / 0.55) % 2 == 0 then held.right = true else held.left = true end
        held.attack = true
    elseif t >= 17.10 and t < 21.00 then
        if math.floor(t / 0.75) % 2 == 0 then held.left = true else held.right = true end
        held.attack = true
    end
end

-- ---------------------------------------------------------------------------
-- Overlay drawing
-- ---------------------------------------------------------------------------
local function drawFade(alpha)
    if alpha <= 0.001 then return end
    love.graphics.setColor(0, 0, 0, math.min(1, alpha))
    love.graphics.rectangle("fill", 0, 0, 480, 270)
    love.graphics.setColor(1, 1, 1, 1)
end

local function drawEmbers(t, count, tint)
    for i = 1, count do
        local seed = i * 37.13
        local x = (seed * 11 + t * (6 + (i % 4) * 3) + math.sin(t * 0.8 + i) * 9) % 480
        local y = 270 - ((seed * 7 + t * (9 + (i % 5) * 4)) % 300)
        local a = 0.14 + 0.16 * (0.5 + 0.5 * math.sin(t * 2.6 + i * 1.7))
        love.graphics.setColor(tint[1], tint[2], tint[3], a)
        love.graphics.rectangle("fill", math.floor(x), math.floor(y), 1, 2)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

local function drawIntro(t)
    if t > 2.15 then return end
    local alpha = math.min(clamp01(t / 0.30), clamp01((2.15 - t) / 0.30))
    if alpha <= 0 then return end

    Theme.drawMenuBackground({ 0.92, 0.72, 0.80, 1 }, 1)
    love.graphics.setColor(0.012, 0.008, 0.018, 0.80)
    love.graphics.rectangle("fill", 0, 0, 480, 270)

    Theme.drawGlow(240, 128, 150, { 0.62, 0.10, 0.16, 1 }, 0.30)
    Theme.drawGlow(240, 128, 78, { 0.85, 0.45, 0.25, 1 }, 0.16)
    drawEmbers(t, 22, { 0.85, 0.45, 0.30 })

    Theme.center("BLOODSTY", "hero", { 0.95, 0.90, 0.84, alpha }, 92, 480)
    Theme.center("EL TURNO DE GUARDIA", "title", { 0.92, 0.72, 0.38, alpha }, 124, 480)

    love.graphics.setColor(0.70, 0.14, 0.20, alpha)
    love.graphics.rectangle("fill", 158, 146, 164, 1)

    Theme.center("4 BIOMAS · 3 CLASES · 1 SELLO ROTO", "small",
        { 0.78, 0.74, 0.72, alpha }, 156, 480)
    Theme.center("UN SEPULTURERO. UNA HORDA. NINGUNA SALIDA.", "small",
        { 0.56, 0.52, 0.56, alpha }, 170, 480)

    Theme.center("FASE 1 JUGABLE · FASES 2-4 EN DISEÑO", "medium",
        { 0.62, 0.46, 0.50, alpha * 0.9 }, 236, 480)
end

local function drawBanner(t)
    if not banner or t < banner.t0 or t > banner.t1 then return end
    local a = math.min(1, (t - banner.t0) / 0.16, (banner.t1 - t) / 0.16)
    a = clamp01(a)
    if a <= 0 then return end

    local C = Theme.colors
    local color = banner.color or C.gold

    if banner.mode == "menu" then
        Theme.panel(12, 240, 392, 24, {
            fill = { 0.020, 0.014, 0.028, 0.97 * a },
            border = { color[1] * 0.55, color[2] * 0.55, color[3] * 0.55, 0.9 * a },
            corners = false,
            shadowAlpha = 0.35 * a
        })
        love.graphics.setColor(color[1], color[2], color[3], a)
        love.graphics.rectangle("fill", 12, 240, 2, 24)
        Theme.center(banner.title, "bold", { color[1], color[2], color[3], a }, 245, 392, 12)
        return
    end

    if banner.mode == "top" then
        Theme.panel(178, 8, 150, 26, {
            fill = { 0.020, 0.014, 0.028, 0.86 * a },
            border = { color[1] * 0.55, color[2] * 0.55, color[3] * 0.55, 0.9 * a },
            corners = false,
            shadowAlpha = 0.35 * a
        })
        Theme.center(banner.kicker, "small", { color[1], color[2], color[3], a }, 11, 150, 178)
        Theme.center(banner.title, "bold", { C.text[1], C.text[2], C.text[3], a },
            18, 150, 178)
        return
    end

    Theme.panel(12, 190, 318, 30, {
        fill = { 0.018, 0.013, 0.026, 0.84 * a },
        border = { color[1] * 0.5, color[2] * 0.5, color[3] * 0.5, 0.9 * a },
        corners = false,
        shadowAlpha = 0.4 * a
    })
    love.graphics.setColor(color[1], color[2], color[3], a)
    love.graphics.rectangle("fill", 12, 190, 2, 30)
    Theme.print(banner.kicker, "small", { color[1], color[2], color[3], a }, 22, 193)
    Theme.print(banner.title, "bold", { C.text[1], C.text[2], C.text[3], a }, 22, 203)
end

local CONCEPTS = {
    {
        at = 23.20,
        phase = "FASE 02",
        name = "CLÍNICA ABANDONADA",
        icon = "cross",
        accent = { 0.46, 0.82, 0.58, 1 },
        tint = { 0.60, 0.90, 0.72, 1 },
        desc = "Sanatorio clausurado. El tráfico de cadáveres frescos alimenta algo en los pabellones sellados.",
        horde = "Zombis putrefactos · Corredores mutilados · Esqueletos remanentes",
        boss = "PACIENTE CERO",
        bossDesc = "Escupe ácido corrosivo y viste la túnica robada de La Parca."
    },
    {
        at = 25.20,
        phase = "FASE 03",
        name = "LA GRANJA MARCHITA",
        icon = "flame",
        accent = { 0.90, 0.68, 0.32, 1 },
        tint = { 0.95, 0.82, 0.58, 1 },
        desc = "Campos de icor y niebla alta que oculta a la horda entre espantapájaros que respiran.",
        horde = "Espantapájaros poseídos · Quimeras de paja",
        boss = "EL CABALLO DE PAJA",
        bossDesc = "Carga veloz de arrollamiento; al arder, lo monta un jinete esqueleto."
    },
    {
        at = 27.20,
        phase = "FASE 04",
        name = "EL MATADERO ABISAL",
        icon = "boss",
        accent = { 0.90, 0.24, 0.30, 1 },
        tint = { 0.95, 0.58, 0.58, 1 },
        desc = "Laboratorio subterráneo de cintas mecánicas y pozas de sangre. La carne aún recuerda.",
        horde = "Carniceros desollados · Sabuesos veloces · Quimeras de carne",
        boss = "DON EVARISTO, EL COSECHADOR",
        bossDesc = "Una amalgama necrótica de extremidades que aún obedece a su amo."
    }
}

local function drawConcept(card, t)
    local lt = t - card.at
    local reveal = 1 - clamp01(lt / 0.16)
    local slide = math.floor((1 - smooth(clamp01(lt / 0.28))) * 6)
    local C = Theme.colors

    Theme.drawMenuBackground(card.tint, 1)
    love.graphics.setColor(0.014, 0.012, 0.022, 0.72)
    love.graphics.rectangle("fill", 0, 0, 480, 270)
    Theme.drawGlow(86, 92, 110, card.accent, 0.20)
    Theme.drawGlow(400, 210, 120, card.accent, 0.10)

    local x, y, w, h = 40, 40 + slide, 400, 188
    Theme.panel(x, y, w, h, {
        fill = { 0.032, 0.030, 0.044, 0.97 },
        border = card.accent,
        accent = card.accent,
        cornerColor = card.accent,
        shadowAlpha = 0.70
    })

    Theme.panel(x + 12, y + 12, 56, 56, {
        fill = { 0.020, 0.020, 0.032, 0.95 },
        border = { card.accent[1] * 0.6, card.accent[2] * 0.6, card.accent[3] * 0.6, 1 },
        corners = false,
        shadowAlpha = 0
    })
    Theme.iconCentered(card.icon, x + 40, y + 22, 2.3, card.accent)
    Theme.drawGlow(x + 40, y + 40, 34, card.accent, 0.22)

    local cx = x + 82
    local cw = w - 96

    Theme.print(card.phase, "small", card.accent, cx, y + 10)
    Theme.print(card.name, "title", C.text, cx, y + 21)

    love.graphics.setColor(card.accent[1], card.accent[2], card.accent[3], 0.75)
    love.graphics.rectangle("fill", cx, y + 42, cw - 4, 1)

    Theme.printf(card.desc, "small", C.textSoft, cx, y + 48, cw, "left")

    Theme.print("HORDA", "small", card.accent, cx, y + 76)
    Theme.printf(card.horde, "small", C.text, cx, y + 86, cw, "left")

    Theme.print("JEFE", "small", card.accent, cx, y + 108)
    Theme.print(card.boss, "bold", C.goldBright, cx, y + 118)
    Theme.printf(card.bossDesc, "small", C.textSoft, cx, y + 132, cw, "left")

    -- Unmistakable "not playable yet" label.
    Theme.panel(cx, y + 158, 132, 16, {
        fill = { card.accent[1] * 0.14, card.accent[2] * 0.14, card.accent[3] * 0.14, 0.95 },
        border = card.accent,
        corners = false,
        shadowAlpha = 0
    })
    Theme.print("CONCEPTO · EN DISEÑO", "small", card.accent, cx + 6, y + 161)
    Theme.print("NO JUGABLE EN ESTA DEMO", "small", C.dim, cx + 142, y + 161)

    Theme.drawVignette(0.55)
    if reveal > 0 then drawFade(reveal) end
end

local function drawEndCard(t)
    local alpha = clamp01((t - 29.00) / 0.25)
    if alpha <= 0 then return end

    Theme.drawMenuBackground({ 0.90, 0.68, 0.76, 1 }, 1)
    love.graphics.setColor(0.010, 0.008, 0.016, 0.82)
    love.graphics.rectangle("fill", 0, 0, 480, 270)
    Theme.drawGlow(240, 120, 140, { 0.62, 0.10, 0.16, 1 }, 0.26)
    drawEmbers(t, 16, { 0.85, 0.45, 0.30 })

    Theme.center("BLOODSTY", "hero", { 0.95, 0.90, 0.84, alpha }, 74, 480)
    Theme.center("EL TURNO DE GUARDIA", "title", { 0.92, 0.72, 0.38, alpha }, 106, 480)

    love.graphics.setColor(0.70, 0.14, 0.20, alpha)
    love.graphics.rectangle("fill", 158, 130, 164, 1)

    Theme.center("FASE 1 · EL CEMENTERIO", "bold", { 0.90, 0.86, 0.80, alpha }, 142, 480)
    Theme.center("JUGABLE AHORA", "bold", { 0.46, 0.82, 0.58, alpha }, 158, 480)
    Theme.center("FASES 2-4 · EN DISEÑO", "bold", { 0.88, 0.66, 0.36, alpha }, 178, 480)
    Theme.center("Clínica Abandonada · Granja Marchita · Matadero Abisal",
        "small", { 0.66, 0.62, 0.64, alpha }, 192, 480)

    Theme.center("GRACIAS POR VER", "small",
        { 0.68, 0.52, 0.56, alpha * 0.9 }, 226, 480)
end

local function drawOverlay()
    local t = frame * DT

    drawIntro(t)

    -- Horde / ability captions sit above the weapon slots.
    drawBanner(t)

    -- Victory strip while the game-over state is visible.
    if t >= 21.15 and t < 23.20 then
        local a = fadeWindow(t, 21.15, 23.20, 0.25)
        Theme.panel(96, 6, 288, 20, {
            fill = { 0.030, 0.024, 0.040, 0.88 * a },
            border = { 0.78, 0.62, 0.30, a },
            corners = false,
            shadowAlpha = 0.4 * a
        })
        Theme.center("FASE 1 COMPLETADA · EL SELLO ESTÁ ROTO", "bold",
            { 0.98, 0.84, 0.48, a }, 11, 288, 96)
    end

    for _, card in ipairs(CONCEPTS) do
        if t >= card.at and t < card.at + 2.0 then
            drawConcept(card, t)
        end
    end

    drawEndCard(t)

    -- Scene-change flashes and fades.
    local fade = 0
    if t < 0.35 then fade = math.max(fade, 1 - t / 0.35) end
    local flash = fadeWindow(t, 4.95, 5.42, 0.12)
    if flash > 0 then fade = math.max(fade, flash * 0.92) end
    local bossFlash = fadeWindow(t, 16.92, 17.32, 0.10)
    if bossFlash > 0 then fade = math.max(fade, bossFlash * 0.85) end
    if t >= 20.90 and t < 21.25 then
        local k = 1 - (t - 20.90) / 0.35
        love.graphics.setColor(0.55, 0.04, 0.08, 0.55 * k)
        love.graphics.rectangle("fill", 0, 0, 480, 270)
        love.graphics.setColor(1, 1, 1, 1)
    end
    if t >= 29.62 then fade = math.max(fade, (t - 29.62) / 0.38) end
    drawFade(fade)
end

-- ---------------------------------------------------------------------------
-- Hook / frame loop
-- ---------------------------------------------------------------------------
function Trailer.hook(stateMachine, screen)
    Trailer.enabled = true
    machine = stateMachine
    push = screen
    frame = 0
    nextEvent = 1
    banner = nil
    held = {}
    pressed = {}
    aim = -math.pi / 2

    math.randomseed(424242)

    realGetTime = love.timer.getTime
    love.timer.getTime = function() return frame * DT end
    love.mouse.getPosition = function() return -100, -100 end

    Input.isDown = function(action)
        return held[action] == true
    end
    Input.wasPressed = function(action)
        return pressed[action] == true
    end
    Input.getGameMouse = function()
        return 240 + math.cos(aim) * 90, 135 + math.sin(aim) * 90
    end

    love.filesystem.createDirectory("trailer_frames")
    local old = love.filesystem.getDirectoryItems("trailer_frames")
    for _, name in ipairs(old) do
        if name:match("%.png$") then
            love.filesystem.remove("trailer_frames/" .. name)
        end
    end

    buildTimeline()
    table.sort(events, function(a, b) return a.at < b.at end)
    print(string.format("[trailer] %d frames at %d fps (%d events)",
        Trailer.totalFrames, math.floor(1 / DT), #events))
end

function Trailer.preUpdate()
    local t = frame * DT
    pressed = {}

    while events[nextEvent] and events[nextEvent].at <= t do
        local ev = events[nextEvent]
        nextEvent = nextEvent + 1
        local ok, err = pcall(ev.fn)
        if not ok then
            print("[trailer] event error at " .. tostring(ev.at) .. ": " .. tostring(err))
        end
    end

    -- Safety net: a stray level-up must never hijack a scripted scene.
    local play = playState()
    if play and t < 13.50 and play.upgradeMenu.active then
        play.upgradeMenu.active = false
        play.player.pendingLevelUps = 0
    end

    updateAim()
    updateHeld()
end

function Trailer.draw()
    if not Trailer.enabled then return end
    local ok, err = pcall(drawOverlay)
    if not ok then
        print("[trailer] overlay error: " .. tostring(err))
    end
end

function Trailer.capture()
    if not Trailer.enabled then return end
    local canvas = push:getCanvasTable("_main").canvas
    local ok, image = pcall(function() return canvas:newImageData() end)
    if ok and image then
        local name = string.format("trailer_frames/frame_%05d.png", frame)
        image:encode("png", name)
    else
        print("[trailer] capture failed at frame " .. frame .. ": " .. tostring(image))
    end

    frame = frame + 1
    if frame >= Trailer.totalFrames then
        print("[trailer] done: " .. frame .. " frames")
        love.event.quit()
    end
end

return Trailer
