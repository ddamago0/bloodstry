local Class = require("lib.classic")
local Camera = require("src.core.camera")
local SpatialHash = require("src.core.spatial_hash")
local Input = require("src.core.input")
local BloodCanvas = require("src.vfx/blood_canvas")
local Particles = require("src.vfx/particles")
local Player = require("src.entities/player")
local Stage1Cemetery = require("src.stages/stage1_cemetery")
local HUD = require("src.ui/hud")
local UpgradeMenu = require("src.ui/upgrade_menu")
local Theme = require("src.ui.theme")

local PlayState = Class:extend()

local function clearList(list)
    for i = #list, 1, -1 do
        list[i] = nil
    end
end

function PlayState:new(stateMachine, push)
    self.stateMachine = stateMachine
    self.push = push
    self.viewWidth = push:getWidth()
    self.viewHeight = push:getHeight()

    self.camera = Camera(self.viewWidth, self.viewHeight)
    self.spatialHash = SpatialHash(64)
    self.bloodCanvas = BloodCanvas(2400, 2400)
    self.particles = Particles()
    self.hud = HUD()
    self.upgradeMenu = UpgradeMenu()

    self.enemies = {}
    self.drops = {}
    self.playerProjectiles = {}
    self.enemyProjectiles = {}
    self.renderList = {}

    self.isPaused = false
    self.isVictory = false
    self.trailTimer = 0
end

function PlayState:enter(params)
    params = params or {}
    local classType = params.classType or "guerrero"

    self.player = Player(0, 0, classType)
    self.stage = Stage1Cemetery()
    self.camera:setBounds(self.stage.bounds.minX, self.stage.bounds.minY,
        self.stage.bounds.maxX, self.stage.bounds.maxY)
    self.camera.x = self.player.x
    self.camera.y = self.player.y

    self.enemies = {}
    self.drops = {}
    self.playerProjectiles = {}
    self.enemyProjectiles = {}
    clearList(self.renderList)

    self.bloodCanvas:clear()
    self.isPaused = false
    self.isVictory = false
    self.trailTimer = 0
    self.upgradeMenu.active = false
end

function PlayState:update(dt)
    if self.isPaused then return end
    if self.upgradeMenu.active then return end

    self.camera:update(dt)
    self.particles:update(dt)

    -- 1. Player & camera
    self.player:update(dt, Input, self.push, self.camera, self.stage.bounds)
    self.camera:follow(self.player.x, self.player.y, dt, 8)

    if not self.player.alive then
        self.stateMachine:change("game_over", {
            victory = false,
            kills = self.player.killCount,
            timeSurvived = self.stage.timeElapsed,
            classType = self.player.classType,
            level = self.player.level
        })
        return
    end

    if self.player.pendingLevelUps > 0 and not self.upgradeMenu.active then
        self.upgradeMenu:open(self.player)
    end

    -- Burning blood trail (Pacto de Hemofilia)
    if self.player.bloodTrailActive then
        self.trailTimer = self.trailTimer + dt
        if self.trailTimer >= 0.15 then
            self.trailTimer = 0
            self.bloodCanvas:splatter(self.player.x, self.player.y, 2, 7,
                { 0.85, 0.15, 0.05, 0.72 })
        end
    end

    -- 2. Spatial hash
    self.spatialHash:clear()
    for i = 1, #self.enemies do
        local enemy = self.enemies[i]
        if enemy.alive then
            self.spatialHash:insert(enemy)
        end
    end

    -- 3. Player combat inputs
    if Input.isDown("attack") then
        if self.player:triggerPrimaryAttack() then
            self:resolveMeleeHit(self.player.primaryWeapon:getHitInfo(
                self.player.x, self.player.y, self.player.aimAngle, self.player.strength))
        end
    end

    if Input.isDown("limb_attack") then
        local limbHit = self.player:triggerLimbAttack(self.playerProjectiles, self.particles)
        if limbHit then
            self:resolveMeleeHit(limbHit)
        end
    end

    if Input.wasPressed("sacrifice") then
        local sacResult = self.player:triggerSacrifice(self.playerProjectiles, self.particles)
        if sacResult then
            self.camera:shake(8, 0.3)
            self.particles:emitBone(self.player.x, self.player.y, 25)
            self.particles:emitBlood(self.player.x, self.player.y, 20)
            if sacResult.type == "sacrifice_blast" then
                self:resolveExplosion(sacResult)
            end
        end
    end

    -- 4. Projectiles
    self:updateProjectiles(dt)

    -- 5. Enemies
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        if enemy.alive then
            if enemy.isBoss then
                -- Bosses need the full enemy list to summon guards and the
                -- projectile list as a destination for their barrages.
                enemy:update(dt, self.player, self.enemyProjectiles, self.enemies,
                    self.bloodCanvas, self.particles, self.camera)
            else
                enemy:update(dt, self.player, self.spatialHash, self.enemyProjectiles,
                    self.bloodCanvas, self.particles, self.camera)
            end
        else
            enemy:handleDeath(self.drops, self.bloodCanvas, self.particles)
            self.player.killCount = self.player.killCount + 1

            if enemy == self.stage.bossInstance then
                self.isVictory = true
                self.stateMachine:change("game_over", {
                    victory = true,
                    kills = self.player.killCount,
                    timeSurvived = self.stage.timeElapsed,
                    classType = self.player.classType,
                    level = self.player.level
                })
                return
            end

            table.remove(self.enemies, i)
        end
    end

    -- 6. Drops
    for i = #self.drops, 1, -1 do
        local drop = self.drops[i]
        if drop.alive then
            drop:update(dt, self.player.x, self.player.y, self.player.magnetRadius)
            local dx = self.player.x - drop.x
            local dy = self.player.y - drop.y
            local distSq = dx * dx + dy * dy
            local grabRadius = self.player.radius + drop.radius

            if distSq < grabRadius * grabRadius then
                if drop.value then
                    self.player:gainBloodPoints(drop.value)
                    self.particles:emitSoul(drop.x, drop.y, 3)
                    table.remove(self.drops, i)
                elseif drop.limb then
                    if not self.player.equippedLimb then
                        self.player:equipLimb(drop.limb)
                        table.remove(self.drops, i)
                    end
                end
            end
        else
            table.remove(self.drops, i)
        end
    end

    -- 7. Stage waves & boss
    self.stage:update(dt, self.player, self.enemies, self.camera)
end

function PlayState:resolveMeleeHit(hitInfo)
    if not hitInfo then return end
    local queryRange = hitInfo.range + 16
    local targets = self.spatialHash:queryRadius(hitInfo.originX, hitInfo.originY, queryRange)

    local halfArc = (hitInfo.arcAngle or math.pi) * 0.5
    local hitSomething = false

    for i = 1, #targets do
        local ent = targets[i]
        if ent.alive then
            local dx = ent.x - hitInfo.originX
            local dy = ent.y - hitInfo.originY
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist <= (hitInfo.range + ent.radius) then
                local angleToEnt = math.atan2(dy, dx)
                local angleDiff = math.abs((angleToEnt - hitInfo.angle + math.pi) % (math.pi * 2) - math.pi)

                if angleDiff <= halfArc then
                    hitSomething = true
                    local kx = math.cos(angleToEnt) * hitInfo.knockback
                    local ky = math.sin(angleToEnt) * hitInfo.knockback
                    local dmgDone = ent:takeDamage(hitInfo.damage, kx, ky)

                    if hitInfo.bleed and ent.applyBleed then
                        ent:applyBleed(3.5, 6)
                    end

                    if self.player.lifesteal > 0 and dmgDone > 0 then
                        self.player.hp = math.min(self.player.maxHp,
                            self.player.hp + dmgDone * self.player.lifesteal)
                    end

                    self.particles:emitBlood(ent.x, ent.y, 6)
                    self.particles:emitBone(ent.x, ent.y, 4)
                end
            end
        end
    end

    if hitSomething then
        self.camera:shake(3, 0.12)
    end
end

function PlayState:resolveExplosion(sacResult)
    local targets = self.spatialHash:queryRadius(sacResult.originX, sacResult.originY, sacResult.radius)
    for i = 1, #targets do
        local ent = targets[i]
        if ent.alive then
            local dx = ent.x - sacResult.originX
            local dy = ent.y - sacResult.originY
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist <= sacResult.radius then
                local angle = math.atan2(dy, dx)
                local kx = math.cos(angle) * sacResult.knockback
                local ky = math.sin(angle) * sacResult.knockback
                ent:takeDamage(sacResult.damage, kx, ky)
            end
        end
    end
    self.bloodCanvas:splatter(sacResult.originX, sacResult.originY, 20, sacResult.radius * 0.8)
end

function PlayState:updateProjectiles(dt)
    for i = #self.playerProjectiles, 1, -1 do
        local proj = self.playerProjectiles[i]
        proj:update(dt)
        if proj.alive then
            local candidates = self.spatialHash:queryRadius(proj.x, proj.y, proj.radius + 12)
            for c = 1, #candidates do
                local ent = candidates[c]
                if ent.alive and not proj.hitEnemies[ent] then
                    local dx = ent.x - proj.x
                    local dy = ent.y - proj.y
                    if (dx * dx + dy * dy) <= (proj.radius + ent.radius) ^ 2 then
                        proj.hitEnemies[ent] = true
                        local kx = math.cos(proj.angle) * 160
                        local ky = math.sin(proj.angle) * 160
                        ent:takeDamage(proj.damage, kx, ky)
                        self.particles:emitBone(proj.x, proj.y, 10)
                        self.particles:emitBlood(proj.x, proj.y, 8)
                        self.camera:shake(4, 0.15)
                        if not proj.isPiercing then
                            proj.alive = false
                            break
                        end
                    end
                end
            end
        else
            table.remove(self.playerProjectiles, i)
        end
    end

    for i = #self.enemyProjectiles, 1, -1 do
        local proj = self.enemyProjectiles[i]
        proj:update(dt)
        if proj.alive then
            local dx = self.player.x - proj.x
            local dy = self.player.y - proj.y
            if (dx * dx + dy * dy) <= (proj.radius + self.player.radius) ^ 2 then
                proj.alive = false
                local kx = math.cos(proj.angle) * 80
                local ky = math.sin(proj.angle) * 80
                self.player:takeDamage(proj.damage, kx, ky)
                self.particles:emitBlood(self.player.x, self.player.y, 6)
                self.camera:shake(4, 0.15)
            end
        else
            table.remove(self.enemyProjectiles, i)
        end
    end
end

function PlayState:keypressed(key)
    if key == "escape" or key == "p" then
        if not self.upgradeMenu.active then
            self.isPaused = not self.isPaused
            return
        end
    end

    if self.isPaused then return end
    if self.upgradeMenu.active then
        self.upgradeMenu:keypressed(key, self.player)
        return
    end

    if key == "tab" or key == "u" then
        if self.player.pendingLevelUps > 0 or not self.upgradeMenu.active then
            self.upgradeMenu:open(self.player)
        end
    elseif key == "b" then
        self.stage:spawnBoss(self.player, self.enemies, self.camera)
    elseif key == "l" then
        self.player:gainBloodPoints(self.player.pointsToNextLevel)
    end
end

function PlayState:mousepressed(x, y, button)
    if self.isPaused then return end
    local gx, gy = self.push:toGame(x, y)
    if self.upgradeMenu.active then
        self.upgradeMenu:mousepressed(gx, gy, button, self.player,
            self.viewWidth, self.viewHeight)
    end
end

function PlayState:drawBossIntro()
    local stage = self.stage
    local boss = stage.bossInstance
    local t = stage.bossIntroTimer
    if not boss or not boss.alive or t <= 0 then return end

    local dur = stage.bossIntroDuration
    local alpha = 1
    if t > dur - 0.4 then
        alpha = math.max(0, (dur - t) / 0.4)
    elseif t < 0.8 then
        alpha = math.max(0, t / 0.8)
    end

    -- Slim top strip below the HUD: the boss sprite can emerge from beneath it
    -- without a large opaque banner covering the fight.
    local y = 56
    love.graphics.setColor(0.015, 0.008, 0.022, 0.62 * alpha)
    love.graphics.rectangle("fill", 0, y, 480, 28)
    love.graphics.setColor(0.72, 0.16, 0.30, 0.9 * alpha)
    love.graphics.rectangle("fill", 0, y, 480, 1)
    love.graphics.rectangle("fill", 0, y + 27, 480, 1)

    Theme.center("LA PARCA", "title", { 0.90, 0.80, 0.94, alpha }, y + 1, 480)
    Theme.center("GUARDIANA DEL SELLO ROTO", "small",
        { 0.72, 0.58, 0.82, alpha }, y + 17, 480)
    love.graphics.setColor(1, 1, 1, 1)
end

function PlayState:drawPause()
    local C = Theme.colors
    local pw, ph = 340, 180
    local px = (self.viewWidth - pw) / 2
    local py = (self.viewHeight - ph) / 2

    love.graphics.setColor(0.010, 0.008, 0.018, 0.78)
    love.graphics.rectangle("fill", 0, 0, self.viewWidth, self.viewHeight)

    Theme.panel(px, py, pw, ph, {
        fill = { 0.050, 0.047, 0.070, 0.98 },
        border = C.border,
        accent = C.blood,
        cornerColor = C.blood,
        shadowAlpha = 0.7
    })

    Theme.iconCentered("pause", self.viewWidth / 2, py + 10, 1.25, C.gold)
    Theme.center("PARTIDA EN PAUSA", "title", C.text, py + 33, self.viewWidth)
    Theme.center(string.format("El turno lleva %s en marcha",
        Theme.timeString(self.stage.timeElapsed)), "small", C.dim, py + 51, self.viewWidth)

    Theme.setColor(C.borderSoft, 0.7)
    love.graphics.line(px + 20, py + 65, px + pw - 20, py + 65)

    local controls = {
        { "WASD / FLECHAS", "MOVERSE" },
        { "RATÓN / J", "ATACAR" },
        { "CLIC DER. / K", "EXTREMIDAD" },
        { "E / F", "SACRIFICIO" },
        { "TAB", "MEJORAS" },
        { "ESC / P", "REANUDAR" }
    }
    for i = 1, #controls do
        local rowY = py + 74 + (i - 1) * 14
        Theme.print(controls[i][1], "small", C.textSoft, px + 26, rowY)
        Theme.right(controls[i][2], "small", C.mute, px + pw - 26, rowY)
    end

    Theme.setColor(C.borderSoft, 0.55)
    love.graphics.line(px + 20, py + 160, px + pw - 20, py + 160)
    Theme.center("[ESC] REANUDAR EL TURNO", "small", C.gold, py + 166, self.viewWidth)
    love.graphics.setColor(1, 1, 1, 1)
end

function PlayState:draw()
    -- World layer
    self.camera:attach()

    self.stage:drawGround(self.camera)
    self.stage:drawGlows()
    self.bloodCanvas:draw()

    -- Soft ambient pool around the player so the dark ground still reads
    -- while keeping the edges of the cemetery lost in the fog.
    Theme.drawGlow(self.player.x, self.player.y - 8, 58,
        { 0.48, 0.46, 0.66, 1 }, 0.055)

    -- Drops lie on the ground, below actors and props.
    for i = 1, #self.drops do
        self.drops[i]:draw()
    end

    -- One Y-sorted pass for props, enemies and the player: feet anchor depth.
    local list = self.renderList
    clearList(list)
    for i = 1, #self.stage.props do
        list[#list + 1] = self.stage.props[i]
    end
    for i = 1, #self.enemies do
        local enemy = self.enemies[i]
        if enemy.alive then
            list[#list + 1] = enemy
        end
    end
    list[#list + 1] = self.player

    table.sort(list, function(a, b)
        return a.y < b.y
    end)

    for i = 1, #list do
        local entry = list[i]
        if entry.draw then
            entry:draw()
        else
            self.stage:drawProp(entry)
        end
    end

    for i = 1, #self.playerProjectiles do
        self.playerProjectiles[i]:draw()
    end
    for i = 1, #self.enemyProjectiles do
        self.enemyProjectiles[i]:draw()
    end

    self.particles:draw()
    self.camera:detach()

    -- Screen-space atmosphere
    self.stage:drawFog(self.viewWidth, self.viewHeight, self.stage.timeElapsed, self.camera)

    -- Frenesí Ciego: a real stencil cut-out instead of two fake circles.
    if self.player.visionRadiusMult < 1.0 then
        local cx, cy = self.camera:toScreenCoords(self.player.x, self.player.y - 12)
        local radius = 96 * self.player.visionRadiusMult + 22
        love.graphics.stencil(function()
            love.graphics.circle("fill", cx, cy, radius)
        end, "replace", 1)
        love.graphics.setStencilTest("equal", 0)
        love.graphics.setColor(0.006, 0.004, 0.012, 0.93)
        love.graphics.rectangle("fill", 0, 0, self.viewWidth, self.viewHeight)
        love.graphics.setStencilTest()
        love.graphics.setColor(0.60, 0.10, 0.14, 0.45)
        love.graphics.circle("line", cx, cy, radius)
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Damage flash.
    if self.player.damageFlash > 0 then
        love.graphics.setColor(0.65, 0.02, 0.05, self.player.damageFlash * 0.8)
        love.graphics.rectangle("fill", 0, 0, self.viewWidth, self.viewHeight)
        love.graphics.setColor(1, 1, 1, 1)
    end

    Theme.drawVignette(0.52)

    self:drawBossIntro()

    -- UI layer
    self.hud:draw(self.player, self.stage, self.viewWidth, self.viewHeight)

    if self.upgradeMenu.active then
        self.upgradeMenu:draw(self.viewWidth, self.viewHeight, self.player, self.push)
    end

    if self.isPaused then
        self:drawPause()
    end
end

return PlayState
