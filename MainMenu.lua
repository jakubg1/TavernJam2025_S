local Class = require("com.class")

---@class MainMenu : Class
---@overload fun(): MainMenu
local MainMenu = Class:derive("MainMenu")

function MainMenu:new()
    self.OPTIONS = {
        {label = "Start", x = 800, y = 550},
        {label = "Settings", x = 800, y = 620},
        {label = "Quit", x = 800, y = 690}
    }
    self.hoveredOption = nil

    self.active = true
    self.time = 0
end

function MainMenu:update(dt)
    if not self.active then
        return
    end
    self:updateTime(dt)
    self:updateHover()
end

function MainMenu:updateTime(dt)
    self.time = self.time + dt
end

function MainMenu:updateHover()
    self.hoveredOption = nil
    local x, y = love.mouse.getPosition()
    for i, option in ipairs(self.OPTIONS) do
        if x >= option.x - 250 and x <= option.x + 250 and y >= option.y - 35 and y <= option.y + 35 then
            self.hoveredOption = i
        end
    end
end

function MainMenu:mousepressed(x, y, button)
    if not self.active then
        return
    end
    if button == 1 then
        if self.hoveredOption == 1 then
            self.active = false
            _GAME:start()
        elseif self.hoveredOption == 2 then
        elseif self.hoveredOption == 3 then
            love.event.quit()
        end
    end
end

function MainMenu:draw()
    if not self.active then
        return
    end
    -- Background
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(_MENU_BG)
    -- Selection
    if self.hoveredOption then
        local sx = self.OPTIONS[self.hoveredOption].x
        local sy = self.OPTIONS[self.hoveredOption].y - 10
        local sscale = 0.8
        local sprite = _SPRITES.menuSelect
        local img = sprite:getImage("select", math.floor(self.time * 10) % 10 + 1)
        local width = sprite.imageWidth
        local height = sprite.imageHeight
        love.graphics.setColor(0.3, 0.3, 0.7, 0.5)
        love.graphics.rectangle("fill", sx - width / 2 * 0.65, sy - height / 2 * 0.3 + 13, width * 0.65 + 3, height * 0.3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(img, sx, sy, 0, sscale, sscale, width / 2, height / 2)
    end
    -- Options
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(_FONT)
    for i, option in ipairs(self.OPTIONS) do
        local x = option.x - _FONT:getWidth(option.label) / 2
        local y = option.y - _FONT:getHeight() / 2
        love.graphics.print(option.label, x, y)
    end

    love.graphics.print(love.mouse:getY())
end

return MainMenu