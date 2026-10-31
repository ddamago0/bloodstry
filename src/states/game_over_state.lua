local Class = require("lib.classic")
local Theme = require("src.ui.theme")

local GameOverState = Class:extend()

local PANEL_W = 340
local PANEL_H = 198
local PANEL_X = 70
local PANEL_Y = 32

function GameOverState:new(stateMachine, push)
    self.stateMachine = stateMachine
    self.push = push
    self.viewWidth = push:getWidth()
    self.viewHeight = push:getHeight()

    self.victory = false
    self.kills = 0
    self.timeSurvived = 0
    self.classType = "guerrero"
    self.level = 1
end

function GameOverState:enter(params)
    params = params or {}
    self.victory = params.victory or false
    self.kills = params.kills or 0
    self.timeSurvived = params.timeSurvived or 0
    self.classType = params.classType or "guerrero"
    self.level = params.level or 1
end

function GameOverState:keypressed(key)
    if key == "return" or key == "space" or key == "kpenter" then
        self.stateMachine:change("class_select")
    elseif key == "escape" then
        love.event.quit()
    end
end

function GameOverState:mousepressed(x, y, button)
    if button == 1 then
        self.stateMachine:change("class_select")
    end
end

function GameOverState:drawStatRow(icon, label, value, y, color)
    local C = Theme.colors
    Theme.icon(icon, PANEL_X + 20, y - 2, 1, color or C.bone)
    Theme.print(label, "small", C.textSoft, PANEL_X + 42, y)
    Theme.right(value, "bold", C.text, PANEL_X + PANEL_W - 20, y - 2)
    Theme.setColor(C.borderSoft, 0.45)
    love.graphics.line(PANEL_X + 20, y + 11, PANEL_X + PANEL_W - 20, y + 11)
end

function GameOverState:draw()
    local C = Theme.colors
    local pulse = (math.sin(love.timer.getTime() * 5) + 1) * 0.5

    Theme.drawMenuBackground(
        self.victory and { 0.80, 0.74, 0.92, 1 } or { 0.92, 0.72, 0.74, 1 },
        1)

    love.graphics.setColor(0, 0, 0, 0.48)
    love.graphics.rectangle("fill", 0, 0, 480, 270)

    local accent = self.victory and C.gold or C.bloodBright
    Theme.panel(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, {
        fill = self.victory and { 0.065, 0.055, 0.090, 0.97 } or { 0.085, 0.032, 0.052, 0.97 },
        border = self.victory and C.gold or C.blood,
        accent = accent,
        cornerColor = accent,
        shadowAlpha = 0.70
    })

    Theme.drawGlow(240, PANEL_Y + 30, 70,
        self.victory and { 0.55, 0.42, 0.15, 1 } or { 0.55, 0.06, 0.10, 1 }, 0.18)

    Theme.iconCentered(self.victory and "boss" or "skull", 240, PANEL_Y + 10, 1.25, accent)

    if self.victory then
        Theme.center("LA PARCA HA CAÍDO", "title", C.goldBright, PANEL_Y + 34, 480)
        Theme.center("El sello está roto. Don Evaristo huye hacia la Clínica Abandonada.",
            "small", C.textSoft, PANEL_Y + 54, 480)
    else
        Theme.center("HAS SUCUMBIDO", "title", C.bloodBright, PANEL_Y + 34, 480)
        Theme.center("Tu carne se pudre entre lápidas. El turno continúa sin ti.",
            "small", C.textSoft, PANEL_Y + 54, 480)
    end

    Theme.setColor(accent, 0.55)
    love.graphics.line(PANEL_X + 20, PANEL_Y + 72, PANEL_X + PANEL_W - 20, PANEL_Y + 72)

    local timeText = Theme.timeString(self.timeSurvived)
    local classText = Theme.className(self.classType)
    self:drawStatRow("hourglass", "TIEMPO SOBREVIVIDO", timeText, PANEL_Y + 84, C.gold)
    self:drawStatRow("skull", "ENEMIGOS MASACRADOS", tostring(self.kills), PANEL_Y + 108, C.bone)
    self:drawStatRow("level", "NIVEL ALCANZADO", tostring(self.level), PANEL_Y + 132, C.purpleBright)
    self:drawStatRow("shield", "CLASE", string.upper(classText), PANEL_Y + 156, C.steelBright)

    Theme.center("[ENTER / CLIC] VOLVER A INTENTAR", "bold",
        { 1, 1, 1, 0.55 + pulse * 0.45 }, PANEL_Y + 177, 480)
    Theme.center("[ESC] ABANDONAR EL CEMENTERIO", "small", C.dim, PANEL_Y + 189, 480)

    Theme.drawVignette(0.55)
    love.graphics.setColor(1, 1, 1, 1)
end

return GameOverState
