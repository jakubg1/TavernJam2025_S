local Class = require("com.class")

---@class Credits : Class
---@overload fun(): Credits
local Credits = Class:derive("Credits")

function Credits:new()
    self.TEXT = [[Yes, that's it! But why was this game abnormally short?! It almost feels like it's a bad joke.

It pretty much boils down to the horrible team mismanagement and bad prioritizing. We have made a lot of enemies which behave and attack in completely different ways. ...But then we forgot about the actual levels. This is a mistake we could've rectified earlier and I should have been more clear to the team early on that we needed actual levels. Unfortunately by the time we've had our first level finished, it was too late. I crunched almost the entire last day fixing bugs and adding literally ANY game progression. And yet the build I've uploaded a few minutes before the deadline was so scuffed that it didn't even launch... But if you're reading this, hey, at least there was SOMETHING, lol! And yes, I am still pissed about how much time we've dedicated to enemies that ultimately never made it into the game.
Even though I am not happy with the result, I want to say THANK YOU to both of my teammates, @fs3k. for fantastic sprites and @UltraLee for fantastic music. This is my first ever team-made jam game experiment, and I've still learned a lot while coding this project. I've also learned what NOT to do when making a jam game, and will stress any issues more boldly if the team happens to have different priorities than the base game in the future games.
I am also sincerely sorry to any Voice Actors for not including their work in the jam. It was impossible for me to fit in the timeline considering how much of the basic game did not exist literally 48 hours ago.
I am not even looking forward to seeing the ratings of this game. We just did poorly in the end. There is no game.

Despite all of this, I hope you enjoyed the game, er, PROGRAM however buggy and incomplete it was.
We will be updating this project with more content, so the voiceovers, enemies, bosses and more will eventually be added to this game. We will do this most likely next week (starting July 21st), because we are just so tired right now. We need to rest.
Thank you so much for your understanding and support!

Click to go back to main menu.]]

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
    love.graphics.setFont(_FONT)
    love.graphics.print("Congratulations!", 650, 20)
    love.graphics.setFont(_FONT_S)
    love.graphics.printf(self.TEXT, 200, 150, 1200)
end

return Credits