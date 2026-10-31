local Class = require("lib.classic")
local Projectile = require("src.combat.projectile")
local Limb = Class:extend()

Limb.TYPES = {
    HEAD = "cabeza",
    SKELETON_ARM = "brazo_esqueleto",
    ZOMBIE_ARM = "brazo_zombie"
}

function Limb:new(limbType, durability)
    self.type = limbType or Limb.TYPES.SKELETON_ARM

    if self.type == Limb.TYPES.HEAD then
        self.name = "Cabeza Cercenada"
        self.maxDurability = durability or math.random(2, 4) -- throws
        self.cooldown = 0.4
        self.damage = 60
        self.range = 220
        self.arcAngle = 0
        self.knockback = 90
    elseif self.type == Limb.TYPES.SKELETON_ARM then
        self.name = "Látigo de Hueso"
        self.maxDurability = durability or math.random(7, 14)
        self.cooldown = 0.42
        self.damage = 22
        self.range = 56
        self.arcAngle = math.pi * 0.95
        self.knockback = 150
    elseif self.type == Limb.TYPES.ZOMBIE_ARM then
        self.name = "Brazo Putrefacto"
        self.maxDurability = durability or math.random(5, 11)
        self.cooldown = 0.65
        self.damage = 50
        self.range = 30
        self.arcAngle = math.pi * 0.4
        self.knockback = 180
    end

    self.durability = self.maxDurability
    self.timer = 0
    self.isAttacking = false
    self.animTimer = 0
    self.animDuration = 0.2
    self.currentAngle = 0
    self.pulseTimer = 0
end

function Limb:isBroken()
    return self.durability <= 0
end

function Limb:isNearBreaking()
    return self.durability <= 2 or (self.durability / self.maxDurability) <= 0.3
end

function Limb:update(dt)
    if self.timer > 0 then
        self.timer = self.timer - dt
    end
    if self.animTimer > 0 then
        self.animTimer = self.animTimer - dt
        if self.animTimer <= 0 then
            self.isAttacking = false
        end
    end

    if self:isNearBreaking() then
        self.pulseTimer = (self.pulseTimer + dt * 10) % (math.pi * 2)
    end
end

function Limb:canAttack()
    return self.timer <= 0 and self.durability > 0
end

function Limb:triggerAttack(player, targetAngle, projectilesList, particles)
    if not self:canAttack() then return nil end
    self.timer = self.cooldown
    self.isAttacking = true
    self.animTimer = self.animDuration
    self.currentAngle = targetAngle

    local strength = player.strength or 1.0

    if self.type == Limb.TYPES.HEAD then
        -- Throw head projectile
        self.durability = self.durability - 1
        local speed = 360
        if player.classType == "asesino" then
            speed = speed * 2 -- Asesino passive: double speed
        end

        local vx = math.cos(targetAngle) * speed
        local vy = math.sin(targetAngle) * speed
        local projDamage = self.damage * strength
        local proj = Projectile(player.x, player.y, vx, vy, projDamage, self.range, 6, "skull", false)
        if projectilesList then
            table.insert(projectilesList, proj)
        end
        return nil
    else
        -- Melee attack with skeletal whip or zombie arm
        self.durability = self.durability - 1
        local hitDamage = self.damage * strength
        local hitBleed = (player.classType == "asesino" and self.type == Limb.TYPES.ZOMBIE_ARM)

        return {
            originX = player.x,
            originY = player.y,
            angle = targetAngle,
            damage = hitDamage,
            range = self.range,
            arcAngle = self.arcAngle,
            knockback = self.knockback,
            bleed = hitBleed,
            limbType = self.type
        }
    end
end

-- Last Ditch Attack (Sacrificio)
function Limb:sacrifice(player, targetAngle, projectilesList, particles)
    if self.durability <= 0 then return nil end
    self.durability = 0 -- Destroy immediately

    local strength = player.strength or 1.0
    local sacDamage = self.damage * strength * 3.0 -- Triple damage!

    if self.type == Limb.TYPES.HEAD then
        -- Supercharged explosive piercing head throw
        local speed = (player.classType == "asesino") and 700 or 500
        local vx = math.cos(targetAngle) * speed
        local vy = math.sin(targetAngle) * speed
        local proj = Projectile(player.x, player.y, vx, vy, sacDamage, 380, 8, "skull", true)
        if projectilesList then
            table.insert(projectilesList, proj)
        end
        return {
            type = "sacrifice_projectile",
            x = player.x,
            y = player.y
        }
    else
        -- Detonation of bone fragments / necrotic burst
        return {
            type = "sacrifice_blast",
            originX = player.x,
            originY = player.y,
            angle = targetAngle,
            damage = sacDamage,
            radius = self.range * 1.8,
            knockback = self.knockback * 2.5
        }
    end
end

function Limb:draw(playerX, playerY, aimAngle, isFacingLeft)
    if self.durability <= 0 then return end

    local drawAngle = self.isAttacking and self.currentAngle or (isFacingLeft and (aimAngle - 0.5) or (aimAngle + 0.5))
    local dist = 10
    local lx = playerX + math.cos(drawAngle) * dist
    local ly = playerY + math.sin(drawAngle) * dist

    love.graphics.push()
    love.graphics.translate(lx, ly)
    love.graphics.rotate(drawAngle)

    -- Warning flash if low durability
    local rMult, gMult, bMult = 1, 1, 1
    if self:isNearBreaking() then
        local pulse = (math.sin(self.pulseTimer) + 1) * 0.5
        rMult = 1 + pulse * 0.5
        gMult = 1 - pulse * 0.6
        bMult = 1 - pulse * 0.6
    end

    if self.type == Limb.TYPES.HEAD then
        -- Held severed head
        love.graphics.setColor(0.9 * rMult, 0.88 * gMult, 0.82 * bMult, 1)
        love.graphics.circle("fill", 0, 0, 5)
        love.graphics.setColor(0.1, 0.05, 0.05, 1)
        love.graphics.circle("fill", 2, -2, 1.2)
        love.graphics.circle("fill", 2, 2, 1.2)
    elseif self.type == Limb.TYPES.SKELETON_ARM then
        -- Segmented bone whip
        love.graphics.setColor(0.92 * rMult, 0.9 * gMult, 0.85 * bMult, 1)
        local segments = self.isAttacking and 5 or 3
        local segLen = self.range / segments
        for s = 1, segments do
            local wobble = self.isAttacking and math.sin(s * 1.2) * 2 or 0
            love.graphics.rectangle("fill", (s - 1) * segLen, -1.5 + wobble, segLen - 1, 3)
            love.graphics.circle("fill", (s - 1) * segLen, wobble, 2)
        end
    elseif self.type == Limb.TYPES.ZOMBIE_ARM then
        -- Bulky rotting zombie arm
        love.graphics.setColor(0.35 * rMult, 0.48 * gMult, 0.32 * bMult, 1)
        love.graphics.rectangle("fill", 0, -3.5, self.range * 0.8, 7)
        -- Bloodied fist & claws
        love.graphics.setColor(0.6 * rMult, 0.1 * gMult, 0.1 * bMult, 1)
        love.graphics.circle("fill", self.range * 0.8, 0, 4.5)
    end

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

function Limb.randomDrop()
    local roll = math.random(1, 100)
    if roll <= 35 then
        return Limb(Limb.TYPES.SKELETON_ARM)
    elseif roll <= 70 then
        return Limb(Limb.TYPES.ZOMBIE_ARM)
    else
        return Limb(Limb.TYPES.HEAD)
    end
end

return Limb
