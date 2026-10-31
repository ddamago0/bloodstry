local Class = require("lib.classic")
local Assets = require("src.core.assets")
local Theme = require("src.ui.theme")

local ClassSelectState = Class:extend()

local CARD_W = 140
local CARD_H = 193
local CARD_Y = 49
local CARD_X = { 20, 170, 320 }

local function mouseGame(push)
    local mx, my = love.mouse.getPosition()
    return push:toGame(mx, my)
end

local function inside(gx, gy, x, y, w, h)
    return gx >= x and gx <= x + w and gy >= y and gy <= y + h
end

function ClassSelectState:new(stateMachine, push)
    self.stateMachine = stateMachine
    self.push = push
    self.viewWidth = push:getWidth()
    self.viewHeight = push:getHeight()

    self.classes = {
        {
            id = "guerrero",
            name = "Guerrero",
            lore = "Ex-cantero y herrero de mausoleos. Su fe pesa más que su acero.",
            weapon = "Espada Bastarda",
            weaponNote = "Arco equilibrado",
            passive = "Escudo óseo al romper una extremidad.",
            stats = { hp = 150, str = 1.0, spd = 92 },
            statText = { hp = "150", str = "1.0x", spd = "92" },
            color = { 0.50, 0.46, 0.66, 1 }
        },
        {
            id = "barbaro",
            name = "Bárbaro",
            lore = "Cavador de fosas y leñador fornido. Huele a tierra recién removida.",
            weapon = "Murakumogiri",
            weaponNote = "Alabarda de alto impacto",
            passive = "Usa la extremidad sin pausar el arma.",
            stats = { hp = 115, str = 1.45, spd = 86 },
            statText = { hp = "115", str = "1.45x", spd = "86" },
            color = { 0.62, 0.40, 0.26, 1 }
        },
        {
            id = "asesino",
            name = "Asesino",
            lore = "Fugitivo y profanador de tumbas. No deja huellas, solo sangre.",
            weapon = "Dagas Gemelas",
            weaponNote = "Ataques rápidos en ráfaga",
            passive = "Cabezas veloces y brazos que sangran.",
            stats = { hp = 85, str = 0.82, spd = 135 },
            statText = { hp = "85", str = "0.82x", spd = "135" },
            color = { 0.34, 0.48, 0.52, 1 }
        }
    }

    self.selectedIndex = 1
end

function ClassSelectState:enter()
    self.selectedIndex = 1
end

function ClassSelectState:keypressed(key)
    if key == "left" or key == "a" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then self.selectedIndex = #self.classes end
    elseif key == "right" or key == "d" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.classes then self.selectedIndex = 1 end
    elseif key == "1" then
        self.selectedIndex = 1
        self:confirmSelection()
    elseif key == "2" then
        self.selectedIndex = 2
        self:confirmSelection()
    elseif key == "3" then
        self.selectedIndex = 3
        self:confirmSelection()
    elseif key == "return" or key == "space" or key == "kpenter" then
        self:confirmSelection()
    end
end

function ClassSelectState:mousepressed(x, y, button)
    if button ~= 1 then return end
    local gx, gy = self.push:toGame(x, y)

    for i = 1, #self.classes do
        if inside(gx, gy, CARD_X[i], CARD_Y, CARD_W, CARD_H) then
            self.selectedIndex = i
            self:confirmSelection()
            return
        end
    end
end

function ClassSelectState:confirmSelection()
    local chosen = self.classes[self.selectedIndex]
    self.stateMachine:change("play", { classType = chosen.id })
end

function ClassSelectState:drawPortrait(cls, x, y, w, h)
    local sprite = Assets.sprites.players and Assets.sprites.players[cls.id]
    local frames = Assets.quads.playerFrames and Assets.quads.playerFrames[cls.id]

    Theme.panel(x, y, w, h, {
        fill = { 0.030, 0.030, 0.048, 0.94 },
        border = { cls.color[1] * 0.55, cls.color[2] * 0.55, cls.color[3] * 0.55, 1 },
        corners = false,
        shadowAlpha = 0
    })

    -- Faint class-coloured haze behind the character.
    Theme.drawGlow(x + w / 2, y + h - 12, 34, cls.color, 0.12)

    if sprite and frames and frames[1] then
        local scale = math.min((h - 8) / 40, (w - 20) / 32)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sprite, frames[1], x + w / 2, y + h - 5, 0, scale, scale, 16, 40)
    else
        Theme.iconCentered("skull", x + w / 2, y + h / 2 - 8, 2, cls.color)
    end
end

function ClassSelectState:drawStatRow(cls, label, valueText, pct, x, y, color)
    local C = Theme.colors
    Theme.print(label, "small", C.dim, x, y)
    Theme.bar(x + 22, y + 2, 68, 3, pct, color, nil, { border = false })
    Theme.right(valueText, "small", color, x + 124, y)
end

function ClassSelectState:drawCard(cls, index, selected, hovered)
    local C = Theme.colors
    local x = CARD_X[index]
    local y = CARD_Y
    local pulse = (math.sin(love.timer.getTime() * 5 + index * 1.7) + 1) * 0.5

    local border = { cls.color[1] * 0.75, cls.color[2] * 0.75, cls.color[3] * 0.75, 1 }
    local accent = cls.color
    if selected then
        border = { 0.90, 0.25 + pulse * 0.20, 0.26, 1 }
        accent = { 0.95, 0.35 + pulse * 0.20, 0.30, 1 }
        Theme.drawGlow(x + CARD_W / 2, y + CARD_H / 2, 105,
            { 0.45, 0.10, 0.16, 1 }, 0.13)
    elseif hovered then
        border = { cls.color[1], cls.color[2], cls.color[3], 1 }
    end

    Theme.panel(x, y, CARD_W, CARD_H, {
        fill = selected and { 0.072, 0.060, 0.080, 0.97 } or { 0.050, 0.048, 0.070, 0.96 },
        border = border,
        accent = accent,
        cornerColor = selected and C.bloodBright or border,
        shadowAlpha = 0.58
    })

    Theme.print("[" .. index .. "]", "bold", selected and C.bloodBright or C.mute, x + 7, y + 6)
    Theme.center(cls.name, "bold", selected and C.text or C.textSoft, y + 5, CARD_W, x)

    self:drawPortrait(cls, x + 8, y + 22, CARD_W - 16, 54)

    Theme.printf(cls.lore, "small", C.textSoft, x + 8, y + 80, CARD_W - 16, "left")

    Theme.setColor(border, 0.55)
    love.graphics.line(x + 10, y + 98, x + CARD_W - 10, y + 98)

    Theme.print("ARMA", "small", C.dim, x + 8, y + 102)
    Theme.print(cls.weapon, "bold", selected and C.goldBright or C.gold, x + 8, y + 110)

    self:drawStatRow(cls, "PS", cls.statText.hp, cls.stats.hp / 150, x + 8, y + 126, C.bloodBright)
    self:drawStatRow(cls, "FUE", cls.statText.str, cls.stats.str / 1.45, x + 8, y + 136, C.goldBright)
    self:drawStatRow(cls, "VEL", cls.statText.spd, cls.stats.spd / 135, x + 8, y + 146, C.steelBright)

    Theme.print("PASIVA", "small", selected and C.purpleBright or C.purple, x + 8, y + 156)
    Theme.printf(cls.passive, "small", C.textSoft, x + 8, y + 163, CARD_W - 16, "left")

    if selected then
        Theme.setColor(accent, 0.9)
        love.graphics.rectangle("fill", x + 1, y + CARD_H - 2, CARD_W - 2, 1)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function ClassSelectState:draw()
    local C = Theme.colors
    Theme.drawMenuBackground()

    -- Extra top-down shadow so the title remains legible.
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", 0, 0, 480, 46)

    Theme.center("BLOODSTY", "hero", C.text, 5, 480)
    Theme.setColor(C.blood)
    love.graphics.rectangle("fill", 168, 29, 144, 1)
    Theme.center("EL TURNO DE GUARDIA", "bold", C.gold, 33, 480)

    local mx, my = mouseGame(self.push)
    local hovered = 0
    for i = 1, #self.classes do
        if inside(mx, my, CARD_X[i], CARD_Y, CARD_W, CARD_H) then
            hovered = i
            break
        end
    end

    for i = 1, #self.classes do
        self:drawCard(self.classes[i], i, i == self.selectedIndex, i == hovered)
    end

    Theme.panel(84, 242, 312, 24, {
        fill = { 0.035, 0.030, 0.045, 0.92 },
        border = C.borderSoft,
        corners = false,
        shadowAlpha = 0.35
    })
    local chosen = self.classes[self.selectedIndex]
    Theme.center(string.upper(chosen.name) .. "  ·  " .. string.upper(chosen.weapon),
        "small", C.text, 244, 480)
    Theme.center("[A/D · FLECHAS] ELEGIR     [ENTER] COMENZAR     [CLIC] CONFIRMAR",
        "small", C.dim, 254, 480)

    love.graphics.setColor(1, 1, 1, 1)
end

return ClassSelectState
