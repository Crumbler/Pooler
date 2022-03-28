

require "PoolTable"
require "Constants"
require "Utils"

local player1
local player2
local currPlayer
local otherPlayer
local loser
local lossMessage


local function onUpdate(dt)
  mousePos = Vector(love.mouse.getPosition()) - winOffset


end


local function drawCurrentPlayer()
  playerText = "1"
  if currPlayer == player2 then
    playerText = "2"
  end

  love.graphics.printf("Current turn: Player " .. playerText, 0, 0, trueSize.x, "center")
end


local function drawGroups()
  local group1Name = groupName(player1.group)
  local group2Name = groupName(player2.group)

  love.graphics.printf("Player 1: " .. group1Name, 0, 0, trueSize.x, "left")
  love.graphics.printf("Player 2: " .. group2Name, 0, 0, trueSize.x, "right")
end


local function drawLossMessage()
  local height = mainFont:getHeight()
  love.graphics.printf(lossMessage, 0, trueSize.y - height, trueSize.x, "center")
end


local function onDraw()
  truePool:drawTable()

  love.graphics.setColor(1, 1, 1, 1)

  drawCurrentPlayer()

  if currPlayer.group then
    drawGroups()
  end

  drawLossMessage()
end


local function onResize()
  PoolResize()
end


local function onSwitch(...)
  player1, player2, currPlayer, otherPlayer, loser = unpack{...}

  lossMessage = loser .. " lost"
end


local function onKeyPressed(key, scancode, isrepeat)
  if scancode == "escape" then
    switchToScene(mainMenuScene)
  end
end


local function onMousePressed(x, y, button, isTouch)
  local mousePoint = Vector(x, y) - winOffset


end


local function onLoad() end


gameOverScene = {
  update = onUpdate,
  draw = onDraw,
  mousePressed = onMousePressed,
  keyPressed = onKeyPressed,
  load = onLoad,
  resize = onResize,
  switch = onSwitch
}
