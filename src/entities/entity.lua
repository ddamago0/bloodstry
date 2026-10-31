local Class = require("lib.classic")
local Entity = Class:extend()

function Entity:new(x, y, radius, hp)
    self.x = x or 0
    self.y = y or 0
    self.vx = 0
    self.vy = 0
    self.radius = radius or 8
    self.hp = hp or 100
    self.maxHp = self.hp
    self.alive = true
    self.hurtTimer = 0
    self.hurtDuration = 0.12
    self.knockbackX = 0
    self.knockbackY = 0
    self.knockbackFriction = 8
end

function Entity:takeDamage(amount, kx, ky)
    if not self.alive then return 0 end
    local actualDamage = math.min(self.hp, amount)
    self.hp = self.hp - actualDamage
    self.hurtTimer = self.hurtDuration

    if kx and ky then
        self.knockbackX = kx
        self.knockbackY = ky
    end

    if self.hp <= 0 then
        self.alive = false
        self:onDeath()
    end
    return actualDamage
end

function Entity:onDeath()
    -- Virtual callback
end

function Entity:update(dt)
    -- Apply knockback decay
    if self.knockbackX ~= 0 or self.knockbackY ~= 0 then
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
        self.knockbackX = self.knockbackX * math.max(0, 1 - self.knockbackFriction * dt)
        self.knockbackY = self.knockbackY * math.max(0, 1 - self.knockbackFriction * dt)
    end

    if self.hurtTimer > 0 then
        self.hurtTimer = self.hurtTimer - dt
    end
end

function Entity:draw()
    -- Subclasses override
end

return Entity
