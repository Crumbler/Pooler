

require "PoolTable"
require "Constants"
require "GameOver"


local accT = 0
local posTime = 0
local allAsleepLast = true
local isBreak = true
local tableOpen = true
local tableJustClosed = false

local player1 = { state = STATE_HITTING, number = 1 }
local player2 = { state = STATE_IDLE, number = 2 }
local currPlayer = player1
local otherPlayer = player2
local mousePos = Vector()
local events = { }

local host = nil
local localPlayer = nil
local remotePeer = nil

local stripesPocketed = 0
local solidsPocketed = 0
local stripesLeft = 7
local solidsLeft = 7


local function swapPlayers()
  currPlayer, otherPlayer = otherPlayer, currPlayer

  SetCurrPlayer(currPlayer)
end


local function sendMessage(msgType)
  local message = love.data.pack("string", ">B", msgType)

  remotePeer:send(message)

  host:flush()
end


local function doFoul()
  currPlayer.state = STATE_IDLE
  swapPlayers()
  currPlayer.state = STATE_PLACING

  balls[1].body:setActive(false)

  sendMessage(MESSAGE_FOUL)
end


local function doGameOver()
  local loser = "Player 1 "
  if currPlayer == player2 then
    loser = "Player 2 "
  end

  if host then host:destroy() end

  switchToScene(gameOverScene, player1, player2, currPlayer, otherPlayer, loser)
end


local function currentGroupLeft()
  if currPlayer.group == GROUP_STRIPES then
    return stripesLeft
  end

  return solidsLeft
end


local function isLegalShot()
  -- if table is open, hitting any ball is a legal shot
  local targetEvent = EVENT_CUE_HIT
  if tableOpen or tableJustClosed then
    targetEvent = EVENT_GENERAL_HIT

    tableJustClosed = tableOpen or not tableJustClosed
  end

  -- find first contact with object ball
  local hitIndex = 0
  for i = 1, #events do
    if events[i] == targetEvent then
      hitIndex = i
      break
    end
  end

  -- if object ball not contacted, foul
  if hitIndex == 0 then
    return false
  end

  -- if any ball pocketed or hits rail, the shot is legal
  for i = hitIndex + 1, #events do
    if (events[i] == EVENT_POCKET) or (events[i] == EVENT_RAIL_HIT) then
      return true
    end
  end

  return false
end


local function checkRules()
  -- check for loss or win
  for _, event in ipairs(events) do
    if event == EVENT_FINAL_POCKET then
      if currentGroupLeft() ~= 0 then
        print("game over - 8 ball pocketed prematurely")
        sendMessage(MESSAGE_LOSS)
      else
        print("game over - 8 ball pocketed")
        swapPlayers()
        sendMessage(MESSAGE_VICTORY)
      end

      doGameOver()
      return
    end
  end

  -- foul on cue ball pocket
  for _, event in ipairs(events) do
    if event == EVENT_CUE_POCKET then
      print("foul - cue ball pocketed")
      doFoul()
      return
    end
  end

  -- don't check legal shot on break
  if isBreak then
    print("break shot")
    currPlayer.state = STATE_IDLE
    otherPlayer.state = STATE_HITTING
    swapPlayers()

    sendMessage(MESSAGE_BREAK_SHOT)
    return
  end

  if isLegalShot() then
    print("legal shot")
    currPlayer.state = STATE_HITTING

    sendMessage(MESSAGE_LEGAL_SHOT)
    return
  end

  print("foul - illegal shot")
  doFoul()
end


local function sendGroups()
  local message = love.data.pack("string", "BBB", MESSAGE_GROUPS, player1.group, player2.group)

  remotePeer:send(message)
end


local function sendPositions(channel, reliability)
  local message = love.data.pack("string", "B", MESSAGE_POS)

  for _, ball in ipairs(balls) do
    local pos = Vector(ball.body:getPosition()) / meter
    local angle = ball.body:getAngle()

    message = message .. love.data.pack("string", ">ddd", pos.x, pos.y, angle)
  end

  remotePeer:send(message, channel, reliability)
end


local function onStop()
  sendPositions()

  checkRules()

  isBreak = false

  stripesLeft = stripesLeft - stripesPocketed
  stripesPocketed = 0

  solidsLeft = solidsLeft - solidsPocketed
  solidsPocketed = 0

  clearTable(events)
end


local function checkBalls()
  local allAsleep = true

  for _, ball in ipairs(balls) do
    speed = Vector(ball.body:getLinearVelocity()).length / meter

    -- check if stopped
    if ball.body:isAwake() and (speed < 1e-4) then
      ball.body:setAwake(false)
      ball.body:setLinearVelocity(0, 0)
      ball.body:setAngularVelocity(0)
    end

    -- check if ball is pocketed
    if isInHole(ball.body:getPosition()) then
      ball.body:setAwake(false)
      ball.body:setActive(false)
      ball.body:setPosition(0, -truePool.holeR)
      ball.body:setLinearVelocity(0, 0)
      ball.body:setAngularVelocity(0)


      -- log event
      if ball.number == 8 then
        table.insert(events, EVENT_FINAL_POCKET)
      elseif ball.number == 0 then
        table.insert(events, EVENT_CUE_POCKET)
      else
        table.insert(events, EVENT_POCKET)

        local thisGroup = ballGroup(ball)

        -- if table is open, set groups
        if tableOpen and not isBreak then
          tableOpen = false
          tableJustClosed = true
          currPlayer.group = thisGroup
          otherPlayer.group = oppositeGroup(currPlayer.group)
          sendGroups()
        end

        if thisGroup == GROUP_STRIPES then
          stripesPocketed = stripesPocketed + 1
        else
          solidsPocketed = solidsPocketed + 1
        end
      end
    end

    allAsleep = allAsleep and not ball.body:isAwake()
  end

  -- if all balls stopped
  if not allAsleepLast and allAsleep then
    onStop()
  end

  allAsleepLast = allAsleep
end


local function simulate(dt)
  local step = 1 / 120

  accT = accT + dt

  while accT >= step do
    accT = accT - step

    world:update(step)
    checkBalls()
  end
end


local function processMessage(message)
  local messageType = string.byte(message)

  if messageType == MESSAGE_CUE_HIT then
    local ax, ay = love.data.unpack(">dd", message, 2)

    balls[1].body:applyLinearImpulse(ax * meter, ay * meter)

    currPlayer.state = STATE_IDLE

    posTime = 0
  elseif messageType == MESSAGE_CUE_PLACE then
    local ax, ay = love.data.unpack(">dd", message, 2)

    balls[1].body:setPosition(ax * meter, ay * meter)
    balls[1].body:setActive(true)
    balls[1].body:setLinearVelocity(0, 0)
    balls[1].body:setAngularVelocity(0, 0)
    balls[1].body:setAngle(0)

    currPlayer.state = STATE_HITTING
  end
end


local function prepareSendPositions(dt)
  local step = 1 / 20

  posTime = posTime + dt

  if posTime >= step then
    posTime = posTime - step

    sendPositions(1, "unsequenced")
  end

  while posTime >= step do
    posTime = posTime - step
  end
end


local function onUpdate(dt)
  mousePos = Vector(love.mouse.getPosition()) - winOffset

  if currPlayer.state == STATE_IDLE then
    simulate(dt)

    prepareSendPositions(dt)
  elseif (currPlayer == localPlayer) and (currPlayer.state == STATE_PLACING) then
    balls[1].body:setPosition(mousePos.x, mousePos.y)
  end

  if host then
    local event = host:service()

    while event do
      if event.type == "receive" then
        processMessage(event.data)
      end

      event = host:service()
    end
  end
end


local function drawCue()
  local mainBallPos = Vector(balls[1].body:getPosition())
  local deltaVec = mainBallPos - mousePos

  local deltaLength = deltaVec.length - truePool.ballR * 1.5
  local forceRatio = clamp(deltaLength / truePool.cueLength, 0.05, 1)
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
  stripesPocketed = 0
  solidsPocketed = 0
  stripesLeft = 7
  solidsLeft = 7

  allAsleepLast = true
  isBreak = true
  tableOpen = true
  tableJustClosed = false
  currPlayer = player1
  otherPlayer = player2
  player1.state = STATE_HITTING
  player1.group = nil
  player2.state = STATE_IDLE
  player2.group = nil
  clearTable(events)

  localPlayer = player1
end


local function onSwitch(...)
  host, remotePeer = unpack{...}

  SetEventLog(events)
  SetCurrPlayer(currPlayer)

  clearConsole()

  resetVariables()

  ResetBalls()
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
    force.length = forceMultiplier * strength * meter
    balls[1].body:applyLinearImpulse(force:split())

    currPlayer.state = STATE_IDLE

    posTime = 0

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


serverScene = {
  update = onUpdate,
  draw = onDraw,
  mousePressed = onMousePressed,
  keyPressed = onKeyPressed,
  load = onLoad,
  resize = PoolResize,
  switch = onSwitch
}
