

require "PoolTable"
require "Constants"
require "GameOver"


local player1 = { state = STATE_HITTING, number = 1 }
local player2 = { state = STATE_IDLE, number = 2 }
local currPlayer = player1
local otherPlayer = player2
local mousePos = Vector()

local host = nil
local localPlayer = nil
local remotePeer = nil


local function swapPlayers()
  currPlayer, otherPlayer = otherPlayer, currPlayer

  SetCurrPlayer(currPlayer)
end


local function doFoul()
  currPlayer.state = STATE_IDLE
  swapPlayers()
  currPlayer.state = STATE_PLACING
end


local function doGameOver()
  local loser = "Player 1 "
  if currPlayer == player2 then
    loser = "Player 2 "
  end

  if host then host:destroy() end

  switchToScene(gameOverScene, player1, player2, currPlayer, otherPlayer, loser)
end


local function receivePositions(message)
  local posX, posY, angle
  local i = 1

  for _, ball in ipairs(balls) do
    posX, posY, angle = love.data.unpack(">ddd", message, i)

    ball.body:setPosition(posX * meter, posY * meter)
    ball.body:setAngle(angle)

    i = i + 24
  end
end


local function processMessage(message)
  local messageType = string.byte(message)

  if messageType == MESSAGE_CUE_PLACE then
    local ax, ay = love.data.unpack(">dd", message, 2)

    balls[1].body:setPosition(ax * meter, ay * meter)
    balls[1].body:setActive(true)
    balls[1].body:setLinearVelocity(0, 0)
    balls[1].body:setAngularVelocity(0, 0)
    balls[1].body:setAngle(0)

    currPlayer.state = STATE_HITTING
  elseif messageType == MESSAGE_POS then
    message = string.sub(message, 2)

    receivePositions(message)
  elseif messageType == MESSAGE_LOSS then
    doGameOver()
    return true
  elseif messageType == MESSAGE_VICTORY then
    swapPlayers()
    doGameOver()
    return true
  elseif messageType == MESSAGE_FOUL then
    doFoul()
  elseif messageType == MESSAGE_BREAK_SHOT then
    currPlayer.state = STATE_IDLE
    otherPlayer.state = STATE_HITTING
    swapPlayers()
  elseif messageType == MESSAGE_LEGAL_SHOT then
    currPlayer.state = STATE_HITTING
  elseif messageType == MESSAGE_GROUPS then
    player1.group, player2.group = love.data.unpack("BB", message, 2)
  end
end


local function onUpdate(dt)
  mousePos = Vector(love.mouse.getPosition()) - winOffset

  if (currPlayer == localPlayer) and (currPlayer.state == STATE_PLACING) then
    balls[1].body:setPosition(mousePos:split())
  end

  if host then
    local event = host:service()

    while event do
      if event.type == "receive" then
        if processMessage(event.data) then
          break
        end
      end

      event = host:service()
    end
  end
end


local function drawCue()
  local mainBallPos = Vector(balls[1].body:getPosition())
  local deltaVec = mainBallPos - mousePos

  local deltaLength = deltaVec.length - truePool.ballR * 1.5
  local forceRatio = clamp(deltaLength / truePool.cueLength, 0.01, 1)
  local power = round(forceRatio * 100)

  truePool:drawCue(mainBallPos, deltaVec.angle, power)

  love.graphics.setColor(1, 1, 1, 1)
end


local function onDraw()
  truePool:drawTable()

  love.graphics.setColor(1, 1, 1, 1)

  if (localPlayer == currPlayer) and (currPlayer.state == STATE_HITTING) then
    drawCue()
  end

  truePool:drawCurrentPlayer(currPlayer)

  if currPlayer.group then
    truePool:drawGroups(player1.group, player2.group)
  end
end


local function resetVariables()
  currPlayer = player1
  otherPlayer = player2
  player1.state = STATE_HITTING
  player1.group = nil
  player2.state = STATE_IDLE
  player2.group = nil

  localPlayer = player2
end


local function onSwitch(...)
  host, remotePeer = unpack{...}

  clearConsole()

  resetVariables()

  ResetBalls()

  for _, ball in ipairs(balls) do
    ball.body:setActive(false)
  end
end


local function onKeyPressed(key, scancode, isrepeat)
  if scancode == "escape" then
    if host then host:destroy() end

    switchToScene(mainMenuScene)
  end
end


local function onMousePressed(x, y, button, isTouch)
  local mousePoint = Vector(x, y) - winOffset

  if (button == 1) and (localPlayer == currPlayer) and (currPlayer.state == STATE_HITTING) then
    local force = mousePoint - Vector(balls[1].body:getPosition())
    local strength = clamp((force.length - truePool.ballR * 1.5) / truePool.cueLength, 0.01, 1)
    force = -force
    force.length = forceMultiplier * strength

    currPlayer.state = STATE_IDLE

    local message = love.data.pack("string", ">Bdd", MESSAGE_CUE_HIT, force.x, force.y)

    remotePeer:send(message)

    return
  end

  if (button == 1) and (localPlayer == currPlayer) and (currPlayer.state == STATE_PLACING) then
    if canPlace(mousePoint) then
      balls[1].body:setPosition(mousePoint:split())
      balls[1].body:setActive(true)
      balls[1].body:setLinearVelocity(0, 0)
      balls[1].body:setAngularVelocity(0, 0)
      balls[1].body:setAngle(0)

      currPlayer.state = STATE_HITTING

      local pos = mousePoint / meter

      local message = love.data.pack("string", ">Bdd", MESSAGE_CUE_PLACE, pos.x, pos.y)

      remotePeer:send(message)
    end
  end
end


local function onLoad() end


clientScene = {
  update = onUpdate,
  draw = onDraw,
  mousePressed = onMousePressed,
  keyPressed = onKeyPressed,
  load = onLoad,
  resize = PoolResize,
  switch = onSwitch
}
