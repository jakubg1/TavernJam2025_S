local Class = require("com.class")

---@class MainMenu : Class
---@overload fun(): MainMenu
local MainMenu = Class:derive("MainMenu")

function MainMenu:new()
    self.OPTIONS = {
        {label = "Start", x = 800, y = 550, w = 250, sound = _RES.sounds.ui_select},
        {label = "Settings", x = 800, y = 620, w = 250, sound = _RES.sounds.ui_select},
        {label = "Quit", x = 800, y = 690, w = 250, sound = _RES.sounds.ui_back}
    }
    self.SETTINGS_OPTIONS = {
        {label = "Sound Volume", x = 800, y = 330, w = 125, font = _RES.fontSmall, slider = true, value = _SETTINGS.soundVolume, sound = _RES.sounds.ui_select},
        {label = "Music Volume", x = 800, y = 430, w = 125, font = _RES.fontSmall, slider = true, value = _SETTINGS.musicVolume, sound = _RES.sounds.ui_select},
        {label = "Full Screen", x = 800, y = 530, w = 150, font = _RES.fontSmall, checkbox = true, sound = _RES.sounds.ui_select},
        {label = "Back", x = 800, y = 630, w = 150, sound = _RES.sounds.ui_back}
    }
    self.hoveredOption = nil
    self.heldSlider = nil

    self.settingsOpen = false
    self.settingsTime = nil
    self.SETTINGS_CLOSE_TIME_MAX = 0.6

    self.active = false
    self.time = 0

    self.fadeoutTime = nil
    self.FADEOUT_TIME_MAX = 1.5

    self:start()
end

function MainMenu:update(dt)
    if not self.active then
        return
    end
    self:updateTime(dt)
    self:updateHover()
    self:updateHeldSlider()
    self:updateFadeout(dt)
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
    if self.fadeoutTime or self.settingsTime and self.settingsTime < 0.6 then
        return
    end
    local lastHovered = self.hoveredOption
    self.hoveredOption = nil
    local x, y = love.mouse.getPosition()
    local options = self.settingsOpen and self.SETTINGS_OPTIONS or self.OPTIONS
    for i, option in ipairs(options) do
        local bx, by, bw, bh = option.x - option.w, option.y - 35, option.w * 2, 70
        if option.slider then
            by, bh = option.y + 20, 32
        end
        if _Utils.isPosInBox(bx, by, bw, bh, x, y) then
            self.hoveredOption = i
        end
    end
    if lastHovered ~= self.hoveredOption then
        _RES.sounds.ui_hover:stop()
        _RES.sounds.ui_hover:play()
    end
end

function MainMenu:updateHeldSlider()
    if not self.heldSlider then
        return
    end
    local slider = self.heldSlider
    local x, y = love.mouse.getPosition()
    slider.value = _Utils.lerp2Clamped(0, 1, slider.x - slider.w, slider.x + slider.w, x)
    if self.heldSlider == self.SETTINGS_OPTIONS[1] then
        _SETTINGS:setSoundVolume(slider.value)
    elseif self.heldSlider == self.SETTINGS_OPTIONS[2] then
        _SETTINGS:setMusicVolume(slider.value)
    end
end

function MainMenu:updateFadeout(dt)
    if not self.fadeoutTime then
        return
    end
    self.fadeoutTime = math.min(self.fadeoutTime + dt, self.FADEOUT_TIME_MAX)
    if self.fadeoutTime == self.FADEOUT_TIME_MAX then
        self.active = false
        _GAME:startLevel(_RES.levels.picnic)
    end
end

function MainMenu:start()
    self.active = true
    _JUKEBOX:play("title")
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
    if not self.active or self.fadeoutTime then
        return
    end
    if button == 1 then
        local options = self.settingsOpen and self.SETTINGS_OPTIONS or self.OPTIONS
        if self.hoveredOption then
            local option = options[self.hoveredOption]
            option.sound:play()
        end
        if not self.settingsOpen then
            if self.hoveredOption == 1 then
                self.fadeoutTime = 0
            elseif self.hoveredOption == 2 then
                self:openSettings()
            elseif self.hoveredOption == 3 then
                love.event.quit()
            end
        else
            if self.hoveredOption == 1 then
                self.heldSlider = self.SETTINGS_OPTIONS[self.hoveredOption]
            elseif self.hoveredOption == 2 then
                self.heldSlider = self.SETTINGS_OPTIONS[self.hoveredOption]
            elseif self.hoveredOption == 3 then
                _SETTINGS:toggleFullscreen()
            elseif self.hoveredOption == 4 then
                self:closeSettings()
            end
        end
    end
end

function MainMenu:mousereleased(x, y, button)
    if button == 1 then
        if self.heldSlider then
            self.heldSlider = nil
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
    self:drawFadeout()
end

function MainMenu:drawBackground()
    local w, h = love.graphics.getDimensions()
    local sw, sh = _RES.images.menuBg:getDimensions()
    local scale = math.min(w / sw, h / sh)
    local x = (w - sw * scale) / 2
    local y = (h - sh * scale) / 2
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(_RES.images.menuBg, x, y, 0, scale)
    -- Text because the artist didn't include it in the image ..............................
    local TITLE = "Secret Identity: Let's Fight the Elements!"
    love.graphics.setColor(0, 0, 0, 0.5)
    self:drawLabel(TITLE, w / 2 + 5, 100 + 5)
    love.graphics.setColor(0, 0.5, 0)
    self:drawLabel(TITLE, w / 2, 100)
end

function MainMenu:drawSelection()
    if self.fadeoutTime then
        return
    end
    local options = self.settingsOpen and self.SETTINGS_OPTIONS or self.OPTIONS
    if self.hoveredOption then
        local option = options[self.hoveredOption]
        if option and not option.slider then
            local sx = option.x
            local sy = option.y - 10
            local sscale = 0.8
            local sprite = _RES.sprites.menuSelect
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
    local alpha = settings and _Utils.lerp2Clamped(0, 1, 0.8, 1, self.settingsTime) or 1
    for i, option in ipairs(options) do
        love.graphics.setColor(0, 0, 0, 0.5 * alpha)
        local shadowOffset = (option.font or _RES.font):getHeight() / 10
        self:drawLabel(option.label, option.x + shadowOffset, option.y + shadowOffset, option.font)
        if not settings then
            love.graphics.setColor(1, 1, 1, alpha)
        else
            love.graphics.setColor(0, 0, 0, alpha)
        end
        self:drawLabel(option.label, option.x, option.y, option.font)
        love.graphics.setColor(1, 1, 1, alpha)
        if option.slider then
            local w, h = _RES.images.menuSlider:getDimensions()
            local nw, nh = _RES.images.menuSliderNotch:getDimensions()
            love.graphics.draw(_RES.images.menuSlider, option.x, option.y + 35, 0, 0.5, 0.5, w / 2, h / 2)
            local notchX = _Utils.lerp(option.x - option.w, option.x + option.w, option.value)
            love.graphics.draw(_RES.images.menuSliderNotch, notchX, option.y + 35, 0, 0.15, 0.15, nw / 2, nh / 2)
        end
        if option.checkbox then
            local checked = i == 3 and _SETTINGS.fullscreen
            local sprite = checked and _RES.images.menuCheckboxSelected or _RES.images.menuCheckbox
            local w, h = sprite:getDimensions()
            love.graphics.draw(sprite, option.x - option.w + 30, option.y, 0, 0.15, 0.15, w / 2, h / 2)
        end
    end
end

function MainMenu:drawSettings()
    if not self.settingsTime then
        return
    end
    local sprite = _RES.sprites.menuWindow
    local frame = self.settingsOpen and math.floor(self.settingsTime * 20) + 1 or 12 - math.floor(self.settingsTime * 20) + 1
    local img = frame <= 12 and sprite:getImage("open", frame) or sprite:getImage("idle", frame % 28 + 1)
    local width = sprite.imageWidth
    local height = sprite.imageHeight
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(img, 800, 450, 0, 1, 1, width / 2, height / 2)
    -- Labels
    local alpha = _Utils.lerp2Clamped(0, 1, 0.8, 1, self.settingsTime)
    love.graphics.setColor(0, 0, 0, alpha)
    self:drawLabel("Settings", 800, 270)
end

function MainMenu:drawFadeout()
    if not self.fadeoutTime then
        return
    end
    local alpha = _Utils.lerp2Clamped(0, 1, 0, self.FADEOUT_TIME_MAX, self.fadeoutTime)
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", 0, 0, w, h)
end

function MainMenu:drawLabel(text, x, y, font)
    font = font or _RES.font
    x = x - font:getWidth(text) / 2
    y = y - font:getHeight() / 2
    love.graphics.setFont(font)
    love.graphics.print(text, x, y)
end

return MainMenu