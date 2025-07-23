local Class = require("com.class")

---@class Jukebox : Class
---@overload fun(): Jukebox
local Jukebox = Class:derive("Jukebox")

function Jukebox:new()
	self.MUSIC = {
		title = love.audio.newSource("assets/Music/title.mp3", "stream"),
		picnic = love.audio.newSource("assets/Music/picnic.mp3", "stream"),
		water = love.audio.newSource("assets/Music/water.mp3", "stream"),
		credits = love.audio.newSource("assets/Music/credits.mp3", "stream")
	}
end

function Jukebox:setVolume(volume)
    for name, music in pairs(self.MUSIC) do
        music:setVolume(volume)
    end
end

function Jukebox:stop()
    for name, music in pairs(self.MUSIC) do
        music:stop()
    end
end

function Jukebox:play(name)
    self:stop()
    self.MUSIC[name]:setLooping(true)
    self.MUSIC[name]:play()
end

return Jukebox