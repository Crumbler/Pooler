local basePool = { }
local realPool = {
  innerWidth = 224,
  innerHeight = 112,
  outerWidth = 262,
  outerHeight = 150,
  totalEdge = 19,
  ballR = 4
}

truePool = { }
pocketCoords = { }


local poolColors = {
  main = {62 / 255, 105 / 255, 44 / 255, 1},
  innerEdge = {90 / 255, 160 / 255, 44 / 255, 1},
  outerEdge = {160 / 255, 90 / 255, 44 / 255, 1},
  cornerEdge = {86 / 255, 82 / 255, 82 / 255, 1},
  hole = {18 / 255, 18 / 255, 18 / 255, 1},
  ball = {0, 1, 0, 1}
}


local function fromCm(x)
  return x * 0.003;
end


function isInHole(x, y)
  vec = Vector(x, y)
  for _, h in ipairs(pocketCoords) do
    if (vec - h).length <= truePool.holeR then
      return true
    end
  end

  return false
end


function PoolLoad()
  local aspectRatio = 16 / 9

  basePool.innerWidth = fromCm(realPool.innerWidth)
  basePool.innerHeight = fromCm(realPool.innerHeight) * aspectRatio
  basePool.outerWidth = fromCm(realPool.outerWidth)
  basePool.outerHeight = fromCm(realPool.outerHeight) * aspectRatio

  basePool.totalEdge = fromCm(realPool.totalEdge)
  basePool.innerEdge = basePool.totalEdge * (2 / 7)
  basePool.outerEdge = basePool.totalEdge * (5 / 7)

  basePool.outerTopLeft = Vector(-basePool.outerWidth, -basePool.outerHeight) / 2 + 0.5

  basePool.ballR = fromCm(realPool.ballR)

  truePool.verPocket = Vector()
end


function PoolResize()
  truePool.innerWidth = basePool.innerWidth * trueSize.x
  truePool.innerHeight = basePool.innerHeight * trueSize.y
  truePool.outerWidth = basePool.outerWidth * trueSize.x
  truePool.outerHeight = basePool.outerHeight * trueSize.y

  truePool.innerEdge = trueSize.x * basePool.innerEdge
  truePool.outerEdge = trueSize.x * basePool.outerEdge

  truePool.totalEdge = trueSize.x * basePool.totalEdge

  truePool.outerTopLeft = basePool.outerTopLeft % trueSize
  truePool.innerTopLeft = truePool.outerTopLeft + truePool.outerEdge

  truePool.outerR = truePool.totalEdge / 2
  truePool.ballR = trueSize.x * basePool.ballR
  truePool.ballInnerR = truePool.ballR / 2
  truePool.holeR = truePool.ballR * 2

  truePool.cueWidth = truePool.ballR * 0.5
  truePool.cueLength = truePool.ballR * 15

  truePool.verPocket.x = math.sqrt(math.pow(truePool.holeR, 2) - math.pow(truePool.holeR / 4, 2))
  truePool.verPocket.y = truePool.holeR / 4

  truePool.horEdgeWidth = truePool.outerWidth - 2 * (truePool.outerEdge + truePool.holeR)
  truePool.horEdgeWidth = truePool.horEdgeWidth / 2 - truePool.verPocket.x

  pocketCoords[1] = truePool.innerTopLeft.copy
  pocketCoords[2] = Vector(truePool.innerTopLeft.x + truePool.holeR + truePool.horEdgeWidth + truePool.verPocket.x, truePool.innerTopLeft.y - truePool.verPocket.y)
  pocketCoords[3] = truePool.innerTopLeft + Vector(truePool.innerWidth + truePool.innerEdge * 2, 0)
  pocketCoords[4] = pocketCoords[1] + Vector(0, truePool.innerHeight + truePool.innerEdge * 2)
  pocketCoords[5] = pocketCoords[2] + Vector(0, truePool.innerHeight + truePool.innerEdge * 2 + truePool.verPocket.y * 2)
  pocketCoords[6] = pocketCoords[3] + Vector(0, truePool.innerHeight + truePool.innerEdge * 2)
end


local function drawBallOutlines()
  for _, ball in ipairs(balls) do
    local posX, posY = ball.body:getPosition()
    love.graphics.circle("fill", posX, posY, truePool.ballR)
  end
end


local ballColors = {
  { 241 / 255, 156 / 255, 68 / 255, 1 },
  { 48 / 255, 83 / 255, 120 / 255, 1 },
  { 199 / 255, 37 / 255, 46 / 255, 1, },
  { 116 / 255, 29 / 255, 116 / 255, 1 },
  { 233 / 255, 49 / 255, 37 / 255, 1 },
  { 32 / 255, 57 / 255, 35 / 255, 1 },
  { 161 / 255, 46 / 255, 57 / 255, 1 },
  { 0, 0, 0, 1 },
  { 241 / 255, 165 / 255, 68 / 255, 1 },
  { 61 / 255, 79 / 255, 100 / 255, 1 },
  { 219 / 255, 42 / 255, 58 / 255, 1 },
  { 96 / 255, 21 / 255, 60 / 255, 1 },
  { 218 / 255, 45 / 255, 38 / 255, 1 },
  { 32 / 255, 60 / 255, 37 / 255, 1 },
  { 150 / 255, 31 / 255, 35 / 255, 1 },
  inner = { 247 / 255, 206 / 255, 154 / 255, 1 }
}

local cueColors = {
  { 80 / 255, 80 / 255, 80 / 255, 1 },
  { 221 / 255, 148 / 255, 77 / 255 }
}


function truePool:drawBall(ball)
  love.graphics.push()

  local posX, posY = ball.body:getPosition()
  local halfHeight = mainFont:getHeight() / 2
  local textScale = 0.4

  love.graphics.translate(posX, posY)

  if ball.number == 0 then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", 0, 0, self.ballR)
  elseif ball.number <= 8 then
    love.graphics.setColor(ballColors[ball.number])
    love.graphics.circle("fill", 0, 0, self.ballR)

    love.graphics.setColor(ballColors.inner)
    love.graphics.circle("fill", 0, 0, self.ballInnerR)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rotate(ball.body:getAngle())

    local halfWidth = mainFont:getWidth(ball.number) / 2
    love.graphics.print(ball.number, -halfWidth * textScale, -halfHeight * textScale, 0, textScale, textScale)
  else
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", 0, 0, self.ballR)

    love.graphics.rotate(ball.body:getAngle())

    love.graphics.setColor(ballColors[ball.number])
    love.graphics.rectangle("fill", -self.ballR, -self.ballR / 2, self.ballR * 2, self.ballR)

    love.graphics.setColor(ballColors.inner)
    love.graphics.circle("fill", 0, 0, self.ballInnerR)

    love.graphics.setColor(0, 0, 0, 1)


    local halfWidth = mainFont:getWidth(ball.number) / 2
    love.graphics.print(ball.number, -halfWidth * textScale, -halfHeight * textScale, 0, textScale, textScale)
  end

  love.graphics.pop()
end


function truePool:drawBalls()
  love.graphics.setColor(1, 1, 1, 1)

  love.graphics.stencil(drawBallOutlines, "replace", 1, false)
  love.graphics.setStencilTest("equal", 1)

  for _, ball in ipairs(balls) do
    self:drawBall(ball)
  end

  love.graphics.setStencilTest()
end


function truePool:drawPockets()
  love.graphics.setColor(poolColors.hole)

  for _, pocket in ipairs(pocketCoords) do
    love.graphics.circle("fill", pocket.x, pocket.y, self.holeR)
  end
end


function truePool:drawCorner()
  love.graphics.arc("fill", self.outerR, self.outerR, self.outerR, pi * 1.5, pi)

  love.graphics.rectangle("fill", 0, self.outerR, self.outerEdge, self.outerEdge + self.holeR - self.outerR)
  love.graphics.rectangle("fill", self.outerR, 0, self.outerEdge + self.holeR - self.outerR, self.outerEdge)
end


function truePool:drawCorners()
  love.graphics.setColor(poolColors.cornerEdge)

  love.graphics.push()

  love.graphics.translate(self.outerTopLeft.x, self.outerTopLeft.y)
  truePool:drawCorner()

  love.graphics.translate(self.outerWidth, 0)
  love.graphics.rotate(pi / 2)
  truePool:drawCorner()

  love.graphics.translate(self.outerHeight, 0)
  love.graphics.rotate(pi / 2)
  truePool:drawCorner()

  love.graphics.translate(self.outerWidth, 0)
  love.graphics.rotate(pi / 2)
  truePool:drawCorner()

  love.graphics.pop()
end


function truePool:verEdgeCoords(offX, offY, scaleX)
  return offX, offY, offX + self.innerEdge * scaleX, offY + self.innerEdge,
  offX + self.innerEdge * scaleX, offY + self.innerHeight - self.innerEdge * 2,
  offX, offY + self.innerHeight - self.innerEdge
end


function truePool:drawVerticalEdge()
  love.graphics.polygon("fill", self:verEdgeCoords(0, 0, 1))
end


function truePool:drawVerticalEdges()
  love.graphics.push()

  love.graphics.translate((self.outerTopLeft + self.outerEdge + Vector(0, self.holeR)):split())
  self:drawVerticalEdge()

  love.graphics.translate(self.innerWidth + 2 * self.innerEdge, 0)
  love.graphics.scale(-1, 1)
  self:drawVerticalEdge()

  love.graphics.pop()
end


function truePool:horEdgeCoords(offX, offY, scaleX, scaleY)
  return offX, offY, self.horEdgeWidth * scaleX + offX, offY,
  (self.horEdgeWidth - self.innerEdge * math.tan(pi / 9)) * scaleX + offX, self.innerEdge * scaleY + offY,
  self.innerEdge * scaleX + offX, self.innerEdge * scaleY + offY
end


function truePool:drawHorizontalEdge()
  love.graphics.polygon("fill", self:horEdgeCoords(0, 0, 1, 1))
end


function truePool:drawHorizontalEdges()
  love.graphics.push()

  love.graphics.translate(Vector.split(self.innerTopLeft + Vector(self.holeR, 0)))
  self:drawHorizontalEdge()

  love.graphics.translate((self.horEdgeWidth + self.verPocket.x) * 2, 0)
  love.graphics.scale(-1, 1)
  self:drawHorizontalEdge()

  love.graphics.translate(0, self.innerHeight + self.innerEdge * 2)
  love.graphics.scale(1, -1)
  self:drawHorizontalEdge()

  love.graphics.translate((self.horEdgeWidth + self.verPocket.x) * 2, 0)
  love.graphics.scale(-1, 1)
  self:drawHorizontalEdge()

  love.graphics.pop()
end


function truePool:drawCue(pos, angle, power)
  love.graphics.push()

  love.graphics.translate(pos:split())
  love.graphics.rotate(angle)
  love.graphics.translate(-self.cueLength - self.ballR * 1.5, -self.cueWidth / 2)

  local text = power .. "%"

  local fontHeight = mainFont:getHeight()

  if math.abs(angle) < pi / 2 then
    love.graphics.printf(text, 0, -fontHeight, self.cueLength, "center")
  else
    love.graphics.printf(text, self.cueLength, 0, self.cueLength, "center", 0, -1, -1)
  end

  love.graphics.setColor(cueColors[1])
  love.graphics.rectangle("fill", 0, 0, self.cueLength / 3, self.cueWidth)
  love.graphics.setColor(cueColors[2])
  love.graphics.rectangle("fill", self.cueLength / 3, 0, self.cueLength * (2 / 3), self.cueWidth)

  love.graphics.pop()
end


function truePool:drawCurrentPlayer(currPlayer)
  playerText = tostring(currPlayer.number)

  love.graphics.printf("Current turn: Player " .. playerText, 0, 0, trueSize.x, "center")
end


function truePool:drawGroups(group1, group2)
  local group1Name = groupName(group1)
  local group2Name = groupName(group2)

  love.graphics.printf("Player 1: " .. group1Name, 0, 0, trueSize.x, "left")
  love.graphics.printf("Player 2: " .. group2Name, 0, 0, trueSize.x, "right")
end


function truePool:drawTable()
  love.graphics.setColor(0.5, 0.5, 0.5, 1)
  love.graphics.rectangle("fill", 0, 0, trueSize.x, trueSize.y)

  love.graphics.setColor(poolColors.outerEdge)
  love.graphics.rectangle("fill", self.outerTopLeft.x, self.outerTopLeft.y,
                          self.outerWidth, self.outerHeight, self.outerR, self.outerR)

  self:drawCorners()

  love.graphics.setColor(poolColors.main)
  love.graphics.rectangle("fill", self.innerTopLeft.x, self.innerTopLeft.y,
                          self.innerWidth + self.innerEdge * 2, self.innerHeight + self.innerEdge * 2)

  self:drawPockets()

  love.graphics.setColor(poolColors.innerEdge)
  self:drawVerticalEdges()
  self:drawHorizontalEdges()

  self:drawBalls()
end
