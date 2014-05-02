local camera = {
  focus = nil,
  box = {x = 0, y = 0, width = 0, height = 0}, --The player camera box
  position = {x = 0, y = 0}, --The current position the camera's view port is based on
  target = {x = 0, y = 0}, --The target position for the camera
  bounds = {x = 0, y = 0}, --The camera movement bounds
  offset = {x = 0, y = 0}, --The offset to translate from position to a viewport bounds
  wobble = {x = 0, y = 0, width = 0, height = 0},
  viewport = {x = 0, y = 0, width = 0, height = 0}, --The viewport defining the world coordinates of the upper left corner

  blockers = {},
  
  wobbleEaseDuration = {x = 1200/60, y = 1},
  currentWobbleEase = {tx = 0, ty = 0, dx = 0, dy = 0},

  --Easing functions not currently in use
  snapDistance = 0,
  isEasing = false,
  easeFrom = {x = 0, y = 0},
  easeTo = {x = 0, y = 0},
  easeDuration = 0,
  currentEaseDuration = 0,
  easeDistance = 0,
  mode = nil
}

camera.update = function(this, dt)
  if this.focus then
    this:pushCameraBox()
    this:mode()
  end
  this:moveCamera(dt)
end

camera.worldToCamera = function(this, x, y)
  return x - this.viewport.x, y - this.viewport.y
end

camera.screenToWorld = function(this, x, y)
  return x + this.viewport.x, y + this.viewport.y
end

--[[
--  Sets the object to focus on
--  focus: An object with a position
--]]
camera.setFocalEntity = function(this, focus)
  this.focus = focus
  local x, y = this:getFocusPosition()
  this.box.x = x - this.box.width / 2
  this.box.y = y - this.box.height / 2

end

--[[
--  Gets the current object being focused on
--]]
camera.setFocalPoint = function(this, x, y)
  this.focus = nil
  this.target.x = x
  this.target.y = y
end

--[[
--  Gets the position of the object being focused on.
--  O verride this
--]]
camera.getFocusPosition = function(this)
  return this.focus.position.x, this.focus.position.y
end

--[[
--  Pushes the player focused 'camera box' around
--  based on the player's movements. The camera box
--  is responsible for dictating the camera movement
--  while reducing camera jitter.
--]]
camera.pushCameraBox = function(this)
  local x, y = this:getFocusPosition()
  if x < this.box.x then
    this.box.x = x
  elseif x > this.box.x + this.box.width then
    this.box.x = x - this.box.width
  end

  if y < this.box.y then
    this.box.y = y
  elseif y > this.box.y + this.box.height then
    this.box.y = y - this.box.height
  end
end

--NOT IN USE
--[[
--  Target the camera's location, but snap the y axis to only move when
--  the player lands on a platform
--]]
camera.targetWithPlatformSnap = function(this)
  this.target.x = this.box.x

  --Snap platform movement
  if this.focus.standing == true then
    this.target.y = this.box.y
  end
end

--[[
--  Target the camera's location freely tracking the player
--]]
camera.targetFreely = function(this)
  local x1, x2, y1, y2, collision
  for name, blocker in ipairs(this.blockers) do
    collision, x1, x2, y1, y2 = this.resolveBlocker(blocker, this.box.x, this.target.y)
    if collision then
      --resolve collision here
      return
    end
  end
  this.target.x = this.box.x
  this.target.y = this.box.y
end

--[[
--  Restricts camera targeting to only change on the
--  x-axis
--]]
camera.targetXOnly = function(this)
  for name, blocker in ipairs(this.blockers) do
    if this.resolveBlocker(blocker, this.box.x, this.target.y) then
      return
    end
  end
  this.target.x = this.box.x
end

camera.wobbleCamera = function(this, dt, x, y)
  --Camera is moving left
  if x > this.position.x then
    if this.offset.x > this.wobble.x then
      if this.currentWobbleEase.dx < 0 then
        this:wobbleX(dt)
      else
        this:resetXWobble(this.wobble.x - this.offset.x)
        this:wobbleX(dt)
      end
    end
  elseif x < this.position.x then
    if this.offset.x < this.wobble.x + this.wobble.width then
      if this.currentWobbleEase.dx > 0 then
        this:wobbleX(dt)
      else
        this:resetXWobble(this.wobble.x + this.wobble.width - this.offset.x)
        this:wobbleX(dt)
      end
    end
  elseif this.currentWobbleEase.tx > 0 then
    if dt > this.currentWobbleEase.tx then
      this.currentWobbleEase.tx = this.currentWobbleEase.tx - dt
    else 
      this.currentWobbleEase.tx = 0
    end
  end
end

camera.resetXWobble = function(this, x)
  this.currentWobbleEase.dx = x
  this.currentWobbleEase.tx = 0
end

camera.wobbleX = function(this, dt)
  this.currentWobbleEase.tx = this.currentWobbleEase.tx + dt
  if this.currentWobbleEase.tx > this.wobbleEaseDuration.x then
    this.currentWobbleEase.tx = this.wobbleEaseDuration.x
  end

  local result = this.easeIn(this.currentWobbleEase.tx, 0, this.currentWobbleEase.dx, this.wobbleEaseDuration.x)
  this.offset.x = this.offset.x + result

  if this.currentWobbleEase.tx == this.wobbleEaseDuration.x then
    this.resetXWobble(0)
  end
end


camera.resetYWobble = function(this)

end


camera.wobbleY = function(this)

end

--[[
--  Translates a movement in the camera target to a resulting
--  camera viewport
--]]
camera.moveCamera = function(this, dt)
  --this:moveWithBounds(dt, this.target.x, this.target.y)
  this:easeCamera(dt)
end

camera.moveWithBounds = function(this, dt, x, y)
  this:wobbleCamera(dt, x, y)

  this.position.x = math.floor(x)
  this.position.y = math.floor(y)

  this.viewport.x = this.position.x - this.offset.x
  this.viewport.y = this.position.y - this.offset.y
  this:checkViewportConstraints()
end

camera.checkViewportConstraints = function(this)
  if this.viewport.x < 0 then
    this.viewport.x = 0
  elseif this.viewport.x + this.viewport.width > this.bounds.x then
    this.viewport.x = this.bounds.x - this.viewport.width
  end

  if this.viewport.y < 0 then
    this.viewport.y = 0
  elseif this.viewport.y + this.viewport.height > this.bounds.y then
    this.viewport.y = this.bounds.y - this.viewport.height
  end
end

camera.resolveBlocker = function(this, blocker, x, y, vx, vy)
  local x1 = blocker.x - (x - this.offset.x + this.viewport.width)
  local x2 = (this.target.x - this.offset.x) - (blocker.x + blocker.width)

  local y1 = blocker.y - (y - this.offset.y + this.viewport.height)
  local y2 = (this.target.y - this.offset.y) - (blocker.y + blocker.height)
  return x1 < 0 and x2 < 0 and y1 < 0 and y2 < 0, 
         x1, x2, y1, y2

  --[[if x1 < 0 and x2 < 0 and
     y1 < 0 and y2 < 0 then
    --If moving along the x axis doesn't cause collision with blocker
    --then do it
    if x1 + vx > 0 or x2 - vx > 0 then
      this.viewport.x = this.viewport.x + vx
    --Otherwise move up next to the blocker
    elseif vx > 0 then
      this.viewport.x = blocker.x - this.viewport.width
    else
      this.viewport.x = blocker.x + blocker.width
    end

    --If moving along the y axis doesn't cause collision with blocker
    --then do it
    if y1 + vy > 0 or y2 - vy > 0 then
      this.viewport.y = this.viewport.y + vy
    --Otherwise move up next to the blocker
    elseif vy > 0 then
      this.viewport.y = blocker.y - this.viewport.height
    else
      this.viewport.y = blocker.x + blocker.height
    end
  end]]--
end

--[[
--  Move the camera with potential easing functionality.
--]]
camera.easeCamera = function(this, dt)
  local dsquared = (this.target.x - this.position.x)^2 + (this.target.y - this.position.y)^2
  if this.isEasing then
    this.currentEaseDuration = this.currentEaseDuration + dt
    if (this.target.x - this.easeTo.x)^2 + (this.target.y - this.easeTo.y)^2 > this.snapDistance^2 then
      this:startEase(dt, math.sqrt(dsquared))
      local x, y = this:getEasePosition(this.currentEaseDuration)
      this:moveWithBounds(dt, x, y)
    elseif this.currentEaseDuration >= this.easeDuration then
      this.isEasing = false
      --Move camera normally
      this:moveWithBounds(dt, this.target.x, this.target.y)
    else
      local x, y = this:getEasePosition(this.currentEaseDuration)
      this:moveWithBounds(dt, x, y)
    end
  else
    if dsquared > this.snapDistance * this.snapDistance then
      this:startEase(dt, math.sqrt(dsquared))
      local x, y = this:getEasePosition(this.currentEaseDuration)
      this:moveWithBounds(dt, x, y)
    else
      this:moveWithBounds(dt, this.target.x, this.target.y)
    end
  end
end

camera.startEase = function(this, dt, distance)
  this.isEasing = true
  this.currentEaseDuration = dt
  this.easeFrom.x = this.position.x
  this.easeFrom.y = this.position.y
  this.easeTo.x = this.target.x
  this.easeTo.y = this.target.y
  this.easeDistance = distance
end

camera.getEasePosition = function(this, time)
  local result = this.easeOut(time, 0, this.easeDistance, this.easeDuration)
  local pct = result / this.easeDistance 
  return this.easeFrom.x + pct * (this.easeTo.x - this.easeFrom.x), this.easeFrom.y + pct * (this.easeTo.y - this.easeFrom.y)
end

--[[
--  Exponential easing function
--  dt = amount of time towards completion
--  start = start value
--  change = ending target - start value
--  duration = total time of easing
--]]
camera.easeOut = function (time, start, change, duration)
  return change * ( -1 * 2^(-10 * time/duration ) + 1 ) + start;
end

camera.easeIn = function(time, start, change, duration)
  local pct = time / duration
  return change*pct*pct + start;
  --return change * 2^(10 * (time/duration - 1) ) + start;
end

camera.draw = function(this)
  local currentPointSize = love.graphics.getPointSize()
  love.graphics.setPointSize(4)
  local currentColor = {}
  currentColor[1], currentColor[2], currentColor[3], currentColor[4] = love.graphics.getColor()

  love.graphics.setColor({255, 0, 0, 255})
  local x, y = this:worldToCamera(0, 0)  
  love.graphics.rectangle("line", x, y, this.bounds.x, this.bounds.y)

  love.graphics.setColor({0, 0, 255, 255})
  local x, y = this:worldToCamera(this.box.x, this.box.y)
  love.graphics.rectangle("line", x, y, this.box.width, this.box.height)

  love.graphics.setColor({255, 0, 0, 255})
  x, y = this:worldToCamera(this.position.x, this.position.y)
  love.graphics.point(x, y)

  love.graphics.setColor(currentColor)
  love.graphics.setPointSize(love.graphics.getPointSize())

  love.graphics.print("px: " .. this.position.x .. " py: " .. this.position.y, 5, 5)
  love.graphics.print("ox: " .. this.offset.x .. " oy: " .. this.offset.y, 5, 15)
  if this.isEasing then
    love.graphics.print("EASING", 5, 30)
  else
    love.graphics.print("NOT EASING", 5, 30)
  end
end

return camera