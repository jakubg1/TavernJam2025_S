local Class = require("com.class")

---@class DialogText : Class
---@overload fun(): DialogText
local DialogText = Class:derive("DialogText")

function DialogText:new()
    self.text = {{1, 1, 1}, "You're a ", {1, 1, 0}, "HUMAN", {1, 1, 1}, " now and you gotta fight like one!"}
    self.x = 100
    self.y = 100
    self.font = _FONT_TMP
end

function DialogText:draw()
	local x, y = love.mouse.getPosition()
	love.graphics.rectangle("line", self.x, self.y, x - self.x, y - self.y)
	love.graphics.printf(self.text, self.font, self.x, self.y, x - self.x)
end

return DialogText