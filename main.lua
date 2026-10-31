local push = require("lib.push")
local StateMachine = require("src.core.state_machine")
local Input = require("src.core.input")
local Assets = require("src.core.assets")
local Autotest = require("dev.autotest")
local Trailer = require("dev.trailer")

local ClassSelectState = require("src.states.class_select_state")
local PlayState = require("src.states.play_state")
local GameOverState = require("src.states.game_over_state")

local VIRTUAL_WIDTH = 480
local VIRTUAL_HEIGHT = 270
local WINDOW_WIDTH = 1280
local WINDOW_HEIGHT = 720
local AUTOTEST = os.getenv("BLOODSTY_AUTOTEST")
local TRAILER = os.getenv("BLOODSTY_TRAILER") == "1"

local stateMachine

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.window.setTitle("Bloodsty - El Turno de Guardia")

    if TRAILER then
        pcall(love.window.setVSync, 0)
    end

    if (not AUTOTEST or AUTOTEST == "") and not TRAILER then
        love.mouse.setVisible(false)
    end

    Assets.load()

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        pixelperfect = false,
        canvas = true,
        highdpi = true
    })

    stateMachine = StateMachine()
    stateMachine:add("class_select", ClassSelectState(stateMachine, push))
    stateMachine:add("play", PlayState(stateMachine, push))
    stateMachine:add("game_over", GameOverState(stateMachine, push))

    stateMachine:change("class_select")
    love.stateMachine = stateMachine

    if TRAILER then
        Trailer.hook(stateMachine, push)
    else
        Autotest.hook(stateMachine)
    end
end

function love.update(dt)
    if TRAILER then
        -- Fixed timestep keeps the recorded trailer perfectly stable even if
        -- PNG encoding is slower than real time.
        Trailer.preUpdate()
        dt = Trailer.dt
    else
        -- Cap delta time to prevent physics/movement tunneling on huge lag spikes
        dt = math.min(dt, 0.05)
    end

    Autotest.update(dt)
    stateMachine:update(dt)
    Input.update()
end

function love.draw()
    push:start()
    stateMachine:draw()
    if TRAILER then Trailer.draw() end

    -- Custom bone cursor (skipped in automated captures and the trailer).
    if (not AUTOTEST or AUTOTEST == "") and not TRAILER and Assets.sprites.cursor then
        local mx, my = love.mouse.getPosition()
        local gx, gy = push:toGame(mx, my)
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.draw(Assets.sprites.cursor, math.floor(gx) - 8, math.floor(gy) - 8)
        love.graphics.setColor(1, 1, 1, 1)
    end

    push:finish()
    if TRAILER then
        Trailer.capture()
    else
        Autotest.draw()
    end
end

function love.keypressed(key)
    Input.keypressed(key)
    stateMachine:keypressed(key)
    Autotest.keypressed(key)
end

function love.mousepressed(x, y, button)
    Input.mousepressed(x, y, button)
    stateMachine:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    if stateMachine.mousereleased then
        stateMachine:mousereleased(x, y, button)
    end
end

function love.resize(w, h)
    push:resize(w, h)
end
