local TYPES = {
  button = 0,
  text = 1
}

if uimanager == nil then
  uimanager = {layer = {}, control = {}, keyboard = {}, keypress = {}}
end

uimanager.previousKey = "w"
uimanager.nextKey = "s"

local selection = nil
local hover = nil

--Input Types

local inputType = {x = 0, y = 0, width = 0, height = 0}

inputType.onPress = function(input)
end

inputType.onRelease = function(input)

end

inputType.onLostHoverWhileFocused = function(input)

end

inputType.enable = function(input)
  input.enabled = true
end

inputType.disable = function(input)
  input.enabled = true
end

inputType.update = function(dt)

end

inputType.draw = function(button)

end

inputType = {__index = inputType}

--Button Type
local buttonType = {title = "", activated = false, controlType = TYPES.button}
setmetatable(buttonType, inputType)

buttonType.onPress = function(input)
  input.focus = true
end

buttonType.onRelease = function(input)
  if input.activated then
    uimanager.loseFocus();
    if input.callback then
      input:callback()
    end
  end
end

buttonType.onLostHoverWhileFocused = function(input)
  if input.activated then
    uimanager.loseFocus();
  end
end

buttonType = {__index = buttonType}

-- Text input field
local textType = {title = "", activated = false, controlType = TYPES.text, value = ""}
setmetatable(textType, inputType)

textType.addCharacter= function(input, char)
  if input:validateCharacter() then
    input.value = input.value .. char
    input:callback(input.value)
  end
end

textType.deleteCharacter = function(input)
  input.value = string.sub(input.value, 1, #input.value - 1)
end

textType.validateCharacter = function(input, char)
  return true
end

textType = {__index = textType}

--Layers
uimanager.layer.DEFAULT_LAYER_NAME = "default"

local internal = {
  layers = {}
}

internal.sort = function(a, b)
  return a.priority < b.priority
end

uimanager.layer.newLayer = function(name, priority)
  if not priority then
    priority = 0
  end
  return {name = name, priority = priority, enabled = true, visible = true, controls = {}, visual = {}}
end

uimanager.layer.addLayer = function(name, priority)
  table.insert(internal.layers, uimanager.layer.newLayer(name, priority))
  table.sort(internal.layers, internal.sort)
end

uimanager.layer.removeLayer = function(name)
  local layer, i = uimanager.layer.getLayer(name)
  table.remove(internal.layers, i)
  table.sort(internal.layers, internal.sort)
end

uimanager.layer.getLayer = function(name)
  for i, layer in ipairs(internal.layers) do 
    if layer.name == name then
      return layer, i
    end
  end
end

uimanager.layer.enableLayer = function(name)
  local layer = uimanager.layer.getLayer(name)
  if layer then
    layer.visible = true
    layer.enabled = true
  end
end

uimanager.layer.disableLayer = function(name)
  local layer = uimanager.layer.getLayer(name)
  if layer then
    layer.enabled = false
  end
end

uimanager.layer.showLayer = function(name)
  local layer = uimanager.layer.getLayer(name)
  if layer then
    layer.visible = true
  end
end

uimanager.layer.hideLayer = function(name)
  local layer = uimanager.layer.getLayer(name)
  if layer then
    layer.visible = false
    layer.enabled = false
  end
end

uimanager.layer.addControl = function(name, control)
  local layer = uimanager.layer.getLayer(name)
  if layer then
    table.insert(layer.controls, control)
  end
end

uimanager.layer.addControls = function(name, controls)
  local layer = uimanager.layer.getLayer(name)
  if layer then
    for i, control in ipairs(controls) do
      table.insert(layer.controls, control)
    end
  end
end

uimanager.layer.addVisual = function(name, context, draw)
  local layer = uimanager.layer.getLayer(name)
  if layer then
    table.insert(layer.visual, {context = context, draw = draw})
  end
end

uimanager.layer.addVisuals = function(name, visuals)

end

uimanager.layer.clear = function(name)
  local layer = uimanager.layer.getLayer(name)
  layer.controls = {}
  layer.visual = {}
end


-- Create default layer
uimanager.layer.newLayer(uimanager.layer.DEFAULT_LAYER_NAME, 0)

-- Buttons
uimanager.control.newButton = function(options)
  local button = {}
  setmetatable(button, buttonType)
  
  for key, value in pairs(options) do
    button[key] = options[key]
  end
  return button
end

-- Text Input
uimanager.control.newTextInput = function(options)
  local textInput = {}
  setmetatable(textInput, textType)
  
  for key, value in pairs(options) do
    textInput[key] = options[key]
  end
  return textInput
end

--UI Manager Methods
uimanager.getHoveredControl = function()
  local x, y = love.mouse.getPosition()
  for i, layer in ipairs(internal.layers) do
    if layer.enabled then
      for j, control in ipairs(layer.controls) do
        if x > control.x and x < control.x + control.width and
          y > control.y and y < control.y + control.height and 
          control.activated then
          return control
        end
      end
    end
  end
  return nil
end

uimanager.selectPrevious = function()
  if selection then
    selection.focus = false
    for i, layer in ipairs(internal.layers) do
      if layer.enabled then
        local lastControl
        for j, control in ipairs(layer.controls) do
          if control == selection then
            if lastControl then
              selection = lastControl
              selection.focus = true
            else
              selection.focus = true
            end
          elseif control.activated then
            lastControl = control
          end
        end
      end
    end
  end
end

uimanager.selectNext = function()
  if selection then
    local foundSelection = false
    selection.focus = false
    for i, layer in ipairs(internal.layers) do
      if layer.enabled then
        local lastControl
        for j, control in ipairs(layer.controls) do
          if control.activated then
            lastControl = control
            if foundSelection then
              selection = control
              selection.focus = true
              return
            end
          end
          if control == selection then
            foundSelection = true
          end
        end
        selection = lastControl
        selection.focus = true
      end
    end
  else
    uimanager.selectFirst()
  end
end

uimanager.selectFirst = function()
  for i, layer in ipairs(internal.layers) do
    if layer.enabled then
      for j, control in ipairs(layer.controls) do
        if control.activated then
          selection = control
          selection.focus = true
          return
        end
      end
    end
  end
end

uimanager.loseFocus = function()
  if selection then
    selection.focus = false
  end
  selection = nil;
end

local viewType = {
  layerName = nil
}

viewType.load = function(this)
  uimanager.layer.clear(this.layerName)
  this:initialize()
  uimanager.layer.enableLayer(this.layerName)
end

viewType.initialize = function(this)
end

viewType.show = function(this)
  uimanager.layer.enableLayer(this.layerName);
end

viewType.hide = function(this)
  uimanager.layer.hideLayer(this.layerName);
end

viewType = {__index = viewType}

uimanager.newView = function(layerName, priority)
  uimanager.layer.addLayer(layerName, priority)
  local result = {layerName = layerName}
  setmetatable(result, viewType)
  return result
end

uimanager.update = function(dt)
  if hover then
    hover.hover = false
  end
  
  hover = uimanager.getHoveredControl()

  if hover then
    hover.hover = true
  end
  
  if selection and (not hover or hover ~= selection) then
    --selection.onLostHoverWhileFocused(selection)
  end
end

uimanager.draw = function()
  for i, layer in ipairs(internal.layers) do
    if layer.visible then
      for j, visual in ipairs(layer.visual) do
        visual.draw(visual.context)
      end
      
      for j, control in ipairs(layer.controls) do
        control:draw()
      end
    end
  end
end

uimanager.keypressed = function(key, isRepeat)
  if selection then
    if key == uimanager.previousKey then
      uimanager.selectPrevious()
    elseif key == uimanager.nextKey then
      uimanager.selectNext()
    elseif key == "return" then
      -- Press button
    elseif selection.controlType == TYPES.text then
      if key == "backspace" then
        selection:deleteCharacter()
      end
    end
  else
    if key == uimanager.nextKey then
     uimanager.selectNext()
    end
  end
end

uimanager.mousepressed = function(x, y, button)
  if hover then
    if selection then
      selection.focus = false
    end
    selection = hover;
    selection.focus = true
    hover:onPress()
  end
end

uimanager.mousereleased = function(x, y, button)
  if hover then
    if selection then
      selection.focus = false
    end
    
    if selection == hover then
      selection.focus = true
      hover:onRelease();
    else
      selection = hover;
      selection.focus = true
    end
  end
end

uimanager.textinput = function(key)
  if selection and selection.controlType == TYPES.text then
    selection:addCharacter(key)
  end
end