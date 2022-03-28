require "Utils"
require "Cursors"
require "Constants"
require "Client"


local buttons = { }
local textFields = { }

local focusedTextField = nil

local hovered = false
local imageScale = 900 / 1080

local host = nil


local function Exit()
  if host then host:destroy() end
  switchToScene(mainMenuScene)
end


local function onUpdate(dt)
  local mousePoint = Vector(love.mouse.getPosition()) - winOffset
  local anyButtonHovered = false
  local anyTextFieldHovered = false

  setUnhovered(buttons)
  setUnhovered(textFields)

  local button = getIntersected(mousePoint, buttons)

  if button then
    button.hovered = true
    anyButtonHovered = true
  end

  for _, textField in ipairs(textFields) do
    textField.hovered = pointInRect(mousePoint, textField)
    anyTextFieldHovered = anyTextFieldHovered or textField.hovered
  end

  anyTextFieldHovered = getIntersected(mousePoint, textFields)

  if anyButtonHovered and not hovered then
    love.mouse.setCursor(Cursors.hand)
  elseif anyTextFieldHovered and not hovered then
    love.mouse.setCursor(Cursors.ibeam)
  elseif not anyButtonHovered and not anyTextFieldHovered and hovered then
    love.mouse.setCursor(Cursors.arrow)
  end

  hovered = anyButtonHovered or anyTextFieldHovered
end


local function unfocus()
  if focusedTextField then
    focusedTextField.focused = false
    focusedTextField = nil
  end
end


local function onSwitch()
  hovered = false

  host = nil
  focusedTextField = nil

  for _, textField in ipairs(textFields) do
    textField.focused = false
    textField.text = ""
  end

  unfocus()

  host = enet.host_create()
end


local function onDraw()
  -- draw background image
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(backgroundImage, 0, 0, 0, imageScale, imageScale)

  local halfHeight = mainFont:getHeight() / 2

  -- draw buttons and their text with corresponding colors
  for _, button in ipairs(buttons) do
    love.graphics.setColor(buttonColors[button.hovered])
    love.graphics.rectangle("fill",
                            button.pos.x, button.pos.y,
                            button.size.x, button.size.y)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.printf(button.text, button.pos.x, button.pos.y + button.size.y / 2 - halfHeight,
                         button.size.x, "center")
  end

  -- draw text fields
  for _, textField in ipairs(textFields) do
    love.graphics.setColor(textFieldColors[textField.focused])
    love.graphics.rectangle("fill",
                            textField.pos.x, textField.pos.y,
                            textField.size.x, textField.size.y)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.printf(textField.text, textField.pos.x, textField.pos.y + textField.size.y / 2 - halfHeight,
                         textField.size.x, "left")
  end
end


local function onTextInput(text)
  if focusedTextField then
    focusedTextField.ontext(focusedTextField, text)
  end
end


local function onIPInput(txtfld, text)
  if (isDigit(text) or text == ".") and (#txtfld.text < 15) then
    txtfld.text = txtfld.text .. text
  end
end


local function onPortInput(txtfld, text)
  if isDigit(text) and (#txtfld.text < 5) then
    txtfld.text = txtfld.text .. text
  end
end


local function deleteChar()
  txtfld = focusedTextField

  if txtfld and (#txtfld.text ~= 0) then
    txtfld.text = string.sub(txtfld.text, 1, (#txtfld.text - 1))
  end
end


local function onJoin()
  local ipString = textFields[1].text
  local portString = textFields[2].text

  local server = host:connect(ipString .. ":" .. portString, 2)

  local event = host:service(2000)

  if event and (event.type == "connect") then
    print("connected")
    host:service()

    switchToScene(clientScene, host, event.peer)
  end
end


local function onResize()
  for _, button in ipairs(buttons) do
    button.pos = button.unpos % trueSize
    button.size = button.unsize % trueSize
  end

  for _, textField in ipairs(textFields) do
    textField.pos = textField.unpos % trueSize
    textField.size = textField.unsize % trueSize
  end

  imageScale = trueSize.y / 1080
end


local function onKeyPressed(key, scancode, isrepeat)
  if scancode == "escape" then
    Exit()
  elseif scancode == "backspace" then
    deleteChar()
  elseif scancode == "return" then
    unfocus()
  end
end


local function onMousePressed(x, y, button, isTouch)
  if button ~= 1 then return end

  local mousePoint = Vector(x, y) - winOffset

  local button = getIntersected(mousePoint, buttons)

  if button then
    unfocus()
    button.click()
    return
  end

  local textField = getIntersected(mousePoint, textFields)

  if textField then
    unfocus()
    textField.focused = true
    focusedTextField = textField
    return
  end

  unfocus()
end


local function onLoad()
  table.insert(buttons, createButton("Join", Vector(0.1, 0.5), buttonSize, onJoin))
  table.insert(textFields, createTextField(Vector(0.25, 0.5), buttonSize % Vector(2, 1), onIPInput))
  table.insert(textFields, createTextField(Vector(0.25, 0.6), buttonSize, onPortInput))
end


joinScene = {
  update = onUpdate,
  draw = onDraw,
  mousePressed = onMousePressed,
  keyPressed = onKeyPressed,
  load = onLoad,
  resize = onResize,
  switch = onSwitch,
  textInput = onTextInput
}
