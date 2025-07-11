local Class = require("com.class")

---@class DialogText : Class
---@overload fun(): DialogText
local DialogText = Class:derive("DialogText")

function DialogText:new()
    self.cutscene = {
        {text = {{1, 1, 1}, "You're a ", {1, 1, 0}, "HUMAN", {1, 1, 1}, " now and you gotta fight like one!"}, img = _SPRITES.player.states.idle[1], side = "right"},
        {text = {{1, 1, 0}, "Congratulations! ", {1, 1, 1}, "You've beaten the first level!"}, img = _SPRITES.player.states.jump[5], side = "left"},
        {text = {{1, 1, 1}, "Now you can go to"}, img = _SPRITES.player.states.jump[5], side = "left"}
    }
    self.line = 1
    self.font = _FONT_TMP

    self.DIALOG = {}
    self.DIALOG.image = _DIALOG
    self.DIALOG.arrowImage = _DIALOG_ARROW
    self.DIALOG.x = 500
    self.DIALOG.y = 100
    self.DIALOG.marginX = 35
    self.DIALOG.marginY = 20
    self.DIALOG.width = self.DIALOG.image:getWidth() - self.DIALOG.marginX * 2

    self.TEXT_TIME_OFFSET = 0.5
    self.TEXT_CPS = 40

    self.lineTime = 0
    self.maxTextTime = 0
end

function DialogText:update(dt)
    self:updateTypeIn(dt)
end

function DialogText:updateTypeIn(dt)
    self.lineTime = self.lineTime + dt
end

function DialogText:skip()
    self.lineTime = self.maxTextTime
end

function DialogText:nextLine()
    self.line = self.line % #self.cutscene + 1
    local line = self.cutscene[self.line]
    local prevLine = self.cutscene[(self.line - 2) % #self.cutscene + 1]
    local sameCharacter = line.img == prevLine.img and line.side == prevLine.side
    self.lineTime = sameCharacter and self.TEXT_TIME_OFFSET or 0
    self.maxTextTime = _Utils.ctextLen(self.cutscene[self.line].text) / self.TEXT_CPS + self.TEXT_TIME_OFFSET
end

function DialogText:mousepressed(x, y, button)
    if button == 1 then
        if self.lineTime > self.maxTextTime then
            self:nextLine()
        else
            self:skip()
        end
    end
end

function DialogText:draw()
    local w, h = love.graphics.getDimensions()
    -- Background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)
    -- Prep for animation
    local line = self.cutscene[self.line]
    local prevLine = self.cutscene[(self.line - 2) % #self.cutscene + 1]
    local sameCharacter = line.img == prevLine.img and line.side == prevLine.side
    local t = (1 - math.cos(math.min(math.max(self.lineTime / 0.3, 0), 1) * math.pi)) / 2
    -- Text
    local dialog = self.DIALOG
    local dialogThisX = line.side == "right" and dialog.x or w - dialog.x
    local dialogPrevX = prevLine.side == "right" and dialog.x or w - dialog.x
    local dialogX = _Utils.interpolateClamped(dialogPrevX, dialogThisX, t)
    love.graphics.draw(dialog.image, dialogX, dialog.y, 0, 1, 1, dialog.image:getWidth() / 2)
    love.graphics.setColor(1, 1, 1)
    local text = _Utils.ctextSub(line.text, 1, math.floor(math.max(self.lineTime - self.TEXT_TIME_OFFSET, 0) * self.TEXT_CPS))
    local textX = dialogX + dialog.marginX - dialog.image:getWidth() / 2
	love.graphics.printf(text, self.font, textX, dialog.y + dialog.marginY, dialog.width)
    -- "Complete" arrow
    if self.lineTime > self.maxTextTime then
        love.graphics.draw(self.DIALOG.arrowImage, dialogX + 310, dialog.y + 200 + math.sin(self.lineTime * 3) * 5)
    end
    -- Character
    local tOut = sameCharacter and 1 or -math.cos(math.min(math.max(self.lineTime / 0.5, 0), 1) * math.pi / 2 + math.pi / 2)
    local imgOffset = _Utils.interpolateClamped(-600, 400, tOut)
    local imgX = line.side == "left" and imgOffset or w - imgOffset
    local imgScaleX = line.side == "left" and 1 or -1
    love.graphics.draw(line.img, imgX, 0, 0, imgScaleX, 1, line.img:getWidth() / 2)
    -- Previous character
    if tOut < 1 then
        local prevImgOffset = _Utils.interpolateClamped(400, -600, tOut)
        local prevImgX = prevLine.side == "left" and prevImgOffset or w - prevImgOffset
        local prevImgScaleX = prevLine.side == "left" and 1 or -1
        love.graphics.draw(prevLine.img, prevImgX, 0, 0, prevImgScaleX, 1, prevLine.img:getWidth() / 2)
    end
end

return DialogText