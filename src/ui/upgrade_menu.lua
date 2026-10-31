local Class = require("lib.classic")
local SkillsData = require("src.progression/skills_data")
local Theme = require("src.ui.theme")

local UpgradeMenu = Class:extend()

local CARD_W = 136
local CARD_H = 156
local CARD_Y = 54
local CARD_X = { 24, 172, 320 }
local REROLL_W = 132
local REROLL_H = 18
local REROLL_Y = 218

local function mouseGame(push)
    local mx, my = love.mouse.getPosition()
    if push then
        return push:toGame(mx, my)
    end
    return mx, my
end

local function inside(gx, gy, x, y, w, h)
    return gx >= x and gx <= x + w and gy >= y and gy <= y + h
end

function UpgradeMenu:new()
    self.active = false
    self.cards = {}
    self.rerollsLeft = 2
    self.selectedIndex = 1
end

function UpgradeMenu:open(player)
    self.active = true
    self.cards = SkillsData.getRandomCardPool(3, 0.4)
    self.rerollsLeft = 2
    self.selectedIndex = 1
end

function UpgradeMenu:reroll()
    if self.rerollsLeft > 0 then
        self.rerollsLeft = self.rerollsLeft - 1
        self.cards = SkillsData.getRandomCardPool(3, 0.4)
        self.selectedIndex = 1
    end
end

function UpgradeMenu:selectCard(index, player)
    if not self.active or not self.cards[index] then return end
    local card = self.cards[index]
    card.apply(player)

    player.pendingLevelUps = math.max(0, player.pendingLevelUps - 1)
    if player.pendingLevelUps > 0 then
        -- Chain the next pending level-up with a fresh set of options.
        self.cards = SkillsData.getRandomCardPool(3, 0.4)
        self.rerollsLeft = 2
        self.selectedIndex = 1
    else
        self.active = false
    end
end

function UpgradeMenu:keypressed(key, player)
    if not self.active then return end
    if key == "1" then
        self:selectCard(1, player)
    elseif key == "2" then
        self:selectCard(2, player)
    elseif key == "3" then
        self:selectCard(3, player)
    elseif key == "r" then
        self:reroll()
    elseif key == "tab" or key == "escape" or key == "u" then
        -- Don't silently discard a pending level-up: the state would reopen
        -- this menu on the next frame anyway.
        if player.pendingLevelUps <= 0 then
            self.active = false
        end
    end
end

function UpgradeMenu:mousepressed(gx, gy, button, player, viewWidth, viewHeight)
    if not self.active or button ~= 1 then return end

    for i = 1, #self.cards do
        if inside(gx, gy, CARD_X[i], CARD_Y, CARD_W, CARD_H) then
            self:selectCard(i, player)
            return
        end
    end

    local rx = (viewWidth or 480) / 2 - REROLL_W / 2
    if inside(gx, gy, rx, REROLL_Y, REROLL_W, REROLL_H) then
        self:reroll()
    end
end

function UpgradeMenu:drawCard(card, index, selected, hovered)
    local C = Theme.colors
    local x = CARD_X[index]
    local y = CARD_Y
    local pulse = (math.sin(love.timer.getTime() * 4 + index) + 1) * 0.5
    local isPact = card.isPact

    local accent = isPact and C.bloodBright or C.steelBright
    local border = isPact and C.blood or C.border
    if selected or hovered then
        border = isPact and { 0.95, 0.30, 0.34, 1 } or C.purpleBright
    end

    local fill = isPact and { 0.095, 0.038, 0.058, 0.97 } or { 0.062, 0.060, 0.088, 0.97 }
    if hovered then
        fill = isPact and { 0.135, 0.052, 0.072, 0.98 } or { 0.090, 0.086, 0.120, 0.98 }
    end

    if selected then
        Theme.drawGlow(x + CARD_W / 2, y + CARD_H / 2 + 10, 92,
            isPact and { 0.55, 0.08, 0.12, 1 } or { 0.30, 0.18, 0.52, 1 }, 0.16)
    end

    Theme.panel(x, y, CARD_W, CARD_H, {
        fill = fill,
        border = border,
        accent = accent,
        cornerColor = accent,
        shadowAlpha = 0.55
    })

    -- Top category tag and keyboard shortcut.
    Theme.print(isPact and "PACTO MALDITO" or "BENDICIÓN", "small",
        isPact and C.bloodBright or C.steel, x + 7, y + 7)
    Theme.right("[" .. index .. "]", "small", C.dim, x + CARD_W - 7, y + 7)

    -- Icon medallion.
    local mx, my = x + CARD_W / 2 - 16, y + 21
    Theme.panel(mx, my, 32, 32, {
        fill = { 0.028, 0.026, 0.042, 0.96 },
        border = isPact and C.bloodDark or C.borderSoft,
        corners = false,
        shadowAlpha = 0
    })
    if card.isPact then
        Theme.drawGlow(mx + 16, my + 16, 22, { 0.55, 0.05, 0.12, 1 }, 0.22)
    end
    Theme.iconCentered(card.icon or (isPact and "flame" or "level"), x + CARD_W / 2, my + 4, 1.5,
        isPact and C.bloodBright or C.goldBright)

    -- Title (up to two lines).
    Theme.setFont("bold")
    Theme.setColor(isPact and { 1, 0.82, 0.82, 1 } or C.text)
    love.graphics.printf(card.title, x + 8, y + 58, CARD_W - 16, "center")

    Theme.setColor(isPact and C.blood or C.borderSoft, 0.8)
    love.graphics.line(x + 14, y + 80, x + CARD_W - 14, y + 80)

    -- Description.
    Theme.printf(card.desc, "small", isPact and { 0.90, 0.82, 0.82, 1 } or C.textSoft,
        x + 8, y + 86, CARD_W - 16, "left")

    -- Footer action.
    local footerColor = selected and C.goldBright or C.dim
    if selected then
        Theme.setColor(accent, 0.10 + pulse * 0.08)
        love.graphics.rectangle("fill", x + 1, y + CARD_H - 18, CARD_W - 2, 17)
    end
    Theme.center("ELEGIR", "small", footerColor, y + CARD_H - 14, CARD_W, x)

    Theme.setColor(accent, selected and 0.95 or 0.55)
    love.graphics.rectangle("fill", x + 1, y + CARD_H - 2, CARD_W - 2, 1)
    love.graphics.setColor(1, 1, 1, 1)
end

function UpgradeMenu:draw(viewWidth, viewHeight, player, push)
    if not self.active then return end
    viewWidth = viewWidth or 480
    viewHeight = viewHeight or 270

    local C = Theme.colors
    local mx, my = mouseGame(push)
    local hovered = 0
    for i = 1, #self.cards do
        if inside(mx, my, CARD_X[i], CARD_Y, CARD_W, CARD_H) then
            hovered = i
            break
        end
    end

    -- Backdrop.
    love.graphics.setColor(0.018, 0.014, 0.026, 0.90)
    love.graphics.rectangle("fill", 0, 0, viewWidth, viewHeight)
    Theme.drawVignette(0.55, { 0.02, 0.0, 0.03, 1 })

    Theme.center("ELIGE TU DESTINO", "title", C.text, 10, viewWidth)
    local sub = string.format("Sangre derramada  ·  Nivel %d", player and player.level or 1)
    if player and player.pendingLevelUps > 1 then
        sub = sub .. string.format("  ·  %d mejoras pendientes", player.pendingLevelUps)
    end
    Theme.center(sub, "small", C.textSoft, 31, viewWidth)

    for i = 1, #self.cards do
        self:drawCard(self.cards[i], i, i == self.selectedIndex, i == hovered)
    end

    -- Reroll control.
    local rx = viewWidth / 2 - REROLL_W / 2
    local hasRerolls = self.rerollsLeft > 0
    Theme.panel(rx, REROLL_Y, REROLL_W, REROLL_H, {
        fill = hasRerolls and { 0.085, 0.075, 0.110, 0.97 } or { 0.045, 0.042, 0.060, 0.9 },
        border = hasRerolls and C.border or C.borderDark,
        corners = false,
        shadowAlpha = 0.35
    })
    Theme.icon("reroll", rx + 8, REROLL_Y + 1, 1,
        hasRerolls and C.steelBright or C.mute)
    Theme.print(hasRerolls and "RECARGAR [R]" or "SIN RECARGAS", "small",
        hasRerolls and C.text or C.dim, rx + 28, REROLL_Y + 5)
    Theme.right("x" .. self.rerollsLeft, "bold",
        hasRerolls and C.gold or C.mute, rx + REROLL_W - 8, REROLL_Y + 3)

    Theme.center("[1-3] o clic para elegir  ·  [R] recargar cartas", "small", C.dim, 247, viewWidth)
    love.graphics.setColor(1, 1, 1, 1)
end

return UpgradeMenu
