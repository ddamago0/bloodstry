local Class = require("lib.classic")
local Weapon = Class:extend()

function Weapon:new(id, name, damage, cooldown, range, arcAngle, knockback)
    self.id = id or "bastard_sword"
    self.name = name or "Espada Bastarda"
    self.baseDamage = damage or 30
    self.cooldown = cooldown or 0.5
    self.range = range or 35
    self.arcAngle = arcAngle or (math.pi * 0.6) -- swing arc in radians
    self.knockback = knockback or 120

    self.timer = 0
    self.isAttacking = false
    self.attackAnimTimer = 0
    self.attackAnimDuration = 0.18
    self.currentAngle = 0
    self.handOffset = 1 -- for alternating daggers
end

function Weapon:canAttack()
    return self.timer <= 0
end

function Weapon:update(dt)
    if self.timer > 0 then
        self.timer = self.timer - dt
    end
    if self.attackAnimTimer > 0 then
        self.attackAnimTimer = self.attackAnimTimer - dt
        if self.attackAnimTimer <= 0 then
            self.isAttacking = false
        end
    end
end

function Weapon:triggerAttack(originX, originY, targetAngle, playerStrength)
    if not self:canAttack() then return false end
    self.timer = self.cooldown
    self.isAttacking = true
    self.attackAnimTimer = self.attackAnimDuration
    self.currentAngle = targetAngle
    self.handOffset = -self.handOffset

    return true
end

function Weapon:getHitInfo(playerX, playerY, targetAngle, playerStrength)
    playerStrength = playerStrength or 1.0
    return {
        originX = playerX,
        originY = playerY,
        angle = targetAngle,
        damage = self.baseDamage * playerStrength,
        range = self.range,
        arcAngle = self.arcAngle,
        knockback = self.knockback,
        weaponId = self.id
    }
end

function Weapon:draw(playerX, playerY, aimAngle, isFacingLeft)
    if not self.isAttacking then
        -- Idle weapon resting position
        local restAngle = isFacingLeft and (aimAngle + 0.3) or (aimAngle - 0.3)
        local hx = playerX + math.cos(restAngle) * 8
        local hy = playerY + math.sin(restAngle) * 8

        love.graphics.push()
        love.graphics.translate(hx, hy)
        love.graphics.rotate(restAngle)
        self:renderSprite(false)
        love.graphics.pop()
    else
        -- Active swing animation
        local progress = 1 - (self.attackAnimTimer / self.attackAnimDuration)
        local swingOffset = (progress - 0.5) * self.arcAngle
        local swingAngle = self.currentAngle + swingOffset

        local hx = playerX + math.cos(swingAngle) * 10
        local hy = playerY + math.sin(swingAngle) * 10

        love.graphics.push()
        love.graphics.translate(hx, hy)
        love.graphics.rotate(swingAngle)
        self:renderSprite(true)
        love.graphics.pop()

        -- Slash arc trail at hand height.
        local alpha = 0.45 * (1 - progress)
        love.graphics.setColor(0.95, 0.95, 1, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.arc("line", "open", playerX, playerY, self.range,
            self.currentAngle - self.arcAngle * 0.5,
            self.currentAngle + self.arcAngle * 0.5)
        love.graphics.setColor(0.90, 0.18, 0.24, alpha * 0.7)
        love.graphics.setLineWidth(1)
        love.graphics.arc("line", "open", playerX, playerY, self.range - 3,
            self.currentAngle - self.arcAngle * 0.5,
            self.currentAngle + self.arcAngle * 0.5)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Weapon:renderSprite(isActive)
    if self.id == "bastard_sword" then
        -- Bastard Sword blade
        love.graphics.setColor(0.10, 0.10, 0.14, 1)
        love.graphics.rectangle("fill", 2, -3, self.range * 0.78, 6)
        love.graphics.setColor(0.80, 0.84, 0.92, 1)
        love.graphics.rectangle("fill", 3, -2, self.range * 0.74, 4)
        love.graphics.setColor(0.96, 0.97, 1, 1)
        love.graphics.rectangle("fill", 4, -2, self.range * 0.68, 1)
        -- Guard & hilt
        love.graphics.setColor(0.10, 0.08, 0.08, 1)
        love.graphics.rectangle("fill", 1, -6, 3, 12)
        love.graphics.setColor(0.62, 0.47, 0.22, 1)
        love.graphics.rectangle("fill", 0, -5, 4, 10)
        love.graphics.setColor(0.26, 0.18, 0.12, 1)
        love.graphics.rectangle("fill", -6, -1.5, 6, 3)
        love.graphics.setColor(0.90, 0.76, 0.38, 1)
        love.graphics.rectangle("fill", -2, -2, 2, 4)
    elseif self.id == "murakumogiri" then
        -- Giant halberd: long shaft and a heavy crescent blade.
        love.graphics.setColor(0.16, 0.10, 0.07, 1)
        love.graphics.rectangle("fill", -14, -2.5, self.range * 0.95, 5)
        love.graphics.setColor(0.40, 0.26, 0.14, 1)
        love.graphics.rectangle("fill", -13, -1.5, self.range * 0.92, 3)
        love.graphics.setColor(0.12, 0.08, 0.07, 1)
        love.graphics.polygon("fill",
            self.range * 0.58, -2,
            self.range * 0.99, -8,
            self.range * 0.90, 4)
        love.graphics.setColor(0.88, 0.89, 0.95, 1)
        love.graphics.polygon("fill",
            self.range * 0.60, -2,
            self.range * 0.95, -7,
            self.range * 0.86, 3)
        love.graphics.setColor(0.62, 0.08, 0.10, 1)
        love.graphics.circle("fill", self.range * 0.58, 0, 2.5)
    elseif self.id == "dual_daggers" then
        -- Dual daggers (shorter, lethal stabs)
        local yOffset = self.handOffset * 4
        love.graphics.setColor(0.10, 0.08, 0.09, 1)
        love.graphics.rectangle("fill", 1, yOffset - 2.5, self.range * 0.68, 5)
        love.graphics.setColor(0.88, 0.90, 0.96, 1)
        love.graphics.rectangle("fill", 2, yOffset - 1.5, self.range * 0.64, 3)
        love.graphics.setColor(0.40, 0.22, 0.10, 1)
        love.graphics.rectangle("fill", -4, yOffset - 1, 5, 2)
        love.graphics.setColor(0.90, 0.72, 0.35, 1)
        love.graphics.rectangle("fill", -6, yOffset - 0.5, 2, 1)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Weapon factory helper
function Weapon.createForClass(classType)
    if classType == "barbaro" then
        return Weapon("murakumogiri", "Murakumogiri", 55, 0.85, 54, math.pi * 0.8, 220)
    elseif classType == "asesino" then
        return Weapon("dual_daggers", "2 Dagas", 18, 0.22, 26, math.pi * 0.45, 60)
    else -- guerrero
        return Weapon("bastard_sword", "Espada Bastarda", 32, 0.52, 38, math.pi * 0.65, 130)
    end
end

return Weapon
