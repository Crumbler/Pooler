
require "Constants"


balls, edges, world = {}, {}, {}

local events
local currPlayer


local ballPositions = {
  [3] = Vector(4, -2),
  [4] = Vector(1, 1),
  [5] = Vector(3, 1),
  [6] = Vector(4, 2),
  [7] = Vector(2, -2),
  [8] = Vector(4, -4),
  [9] = Vector(2, 0),
  [10] = Vector(3, 3),
  [11] = Vector(4, 0),
  [12] = Vector(1, -1),
  [13] = Vector(4, 4),
  [14] = Vector(3, -3),
  [15] = Vector(2, 2),
  [16] = Vector(3, -1),
}


local function createEdges()
  edges.type = "edge"
  edges.shapes = { }
  edges.body = love.physics.newBody(world, 0, 0, "static")

  table.insert(edges.shapes, love.physics.newChainShape(true,
                                  truePool:horEdgeCoords(truePool.innerTopLeft.x + truePool.holeR,
                                  truePool.innerTopLeft.y, 1, 1)))
  table.insert(edges.shapes, love.physics.newChainShape(true,
                                  truePool:horEdgeCoords(truePool.innerTopLeft.x + truePool.holeR + (truePool.horEdgeWidth + truePool.verPocket.x) * 2,
                                  truePool.innerTopLeft.y, -1, 1)))
  table.insert(edges.shapes, love.physics.newChainShape(true,
                                  truePool:horEdgeCoords(truePool.innerTopLeft.x + truePool.holeR,
                                  truePool.innerTopLeft.y + truePool.innerHeight + truePool.innerEdge * 2, 1, -1)))
  table.insert(edges.shapes, love.physics.newChainShape(true,
                                  truePool:horEdgeCoords(truePool.innerTopLeft.x + truePool.holeR + (truePool.horEdgeWidth + truePool.verPocket.x) * 2,
                                  truePool.innerTopLeft.y + truePool.innerHeight + truePool.innerEdge * 2, -1, -1)))
  table.insert(edges.shapes, love.physics.newChainShape(true, truePool:verEdgeCoords(
                                  truePool.innerTopLeft.x,
                                  truePool.innerTopLeft.y + truePool.holeR, 1)))
  table.insert(edges.shapes, love.physics.newChainShape(true, truePool:verEdgeCoords(
                                  truePool.innerTopLeft.x + truePool.innerWidth + truePool.innerEdge * 2,
                                  truePool.innerTopLeft.y + truePool.holeR, -1)))

  for _, shape in ipairs(edges.shapes) do
    local fx = love.physics.newFixture(edges.body, shape, 1)
    fx:setUserData(edges)
  end
end


local function createBall(ballNumber)
  local ball = { number = ballNumber, type = "ball" }

  ball.body = love.physics.newBody(world, 0.5 * trueSize.x, 0.5 * trueSize.y, "dynamic")
  ball.body:setLinearDamping(damping)
  ball.body:setAngularDamping(damping)
  ball.body:setUserData(ball)
  ball.shape = love.physics.newCircleShape(truePool.ballR)
  ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
  ball.fixture:setUserData(ball)

  return ball
end


local function createBalls()
  for i = 0, 15 do
    table.insert(balls, createBall(i))
  end
end


local function setBallPosition(ball, x, y)
  if not y then
    ball.body:setPosition(x:split())
  else
    ball.body:setPosition(x, y)
  end
end


function ResetBalls()
  local rackBase = truePool.innerTopLeft + truePool.innerEdge +
                   Vector(truePool.innerWidth * 0.7, truePool.innerHeight / 2) +
                   Vector(truePool.ballR, 0)

  local zeroPos = truePool.innerTopLeft + Vector(truePool.innerWidth * 0.3, truePool.innerHeight / 2) + truePool.innerEdge

  local baseVec = Vector(truePool.ballR * math.sqrt(3), truePool.ballR)

  setBallPosition(balls[1], zeroPos)

  setBallPosition(balls[2], rackBase)

  for i = 3, 16 do
    setBallPosition(balls[i], rackBase + baseVec % ballPositions[i])
  end

  for _, ball in ipairs(balls) do
    ball.body:setLinearVelocity(0, 0)
    ball.body:setAngle(0)
    ball.body:setAngularVelocity(0)
    ball.body:setAwake(false)
    ball.body:setActive(true)
  end
end


function SetEventLog(eventLog)
  events = eventLog
end


function SetCurrPlayer(player)
  currPlayer = player
end


local function onContact(a, b, contact)
  local dataA = a:getUserData()
  local dataB = b:getUserData()

  if dataA.type == dataB.type then
    -- two balls
    contact:setRestitution(0.95)

    -- if second ball is cue ball, swap it with the first one
    if dataB.number == 0 then
      dataA, dataB = dataB, dataA
    end

    -- log when cue ball hits any other ball
    if dataA.number == 0 then
      table.insert(events, EVENT_GENERAL_HIT)

      if currPlayer.group == ballGroup(dataB) then
        table.insert(events, EVENT_CUE_HIT)
      elseif dataB.number == 8 then
        table.insert(events, EVENT_FINAL_HIT)
      else
        table.insert(events, EVENT_CUE_OTHER_HIT)
      end
    end
  else -- any ball hit a rail
    contact:setRestitution(0.75)

    table.insert(events, EVENT_RAIL_HIT)
  end
end


function PhysicsLoad()
  world = love.physics.newWorld(0, 0, true)

  meter = trueSize.x / meterRatio
  love.physics.setMeter(meter)

  world:setCallbacks(onContact)

  createBalls()

  createEdges()
end


function PhysicsResize()
  meter = trueSize.x / meterRatio
  love.physics.setMeter(meter)
end
