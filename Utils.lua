
require "Constants"


function pointInRect(point, rect)
  return (point.x >= rect.pos.x) and
         (point.x <= rect.pos.x + rect.size.x) and
         (point.y >= rect.pos.y) and
         (point.y <= rect.pos.y + rect.size.y)
end


function getIntersected(point, rects)
  for _, rect in ipairs(rects) do
    if pointInRect(point, rect) then
      return rect
    end
  end

  return nil
end


function setUnhovered(rects)
  for _, rect in ipairs(rects) do
    rect.hovered = false
  end
end


function round(x, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)

  return math.floor(x * mult + 0.5) / mult
end


function clamp(value, min, max)
  return math.min(math.max(min, value), max)
end


function clearTable(t)
  for k in pairs(t) do
    t[k] = nil
  end
end


function ballGroup(ball)
  if ball.number < 8 then
    return GROUP_SOLIDS
  elseif ball.number > 8 then
    return GROUP_STRIPES
  end

  return GROUP_NONE
end


local groups = {
  [GROUP_STRIPES] = "Stripes",
  [GROUP_SOLIDS] = "Solids",
  [GROUP_NONE] = "None"
}


function groupName(group)
  return groups[group]
end


function oppositeGroup(group)
  if group == GROUP_SOLIDS then
    return GROUP_STRIPES
  end

  return GROUP_SOLIDS
end


function canPlace(pos)
  local upLeft = truePool.innerTopLeft + truePool.innerEdge + truePool.ballR
  --local downRight = upleft --[[+ Vector(truePool.innerWidth, truePool.innerHeight)]] - truePool.ballR * 2
  local downRight = upLeft + Vector(truePool.innerWidth, truePool.innerHeight) - Vector(truePool.ballR, truePool.ballR) * 2

  if (pos.x < upLeft.x) or (pos.y < upLeft.y) or (pos.x > downRight.x) or (pos.y > downRight.y) then
    return false
  end

  for i = 2, 16 do
    local ballPos = Vector(balls[i].body:getPosition())

    if (ballPos - pos).length <= truePool.ballR * 2 then
      return false
    end
  end

  return true
end


function clearConsole()
  os.execute("cls")
end


function isDigit(c)
  local char = string.byte(c)
  return (char >= char0) and (char <= char9)
end


function createTextField(pos, size, fn)
  return {
    text = "",
    unpos = pos,
    unsize = size,
    ontext = fn,
    hovered = false,
    focused = false
  }
end


function createButton(text, pos, size, fn)
  return {
    text = text,
    unpos = pos,
    unsize = size,
    click = fn,
    hovered = false
  }
end
