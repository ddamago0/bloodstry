local Class = require("lib.classic")
local Entity = require("src.entities/entity")
local Projectile = require("src.combat.projectile")
local SoulDrop = require("src.entities/soul_drop")
local Limb = require("src.combat.limb")
local LimbDrop = require("src.entities/limb_drop")
local Assets = require("src.core.assets")
local Theme = require("src.ui.theme")
local LaParca = Entity:extend()

function LaParca:new(x, y)
    LaParca.super.new(self, x, y, 16, 600)
    self.isBoss = true
    self.name = "La Parca"
    self.subtitle = "Guardiana del Sello Roto"
    self.speed = 42

    -- Attack state machine
    self.state = "hover" -- "hover", "scythe_windup", "scythe_slash", "teleport"
    self.stateTimer = 2.0
    self.targetAngle = 0
    self.summonDone = false

    -- Visuals
    self.floatTimer = 0
    self.teleportAlpha = 1.0
    self.isFacingLeft = false
end

function LaParca:update(dt, player, enemyProjectiles, enemiesList, bloodCanvas, particles, camera)
    if not self.alive then return end
    LaParca.super.update(self, dt)

    self.floatTimer = self.floatTimer + dt * 3
    local dx = player.x - self.x
    local dy = player.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    self.targetAngle = math.atan2(dy, dx)
    self.isFacingLeft = dx < 0

    -- Phase 2 Trigger: Summon skeletal guard at 50% HP
    if self.hp <= (self.maxHp * 0.5) and not self.summonDone then
        self.summonDone = true
        if camera then camera:shake(6, 0.4) end
        if particles then particles:emitSoul(self.x, self.y, 30) end
        if enemiesList then
            local Enemy = require("src.entities/enemy")
            for i = 1, 6 do
                local sAngle = (i / 6) * math.pi * 2
                local sx = self.x + math.cos(sAngle) * 45
                local sy = self.y + math.sin(sAngle) * 45
                table.insert(enemiesList, Enemy(sx, sy, Enemy.TYPES.SKELETON_ROBED))
            end
        end
    end

    self.stateTimer = self.stateTimer - dt

    if self.state == "hover" then
        -- Drift towards player
        if dist > 60 then
            self.x = self.x + (dx / dist) * self.speed * dt
            self.y = self.y + (dy / dist) * self.speed * dt
        end

        if self.stateTimer <= 0 then
            -- Choose next attack
            local choice = math.random()
            if choice < 0.45 and dist < 120 then
                -- Scythe Windup
                self.state = "scythe_windup"
                self.stateTimer = 0.65
            elseif choice < 0.8 then
                -- Skull barrage
                self:castSkullBarrage(enemyProjectiles, particles)
                self.stateTimer = 1.8
            else
                -- Teleport near player
                self.state = "teleport"
                self.stateTimer = 0.5
            end
        end

    elseif self.state == "scythe_windup" then
        if self.stateTimer <= 0 then
            self.state = "scythe_slash"
            self.stateTimer = 0.35
            if camera then camera:shake(5, 0.25) end

            -- Hit check on player
            if dist < 55 then
                player:takeDamage(32, math.cos(self.targetAngle) * 160, math.sin(self.targetAngle) * 160)
                if bloodCanvas then
                    bloodCanvas:splatter(player.x, player.y, 8, 16, { 0.7, 0.05, 0.08, 0.9 })
                end
            end
        end

    elseif self.state == "scythe_slash" then
        if self.stateTimer <= 0 then
            self.state = "hover"
            self.stateTimer = 1.2
        end

    elseif self.state == "teleport" then
        if self.stateTimer <= 0 then
            -- Teleport 90px away from player
            local tAngle = math.random() * math.pi * 2
            self.x = player.x + math.cos(tAngle) * 95
            self.y = player.y + math.sin(tAngle) * 95
            if particles then particles:emitSoul(self.x, self.y, 20) end
            self.state = "hover"
            self.stateTimer = 1.4
        end
    end
end

function LaParca:castSkullBarrage(enemyProjectiles, particles)
    if not enemyProjectiles then return end
    if particles then particles:emitSoul(self.x, self.y, 15) end
    local count = 6
    for i = 1, count do
        local angle = self.targetAngle + ((i - (count + 1) * 0.5) * 0.22)
        local spd = 125
        local vx = math.cos(angle) * spd
        local vy = math.sin(angle) * spd
        local proj = Projectile(self.x, self.y, vx, vy, 16, 260, 5, "skull", false)
        table.insert(enemyProjectiles, proj)
    end
end

function LaParca:handleDeath(dropsList, bloodCanvas, particles)
    if bloodCanvas then
        bloodCanvas:splatter(self.x, self.y, 25, 45, { 0.45, 0.05, 0.45, 0.95 })
    end
    if particles then
        particles:emitSoul(self.x, self.y, 50)
        particles:emitBone(self.x, self.y, 30)
    end

    if dropsList then
        -- Massive soul burst
        for i = 1, 8 do
            local ox = self.x + (math.random() * 2 - 1) * 20
            local oy = self.y + (math.random() * 2 - 1) * 20
            table.insert(dropsList, SoulDrop(ox, oy, 60))
        end
        -- Legendary Bone Whip Limb drop
        table.insert(dropsList, LimbDrop(self.x, self.y, Limb(Limb.TYPES.SKELETON_ARM, 20)))
    end
end

function LaParca:draw()
    if not self.alive then return end

    local frames = Assets.quads.bossFrames
    local sprite = Assets.sprites.boss
    local floatY = math.sin(self.floatTimer) * 2.5 - 3

    -- Aura and shadow are in world space; the sprite is bottom-anchored.
    Theme.drawGlow(self.x, self.y - 34, 34, { 0.42, 0.12, 0.55, 1 }, 0.12)

    love.graphics.setColor(0, 0, 0, 0.46)
    love.graphics.ellipse("fill", self.x, self.y - 1, 16, 5)
    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.ellipse("fill", self.x, self.y + 2, 20, 6)

    if sprite and frames and frames[1] then
        local frameIndex = math.floor(self.floatTimer) % 4 + 1
        local quad = frames[frameIndex] or frames[1]
        local scaleX = self.isFacingLeft and -1 or 1

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sprite, quad, self.x, self.y + floatY, 0, scaleX, 1, 24, 64)

        if self.hurtTimer > 0 then
            love.graphics.setBlendMode("add", "alphamultiply")
            love.graphics.setColor(0.85, 0.10, 0.12, 0.85)
            love.graphics.draw(sprite, quad, self.x, self.y + floatY, 0, scaleX, 1, 24, 64)
            love.graphics.setBlendMode("alpha", "alphamultiply")
        end

        -- Spectral eyes.
        local eyeGlow = 0.55 + 0.45 * math.sin(self.floatTimer * 2)
        Theme.drawGlow(self.x, self.y - 48 + floatY, 7, { 0.85, 0.80, 0.35, 1 }, 0.30 * eyeGlow)
    end

    -- Spectral scythe, rotating around the torso rather than the feet.
    love.graphics.push()
    love.graphics.translate(self.x, self.y - 32 + floatY)

    local scytheAngle = self.targetAngle
    if self.state == "scythe_windup" then
        scytheAngle = scytheAngle - 1.2
    elseif self.state == "scythe_slash" then
        scytheAngle = scytheAngle + 0.8
    end
    love.graphics.rotate(scytheAngle)

    love.graphics.setColor(0.34, 0.27, 0.33, 1)
    love.graphics.rectangle("fill", -16, -1, 46, 3)
    love.graphics.setColor(0.55, 0.50, 0.60, 1)
    love.graphics.rectangle("fill", -16, -1, 46, 1)

    love.graphics.setColor(0.83, 0.90, 0.98, 0.92)
    love.graphics.polygon("fill",
        28, -2,
        42, -18,
        30, -6)
    love.graphics.setColor(0.62, 0.55, 0.85, 0.35)
    love.graphics.polygon("fill",
        29, -3,
        39, -15,
        31, -5)
    love.graphics.pop()

    love.graphics.setColor(1, 1, 1, 1)
end

return LaParca
