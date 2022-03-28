
local baseWinHeight = 900

function loadFonts()
  mainFont = love.graphics.newFont("Lato-Regular.ttf", (40 * trueSize.y) / baseWinHeight)

  love.graphics.setFont(mainFont)
end
