require "Utils"
require "Cursors"
require "Hotseat"
require "Host"
require "Join"
require "Constants"


local function Exit()
  love.event.quit()
end


local buttons = { }

local hovered = false
local imageScale = 900 / 1080


local function onButtonHotseat()
  switchToScene(hotSeatScene)
end


local function onButtonHost()
  switchToScene(hostScene)
end


local function onButtonJoin()
  switchToScene(joinScene)
end


local function onButtonExit()
  Exit()
end


local function onUpdate(dt)
  local mousePoint = Vector(love.mouse.getPosition()) - winOffset
  local anyHovered = false

  setUnhovered(buttons)

  local button = getIntersected(mousePoint, buttons)

  if button then
    button.hovered = true
    anyHovered = true
  end

  if anyHovered and not hovered then
    love.mouse.setCursor(Cursors.hand)
  elseif not anyHovered and hovered then
    love.mouse.setCursor(Cursors.arrow)
  end

  hovered = anyHovered
end


local function onSwitch()
  hovered = false
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
end


local function onResize()
  for _, button in ipairs(buttons) do
    button.pos = button.unpos % trueSize
    button.size = button.unsize % trueSize
  end

  imageScale = trueSize.y / 1080
end


local function onKeyPressed(key, scancode, isrepeat)
  if scancode == "escape" then
    Exit()
  end
end


local function onMousePressed(x, y, button, isTouch)
  if button ~= 1 then return end

  local mousePoint = Vector(x, y) - winOffset

  local button = getIntersected(mousePoint, buttons)

  if button then
    button.click()
  end
end


local function onLoad()
  backgroundImage = love.graphics.newImage("MenuBackground.jpg")

  table.insert(buttons, createButton("Exit", Vector(0.1, 0.8), buttonSize, onButtonExit))
  table.insert(buttons, createButton("Host", Vector(0.1, 0.7), buttonSize, onButtonHost))
  table.insert(buttons, createButton("Join", Vector(0.1, 0.6), buttonSize, onButtonJoin))
  table.insert(buttons, createButton("Hotseat", Vector(0.1, 0.5), buttonSize, onButtonHotseat))
end


mainMenuScene = {
  update = onUpdate,
  draw = onDraw,
  mousePressed = onMousePressed,
  keyPressed = onKeyPressed,
  load = onLoad,
  resize = onResize,
  switch = onSwitch
}
