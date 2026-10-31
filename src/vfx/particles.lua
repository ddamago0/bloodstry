local Class = require("lib.classic")
local Particles = Class:extend()

function Particles:new()
    self.systems = {}

    -- Dummy 2x2 white texture for particles
    local imgData = love.image.newImageData(2, 2)
    imgData:setPixel(0, 0, 1, 1, 1, 1)
    imgData:setPixel(0, 1, 1, 1, 1, 1)
    imgData:setPixel(1, 0, 1, 1, 1, 1)
    imgData:setPixel(1, 1, 1, 1, 1, 1)
    self.baseTexture = love.graphics.newImage(imgData)

    -- Blood Burst
    local blood = love.graphics.newParticleSystem(self.baseTexture, 1000)
    blood:setParticleLifetime(0.2, 0.5)
    blood:setSpeed(60, 180)
    blood:setSpread(math.pi * 2)
    blood:setSizes(1.5, 0.5)
    blood:setColors(
        0.8, 0.05, 0.05, 1,
        0.4, 0.0, 0.0, 0.8,
        0.2, 0.0, 0.0, 0
    )
    blood:setLinearDamping(4)
    self.bloodSystem = blood

    -- Bone Shards
    local bone = love.graphics.newParticleSystem(self.baseTexture, 500)
    bone:setParticleLifetime(0.3, 0.7)
    bone:setSpeed(80, 220)
    bone:setSpread(math.pi * 2)
    bone:setSizes(2, 0.8)
    bone:setColors(
        0.95, 0.95, 0.9, 1,
        0.8, 0.78, 0.7, 0.8,
        0.5, 0.5, 0.45, 0
    )
    bone:setLinearDamping(3)
    self.boneSystem = bone

    -- Cursed Soul / Magic Sparkles
    local soul = love.graphics.newParticleSystem(self.baseTexture, 500)
    soul:setParticleLifetime(0.4, 0.9)
    soul:setSpeed(20, 60)
    soul:setSpread(math.pi * 2)
    soul:setSizes(1.2, 0)
    soul:setColors(
        0.7, 0.2, 0.9, 1,
        0.4, 0.1, 0.6, 0.7,
        0.1, 0.0, 0.2, 0
    )
    soul:setLinearDamping(1)
    self.soulSystem = soul
end

function Particles:emitBlood(x, y, count)
    self.bloodSystem:setPosition(x, y)
    self.bloodSystem:emit(count or 12)
end

function Particles:emitBone(x, y, count)
    self.boneSystem:setPosition(x, y)
    self.boneSystem:emit(count or 10)
end

function Particles:emitSoul(x, y, count)
    self.soulSystem:setPosition(x, y)
    self.soulSystem:emit(count or 8)
end

function Particles:update(dt)
    self.bloodSystem:update(dt)
    self.boneSystem:update(dt)
    self.soulSystem:update(dt)
end

function Particles:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.bloodSystem, 0, 0)
    love.graphics.draw(self.boneSystem, 0, 0)
    love.graphics.draw(self.soulSystem, 0, 0)
end

return Particles
