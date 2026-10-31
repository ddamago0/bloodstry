local Class = require("lib.classic")
local Theme = require("src.ui.theme")
local Projectile = Class:extend()

function Projectile:new(x, y, vx, vy, damage, range, radius, projType, isPiercing)
    self.x = x
    self.y = y
    self.vx = vx
    self.vy = vy
    self.damage = damage or 25
    self.range = range or 250
    self.distanceTraveled = 0
    self.radius = radius or 5
    self.projType = projType or "skull" -- "skull", "acid", "bone"
    self.isPiercing = isPiercing or false
    self.alive = true
    self.angle = math.atan2(vy, vx)
    self.hitEnemies = {}
    self.spin = 0
end

function Projectile:update(dt)
    if not self.alive then return end
    local stepX = self.vx * dt
    local stepY = self.vy * dt
    self.x = self.x + stepX
    self.y = self.y + stepY
    self.spin = self.spin + dt * 16

    self.distanceTraveled = self.distanceTraveled + math.sqrt(stepX * stepX + stepY * stepY)
    if self.distanceTraveled >= self.range then
        self.alive = false
    end
end

function Projectile:draw()
    if not self.alive then return end
    local drawY = self.y - 5

    -- Ground shadow keeps projectiles anchored in the 2.5D plane.
    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.ellipse("fill", self.x + 1, self.y + 3, self.radius * 0.7, 1.8)

    if self.projType == "skull" then
        Theme.drawGlow(self.x, drawY, self.radius + 7, { 0.95, 0.70, 0.55, 1 }, 0.18)
    elseif self.projType == "acid" then
        Theme.drawGlow(self.x, drawY, self.radius + 8, { 0.55, 0.95, 0.20, 1 }, 0.25)
    end

    love.graphics.push()
    love.graphics.translate(self.x, drawY)
    love.graphics.rotate(self.angle)

    if self.projType == "skull" then
        -- Thrown skull
        love.graphics.setColor(0.10, 0.07, 0.08, 1)
        love.graphics.circle("fill", 0, 0, self.radius + 1)
        love.graphics.setColor(0.93, 0.90, 0.82, 1)
        love.graphics.circle("fill", 0, 0, self.radius)
        love.graphics.setColor(0.72, 0.69, 0.61, 1)
        love.graphics.rectangle("fill", -1, self.radius - 1, 3, 2)
        -- Eye sockets and crimson pinpoints.
        love.graphics.setColor(0.08, 0.05, 0.06, 1)
        love.graphics.circle("fill", 2, -2, 1.5)
        love.graphics.circle("fill", 2, 2, 1.5)
        love.graphics.setColor(0.95, 0.18, 0.20, 1)
        love.graphics.circle("fill", 2.5, -2, 0.7)
        love.graphics.circle("fill", 2.5, 2, 0.7)
    elseif self.projType == "acid" then
        love.graphics.setColor(0.16, 0.28, 0.06, 1)
        love.graphics.circle("fill", 0, 0, self.radius + 1)
        love.graphics.setColor(0.62, 0.92, 0.20, 0.95)
        love.graphics.circle("fill", 0, 0, self.radius)
        love.graphics.setColor(0.88, 1, 0.55, 0.9)
        love.graphics.circle("fill", 1, -1, self.radius * 0.45)
    elseif self.projType == "bone" then
        -- Spinning bone shard.
        love.graphics.setColor(0.12, 0.10, 0.10, 1)
        love.graphics.rectangle("fill", -self.radius * 1.6, -2.5, self.radius * 3.2, 5)
        love.graphics.setColor(0.88, 0.85, 0.77, 1)
        love.graphics.rectangle("fill", -self.radius * 1.5, -1.5, self.radius * 3, 3)
        love.graphics.setColor(0.65, 0.61, 0.53, 1)
        love.graphics.circle("fill", -self.radius * 1.4, 0, 1.5)
        love.graphics.circle("fill", self.radius * 1.4, 0, 1.5)
    end

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

return Projectile
