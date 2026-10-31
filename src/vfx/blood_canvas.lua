local Class = require("lib.classic")
local Assets = require("src.core.assets")
local BloodCanvas = Class:extend()

function BloodCanvas:new(width, height)
    self.width = width or 2400
    self.height = height or 2400
    -- World coordinates are centred on the canvas; the previous version
    -- clipped every negative coordinate because it forgot this offset.
    self.offsetX = self.width / 2
    self.offsetY = self.height / 2
    self.canvas = love.graphics.newCanvas(self.width, self.height)
    self:clear()
end

function BloodCanvas:clear()
    love.graphics.push()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setCanvas()
    love.graphics.pop()
end

function BloodCanvas:splatter(x, y, count, spread, color)
    count = count or 5
    spread = spread or 16
    color = color or { 0.60, 0.05, 0.08, 0.85 }

    local tex = Assets.sprites.bloodSplats
    local quads = Assets.quads.bloodSplats

    love.graphics.push()
    love.graphics.setCanvas(self.canvas)
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.setColor(1, 1, 1, 1)

    for _ = 1, count do
        local angle = math.random() * math.pi * 2
        local dist = (math.random() ^ 0.65) * spread
        -- Slightly compressed vertically so pools read as lying on the ground.
        local sx = x + math.cos(angle) * dist
        local sy = y + math.sin(angle) * dist * 0.62

        local shade = 0.80 + math.random() * 0.38
        love.graphics.setColor(
            math.min(1, color[1] * shade),
            math.min(1, color[2] * shade),
            math.min(1, color[3] * shade),
            math.min(1, color[4] * (0.82 + math.random() * 0.22))
        )

        if tex and quads and #quads > 0 then
            local quad = quads[math.random(1, #quads)]
            local base = 0.38 + math.random() * 0.55
            local grow = 0.80 + spread / 70
            local scale = base * grow
            love.graphics.draw(tex, quad,
                sx + self.offsetX, sy + self.offsetY,
                math.random() * math.pi * 2,
                scale, scale * 0.78,
                16, 16)
        else
            love.graphics.circle("fill", sx + self.offsetX, sy + self.offsetY,
                math.random(1, 3))
        end
    end

    love.graphics.setCanvas()
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

function BloodCanvas:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvas, -self.offsetX, -self.offsetY)
end

return BloodCanvas
