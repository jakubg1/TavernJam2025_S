local Class = require("com.class")

---@class Player : Class
---@overload fun(): Player
local Player = Class:derive("Player")

---Constructs the Player.
function Player:new()
    -- Parameters
    self.SCALE = 0.8
    self.MAX_SPEED = 600
    self.MAX_ACC = 4000
    self.DRAG = 2000
    self.GRAVITY = 2500
    self.JUMP_SPEED = -1000
    self.JUMP_GRACE_TIME_MAX = 0.1

    -- State
    self.x, self.y = 100, 600
    self.width, self.height = 80 * self.SCALE, 160 * self.SCALE
    self.speedX, self.speedY = 0, 0
    self.accX, self.accY = 0, 0
    self.direction = "right"
    self.ground = nil
    self.jumpGraceTime = self.JUMP_GRACE_TIME_MAX

    -- Physics
    self.physics = {}
    self.physics.body = love.physics.newBody(_WORLD, self.x, self.y, "dynamic")
    self.physics.body:setFixedRotation(true)
    self.physics.shape = love.physics.newRectangleShape(self.width, self.height)
    self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)

    -- Appearance
    ---@alias SpriteState {start: integer, frames: integer, framerate: number, nextStates: string[]?, onFinish: string?}
    ---@type table<string, SpriteState>
    self.SPRITE_STATES = {
        idle = {start = 1, frames = 6, framerate = 15, nextStates = {"jump", "run", "fall"}},
        jump = {start = 17, frames = 9, framerate = 15, nextStates = {"fall", "land"}, onFinish = "fall"},
        fall = {start = 26, frames = 1, framerate = 15, nextStates = {"land", "run"}},
        land = {start = 27, frames = 2, framerate = 15, nextStates = {"idle", "run"}, onFinish = "idle"},
        run = {start = 33, frames = 16, framerate = 30, nextStates = {"idle", "jump", "fall"}}
    }
    self.sprites = _PLAYER_SPRITES
    self.state = self.SPRITE_STATES.idle
    self.stateFrame = 1
    self.stateTime = 0
end

---Updates the Player.
---@param dt number Time delta in seconds
function Player:update(dt)
    self:updatePhysics()
    self:move(dt)
    self:updateDirection()
    self:updateGravity(dt)
    self:updateJumpGrace(dt)
    self:updateSprite(dt)
end

function Player:updatePhysics()
    self.x, self.y = self.physics.body:getPosition()
    self.physics.body:setLinearVelocity(self.speedX, self.speedY)
end

function Player:move(dt)
    -- Calculate the current acceleration.
    local left = love.keyboard.isDown("a", "left")
    local right = love.keyboard.isDown("d", "right")
    if left and not right then
        self.accX = -self.MAX_ACC
    elseif right and not left then
        self.accX = self.MAX_ACC
    else
        self.accX = 0
        self:applyDrag(dt)
    end
    -- Apply the acceleration and cap the speed.
    self.speedX = math.min(math.max(self.speedX + self.accX * dt, -self.MAX_SPEED), self.MAX_SPEED)
end

function Player:applyDrag(dt)
    if self.speedX > 0 then
        self.speedX = math.max(self.speedX - self.DRAG * dt, 0)
    else
        self.speedX = math.min(self.speedX + self.DRAG * dt, 0)
    end
end

function Player:updateDirection()
    if self.accX > 0 then
        self.direction = "right"
    elseif self.accX < 0 then
        self.direction = "left"
    end
end

function Player:updateGravity(dt)
    if self.ground then
        return
    end
    self.speedY = self.speedY + self.GRAVITY * dt
end

function Player:updateJumpGrace(dt)
    if self.ground then
        self.jumpGraceTime = self.JUMP_GRACE_TIME_MAX
    else
        self.jumpGraceTime = self.jumpGraceTime - dt
    end
end

function Player:jump()
    if not self.ground and self.jumpGraceTime <= 0 then
        return
    end
    self.ground = nil
    self.speedY = self.JUMP_SPEED
    self.jumpGraceTime = 0
end

function Player:landOn(ground)
    self.ground = ground
    self.speedY = 0
end

function Player:updateSprite(dt)
    local running = self.speedX ~= 0 and (self.accX ~= 0 or math.abs(self.speedX) > 300)
    -- Change the state if we are not locked in the current one.
    if not self.ground then
        if self.speedY > 0 then
            self:setSpriteState("fall")
        else
            self:setSpriteState("jump")
        end
    else
        if running then
            self:setSpriteState("run")
        elseif self.state ~= self.SPRITE_STATES.land and self.state ~= self.SPRITE_STATES.fall then
            self:setSpriteState("idle")
        else
            self:setSpriteState("land")
        end
    end

    -- Update the animation state.
    self.stateTime = self.stateTime + dt
    while self.stateTime > 1 / self.state.framerate do
        -- Advance to next frame.
        self.stateTime = self.stateTime - 1 / self.state.framerate
        if self.stateFrame < self.state.start + self.state.frames - 1 then
            self.stateFrame = self.stateFrame + 1
        else
            -- Loop or change to other state.
            if self.state.onFinish then
                self:setSpriteState(self.state.onFinish)
            else
                self.stateFrame = self.state.start
            end
        end
    end
end

---Sets a new sprite state for this player, unless we already have that state.
---@param state string The new state.
function Player:setSpriteState(state)
    -- Cannot transition into the same state.
    if self.state == self.SPRITE_STATES[state] then
        return
    end
    -- Cannot transition into a state we can't transition to.
    if self.state.nextStates and not _Utils.isValueInTable(self.state.nextStates, state) then
        return
    end
    self.state = self.SPRITE_STATES[state]
    self.stateFrame = self.state.start
    self.stateTime = 0
end

---Executed when key is pressed.
---@param key string The keycode.
function Player:keypressed(key)
    if key == "w" or key == "up" then
        self:jump()
    end
end

---Executed when key is released.
---@param key string The keycode.
function Player:keyreleased(key)

end

function Player:beginContact(a, b, collision)
    if self.ground then
        return
    end
    local nx, ny = collision:getNormal()
    -- We can be either `a` or `b` in the collision.
    if a == self.physics.fixture then
        if ny > 0 then
            self:landOn(b)
        end
    elseif b == self.physics.fixture then
        if ny < 0 then
            self:landOn(a)
        end
    end
end

function Player:endContact(a, b, collision)
    if a == self.physics.fixture then
        if self.ground == b then
            self.ground = nil
        end
    elseif b == self.physics.fixture then
        if self.ground == a then
            self.ground = nil
        end
    end
end

---Draws the Player on the screen.
function Player:draw()
    love.graphics.setColor(1, 1, 1)
    self.sprites:drawFrame(self.stateFrame, self.x, self.y - 28, 0.5, 0.5, self.SCALE, self.direction == "left")

    love.graphics.rectangle("line", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
end

return Player