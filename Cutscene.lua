local Class = require("com.class")

---@class Cutscene : Class
---@overload fun(): Cutscene
local Cutscene = Class:derive("Cutscene")

function Cutscene:new()
    self.cutscene = nil
    self.line = nil
    self.font = _FONT

    self.DIALOG = {}
    self.DIALOG.image = _DIALOG
    self.DIALOG.arrowImage = _DIALOG_ARROW
    self.DIALOG.x = 500
    self.DIALOG.y = 100
    self.DIALOG.marginX = 35
    self.DIALOG.marginY = 20
    self.DIALOG.width = self.DIALOG.image:getWidth() - self.DIALOG.marginX * 2

    self.TRANSITION_TIME_MAX = 0.2
    self.TEXT_TIME_OFFSET = 0.5
    self.TEXT_CPS = 40

    self.transitionTime = nil
    self.fadingOut = false
    self.lineTime = 0
    self.maxTextTime = 0
end

function Cutscene:update(dt)
    self:updateTransition(dt)
    self:updateTypeIn(dt)
end

function Cutscene:updateTransition(dt)
    if not self.transitionTime then
        return
    end
    self.transitionTime = self.transitionTime + dt
    if self.transitionTime >= self.TRANSITION_TIME_MAX then
        self.transitionTime = nil
        if self.fadingOut then
            self.cutscene = nil
            -- first level -> move to second one
            if _GAME.level.data == _LEVEL_DATA then
                _GAME:startLevel(_LEVEL_WT_DATA)
            end
        end
    end
end

function Cutscene:updateTypeIn(dt)
    self.lineTime = self.lineTime + dt
end

function Cutscene:startCutscene(cutscene)
    self.cutscene = cutscene
    self.line = 0
    self.transitionTime = 0
    self.fadingOut = false
    self:nextLine()
end

function Cutscene:skipOrNext()
    if self.lineTime > self.maxTextTime then
        self:nextLine()
    else
        self:skip()
    end
end

function Cutscene:skip()
    self.lineTime = self.maxTextTime
end

function Cutscene:nextLine()
    if self.line > #self.cutscene then
        return
    end
    self.line = self.line + 1
    if self.line > #self.cutscene then
        self.fadingOut = true
        self.transitionTime = 0
        return
    end
    local line = self.cutscene[self.line]
    local prevLine = self.cutscene[self.line - 1]
    local sameCharacter = prevLine and line.img == prevLine.img and line.side == prevLine.side
    self.lineTime = sameCharacter and self.TEXT_TIME_OFFSET or 0
    self.maxTextTime = _Utils.ctextLen(self.cutscene[self.line].text) / self.TEXT_CPS + self.TEXT_TIME_OFFSET
end

function Cutscene:isActive()
    return self.cutscene ~= nil
end

function Cutscene:keypressed(key)
    if key == "space" or key == "return" or key == "z" then
        self:skipOrNext()
    end
end

function Cutscene:mousepressed(x, y, button)
    if button == 1 then
        self:skipOrNext()
    end
end

function Cutscene:draw()
    if not self.cutscene then
        return
    end
    local w, h = love.graphics.getDimensions()
    -- Background
    love.graphics.setColor(0, 0, 0, 0.5)
    if self.transitionTime then
        local t = self.transitionTime / self.TRANSITION_TIME_MAX
        if not self.fadingOut then
            love.graphics.rectangle("fill", 0, h / 2 * (1 - t), w, h * t)
        else
            love.graphics.rectangle("fill", 0, h / 2 * t, w, h * (1 - t))
        end
    else
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
    -- Prep for animation
    local line = self.cutscene[self.line]
    local prevLine = self.cutscene[self.line - 1]
    local sameCharacter = line and prevLine and line.img == prevLine.img and line.side == prevLine.side
    local t = (1 - math.cos(math.min(math.max(self.lineTime / 0.3, 0), 1) * math.pi)) / 2
    -- Text
    if line then
        local dialog = self.DIALOG
        local dialogThisX = line.side == "right" and dialog.x or w - dialog.x
        local dialogPrevX = prevLine and (prevLine.side == "right" and dialog.x or w - dialog.x) or dialogThisX
        local dialogX = _Utils.interpolateClamped(dialogPrevX, dialogThisX, t)
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.draw(dialog.image, dialogX, dialog.y, 0, 1, 1, dialog.image:getWidth() / 2)
        love.graphics.setColor(1, 1, 1)
        local text = _Utils.ctextSub(line.text, 1, math.floor(math.max(self.lineTime - self.TEXT_TIME_OFFSET, 0) * self.TEXT_CPS))
        local textX = dialogX + dialog.marginX - dialog.image:getWidth() / 2
        love.graphics.printf(text, self.font, textX, dialog.y + dialog.marginY, dialog.width)
        -- "Complete" arrow
        if self.lineTime > self.maxTextTime then
            love.graphics.draw(self.DIALOG.arrowImage, dialogX + 310, dialog.y + 200 + math.sin(self.lineTime * 3) * 5)
        end
    end
    -- Character
    local tOut = sameCharacter and 1 or -math.cos(math.min(math.max(self.lineTime / 0.5, 0), 1) * math.pi / 2 + math.pi / 2)
    if line then
        local imgOffset = _Utils.interpolateClamped(-600, 400, tOut)
        local imgX = line.side == "left" and imgOffset or w - imgOffset
        local imgScaleX = line.side == "left" and 1 or -1
        love.graphics.draw(line.img, imgX, 0, 0, imgScaleX, 1, line.img:getWidth() / 2)
    end
    -- Previous character
    if prevLine and tOut < 1 then
        local prevImgOffset = _Utils.interpolateClamped(400, -600, tOut)
        local prevImgX = prevLine.side == "left" and prevImgOffset or w - prevImgOffset
        local prevImgScaleX = prevLine.side == "left" and 1 or -1
        love.graphics.draw(prevLine.img, prevImgX, 0, 0, prevImgScaleX, 1, prevLine.img:getWidth() / 2)
    end
end

return Cutscene