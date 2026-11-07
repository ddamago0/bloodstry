local Class = require("lib.classic")
local Entity = require("src.entities/entity")
local Weapon = require("src.combat.weapon")
local Limb = require("src.combat.limb")
local Assets = require("src.core.assets")
local Theme = require("src.ui.theme")
local Player = Entity:extend()

-- Blood/XP pacing. The first level asks for roughly 12-15 regular kills, and
-- the 1.30 curve keeps the pace readable across a full stage instead of
-- cascading the upgrade menu every few seconds.
local BASE_LEVEL_COST = 160
local LEVEL_COST_GROWTH = 1.38

function Player:new(x, y, classType)
    self.classType = classType or "guerrero"

    -- Base class stats
    local hp, spd, str
    if self.classType == "guerrero" then
        hp = 150
        spd = 92
        str = 1.0
    elseif self.classType == "barbaro" then
        hp = 115
        spd = 86
        str = 1.45
    elseif self.classType == "asesino" then
        hp = 85
        spd = 135
        str = 0.82
    end

    Player.super.new(self, x, y, 7, hp)
    self.baseSpeed = spd
    self.speed = spd
    self.strength = str
    self.primaryWeapon = Weapon.createForClass(self.classType)
    self.equippedLimb = nil

    -- Defensive stats & Passives
    self.boneShield = 0
    self.maxBoneShield = 50
    self.shieldDuration = 0
    self.invulnTimer = 0
    self.invulnDuration = 0.4
    self.damageFlash = 0

    -- Progression / Souls
    self.bloodPoints = 0
    self.level = 1
    self.pointsToNextLevel = BASE_LEVEL_COST
    self.pendingLevelUps = 0
    self.magnetRadius = 75
    self.killCount = 0

    -- Pact Modifiers
    self.lifesteal = 0.0
    self.bloodTrailActive = false
    self.visionRadiusMult = 1.0
    self.pacts = {}

    -- Visuals & Aim
    self.aimAngle = 0
    self.isFacingLeft = false
    self.stepTimer = 0
    self.moving = false
    self.bobTimer = 0
end

function Player:applyBoneShield(amount, duration)
    self.boneShield = math.min(self.maxBoneShield, self.boneShield + (amount or 35))
    self.shieldDuration = duration or 6.0
end

function Player:takeDamage(amount, kx, ky)
    if self.invulnTimer > 0 or not self.alive then return 0 end

    local damageLeft = amount
    -- Absorb with bone shield first
    if self.boneShield > 0 then
        if self.boneShield >= damageLeft then
            self.boneShield = self.boneShield - damageLeft
            damageLeft = 0
        else
            damageLeft = damageLeft - self.boneShield
            self.boneShield = 0
        end
    end

    local taken = 0
    if damageLeft > 0 then
        taken = Player.super.takeDamage(self, damageLeft, kx, ky)
    end

    self.damageFlash = math.max(self.damageFlash, 0.20)
    self.invulnTimer = self.invulnDuration
    return taken
end

function Player:gainBloodPoints(amount)
    self.bloodPoints = self.bloodPoints + amount

    -- `while` instead of `if`: a single big orb (boss drops, chained pickups)
    -- can cross more than one threshold in a frame. Consuming only one would
    -- leave bloodPoints above pointsToNextLevel and push the HUD bar past 100%.
    local leveled = false
    while self.bloodPoints >= self.pointsToNextLevel do
        self.bloodPoints = self.bloodPoints - self.pointsToNextLevel
        self.level = self.level + 1
        self.pointsToNextLevel = math.floor(self.pointsToNextLevel * LEVEL_COST_GROWTH)
        self.pendingLevelUps = self.pendingLevelUps + 1
        leveled = true
    end

    return leveled
end

function Player:equipLimb(newLimb)
    self.equippedLimb = newLimb
end

function Player:update(dt, input, push, camera, bounds)
    if not self.alive then return end
    Player.super.update(self, dt)

    if self.invulnTimer > 0 then
        self.invulnTimer = math.max(0, self.invulnTimer - dt)
    end
    if self.damageFlash > 0 then
        self.damageFlash = math.max(0, self.damageFlash - dt * 2.2)
    end
    self.bobTimer = self.bobTimer + dt

    if self.shieldDuration > 0 then
        self.shieldDuration = self.shieldDuration - dt
        if self.shieldDuration <= 0 then
            self.boneShield = 0
        end
    end

    -- Aim angle from mouse game coordinates
    local mx, my = input.getGameMouse(push)
    local wx, wy = camera:toWorldCoords(mx, my)
    self.aimAngle = math.atan2(wy - (self.y - 14), wx - self.x)
    self.isFacingLeft = math.cos(self.aimAngle) < 0

    -- Movement
    local dx, dy = input.getMovementVector()
    self.moving = (dx ~= 0 or dy ~= 0)
    if self.moving then
        self.x = self.x + dx * self.speed * dt
        self.y = self.y + dy * self.speed * dt
        self.stepTimer = self.stepTimer + dt * 8
    end

    -- Keep the player inside the consecrated ground.
    if bounds then
        local margin = 18
        self.x = math.max(bounds.minX + margin, math.min(bounds.maxX - margin, self.x))
        self.y = math.max(bounds.minY + margin, math.min(bounds.maxY - margin, self.y))
    end

    -- Weapon & Limb timers
    self.primaryWeapon:update(dt)
    if self.equippedLimb then
        self.equippedLimb:update(dt)
        if self.equippedLimb:isBroken() then
            -- Guerrero Passive: gain bone shield when limb breaks
            if self.classType == "guerrero" then
                self:applyBoneShield(40, 7.0)
            end
            self.equippedLimb = nil
        end
    end
end

function Player:triggerPrimaryAttack()
    return self.primaryWeapon:triggerAttack(self.x, self.y - 13, self.aimAngle, self.strength)
end

function Player:triggerLimbAttack(projectilesList, particles)
    if not self.equippedLimb then return nil end
    local hit = self.equippedLimb:triggerAttack(self, self.aimAngle, projectilesList, particles)

    if self.equippedLimb and self.equippedLimb:isBroken() then
        if self.classType == "guerrero" then
            self:applyBoneShield(40, 7.0)
        end
        self.equippedLimb = nil
    end
    return hit
end

function Player:triggerSacrifice(projectilesList, particles)
    if not self.equippedLimb then return nil end
    local result = self.equippedLimb:sacrifice(self, self.aimAngle, projectilesList, particles)

    -- Guerrero Passive on sacrifice
    if self.classType == "guerrero" then
        self:applyBoneShield(45, 8.0)
    end

    self.equippedLimb = nil
    return result
end

function Player:drawShadow()
    local movingScale = self.moving and 1.0 or 0.92
    love.graphics.setColor(0, 0, 0, 0.42)
    love.graphics.ellipse("fill", self.x, self.y - 1, 10 * movingScale, 4)
    love.graphics.setColor(0, 0, 0, 0.16)
    love.graphics.ellipse("fill", self.x, self.y + 1, 12 * movingScale, 4.5)
end

function Player:drawBoneShield()
    if self.boneShield <= 0 then return end
    local C = Theme.colors
    local cy = self.y - 17
    local pulse = (math.sin(self.bobTimer * 5) + 1) * 0.5
    love.graphics.setColor(C.bone[1], C.bone[2], C.bone[3], 0.20 + pulse * 0.12)
    love.graphics.circle("line", self.x, cy, 15)
    for i = 1, 4 do
        local a = love.timer.getTime() * 2.4 + i * math.pi * 0.5
        local ox = self.x + math.cos(a) * 15
        local oy = cy + math.sin(a) * 10
        love.graphics.setColor(C.bone[1], C.bone[2], C.bone[3], 0.85)
        love.graphics.circle("fill", ox, oy, 1.6)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Player:draw()
    if not self.alive then return end

    -- Invulnerability blink.
    if self.invulnTimer > 0 and math.floor(self.invulnTimer * 15) % 2 == 0 then
        return
    end

    local sprite = Assets.sprites.players and Assets.sprites.players[self.classType]
    local frames = Assets.quads.playerFrames and Assets.quads.playerFrames[self.classType]
    if not (sprite and frames and frames[1]) then return end

    local frameIndex = 1
    if self.moving then
        frameIndex = math.floor(self.stepTimer) % 4 + 1
    end
    local quad = frames[frameIndex] or frames[1]
    local bob = self.moving and math.sin(self.stepTimer * 1.5) * 0.9 or 0
    local scaleX = self.isFacingLeft and -1 or 1

    self:drawShadow()
    self:drawBoneShield()

    -- Weapons aimed upward are drawn behind the body for depth.
    local weaponBehind = math.sin(self.aimAngle) < -0.25
    if weaponBehind then
        self.primaryWeapon:draw(self.x, self.y - 13, self.aimAngle, self.isFacingLeft)
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sprite, quad, self.x, self.y - bob, 0, scaleX, 1, 16, 40)

    -- Red hit tint on the sprite itself for extra feedback.
    if self.damageFlash > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(0.55, 0.03, 0.05, self.damageFlash * 1.6)
        love.graphics.draw(sprite, quad, self.x, self.y - bob, 0, scaleX, 1, 16, 40)
        love.graphics.setBlendMode("alpha", "alphamultiply")
    end

    if not weaponBehind then
        self.primaryWeapon:draw(self.x, self.y - 13, self.aimAngle, self.isFacingLeft)
    end
    if self.equippedLimb then
        self.equippedLimb:draw(self.x, self.y - 12, self.aimAngle, self.isFacingLeft)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Player
