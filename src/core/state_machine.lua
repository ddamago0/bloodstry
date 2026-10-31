local Class = require("lib.classic")
local StateMachine = Class:extend()

function StateMachine:new(states)
    self.states = states or {}
    self.current = nil
    self.currentStateName = nil
end

function StateMachine:add(name, state)
    self.states[name] = state
end

function StateMachine:change(stateName, ...)
    assert(self.states[stateName], "State '" .. tostring(stateName) .. "' does not exist.")
    if self.current and self.current.exit then
        self.current:exit()
    end
    self.currentStateName = stateName
    self.current = self.states[stateName]
    if self.current.enter then
        self.current:enter(...)
    end
end

function StateMachine:update(dt)
    if self.current and self.current.update then
        self.current:update(dt)
    end
end

function StateMachine:draw()
    if self.current and self.current.draw then
        self.current:draw()
    end
end

function StateMachine:keypressed(key)
    if self.current and self.current.keypressed then
        self.current:keypressed(key)
    end
end

function StateMachine:mousepressed(x, y, button)
    if self.current and self.current.mousepressed then
        self.current:mousepressed(x, y, button)
    end
end

function StateMachine:mousereleased(x, y, button)
    if self.current and self.current.mousereleased then
        self.current:mousereleased(x, y, button)
    end
end

return StateMachine
