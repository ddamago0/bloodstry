local Assets = require("src.core.assets")

local Theme = {}

Theme.colors = {
    ink          = { 0.035, 0.030, 0.050, 1 },
    panel        = { 0.065, 0.060, 0.090, 0.94 },
    panelDeep    = { 0.045, 0.042, 0.065, 0.96 },
    panelRaised  = { 0.100, 0.092, 0.130, 0.96 },
    border       = { 0.300, 0.285, 0.380, 1 },
    borderSoft   = { 0.175, 0.170, 0.235, 1 },
    borderDark   = { 0.100, 0.095, 0.140, 1 },
    text         = { 0.905, 0.880, 0.820, 1 },
    textSoft     = { 0.740, 0.715, 0.690, 1 },
    dim          = { 0.560, 0.535, 0.575, 1 },
    mute         = { 0.380, 0.360, 0.410, 1 },
    blood        = { 0.700, 0.135, 0.205, 1 },
    bloodBright  = { 0.930, 0.235, 0.285, 1 },
    bloodDark    = { 0.280, 0.055, 0.100, 1 },
    gold         = { 0.830, 0.665, 0.345, 1 },
    goldBright   = { 0.980, 0.840, 0.480, 1 },
    bone         = { 0.850, 0.820, 0.740, 1 },
    steel        = { 0.565, 0.620, 0.750, 1 },
    steelBright  = { 0.760, 0.810, 0.900, 1 },
    purple       = { 0.620, 0.390, 0.680, 1 },
    purpleBright = { 0.820, 0.545, 0.870, 1 },
    green        = { 0.500, 0.705, 0.505, 1 },
    acid         = { 0.650, 0.900, 0.280, 1 }
}

function Theme.setColor(color, alpha)
    if not color then
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    love.graphics.setColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

function Theme.font(name)
    return Assets.fonts[name] or Assets.fonts.normal
end

function Theme.setFont(name)
    love.graphics.setFont(Theme.font(name))
    return Theme.font(name)
end

-- The 8px TTF rasterizes with only ~80% coverage inside its strokes, which
-- makes small text look washed out over dark panels. Drawing it twice at the
-- same position restores the intended weight without changing the layout.
local function needsSecondPass(fontName)
    -- Kept as a tunable hook: currently the hinted font already renders with
    -- full coverage, so no second pass is needed.
    return false
end

function Theme.print(text, fontName, color, x, y)
    Theme.setFont(fontName)
    Theme.setColor(color)
    local px, py = math.floor(x), math.floor(y)
    love.graphics.print(text, px, py)
    if needsSecondPass(fontName) then
        love.graphics.print(text, px, py)
    end
end

function Theme.center(text, fontName, color, y, width, xOffset)
    Theme.setFont(fontName)
    Theme.setColor(color)
    local w = width or 480
    love.graphics.printf(text, xOffset or 0, math.floor(y), w, "center")
    if needsSecondPass(fontName) then
        love.graphics.printf(text, xOffset or 0, math.floor(y), w, "center")
    end
end

function Theme.right(text, fontName, color, right, y)
    Theme.setFont(fontName)
    Theme.setColor(color)
    local width = Theme.font(fontName):getWidth(text)
    local px = math.floor(right - width)
    love.graphics.print(text, px, math.floor(y))
    if needsSecondPass(fontName) then
        love.graphics.print(text, px, math.floor(y))
    end
end

function Theme.printf(text, fontName, color, x, y, width, align)
    Theme.setFont(fontName)
    Theme.setColor(color)
    local px, py = math.floor(x), math.floor(y)
    love.graphics.printf(text, px, py, width, align or "left")
    if needsSecondPass(fontName) then
        love.graphics.printf(text, px, py, width, align or "left")
    end
end

function Theme.measure(text, fontName)
    return Theme.font(fontName):getWidth(text)
end

function Theme.panel(x, y, w, h, opts)
    opts = opts or {}
    local fill = opts.fill or Theme.colors.panel
    local border = opts.border or Theme.colors.border
    local accent = opts.accent
    local shadowAlpha = opts.shadowAlpha == nil and 0.45 or opts.shadowAlpha

    if shadowAlpha > 0 then
        love.graphics.setColor(0, 0, 0, shadowAlpha)
        love.graphics.rectangle("fill", math.floor(x + 2), math.floor(y + 2), math.floor(w), math.floor(h))
    end

    Theme.setColor(fill)
    love.graphics.rectangle("fill", math.floor(x), math.floor(y), math.floor(w), math.floor(h))

    -- Subtle top bevel.
    love.graphics.setColor(1, 1, 1, 0.035)
    love.graphics.rectangle("fill", math.floor(x + 1), math.floor(y + 1), math.floor(w - 2), 1)

    Theme.setColor(border)
    love.graphics.rectangle("line", math.floor(x) + 0.5, math.floor(y) + 0.5, math.floor(w) - 1, math.floor(h) - 1)

    if opts.corners ~= false then
        local c = opts.cornerColor or border
        Theme.setColor(c, 0.9)
        local cl = 3
        love.graphics.line(x, y + cl, x, y)
        love.graphics.line(x, y, x + cl, y)
        love.graphics.line(x + w - cl, y, x + w, y)
        love.graphics.line(x + w, y, x + w, y + cl)
        love.graphics.line(x, y + h - cl, x, y + h)
        love.graphics.line(x, y + h, x + cl, y + h)
        love.graphics.line(x + w - cl, y + h, x + w, y + h)
        love.graphics.line(x + w, y + h - cl, x + w, y + h)
    end

    if accent then
        Theme.setColor(accent)
        love.graphics.rectangle("fill", math.floor(x + 5), math.floor(y), math.floor(w - 10), 1)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Theme.bar(x, y, w, h, pct, fillColor, bgColor, opts)
    opts = opts or {}
    pct = math.max(0, math.min(1, pct or 0))
    -- Full pixel rectangles avoid blurry sub-pixel bleed through the nearest filter.
    love.graphics.setColor(bgColor or { 0.10, 0.075, 0.12, 0.95 })
    love.graphics.rectangle("fill", math.floor(x), math.floor(y), math.floor(w), math.floor(h))
    local fillW = math.floor(w * pct)
    if fillW > 0 then
        Theme.setColor(fillColor)
        love.graphics.rectangle("fill", math.floor(x), math.floor(y), fillW, math.floor(h))
        if h > 3 then
            love.graphics.setColor(1, 1, 1, 0.16)
            love.graphics.rectangle("fill", math.floor(x), math.floor(y), fillW, 1)
        end
    end
    if opts.segments then
        love.graphics.setColor(0, 0, 0, 0.22)
        local step = opts.segments
        for sx = x + step, x + w - 1, step do
            love.graphics.rectangle("fill", math.floor(sx), math.floor(y), 1, math.floor(h))
        end
    end
    if opts.border ~= false then
        love.graphics.setColor(opts.borderColor or { 0.24, 0.22, 0.30, 1 })
        love.graphics.rectangle("line", math.floor(x) - 0.5, math.floor(y) - 0.5, math.floor(w) + 1, math.floor(h) + 1)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Theme.icon(name, x, y, scale, color, alpha)
    local asset = Assets.getIcon(name)
    if not asset then return 0 end
    scale = scale or 1
    Theme.setColor(color or { 1, 1, 1, 1 }, alpha)
    love.graphics.draw(Assets.sprites.icons, asset.quad,
        math.floor(x), math.floor(y), 0, scale, scale,
        0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    return 16 * scale
end

function Theme.iconCentered(name, cx, y, scale, color, alpha)
    scale = scale or 1
    Theme.icon(name, cx - 8 * scale, y, scale, color, alpha)
end

function Theme.drawMenuBackground(tint, alpha, offsetY)
    local bg = Assets.sprites.menuBg
    if not bg then return end
    Theme.setColor(tint or { 1, 1, 1, 1 }, alpha or 1)
    love.graphics.draw(bg, 0, math.floor(offsetY or 0))
    love.graphics.setColor(0, 0, 0, 0.28)
    love.graphics.rectangle("fill", 0, 0, 480, 270)
    love.graphics.setColor(1, 1, 1, 1)
end

function Theme.drawVignette(alpha, tint)
    local vignette = Assets.sprites.vignette
    if not vignette then return end
    Theme.setColor(tint or { 0, 0, 0, 1 }, alpha or 1)
    love.graphics.draw(vignette, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
end

function Theme.drawGlow(x, y, radius, color, alpha, blendMode)
    local glow = Assets.sprites.glow
    if not glow then return end
    local prevMode, prevAlpha = love.graphics.getBlendMode()
    love.graphics.setBlendMode(blendMode or "add", "alphamultiply")
    Theme.setColor(color or { 1, 1, 1, 1 }, alpha or 0.5)
    local scale = (radius * 2) / glow:getWidth()
    love.graphics.draw(glow, x - radius, y - radius, 0, scale, scale)
    love.graphics.setBlendMode(prevMode, prevAlpha)
    love.graphics.setColor(1, 1, 1, 1)
end

function Theme.className(id)
    if id == "guerrero" then return "Guerrero" end
    if id == "barbaro" then return "Bárbaro" end
    if id == "asesino" then return "Asesino" end
    return "Sepulturero"
end

function Theme.timeString(seconds)
    seconds = math.max(0, seconds or 0)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

function Theme.phrase(seconds)
    local value = math.floor(seconds or 0)
    if value < 30 then return "Unos segundos" end
    if value < 60 then return "Menos de un minuto" end
    local mins = math.floor(value / 60)
    if mins == 1 then return "Un minuto" end
    return tostring(mins) .. " minutos"
end

return Theme
