local Class = require("lib.classic")
local Theme = require("src.ui.theme")
local SoulDrop = Class:extend()

function SoulDrop:new(x, y, value)
    self.x = x
    self.y = y
    self.value = value or 10
    self.radius = 4
    self.alive = true
    self.pulse = math.random() * math.pi * 2
    self.speed = 0
    self.maxSpeed = 240
    self.accel = 500
end

function SoulDrop:update(dt, playerX, playerY, magnetRadius)
    if not self.alive then return end
    self.pulse = (self.pulse + dt * 6) % (math.pi * 2)

    local dx = playerX - self.x
    local dy = playerY - self.y
    local distSq = dx * dx + dy * dy
    local magR = magnetRadius or 65

    if distSq < magR * magR then
        local dist = math.sqrt(distSq)
        if dist > 0.001 then
            self.speed = math.min(self.maxSpeed, self.speed + self.accel * dt)
            self.x = self.x + (dx / dist) * self.speed * dt
            self.y = self.y + (dy / dist) * self.speed * dt
        end
    end
end

function SoulDrop:draw()
    if not self.alive then return end
    local glow = (math.sin(self.pulse) + 1) * 0.5
    local hover = 6 + math.sin(self.pulse * 0.8) * 1.5
    local dy = self.y - hover

    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.ellipse("fill", self.x, self.y + 1, 4, 1.8)

    Theme.drawGlow(self.x, dy, 11, { 0.90, 0.10, 0.25, 1 }, 0.28 + glow * 0.20)

    love.graphics.setColor(0.92, 0.18, 0.30, 0.95)
    love.graphics.circle("fill", self.x, dy, self.radius)
    love.graphics.setColor(1, 0.42, 0.48, 1)
    love.graphics.circle("fill", self.x, dy, self.radius * 0.62)
    love.graphics.setColor(1, 0.86, 0.86, 0.9)
    love.graphics.circle("fill", self.x - 1, dy - 1, 1.2)

    -- Two tiny wisps trailing behind the orb.
    love.graphics.setColor(0.75, 0.10, 0.22, 0.35 + glow * 0.2)
    love.graphics.circle("fill", self.x - 4, dy + 2, 1)
    love.graphics.circle("fill", self.x + 4, dy - 3, 0.8)

    love.graphics.setColor(1, 1, 1, 1)
end

return SoulDrop
