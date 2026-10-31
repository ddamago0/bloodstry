local Class = require("lib.classic")
local Limb = require("src.combat.limb")
local Assets = require("src.core.assets")
local Theme = require("src.ui.theme")
local LimbDrop = Class:extend()

local GLOW = {
    [Limb.TYPES.HEAD] = { 0.85, 0.30, 0.30, 1 },
    [Limb.TYPES.SKELETON_ARM] = { 0.80, 0.78, 0.70, 1 },
    [Limb.TYPES.ZOMBIE_ARM] = { 0.45, 0.72, 0.35, 1 }
}

function LimbDrop:new(x, y, limb)
    self.x = x
    self.y = y
    self.radius = 10
    self.limb = limb or Limb.randomDrop()
    self.alive = true
    self.bobTimer = math.random() * math.pi * 2
    self.lifeTime = 30 -- seconds before rotting away
    self.maxLifeTime = 30
end

function LimbDrop:update(dt)
    if not self.alive then return end
    self.bobTimer = self.bobTimer + dt * 4
    self.lifeTime = self.lifeTime - dt
    if self.lifeTime <= 0 then
        self.alive = false
    end
end

function LimbDrop:draw()
    if not self.alive then return end
    local yOffset = math.sin(self.bobTimer) * 1.5 - 3
    local fade = 1
    if self.lifeTime < 5 then
        fade = 0.35 + 0.65 * ((math.sin(self.bobTimer * 3) + 1) * 0.5)
    end

    -- Ground shadow stays on the floor while the item bobs above it.
    love.graphics.setColor(0, 0, 0, 0.34 * fade)
    love.graphics.ellipse("fill", self.x, self.y + 2, 7, 2.5)

    local glowColor = GLOW[self.limb.type] or { 0.85, 0.85, 0.85, 1 }
    Theme.drawGlow(self.x, self.y - 10 + yOffset, 11, glowColor, 0.16 * fade)

    local sprite = Assets.sprites.limbs
    local asset = Assets.quads.limbs
    if sprite and asset then
        local quadKey = "skeleton_arm"
        if self.limb.type == Limb.TYPES.HEAD then
            quadKey = "head"
        elseif self.limb.type == Limb.TYPES.ZOMBIE_ARM then
            quadKey = "zombie_arm"
        end
        local quad = asset[quadKey]
        if quad then
            love.graphics.setColor(1, 1, 1, fade)
            love.graphics.draw(sprite, quad.quad, self.x, self.y - 8 + yOffset,
                math.sin(self.bobTimer * 0.5) * 0.08, 1, 1, 10, 10)
        end
    end

    -- Small highlight spark to draw the eye.
    local spark = (math.sin(self.bobTimer * 2) + 1) * 0.5
    love.graphics.setColor(1, 0.92, 0.80, 0.25 + spark * 0.35)
    love.graphics.circle("fill", self.x + 5, self.y - 13 + yOffset, 1)
    love.graphics.setColor(1, 1, 1, 1)
end

return LimbDrop
