local entity = {
  position = {x = 10, y = 10},
  velocity = {x = 0, y = 0}
}

entity.update = function(dt)
  entity.position.x = entity.position.x + entity.velocity.x * dt
  entity.position.y = entity.position.y + entity.velocity.y * dt
end

entity.draw = function()
  local x, y = myCamera:worldToCamera(entity.position.x, entity.position.y)
  love.graphics.rectangle("fill", x, y, 8, 8)
end

return entity