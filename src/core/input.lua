local Input = {
    keysPressed = {},
    mousePressed = {}
}

function Input.update()
    for k in pairs(Input.keysPressed) do
        Input.keysPressed[k] = nil
    end
    for b in pairs(Input.mousePressed) do
        Input.mousePressed[b] = nil
    end
end

function Input.keypressed(key)
    Input.keysPressed[key] = true
end

function Input.mousepressed(x, y, button)
    Input.mousePressed[button] = true
end

function Input.isDown(action)
    if action == "left" then
        return love.keyboard.isDown("a", "left")
    elseif action == "right" then
        return love.keyboard.isDown("d", "right")
    elseif action == "up" then
        return love.keyboard.isDown("w", "up")
    elseif action == "down" then
        return love.keyboard.isDown("s", "down")
    elseif action == "attack" then
        return love.mouse.isDown(1) or love.keyboard.isDown("j", "space")
    elseif action == "limb_attack" then
        return love.mouse.isDown(2) or love.keyboard.isDown("k")
    elseif action == "sacrifice" then
        return love.keyboard.isDown("e", "f", "lshift")
    elseif action == "upgrade_menu" then
        return love.keyboard.isDown("tab", "u")
    end
    return love.keyboard.isDown(action)
end

function Input.wasPressed(action)
    if action == "sacrifice" then
        return Input.keysPressed["e"] or Input.keysPressed["f"] or Input.keysPressed["lshift"] or Input.mousePressed[3]
    elseif action == "upgrade_menu" then
        return Input.keysPressed["tab"] or Input.keysPressed["u"]
    elseif action == "pause" then
        return Input.keysPressed["escape"] or Input.keysPressed["p"]
    elseif action == "reroll" then
        return Input.keysPressed["r"]
    elseif action == "confirm" then
        return Input.keysPressed["return"] or Input.keysPressed["space"]
    end
    return Input.keysPressed[action] or false
end

function Input.getMovementVector()
    local dx = 0
    local dy = 0

    if Input.isDown("left") then dx = dx - 1 end
    if Input.isDown("right") then dx = dx + 1 end
    if Input.isDown("up") then dy = dy - 1 end
    if Input.isDown("down") then dy = dy + 1 end

    if dx ~= 0 and dy ~= 0 then
        local invLen = 1 / math.sqrt(2)
        dx = dx * invLen
        dy = dy * invLen
    end

    return dx, dy
end

function Input.getGameMouse(push)
    local mx, my = love.mouse.getPosition()
    return push:toGame(mx, my)
end

return Input
