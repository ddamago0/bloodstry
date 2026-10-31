local Class = require("lib.classic")
local SpatialHash = Class:extend()

function SpatialHash:new(cellSize)
    self.cellSize = cellSize or 64
    self.cells = {}
    self.queryResults = {}
    self.queryVisited = {}
end

local function hashCoords(cx, cy)
    return cx * 73856093 + cy * 19349663
end

function SpatialHash:clear()
    for k in pairs(self.cells) do
        self.cells[k] = nil
    end
end

function SpatialHash:insert(entity)
    local r = entity.radius or 8
    local minCX = math.floor((entity.x - r) / self.cellSize)
    local maxCX = math.floor((entity.x + r) / self.cellSize)
    local minCY = math.floor((entity.y - r) / self.cellSize)
    local maxCY = math.floor((entity.y + r) / self.cellSize)

    for cx = minCX, maxCX do
        for cy = minCY, maxCY do
            local key = hashCoords(cx, cy)
            local cell = self.cells[key]
            if not cell then
                cell = {}
                self.cells[key] = cell
            end
            cell[#cell + 1] = entity
        end
    end
end

function SpatialHash:queryRadius(x, y, radius, outList)
    outList = outList or {}
    local visited = self.queryVisited
    for k in pairs(visited) do visited[k] = nil end

    local minCX = math.floor((x - radius) / self.cellSize)
    local maxCX = math.floor((x + radius) / self.cellSize)
    local minCY = math.floor((y - radius) / self.cellSize)
    local maxCY = math.floor((y + radius) / self.cellSize)

    local count = 0
    local r2 = radius * radius

    for cx = minCX, maxCX do
        for cy = minCY, maxCY do
            local key = hashCoords(cx, cy)
            local cell = self.cells[key]
            if cell then
                for i = 1, #cell do
                    local ent = cell[i]
                    if not visited[ent] then
                        visited[ent] = true
                        local dx = ent.x - x
                        local dy = ent.y - y
                        local entR = ent.radius or 0
                        local totalR = radius + entR
                        if dx * dx + dy * dy <= totalR * totalR then
                            count = count + 1
                            outList[count] = ent
                        end
                    end
                end
            end
        end
    end

    for i = count + 1, #outList do
        outList[i] = nil
    end

    return outList
end

return SpatialHash
