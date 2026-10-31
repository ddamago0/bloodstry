--
-- push.lua
-- A simple resolution-handling library for LÖVE
-- Copyright (c) 2020 Ulydev
-- MIT License
--

local push = {
  defaults = {
    fullscreen = false,
    resizable = false,
    pixelperfect = false,
    highdpi = true,
    canvas = true,
    stencil = true
  }
}

setmetatable(push, push)

function push:setupScreen(WWIDTH, WHEIGHT, RWIDTH, RHEIGHT, df)
  df = df or {}

  self._WWIDTH = WWIDTH
  self._WHEIGHT = WHEIGHT
  self._RWIDTH = RWIDTH
  self._RHEIGHT = RHEIGHT

  self._fullscreen = df.fullscreen or self.defaults.fullscreen
  self._resizable = df.resizable or self.defaults.resizable
  self._pixelperfect = df.pixelperfect or self.defaults.pixelperfect
  self._highdpi = df.highdpi or self.defaults.highdpi
  self._canvas = df.canvas or self.defaults.canvas
  self._stencil = df.stencil or self.defaults.stencil

  self:initValues()

  if self._canvas then
    self:setupCanvas()
  end

  self._windowCreated = love.window.setMode(self._RWIDTH, self._RHEIGHT, {
    fullscreen = self._fullscreen,
    resizable = self._resizable,
    highdpi = self._highdpi
  })

  self:resize(self._RWIDTH, self._RHEIGHT)
  return self
end

function push:setupCanvas()
  table.insert(self._canvasList, {
    name = "_main",
    canvas = love.graphics.newCanvas(self._WWIDTH, self._WHEIGHT),
    shader = nil
  })
end

function push:initValues()
  self._canvasList = {}
  self._OFFSET = { x = 0, y = 0 }
  self._SCALE = { x = 0, y = 0 }
  self._GWIDTH = self._WWIDTH
  self._GHEIGHT = self._WHEIGHT
end

function push:apply(operation, shader)
  if operation == "start" then
    if self._canvas then
      love.graphics.push()
      love.graphics.setCanvas({ self:getCanvasTable("_main").canvas, stencil = self._stencil })
      love.graphics.clear()
    else
      love.graphics.push()
      love.graphics.translate(self._OFFSET.x, self._OFFSET.y)
      love.graphics.scale(self._SCALE.x, self._SCALE.y)
    end
  elseif operation == "finish" then
    if self._canvas then
      love.graphics.setCanvas()
      love.graphics.pop()

      love.graphics.setColor(1, 1, 1, 1)
      local mainCanvas = self:getCanvasTable("_main").canvas
      if mainCanvas and mainCanvas.setFilter then
        mainCanvas:setFilter("nearest", "nearest")
      end

      love.graphics.draw(
        mainCanvas,
        self._OFFSET.x, self._OFFSET.y,
        0,
        self._SCALE.x, self._SCALE.y
      )
    else
      love.graphics.pop()
    end
  end
end

function push:start()
  self:apply("start")
end

function push:finish()
  self:apply("finish")
end

function push:getCanvasTable(name)
  for _, c in ipairs(self._canvasList) do
    if c.name == name then return c end
  end
end

function push:resize(w, h)
  self._RWIDTH = w
  self._RHEIGHT = h

  if self._highdpi then
    local dpis = love.window.getDPIScale()
    w, h = w * dpis, h * dpis
  end

  local scaleX = w / self._WWIDTH
  local scaleY = h / self._WHEIGHT

  if self._pixelperfect then
    local scale = math.max(math.floor(math.min(scaleX, scaleY)), 1)
    self._SCALE.x = scale
    self._SCALE.y = scale
  else
    local scale = math.min(scaleX, scaleY)
    self._SCALE.x = scale
    self._SCALE.y = scale
  end

  self._OFFSET.x = math.floor((w - self._WWIDTH * self._SCALE.x) / 2)
  self._OFFSET.y = math.floor((h - self._WHEIGHT * self._SCALE.y) / 2)
end

function push:toGame(x, y)
  if not x or not y then return 0, 0 end
  local gx = (x - self._OFFSET.x) / self._SCALE.x
  local gy = (y - self._OFFSET.y) / self._SCALE.y
  return gx, gy
end

function push:toReal(x, y)
  if not x or not y then return 0, 0 end
  local rx = x * self._SCALE.x + self._OFFSET.x
  local ry = y * self._SCALE.y + self._OFFSET.y
  return rx, ry
end

function push:getWidth() return self._WWIDTH end
function push:getHeight() return self._WHEIGHT end

return push
