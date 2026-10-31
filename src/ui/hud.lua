local Class = require("lib.classic")
local Assets = require("src.core.assets")
local Limb = require("src.combat.limb")
local Theme = require("src.ui.theme")

local HUD = Class:extend()

local function drawClassPortrait(player, x, y, w, h)
    local sprite = Assets.sprites.players and Assets.sprites.players[player.classType]
    local frames = Assets.quads.playerFrames and Assets.quads.playerFrames[player.classType]
    if sprite and frames and frames[1] then
        local scale = math.min((w - 4) / 32, (h - 4) / 40)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sprite, frames[1], x + w * 0.5, y + h - 2, 0, scale, scale, 16, 40)
    else
        Theme.iconCentered("shield", x + w * 0.5, y + 8, 1, Theme.colors.steel)
    end
end

local function limbQuadKey(limbType)
    if limbType == Limb.TYPES.HEAD then return "head" end
    if limbType == Limb.TYPES.ZOMBIE_ARM then return "zombie_arm" end
    return "skeleton_arm"
end

local function drawLimbIcon(limb, x, y)
    local key = limbQuadKey(limb.type)
    local asset = Assets.quads.limbs and Assets.quads.limbs[key]
    if asset and Assets.sprites.limbs then
        Theme.setColor({ 1, 1, 1, 1 })
        love.graphics.draw(Assets.sprites.limbs, asset.quad, x, y, 0, 0.8, 0.8)
    else
        Theme.icon("bone", x, y, 1, Theme.colors.bone)
    end
end

function HUD:draw(player, stage, viewWidth, viewHeight)
    viewWidth = viewWidth or 480
    viewHeight = viewHeight or 270
    local C = Theme.colors
    local hpPct = math.max(0, math.min(1, player.hp / math.max(1, player.maxHp)))
    local xpPct = math.max(0, math.min(1, player.bloodPoints / math.max(1, player.pointsToNextLevel)))

    -- 1. Character panel ---------------------------------------------------
    local px, py = 8, 8
    Theme.panel(px, py, 170, 46, { accent = C.blood, fill = C.panelDeep, cornerColor = C.borderSoft })
    -- Portrait niche
    Theme.panel(px + 5, py + 5, 24, 36, {
        fill = { 0.035, 0.034, 0.055, 0.9 },
        border = C.borderDark,
        corners = false,
        shadowAlpha = 0
    })
    drawClassPortrait(player, px + 5, py + 5, 24, 36)

    local barX, barW = px + 34, 130
    Theme.icon("heart", px + 33, py + 6, 0.5, C.bloodBright)
    Theme.bar(barX + 8, py + 8, barW - 8, 6, hpPct,
        hpPct < 0.3 and C.bloodBright or C.blood, nil,
        { segments = 16, borderColor = C.borderDark })

    if player.boneShield and player.boneShield > 0 then
        local shieldPct = math.min(1, player.boneShield / math.max(1, player.maxBoneShield))
        Theme.setColor(C.bone, 0.9)
        love.graphics.rectangle("fill", barX + 8, py + 9, math.floor((barW - 8) * shieldPct), 2)
        Theme.icon("shield", px + 158, py + 8, 0.55, C.bone)
        Theme.right(tostring(math.ceil(player.boneShield)), "small", C.bone, px + 158, py + 17)
    end

    Theme.print(string.format("PS %d / %d", math.ceil(player.hp), player.maxHp), "small", C.text, barX, py + 17)
    Theme.print("Nv. " .. tostring(player.level), "small", C.goldBright, barX, py + 29)
    Theme.bar(barX + 34, py + 30, barW - 34, 3, xpPct, C.purpleBright, nil, { border = false })

    -- 2. Timer panel -------------------------------------------------------
    -- Right-aligned so the top-centre stays clear for bosses and tall props.
    local timerW = 64
    local timerX = viewWidth - 148
    Theme.panel(timerX, 8, timerW, 20, {
        fill = C.panelDeep, border = C.borderSoft, corners = false, shadowAlpha = 0.35
    })
    Theme.icon("hourglass", timerX + 5, 12, 0.7, C.goldBright)
    Theme.center(Theme.timeString(stage.timeElapsed), "bold", C.text, 9, timerW, timerX)

    -- 3. Kills / pause -----------------------------------------------------
    Theme.panel(viewWidth - 76, 8, 68, 42, {
        fill = C.panelDeep, border = C.borderSoft, corners = false, shadowAlpha = 0.35
    })
    Theme.icon("skull", viewWidth - 70, 12, 0.75, C.bone)
    Theme.print(tostring(player.killCount), "bold", C.text, viewWidth - 50, 9)
    Theme.print("BAJAS", "small", C.textSoft, viewWidth - 50, 21)
    Theme.right("[ESC] PAUSA", "small", C.dim, viewWidth - 12, 32)

    -- 4. Pending upgrades --------------------------------------------------
    if player.pendingLevelUps > 0 then
        local pulse = (math.sin(love.timer.getTime() * 6) + 1) * 0.5
        local bw = 164
        local bx = (viewWidth - bw) / 2
        local by = 60
        Theme.panel(bx, by, bw, 18, {
            fill = { 0.16, 0.09, 0.05, 0.96 },
            border = C.gold,
            accent = C.goldBright,
            shadowAlpha = 0.4
        })
        Theme.icon("level", bx + 5, by + 2, 0.85, C.goldBright)
        Theme.print("MEJORA DISPONIBLE", "small", C.goldBright, bx + 20, by + 3)
        Theme.right("[TAB]", "small", { 1, 1, 1, 0.55 + pulse * 0.4 }, bx + bw - 5, by + 3)
    end

    -- 5. Active pacts ------------------------------------------------------
    local pactIcons = {
        hemofilia = { icon = "blood_drop", color = C.bloodBright },
        frenesi_ciego = { icon = "eye", color = C.purpleBright },
        huesos_cristal = { icon = "claw", color = C.bone }
    }
    local pactX = 10
    for id, data in pairs(player.pacts or {}) do
        local info = pactIcons[id]
        if info then
            Theme.icon(info.icon, pactX, 57, 0.65, info.color)
            pactX = pactX + 13
        end
    end

    -- 6. Boss bar (bottom, above the weapon slots) -------------------------
    local boss = stage.bossInstance
    if boss and boss.alive then
        local bw, bh = 266, 30
        local bx = (viewWidth - bw) / 2
        local by = viewHeight - 78
        Theme.panel(bx, by, bw, bh, {
            fill = { 0.095, 0.040, 0.085, 0.96 },
            border = C.purple,
            accent = C.purpleBright,
            cornerColor = C.purple,
            shadowAlpha = 0.5
        })
        Theme.icon("boss", bx + 7, by + 6, 0.95, C.purpleBright)
        Theme.print(string.upper(boss.name), "small", C.purpleBright, bx + 26, by + 5)
        Theme.print(boss.subtitle or "", "small", C.dim, bx + 26, by + 14)
        local bossPct = math.max(0, math.min(1, boss.hp / math.max(1, boss.maxHp)))
        Theme.bar(bx + 26, by + 22, bw - 36, 5, bossPct,
            { 0.66, 0.16, 0.55, 1 }, nil, { segments = 24, borderColor = C.borderDark })
        if bossPct <= 0.5 then
            Theme.right("FASE II", "small", C.bloodBright, bx + bw - 7, by + 4)
        end
    end

    -- 7. Weapon slots ------------------------------------------------------
    local slotY = viewHeight - 38
    Theme.panel(8, slotY, 176, 30, {
        fill = C.panel, border = C.borderSoft, shadowAlpha = 0.4
    })
    Theme.icon(player.primaryWeapon.id == "dual_daggers" and "claw" or "sword",
        14, slotY + 7, 1, C.steelBright)
    Theme.print(player.primaryWeapon.name, "small", C.text, 34, slotY + 5)
    Theme.print("INFINITO · CLIC IZQ / ESPACIO", "small", C.dim, 34, slotY + 16)

    local limbX = 190
    local nearBreak = player.equippedLimb and player.equippedLimb:isNearBreaking()
    local limbBorder = C.borderSoft
    if nearBreak then
        local pulse = (math.sin(love.timer.getTime() * 10) + 1) * 0.5
        limbBorder = { 0.95, 0.15 + pulse * 0.2, 0.15, 1 }
    end
    Theme.panel(limbX, slotY, 188, 30, {
        fill = C.panel,
        border = limbBorder,
        accent = nearBreak and C.bloodBright or nil,
        shadowAlpha = 0.4
    })
    if player.equippedLimb then
        drawLimbIcon(player.equippedLimb, limbX + 5, slotY + 5)
        Theme.print(player.equippedLimb.name, "small", nearBreak and C.bloodBright or C.text, limbX + 25, slotY + 5)
        if nearBreak then
            Theme.print(string.format("¡INESTABLE! %d USOS · [E] SACRIFICAR", player.equippedLimb.durability),
                "small", C.bloodBright, limbX + 25, slotY + 16)
        else
            Theme.print(string.format("%d USOS · CLIC DER / [K]", player.equippedLimb.durability),
                "small", C.dim, limbX + 25, slotY + 16)
        end
    else
        Theme.icon("bone", limbX + 7, slotY + 6, 1, C.border)
        Theme.print("SIN EXTREMIDAD", "small", C.text, limbX + 25, slotY + 5)
        Theme.print("Busca restos en el suelo", "small", C.dim, limbX + 25, slotY + 16)
    end

    -- Contextual help tag for the upgrade menu, with its own backing panel so
    -- it stays legible over bright ground props.
    local helpX = 382
    local helpColor = player.pendingLevelUps > 0 and C.goldBright or C.textSoft
    Theme.panel(helpX, slotY, 90, 30, {
        fill = C.panel,
        border = C.borderSoft,
        accent = player.pendingLevelUps > 0 and C.gold or nil,
        shadowAlpha = 0.4
    })
    Theme.icon("level", helpX + 7, slotY + 7, 0.85, helpColor)
    Theme.print("[TAB]", "small", helpColor, helpX + 26, slotY + 5)
    Theme.print("MEJORAS", "small", C.dim, helpX + 26, slotY + 16)

    love.graphics.setColor(1, 1, 1, 1)
end

return HUD
