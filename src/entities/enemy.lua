local Class = require("lib.classic")
local Entity = require("src.entities/entity")
local Limb = require("src.combat.limb")
local LimbDrop = require("src.entities/limb_drop")
local SoulDrop = require("src.entities/soul_drop")
local Projectile = require("src.combat.projectile")
local Assets = require("src.core.assets")
local Enemy = Entity:extend()

Enemy.TYPES = {
    SKELETON_COMMON = "skeleton_common",
    SKELETON_TALL = "skeleton_tall",
    SKELETON_ROBED = "skeleton_robed",
    ZOMBIE = "zombie"
}

function Enemy:new(x, y, enemyType)
    self.type = enemyType or Enemy.TYPES.SKELETON_COMMON

    local hp, spd, rad, dmg
    if self.type == Enemy.TYPES.SKELETON_COMMON then
        hp = 22
        spd = 54
        rad = 6
        dmg = 8
    elseif self.type == Enemy.TYPES.SKELETON_TALL then
        hp = 50
        spd = 38
        rad = 10
        dmg = 18
    elseif self.type == Enemy.TYPES.SKELETON_ROBED then
        hp = 28
        spd = 46
        rad = 7
        dmg = 10
        self.shootCooldown = math.random(2.5, 4.5)
        self.shootTimer = self.shootCooldown
    elseif self.type == Enemy.TYPES.ZOMBIE then
        hp = 40
        spd = 35
        rad = 8
        dmg = 14
    end

    Enemy.super.new(self, x, y, rad, hp)
    self.speed = spd
    self.contactDamage = dmg
    self.attackCooldown = 0.5
    self.attackTimer = 0

    -- Bleed DoT
    self.bleedTimer = 0
    self.bleedTickTimer = 0
    self.bleedDamagePerTick = 4

    -- Visual step wobble
    self.wobble = math.random() * math.pi * 2
    self.isFacingLeft = false
end

function Enemy:applyBleed(duration, dps)
    self.bleedTimer = math.max(self.bleedTimer, duration or 3.0)
    self.bleedDamagePerTick = dps or 4
end

function Enemy:update(dt, player, spatialHash, enemyProjectiles, bloodCanvas, particles)
    if not self.alive then return end
    Enemy.super.update(self, dt)

    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end

    -- Handle Bleed DoT
    if self.bleedTimer > 0 then
        self.bleedTimer = self.bleedTimer - dt
        self.bleedTickTimer = self.bleedTickTimer + dt
        if self.bleedTickTimer >= 0.5 then
            self.bleedTickTimer = 0
            self:takeDamage(self.bleedDamagePerTick)
            if particles then
                particles:emitBlood(self.x, self.y, 4)
            end
        end
    end

    if not self.alive then return end

    -- Vector towards player
    local dx = player.x - self.x
    local dy = player.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    self.isFacingLeft = dx < 0

    local moveX, moveY = 0, 0
    if dist > 0.001 then
        moveX = dx / dist
        moveY = dy / dist
    end

    -- Flocking / Separation using SpatialHash
    local sepX, sepY = 0, 0
    local neighbors = spatialHash:queryRadius(self.x, self.y, self.radius * 2.5)
    for i = 1, #neighbors do
        local other = neighbors[i]
        if other ~= self and other.alive then
            local ndx = self.x - other.x
            local ndy = self.y - other.y
            local ndist = math.sqrt(ndx * ndx + ndy * ndy)
            if ndist > 0.001 and ndist < (self.radius + other.radius) then
                local push = (self.radius + other.radius - ndist) / (self.radius + other.radius)
                sepX = sepX + (ndx / ndist) * push
                sepY = sepY + (ndy / ndist) * push
            end
        end
    end

    local finalVX = (moveX + sepX * 1.5) * self.speed
    local finalVY = (moveY + sepY * 1.5) * self.speed

    self.x = self.x + finalVX * dt
    self.y = self.y + finalVY * dt
    self.wobble = self.wobble + dt * 6

    -- Robed Skeleton ranged attack
    if self.type == Enemy.TYPES.SKELETON_ROBED and enemyProjectiles then
        self.shootTimer = self.shootTimer - dt
        if self.shootTimer <= 0 and dist < 220 then
            self.shootTimer = self.shootCooldown
            local pSpeed = 110
            local pvx = (dx / dist) * pSpeed
            local pvy = (dy / dist) * pSpeed
            local proj = Projectile(self.x, self.y, pvx, pvy, 12, 240, 4, "bone", false)
            table.insert(enemyProjectiles, proj)
        end
    end

    -- Player contact damage
    if dist < (self.radius + player.radius) and self.attackTimer <= 0 then
        self.attackTimer = self.attackCooldown
        local pKx = moveX * 90
        local pKy = moveY * 90
        player:takeDamage(self.contactDamage, pKx, pKy)
        if bloodCanvas then
            bloodCanvas:splatter(player.x, player.y, 4, 10, { 0.7, 0.05, 0.1, 0.8 })
        end
        if particles then
            particles:emitBlood(player.x, player.y, 6)
        end
    end
end

function Enemy:handleDeath(dropsList, bloodCanvas, particles)
    -- Splatter persistent gore on ground
    if bloodCanvas then
        local bloodColor = (self.type == Enemy.TYPES.ZOMBIE) and { 0.2, 0.35, 0.15, 0.85 } or { 0.55, 0.05, 0.08, 0.85 }
        bloodCanvas:splatter(self.x, self.y, math.random(5, 9), 18, bloodColor)
    end
    if particles then
        particles:emitBone(self.x, self.y, 10)
        particles:emitBlood(self.x, self.y, 8)
    end

    -- Always drop Blood/Soul XP orb
    if dropsList then
        local xpVal = (self.type == Enemy.TYPES.SKELETON_TALL) and 25 or 12
        table.insert(dropsList, SoulDrop(self.x, self.y, xpVal))

        -- 22% Chance of dropping a usable Limb Weapon
        if math.random() <= 0.22 then
            local limb
            if self.type == Enemy.TYPES.SKELETON_TALL then
                limb = Limb(Limb.TYPES.SKELETON_ARM, math.random(9, 15))
            elseif self.type == Enemy.TYPES.ZOMBIE then
                limb = Limb(Limb.TYPES.ZOMBIE_ARM, math.random(6, 12))
            else
                limb = Limb.randomDrop()
            end
            table.insert(dropsList, LimbDrop(self.x, self.y, limb))
        end
    end
end

function Enemy:draw()
    if not self.alive then return end

    local frames = Assets.quads.enemyFrames and Assets.quads.enemyFrames[self.type]
    local sprite = Assets.sprites.enemySheet
    if not (frames and frames[1] and sprite) then return end

    local isTall = self.type == Enemy.TYPES.SKELETON_TALL
    local isRobed = self.type == Enemy.TYPES.SKELETON_ROBED
    local isZombie = self.type == Enemy.TYPES.ZOMBIE

    local scale = 1
    if isTall then
        scale = 1.18
    elseif isRobed then
        scale = 1.04
    end

    local frameIndex = math.floor(self.wobble) % 4 + 1
    local quad = frames[frameIndex] or frames[1]
    local scaleX = self.isFacingLeft and -scale or scale
    local shadowRX = isTall and 11 or (isZombie and 9 or 8)
    local shadowRY = isTall and 4 or 3

    -- 2.5D elliptical shadow anchored under the feet.
    love.graphics.setColor(0, 0, 0, 0.38)
    love.graphics.ellipse("fill", self.x, self.y - 1, shadowRX, shadowRY)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sprite, quad, self.x, self.y, 0, scaleX, scale, 16, 40)

    -- Hurt flash: additive red silhouette on top of the sprite.
    if self.hurtTimer > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(0.85, 0.08, 0.10, 0.85)
        love.graphics.draw(sprite, quad, self.x, self.y, 0, scaleX, scale, 16, 40)
        love.graphics.setBlendMode("alpha", "alphamultiply")
    end

    -- Bleed dripping effect.
    if self.bleedTimer > 0 then
        love.graphics.setColor(0.80, 0.04, 0.07, 0.85)
        love.graphics.circle("fill", self.x - 2, self.y - 3, 1.5)
        love.graphics.setColor(0.55, 0.02, 0.05, 0.9)
        love.graphics.rectangle("fill", self.x + 3, self.y - 2, 1, 5)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Enemy
