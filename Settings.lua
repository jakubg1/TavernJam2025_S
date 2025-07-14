local Class = require("com.class")

---@class Settings : Class
---@overload fun(): Settings
local Settings = Class:derive("Settings")

function Settings:new()
	self.sfxVolume = 0.5
	self.musicVolume = 0.5
	self.fullscreen = false
end

function Settings:toggleFullscreen()
    self.fullscreen = not self.fullscreen
    love.window.setFullscreen(self.fullscreen)
end

return Settings