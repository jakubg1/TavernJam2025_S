local Class = require("com.class")

---@class MainMenu : Class
---@overload fun(): MainMenu
local MainMenu = Class:derive("MainMenu")

function MainMenu:new()
    self.OPTIONS = {
        {label = "Start", x = 800, y = 550, w = 250},
        {label = "Settings", x = 800, y = 620, w = 250},
        {label = "Quit", x = 800, y = 690, w = 250}
    }
    self.SETTINGS_OPTIONS = {
        {label = "Sound Volume", x = 800, y = 330, w = 135, font = _FONT_S, slider = true},
        {label = "Music Volume", x = 800, y = 430, w = 135, font = _FONT_S, slider = true},
        {label = "Full Screen", x = 800, y = 530, w = 150, font = _FONT_S, checkbox = true},
        {label = "Back", x = 800, y = 630, w = 150}
    }
    self.hoveredOption = nil

    self.settingsOpen = false
    self.settingsTime = nil
    self.SETTINGS_CLOSE_TIME_MAX = 0.6

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
    if self.settingsTime then
        self.settingsTime = self.settingsTime + dt
        if not self.settingsOpen and self.settingsTime >= self.SETTINGS_CLOSE_TIME_MAX then
            self.settingsTime = nil
        end
    end
end

function MainMenu:updateHover()
    self.hoveredOption = nil
    if self.settingsTime and self.settingsTime < 0.6 then
        return
    end
    local x, y = love.mouse.getPosition()
    local options = self.settingsOpen and self.SETTINGS_OPTIONS or self.OPTIONS
    for i, option in ipairs(options) do
        if x >= option.x - option.w and x <= option.x + option.w and y >= option.y - 35 and y <= option.y + 35 then
            self.hoveredOption = i
        end
    end
end

function MainMenu:openSettings()
    self.settingsOpen = true
    self.settingsTime = 0
end

function MainMenu:closeSettings()
    self.settingsOpen = false
    self.settingsTime = 0
end

function MainMenu:mousepressed(x, y, button)
    if not self.active then
        return
    end
    if button == 1 then
        if not self.settingsOpen then
            if self.hoveredOption == 1 then
                self.active = false
                _GAME:start()
            elseif self.hoveredOption == 2 then
                self:openSettings()
            elseif self.hoveredOption == 3 then
                love.event.quit()
            end
        else
            if self.hoveredOption == 1 then
            elseif self.hoveredOption == 2 then
            elseif self.hoveredOption == 3 then
                _SETTINGS:toggleFullscreen()
            elseif self.hoveredOption == 4 then
                self:closeSettings()
            end
        end
    end
end

function MainMenu:draw()
    if not self.active then
        return
    end
    self:drawBackground()
    self:drawOptions()
    self:drawSettings()
    self:drawOptions(true)
    self:drawSelection()
end

function MainMenu:drawBackground()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(_MENU_BG)
end

function MainMenu:drawSelection()
    local options = self.settingsOpen and self.SETTINGS_OPTIONS or self.OPTIONS
    if self.hoveredOption then
        local option = options[self.hoveredOption]
        if not option.slider then
            local sx = option.x
            local sy = option.y - 10
            local sscale = 0.8
            local sprite = _SPRITES.menuSelect
            local img = sprite:getImage("select", math.floor(self.time * 10) % 10 + 1)
            local width = sprite.imageWidth
            local height = sprite.imageHeight
            love.graphics.setColor(0.3, 0.3, 0.7, 0.5)
            love.graphics.rectangle("fill", sx - width / 2 * 0.65 * option.w / 250, sy - height / 2 * 0.3 + 13, width * 0.65 * option.w / 250, height * 0.3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(img, sx, sy, 0, sscale * option.w / 250, sscale, width / 2, height / 2)
        end
    end
end

function MainMenu:drawOptions(settings)
    if settings and not self.settingsTime then
        return
    end
    local options = settings and self.SETTINGS_OPTIONS or self.OPTIONS
    local alpha = settings and _Utils.interpolate2Clamped(0, 1, 0.8, 1, self.settingsTime) or 1
    for i, option in ipairs(options) do
        love.graphics.setColor(0, 0, 0, alpha)
        self:drawLabel(option.label, option.x, option.y, option.font)
        love.graphics.setColor(1, 1, 1, alpha)
        if option.slider then
            local w, h = _MENU_SLIDER:getDimensions()
            local nw, nh = _MENU_SLIDER_NOTCH:getDimensions()
            love.graphics.draw(_MENU_SLIDER, option.x, option.y + 35, 0, 0.5, 0.5, w / 2, h / 2)
            love.graphics.draw(_MENU_SLIDER_NOTCH, option.x - option.w, option.y + 35, 0, 0.15, 0.15, nw / 2, nh / 2)
        end
        if option.checkbox then
            local checked = i == 3 and _SETTINGS.fullscreen
            local sprite = checked and _MENU_CHECKBOX_SELECTED or _MENU_CHECKBOX
            local w, h = sprite:getDimensions()
            love.graphics.draw(sprite, option.x - option.w + 30, option.y, 0, 0.15, 0.15, w / 2, h / 2)
        end
    end
end

function MainMenu:drawSettings()
    if not self.settingsTime then
        return
    end
    local sprite = _SPRITES.menuWindow
    local frame = self.settingsOpen and math.floor(self.settingsTime * 20) + 1 or 12 - math.floor(self.settingsTime * 20) + 1
    local img = frame <= 12 and sprite:getImage("open", frame) or sprite:getImage("idle", frame % 28 + 1)
    local width = sprite.imageWidth
    local height = sprite.imageHeight
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(img, 800, 450, 0, 0.5, 0.5, width / 2, height / 2)
    -- Labels
    local alpha = _Utils.interpolate2Clamped(0, 1, 0.8, 1, self.settingsTime)
    love.graphics.setColor(0, 0, 0, alpha)
    self:drawLabel("Settings", 800, 270)
end

function MainMenu:drawLabel(text, x, y, font)
    font = font or _FONT
    x = x - font:getWidth(text) / 2
    y = y - font:getHeight() / 2
    love.graphics.setFont(font)
    love.graphics.print(text, x, y)
end

return MainMenu