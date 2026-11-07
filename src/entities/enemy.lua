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
    ZOMBIE = "zombie",
    HOUND = "hound",
    BONE_GOLEM = "bone_golem",
    LANKER = "lanker",
    WARDEN = "warden",
    WEAVER = "weaver"
}

-- One row per creature. `sprite` points at an animation in the imported
-- bestiary atlas (see tools/import_external.py); `flip` marks sprites that are
-- drawn facing left by default so the mirroring stays consistent.
local DEFS = {
    skeleton_common = { hp = 22, speed = 54, radius = 6,  damage = 8,  xp = 10, sprite = "skeleton_common" },
    skeleton_tall   = { hp = 60, speed = 40, radius = 10, damage = 20, xp = 20, sprite = "werewolf" },
    skeleton_robed  = { hp = 30, speed = 44, radius = 7,  damage = 10, xp = 14, sprite = "pallid", ranged = true },
    zombie          = { hp = 40, speed = 62, radius = 8,  damage = 12, xp = 12, sprite = "crawler", flip = true },
    hound           = { hp = 16, speed = 96, radius = 6,  damage = 6,  xp = 9,  sprite = "hound", flip = true },
    bone_golem      = { hp = 110, speed = 26, radius = 12, damage = 24, xp = 30, sprite = "bone_golem" },
    lanker          = { hp = 170, speed = 36, radius = 9,  damage = 26, xp = 50, sprite = "lanker", elite = true },
    warden          = { hp = 320, speed = 30, radius = 16, damage = 30, xp = 90, sprite = "warden", elite = true },
    weaver          = { hp = 220, speed = 34, radius = 13, damage = 26, xp = 60, sprite = "weaver", elite = true }
}

function Enemy:new(x, y, enemyType)
    self.type = enemyType or Enemy.TYPES.SKELETON_COMMON
    local def = DEFS[self.type] or DEFS[Enemy.TYPES.SKELETON_COMMON]

    Enemy.super.new(self, x, y, def.radius, def.hp)
    self.speed = def.speed
    self.contactDamage = def.damage
    self.xpValue = def.xp
    self.isElite = def.elite or false
    self.spriteName = def.sprite
    self.spriteFB = Assets.quads.bestiary and Assets.quads.bestiary[def.sprite] or nil
    self.spriteFacesLeft = def.flip or false
    self.attackCooldown = 0.5
    self.attackTimer = 0

    if def.ranged then
        self.shootCooldown = math.random(2.5, 4.5)
        self.shootTimer = self.shootCooldown
    end

    -- Bleed DoT
    self.bleedTimer = 0
    self.bleedTickTimer = 0
    self.bleedDamagePerTick = 4

    -- Visual step wobble and animation clock.
    self.wobble = math.random() * math.pi * 2
    self.animTime = math.random() * 2
    self.animFrame = 1
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

    -- Multi-frame sprites advance on their own clock. Single-pose creatures
    -- still breathe through the procedural wobble in draw().
    local sheet = self.spriteFB
    if sheet and sheet.fps > 0 and #sheet.frames > 1 then
        self.animTime = self.animTime + dt * sheet.fps
        self.animFrame = (math.floor(self.animTime) % #sheet.frames) + 1
    end

    -- Ranged caster
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
        local drops = self.isElite and math.random(12, 18) or math.random(5, 9)
        local radius = self.isElite and 30 or 18
        bloodCanvas:splatter(self.x, self.y, drops, radius, bloodColor)
    end
    if particles then
        particles:emitBone(self.x, self.y, self.isElite and 24 or 10)
        particles:emitBlood(self.x, self.y, self.isElite and 22 or 8)
    end

    -- Always drop Blood/Soul XP orb
    if dropsList then
        table.insert(dropsList, SoulDrop(self.x, self.y, self.xpValue or 10))

        -- 22% Chance of dropping a usable Limb Weapon. Elites always bleed.
        if self.isElite or math.random() <= 0.22 then
            local limb
            if self.type == Enemy.TYPES.SKELETON_TALL or self.isElite then
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

-- Resolve which sprite/quad to draw. The imported atlas wins; the original
-- hand-drawn sheet stays as a fallback for development without the importer.
function Enemy:getDrawState()
    local sheet = self.spriteFB
    local image = Assets.sprites.bestiary
    if sheet and image then
        local quad = sheet.frames[self.animFrame] or sheet.frames[1]
        if quad then
            local _, _, w, h = quad:getViewport()
            return image, quad, w, h, 1
        end
    end

    local frames = Assets.quads.enemyFrames and Assets.quads.enemyFrames[self.type]
    local legacy = Assets.sprites.enemySheet
    if not (frames and frames[1] and legacy) then return nil end

    local frameIndex = math.floor(self.wobble) % 4 + 1
    local quad = frames[frameIndex] or frames[1]
    local scale = 1
    if self.type == Enemy.TYPES.SKELETON_TALL then
        scale = 1.18
    elseif self.type == Enemy.TYPES.SKELETON_ROBED then
        scale = 1.04
    end
    return legacy, quad, 32, 40, scale
end

function Enemy:draw()
    if not self.alive then return end

    local sprite, quad, spriteW, spriteH, baseScale = self:getDrawState()
    if not (sprite and quad) then return end

    local isElite = self.isElite
    local facing = (self.spriteFacesLeft ~= self.isFacingLeft) and -1 or 1

    -- Elites breathe slightly heavier so the big silhouettes do not feel frozen.
    local breathe = 1
    if isElite then
        breathe = 1 + 0.02 * math.sin(self.wobble * 0.6)
    end
    local scale = baseScale * breathe
    local offsetY = math.floor(math.sin(self.wobble) * 0.9)
    if isElite then offsetY = math.floor(math.sin(self.wobble * 0.5) * 1.6) end

    local originX = spriteW * 0.5
    local originY = spriteH
    local drawW = spriteW * scale

    -- 2.5D elliptical shadow anchored under the feet.
    local shadowRX = math.max(4, drawW * 0.34)
    local shadowRY = math.max(2, drawW * 0.11)
    love.graphics.setColor(0, 0, 0, isElite and 0.46 or 0.38)
    love.graphics.ellipse("fill", self.x, self.y - 1, shadowRX, shadowRY)

    -- Elites carry a faint cold halo so they read as a threat through the fog.
    if isElite then
        love.graphics.setColor(0.55, 0.72, 0.85, 0.10 + 0.05 * math.sin(self.wobble))
        love.graphics.ellipse("fill", self.x, self.y - 2, shadowRX * 1.5, shadowRY * 1.9)
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sprite, quad, self.x, self.y + offsetY, 0,
        facing * scale, scale, originX, originY)

    -- Hurt flash: additive red silhouette on top of the sprite.
    if self.hurtTimer > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(0.85, 0.08, 0.10, 0.85)
        love.graphics.draw(sprite, quad, self.x, self.y + offsetY, 0,
            facing * scale, scale, originX, originY)
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
