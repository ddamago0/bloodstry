local Class = require("lib.classic")
local Camera = Class:extend()

function Camera:new(viewWidth, viewHeight)
    self.x = 0
    self.y = 0
    self.viewWidth = viewWidth or 480
    self.viewHeight = viewHeight or 270

    self.shakeIntensity = 0
    self.shakeDuration = 0
    self.shakeTimer = 0
    self.shakeOffsetX = 0
    self.shakeOffsetY = 0

    self.bounds = nil -- { minX, minY, maxX, maxY }
end

function Camera:setBounds(minX, minY, maxX, maxY)
    self.bounds = { minX = minX, minY = minY, maxX = maxX, maxY = maxY }
end

function Camera:shake(intensity, duration)
    self.shakeIntensity = math.max(self.shakeIntensity, intensity)
    self.shakeDuration = math.max(self.shakeDuration, duration)
    self.shakeTimer = self.shakeDuration
end

function Camera:follow(targetX, targetY, dt, lerpSpeed)
    lerpSpeed = lerpSpeed or 10
    local t = math.min(1, dt * lerpSpeed)
    self.x = self.x + (targetX - self.x) * t
    self.y = self.y + (targetY - self.y) * t

    if self.bounds then
        local halfW = self.viewWidth / 2
        local halfH = self.viewHeight / 2
        self.x = math.max(self.bounds.minX + halfW, math.min(self.bounds.maxX - halfW, self.x))
        self.y = math.max(self.bounds.minY + halfH, math.min(self.bounds.maxY - halfH, self.y))
    end
end

function Camera:update(dt)
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
        local progress = self.shakeTimer / self.shakeDuration
        local currentIntensity = self.shakeIntensity * progress
        self.shakeOffsetX = (math.random() * 2 - 1) * currentIntensity
        self.shakeOffsetY = (math.random() * 2 - 1) * currentIntensity
        if self.shakeTimer <= 0 then
            self.shakeIntensity = 0
            self.shakeOffsetX = 0
            self.shakeOffsetY = 0
        end
    end
end

function Camera:attach()
    love.graphics.push()
    local halfW = math.floor(self.viewWidth / 2)
    local halfH = math.floor(self.viewHeight / 2)
    local camX = math.floor(self.x + self.shakeOffsetX)
    local camY = math.floor(self.y + self.shakeOffsetY)
    love.graphics.translate(halfW - camX, halfH - camY)
end

function Camera:detach()
    love.graphics.pop()
end

function Camera:toWorldCoords(screenX, screenY)
    local halfW = self.viewWidth / 2
    local halfH = self.viewHeight / 2
    local camX = self.x + self.shakeOffsetX
    local camY = self.y + self.shakeOffsetY
    local wx = screenX - (halfW - camX)
    local wy = screenY - (halfH - camY)
    return wx, wy
end

function Camera:toScreenCoords(worldX, worldY)
    local halfW = self.viewWidth / 2
    local halfH = self.viewHeight / 2
    local camX = self.x + self.shakeOffsetX
    local camY = self.y + self.shakeOffsetY
    local sx = worldX + (halfW - camX)
    local sy = worldY + (halfH - camY)
    return sx, sy
end

return Camera
