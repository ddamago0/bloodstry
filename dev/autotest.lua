--[[
    Dev-only visual/regression harness.

    Enable with:
        BLOODSTY_AUTOTEST=full love .
        BLOODSTY_AUTOTEST=ysort love .

    Screenshots are written to LOVE's save directory under captures/.
    This module is a no-op unless the environment variable is set, so it
    never affects a normal game session.
]]

local Autotest = {}

local mode = os.getenv("BLOODSTY_AUTOTEST")
if not mode or mode == "" then
    function Autotest.hook() end
    function Autotest.update() end
    function Autotest.draw() end
    function Autotest.keypressed() end
    return Autotest
end

local Input = require("src.core.input")
local push = require("lib.push")
local Enemy = require("src.entities/enemy")
local Limb = require("src.combat.limb")
local LimbDrop = require("src.entities/limb_drop")

local stateMachine
local startedAt
local nextEvent = 1
local capturesLeft = 0
local finished = false
local events = {}

-- Deterministic RNG for reproducible captures.
math.randomseed(9271)

local function addCapture(t, name)
    table.insert(events, { t = t, kind = "capture", name = name })
end

local function addAction(t, fn)
    table.insert(events, { t = t, kind = "action", fn = fn })
end

local function heldInputs(held)
    Input.isDown = function(action)
        return held[action] == true
    end
    Input.getGameMouse = function()
        return held.mouseX or 360, held.mouseY or 120
    end
end

local function scenarioFull()
    heldInputs({})

    addCapture(0.35, "01_class_select")
    addAction(0.60, function() love.keypressed("right") end)
    addAction(0.80, function() love.keypressed("right") end)
    addCapture(1.00, "02_class_select_asesino")
    addAction(1.15, function() love.keypressed("1") end)
    addCapture(1.55, "03_gameplay_start")

    addAction(1.80, function()
        heldInputs({ right = true, attack = true, mouseX = 420, mouseY = 120 })
    end)
    addAction(2.60, function() love.keypressed("l") end)
    addAction(2.80, function()
        local play = stateMachine.current
        if play.player then
            play.player.pendingLevelUps = 0
            play.player.bloodPoints = 0
            play.upgradeMenu.active = false
        end
    end)
    addAction(3.00, function()
        local play = stateMachine.current
        if play.player then
            play.player:equipLimb(Limb(Limb.TYPES.SKELETON_ARM, 12))
        end
    end)
    addAction(3.20, function()
        heldInputs({ attack = true, limb_attack = true, mouseX = 430, mouseY = 130 })
    end)
    addCapture(4.20, "04_gameplay_combat")

    addAction(4.50, function()
        heldInputs({})
        local play = stateMachine.current
        play.player:gainBloodPoints(play.player.pointsToNextLevel)
    end)
    addCapture(5.20, "05_upgrade_menu")

    addAction(5.50, function() love.keypressed("r") end)
    addCapture(5.90, "06_upgrade_reroll")

    addAction(6.10, function() love.keypressed("1") end)
    addAction(6.40, function()
        heldInputs({ mouseX = 360, mouseY = 120 })
        love.keypressed("b")
    end)
    addCapture(7.60, "07_boss")

    addAction(8.20, function()
        heldInputs({ attack = true, limb_attack = true, mouseX = 300, mouseY = 100 })
    end)
    addCapture(9.20, "08_boss_combat")

    addAction(9.35, function()
        local play = stateMachine.current
        local boss = play.stage.bossInstance
        if boss and boss.alive then
            boss.x = play.player.x + 4
            boss.y = play.player.y - 78
            boss.hp = boss.maxHp * 0.45
            boss.summonDone = true
        end
    end)
    addCapture(9.55, "08b_boss_closeup")

    addAction(9.80, function()
        heldInputs({})
        local play = stateMachine.current
        if play.player then
            play.player.invulnTimer = 0
            play.player.boneShield = 0
            play.player:takeDamage(9999, 0, 0)
        end
    end)
    addCapture(10.40, "09_game_over")
    addAction(10.80, function() finished = true end)
end

local function scenarioYsort()
    heldInputs({})
    addAction(0.20, function() love.keypressed("1") end)

    addAction(0.60, function()
        local play = stateMachine.current
        local player = play.player
        player.x = 0
        player.y = 10

        -- Ring of props around the player to inspect depth ordering.
        local stage = play.stage
        stage.props = {}
        table.insert(stage.props, { type = "tombstone_a", x = -28, y = 20, scale = 1, flip = false })
        table.insert(stage.props, { type = "tombstone_b", x = 28, y = 20, scale = 1, flip = true })
        table.insert(stage.props, { type = "tombstone_c", x = 0, y = -18, scale = 1, flip = false })
        table.insert(stage.props, { type = "dead_tree_a", x = -70, y = -30, scale = 1.1, flip = false })
        table.insert(stage.props, { type = "dead_tree_b", x = 70, y = 40, scale = 1.15, flip = true })
        table.insert(stage.props, { type = "brazier", x = -46, y = 56, scale = 1, flip = false })
        table.insert(stage.props, { type = "central_crypt", x = 0, y = -70, w = 84, h = 64, scale = 1 })

        table.insert(play.enemies, Enemy(-42, 45, Enemy.TYPES.SKELETON_COMMON))
        table.insert(play.enemies, Enemy(48, -35, Enemy.TYPES.SKELETON_TALL))
        table.insert(play.enemies, Enemy(-80, 60, Enemy.TYPES.SKELETON_ROBED))
        table.insert(play.enemies, Enemy(80, -60, Enemy.TYPES.ZOMBIE))
        table.insert(play.drops, LimbDrop(20, 60, Limb(Limb.TYPES.HEAD, 6)))
        table.insert(play.drops, LimbDrop(-22, 65, Limb(Limb.TYPES.SKELETON_ARM, 12)))

        -- Freeze incoming damage for the depth test so the red damage flash
        -- and invulnerability blink do not hide the actor being inspected.
        play.player.takeDamage = function() return 0 end
    end)
    addCapture(1.40, "10_ysort_layout")

    addAction(1.80, function()
        local play = stateMachine.current
        play.player.x = 0
        play.player.y = 32
    end)
    addCapture(2.40, "11_ysort_front")

    addAction(2.80, function()
        local play = stateMachine.current
        play.player.x = 0
        play.player.y = -28
    end)
    addCapture(3.40, "12_ysort_behind")

    addAction(3.80, function() love.keypressed("escape") end)
    addCapture(4.10, "16_pause_overlay")

    addAction(4.30, function() love.keypressed("escape") end)
    addAction(4.50, function()
        local play = stateMachine.current
        if play.player then
            play.player.visionRadiusMult = 0.5
        end
    end)
    addCapture(4.80, "17_vision_stencil")
    addAction(5.20, function() finished = true end)
end

local function scenarioLong()
    heldInputs({})
    addAction(0.20, function() love.keypressed("1") end)
    addAction(0.50, function()
        heldInputs({ right = true, down = true, attack = true, limb_attack = true, mouseX = 400, mouseY = 150 })
    end)

    -- Populate a dense horde + gore to check readability and performance.
    addAction(1.20, function()
        local play = stateMachine.current
        local p = play.player
        p:equipLimb(Limb(Limb.TYPES.SKELETON_ARM, 14))
        for i = 1, 90 do
            local a = math.random() * math.pi * 2
            local d = math.random(35, 190)
            local types = {
                Enemy.TYPES.SKELETON_COMMON,
                Enemy.TYPES.SKELETON_COMMON,
                Enemy.TYPES.SKELETON_TALL,
                Enemy.TYPES.SKELETON_ROBED,
                Enemy.TYPES.ZOMBIE,
            }
            local e = Enemy(p.x + math.cos(a) * d, p.y + math.sin(a) * d,
                types[math.random(1, #types)])
            table.insert(play.enemies, e)
        end
        for i = 1, 30 do
            play.bloodCanvas:splatter(p.x + math.random(-140, 140), p.y + math.random(-100, 100),
                8, 22, { 0.55, 0.04, 0.07, 0.85 })
        end

        -- Keep the horde capture on the battlefield rather than the level-up
        -- menu: the scenario is about dense combat readability.
        p.pointsToNextLevel = 1e9
        p.bloodPoints = 0
        p.pendingLevelUps = 0
        play.upgradeMenu.active = false
    end)
    addCapture(3.00, "13_dense_horde")
    addCapture(6.00, "14_dense_horde_late")

    addAction(6.40, function()
        local play = stateMachine.current
        if play.player then
            play.player.invulnTimer = 0
            play.player.boneShield = 0
            play.player:takeDamage(9999, 0, 0)
        end
    end)
    addCapture(7.00, "15_long_game_over")
    addAction(7.40, function() finished = true end)
end

local function scenarioVictory()
    heldInputs({})
    addAction(0.20, function() love.keypressed("1") end)
    addAction(0.70, function()
        love.keypressed("b")
        local play = stateMachine.current
        local boss = play.stage.bossInstance
        if boss then
            boss.x = play.player.x + 6
            boss.y = play.player.y - 80
        end
    end)
    addCapture(1.20, "18_boss_entry")
    addAction(1.50, function()
        local play = stateMachine.current
        local boss = play.stage.bossInstance
        if boss then
            boss.hp = 1
            boss:takeDamage(9999, 0, 0)
        end
    end)
    addCapture(2.00, "19_victory")
    addAction(2.60, function() finished = true end)
end

local scenarios = {
    full = scenarioFull,
    ysort = scenarioYsort,
    long = scenarioLong,
    victory = scenarioVictory,
}

function Autotest.hook(machine)
    stateMachine = machine
    startedAt = love.timer.getTime()
    love.filesystem.createDirectory("captures")

    local build = scenarios[mode] or scenarioFull
    build()
    table.sort(events, function(a, b) return a.t < b.t end)

    print(string.format("[autotest] mode=%s events=%d", mode, #events))
end

function Autotest.update(dt)
    if not stateMachine or finished then return end
    local t = love.timer.getTime() - startedAt

    while events[nextEvent] and events[nextEvent].t <= t do
        local ev = events[nextEvent]
        nextEvent = nextEvent + 1
        if ev.kind == "capture" then
            capturesLeft = capturesLeft + 1
            ev.pending = true
        elseif ev.kind == "action" then
            local ok, err = pcall(ev.fn)
            if not ok then
                print("[autotest] action error: " .. tostring(err))
            end
        end
    end
end

function Autotest.draw()
    if capturesLeft <= 0 then return end
    for i = nextEvent - 1, 1, -1 do
        local ev = events[i]
        if ev.kind == "capture" and ev.pending then
            ev.pending = false
            capturesLeft = capturesLeft - 1
            local name = ev.name .. ".png"

            -- Capture the virtual-resolution canvas instead of the OS window:
            -- this keeps pixel-perfect layout captures independent of the WM.
            local canvas = push:getCanvasTable("_main").canvas
            local ok, imgdata = pcall(function() return canvas:newImageData() end)
            if ok and imgdata then
                imgdata:encode("png", "captures/" .. name)
                print("[autotest] captured " .. name)
            else
                print("[autotest] canvas capture failed: " .. tostring(imgdata))
            end
        end
    end
end

function Autotest.keypressed()
    -- Captures are driven by scheduled events, not real input.
end

return Autotest
