local SkillsData = {
    standard = {
        {
            id = "vigor_impio",
            title = "Vigor Impío",
            icon = "heart",
            desc = "+25 Vida Máxima y cura 25 PS de inmediato.",
            isPact = false,
            apply = function(player)
                player.maxHp = player.maxHp + 25
                player.hp = math.min(player.maxHp, player.hp + 25)
            end
        },
        {
            id = "fuerza_cadaverica",
            title = "Fuerza Cadavérica",
            icon = "sword",
            desc = "+22% de Daño en todas las armas y extremidades.",
            isPact = false,
            apply = function(player)
                player.strength = player.strength * 1.22
            end
        },
        {
            id = "pies_sepultureros",
            title = "Paso del Sepulturero",
            icon = "boot",
            desc = "+15% de Velocidad de movimiento.",
            isPact = false,
            apply = function(player)
                player.speed = player.speed * 1.15
            end
        },
        {
            id = "iman_sanguineo",
            title = "Imán Sanguíneo",
            icon = "magnet",
            desc = "+45% de Rango de atracción para almas y sangre.",
            isPact = false,
            apply = function(player)
                player.magnetRadius = player.magnetRadius * 1.45
            end
        },
        {
            id = "sed_de_sangre",
            title = "Sed Insaciable",
            icon = "blood_drop",
            desc = "+5% de Robo de vida al golpear enemigos.",
            isPact = false,
            apply = function(player)
                player.lifesteal = (player.lifesteal or 0) + 0.05
            end
        }
    },

    pacts = {
        {
            id = "pacto_hemofilia",
            title = "Pacto de Hemofilia",
            icon = "blood_drop",
            desc = "MALDICIÓN: -30% Vida Máxima.\nBENDICIÓN: +10% Robo de vida y dejas un rastro de sangre abrasadora.",
            isPact = true,
            apply = function(player)
                player.maxHp = math.floor(player.maxHp * 0.7)
                player.hp = math.min(player.hp, player.maxHp)
                player.lifesteal = (player.lifesteal or 0) + 0.10
                player.bloodTrailActive = true
                player.pacts["hemofilia"] = true
            end
        },
        {
            id = "frenesi_ciego",
            title = "Frenesí Ciego",
            icon = "eye",
            desc = "MALDICIÓN: Tu campo de visión se reduce a la mitad.\nBENDICIÓN: +100% Fuerza bruta y +40% cadencia de ataque.",
            isPact = true,
            apply = function(player)
                player.visionRadiusMult = 0.5
                player.strength = player.strength * 2.0
                player.primaryWeapon.cooldown = player.primaryWeapon.cooldown * 0.7
                player.pacts["frenesi_ciego"] = true
            end
        },
        {
            id = "huesos_de_cristal",
            title = "Huesos de Cristal",
            icon = "claw",
            desc = "MALDICIÓN: Las extremidades duran 50% menos golpes.\nBENDICIÓN: El daño y radio del Sacrificio (Last Ditch) se triplican.",
            isPact = true,
            apply = function(player)
                player.pacts["huesos_cristal"] = true
            end
        }
    }
}

function SkillsData.getRandomCardPool(count, pactChance)
    count = count or 3
    pactChance = pactChance or 0.35
    local pool = {}
    local chosen = {}

    while #pool < count do
        local isPactRoll = math.random() < pactChance
        local source = isPactRoll and SkillsData.pacts or SkillsData.standard
        local item = source[math.random(1, #source)]

        if not chosen[item.id] then
            chosen[item.id] = true
            table.insert(pool, item)
        end
    end

    return pool
end

return SkillsData
