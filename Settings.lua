local Class = require("com.class")

---@class Settings : Class
---@overload fun(): Settings
local Settings = Class:derive("Settings")

function Settings:new()
	self.soundVolume = 0.5
	self.musicVolume = 0.5
	self.fullscreen = false
end

function Settings:setSoundVolume(volume)
	self.soundVolume = volume
	_RES:setSoundVolume(volume)
end

function Settings:setMusicVolume(volume)
	self.musicVolume = volume
	_JUKEBOX:setVolume(volume)
end

function Settings:setFullscreen(fullscreen)
    self.fullscreen = fullscreen
    love.window.setFullscreen(self.fullscreen)
end

function Settings:toggleFullscreen()
	self:setFullscreen(not self.fullscreen)
end

function Settings:save()
	_Utils.saveJson("settings.json", _SETTINGS:serialize())
end

function Settings:load()
	local data = _Utils.loadJson("settings.json")
	if data then
		self:deserialize(data)
	end
end

function Settings:serialize()
	return {
		soundVolume = self.soundVolume,
		musicVolume = self.musicVolume,
		fullscreen = self.fullscreen
	}
end

function Settings:deserialize(t)
	self:setSoundVolume(t.soundVolume)
	self:setMusicVolume(t.musicVolume)
	self:setFullscreen(t.fullscreen)
end

return Settings