local playfield = {
  background = nil,
  quad = nil
}

playfield.init = function()
  playfield.createBackground()
end

playfield.createBackground = function()

  playfield.quad = love.graphics.newQuad(0, 0, WORLD_SIZE.x, WORLD_SIZE.y, IMAGE_SIZE.x, IMAGE_SIZE.y)
  local backgroundData = love.image.newImageData(IMAGE_SIZE.x, IMAGE_SIZE.y)

  for i = 0, STARS, 1 do
    backgroundData:setPixel(math.random(0, IMAGE_SIZE.x - 1), math.random(0, IMAGE_SIZE.y - 1), 255, 255, 255, 255)
  end

  playfield.background = love.graphics.newImage(backgroundData)
  playfield.background:setWrap("repeat", "repeat")
end

playfield.draw = function()
  local x, y = myCamera:worldToCamera(0, 0)
  love.graphics.draw(playfield.background, playfield.quad, x, y)
end

return playfield