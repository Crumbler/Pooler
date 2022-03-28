Vector = require "brinevector"
require "MainMenu"
require "Fonts"
require "Scenes"
require "PhysicsModel"
require "Constants"


local timers = {}


function recalcSizes()
  local ratio = 16 / 9

  trueSize.x, trueSize.y = winSize.x, winSize.y

  winOffset.x, winOffset.y = 0, 0

  if winSize.x > (winSize.y * ratio) then
    trueSize.x = winSize.y * ratio
    winOffset.x = (winSize.x - trueSize.x) / 2
  else
    trueSize.y = winSize.x / ratio
    winOffset.y = (winSize.y - trueSize.y) / 2
  end

  love.graphics.setScissor(winOffset.x, winOffset.y, trueSize.x, trueSize.y)
end


function switchToScene(scene, ...)
  love.mouse.setCursor(Cursors.arrow)

  clearTable(timers)

  currentScene = scene
  currentScene.resize()
  currentScene.switch(unpack{...})
end


function love.textinput(text)
  if currentScene.textInput then
    currentScene.textInput(text)
  end
end


function love.load()
  getmetatable('').__index = function(str, i) return string.sub(str, i) end

  winSize = Vector(love.graphics.getWidth(), love.graphics.getHeight())
  trueSize, winOffset = Vector(), Vector()

  recalcSizes()

  loadFonts()

  love.graphics.setBackgroundColor(0, 0, 0, 1)

  PoolLoad()
  PoolResize()
  PhysicsLoad()

  for _, scene in ipairs(scenes) do
    scene.load()
  end

  switchToScene(mainMenuScene)
end


local function onResize()
  recalcSizes()

  loadFonts()

  PhysicsResize()

  currentScene.resize()
end


function love.resize(w, h)
  winSize.x, winSize.y = w, h

  onResize()
end


function love.draw()
  love.graphics.translate(winOffset.x, winOffset.y)

  currentScene.draw()
end


function love.keypressed(key, scancode, isrepeat)
  if (scancode == 'return') and (love.keyboard.isScancodeDown('lalt', 'ralt')) then
    love.window.setFullscreen(not love.window.getFullscreen())
    winSize.x, winSize.y = love.graphics.getDimensions()
    onResize()
  end

  currentScene.keyPressed(key, scancode, isrepeat)
end


function love.mousepressed(x, y, button, isTouch)
  currentScene.mousePressed(x, y, button, isTouch)
end


function after(delay, action)
  table.insert(timers, { currTime = 0, delay = delay, action = action })
end


function love.update(dt)
  for i = #timers, 1, -1 do
    local timer = timers[i]

    timer.currTime = timer.currTime + dt

    if timer.currTime > timer.delay then
      timer.action()
      table.remove(timers, i)
    end
  end

  currentScene.update(dt)
end
