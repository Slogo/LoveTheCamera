myCamera = require("libs/lovethecamera")
require("libs/uimanager")

local playfield = require("libs/playfield")
local entity = require("entity")

CAMERA_OFFSET = {x = 9 * love.window.getWidth() / 20, y = love.window.getHeight() / 2}
CAMERA_WOBBLE = {x = love.window.getWidth() / 3, y = love.window.getHeight() / 3,
                 width = 9*love.window.getWidth() / 20, height = 2*love.window.getHeight() / 20}
CAMERA_BOX_SIZE = {width = 92, height = 92}

SNAP_DISTANCE = 5
EASE_DURATION = 60 / 60

WORLD_SIZE = {x = 1600, y = 1200}
IMAGE_SIZE = {x = 800, y = 600}
STARS = 1000

love.load = function()
  playfield.init()
  myCamera.viewport.width = love.window.getWidth()
  myCamera.viewport.height = love.window.getHeight()
  myCamera.bounds.x = WORLD_SIZE.x
  myCamera.bounds.y = WORLD_SIZE.y
  myCamera.offset.x = CAMERA_OFFSET.x
  myCamera.offset.y = CAMERA_OFFSET.y
  myCamera.wobble.x = CAMERA_WOBBLE.x
  myCamera.wobble.y = CAMERA_WOBBLE.y
  myCamera.wobble.width = CAMERA_WOBBLE.width
  myCamera.wobble.height = CAMERA_WOBBLE.height
  myCamera.box.width = CAMERA_BOX_SIZE.width
  myCamera.box.height = CAMERA_BOX_SIZE.height
  myCamera.snapDistance = SNAP_DISTANCE
  myCamera.easeDuration = EASE_DURATION
  myCamera.mode = myCamera.targetFreely

  myCamera:setFocalEntity(entity)
end

love.update = function(dt)
  entity.update(dt)
  myCamera:update(dt)
end

love.draw = function()
  playfield.draw()
  entity.draw(dt)
  myCamera:draw()
  uimanager.draw()
end

love.mousepressed = function(x, y, button)
  uimanager.mousepressed(x, y, button)
end

love.mousereleased = function(x, y, button)
  local wx, wy = myCamera:screenToWorld(x, y)
  --myCamera:setFocalPoint(wx, wy)
  uimanager.mousereleased(x, y, button)
end

love.keypressed = function(key)
  if key == "a" then
    entity.velocity.x = -64
  elseif key == "d" then
    entity.velocity.x = 64
  end

  if key == "w" then
    entity.velocity.y = -64
  elseif key == "s" then
    entity.velocity.y = 64
  end

  uimanager.keypressed(key)
end

love.keyreleased = function(key)
  if key == "a" or key == "d" then
    entity.velocity.x = 0
  end

  if key == "w" or key == "s" then
    entity.velocity.y = 0
  end
end

love.textinput = function(text)
  uimanager.textinput(text)
end