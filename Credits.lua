local Class = require("com.class")

---@class Credits : Class
---@overload fun(): Credits
local Credits = Class:derive("Credits")

function Credits:new()
    self.TEXT = [[You're a real hero!

Thank you for playing our game! Our team of 3 worked really hard in only one week to present this to you! 

If you enjoyed our this game, please bookmark this page and follow our socials for updates! 

We weren't able to include lot of what we've had planned, but throughout this month we'll be including a lot more including; more enemies, voice acting, more levels, music, boss fight and more!

So if this is something you'd like to play, please leave us some good feedback, suggestions and share with your friends!

Thank you again!

Art - @fs3k_art
Coding - @jakubg1
Music - @UltraLee]]

    self.active = false
end

function Credits:update(dt)
    
end

function Credits:mousepressed(x, y, button)
    if button == 1 then
        self.active = false
        _MENU:start()
    end
end

function Credits:start()
    self.active = true
    _JUKEBOX:play("credits")
end

function Credits:draw()
    if not self.active then
        return
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(_FONT)
    love.graphics.print("Congratulations!", 650, 20)
    love.graphics.setFont(_FONT_S)
    love.graphics.printf(self.TEXT, 200, 150, 1200)
end

return Credits