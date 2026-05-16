-- EdgeTX Tetris Game for RadioMasterMT12
-- Controls: Steering wheel = Move left/right, Scroll wheel = Rotate, Throttle = Drop
-- 128x64 Monochrome LCD

local SCREEN_W = 128
local SCREEN_H = 64
local GRID_W = 10
local GRID_H = 20
local BLOCK_SIZE = 6

-- Game state
local gameState = {
  running = true,
  score = 0,
  level = 1,
  lines = 0,
  grid = {},
  currentPiece = nil,
  nextPiece = nil,
  pieceX = 0,
  pieceY = 0,
  fallTimer = 0,
  fallSpeed = 30
}

-- Tetris piece definitions
local PIECES = {
  { {{1,1,1,1}}, color = "I" },                           -- I
  { {{1,1},{1,1}}, color = "O" },                         -- O
  { {{0,1,0},{1,1,1}}, color = "T" },                     -- T
  { {{1,0,0},{1,1,1}}, color = "J" },                     -- J
  { {{0,0,1},{1,1,1}}, color = "L" },                     -- L
  { {{0,1,1},{1,1,0}}, color = "S" },                     -- S
  { {{1,1,0},{0,1,1}}, color = "Z" }                      -- Z
}

-- Initialize grid
local function initGrid()
  gameState.grid = {}
  for y = 1, GRID_H do
    gameState.grid[y] = {}
    for x = 1, GRID_W do
      gameState.grid[y][x] = 0
    end
  end
end

-- Get random piece
local function getRandomPiece()
  local piece = PIECES[math.random(1, #PIECES)]
  return {
    shape = piece[1],
    color = piece.color,
    rotation = 0
  }
end

-- Spawn new piece
local function spawnPiece()
  gameState.currentPiece = gameState.nextPiece or getRandomPiece()
  gameState.nextPiece = getRandomPiece()
  gameState.pieceX = math.floor(GRID_W / 2) - 1
  gameState.pieceY = 1
  
  -- Check for game over
  if not canPlacePiece(gameState.currentPiece, gameState.pieceX, gameState.pieceY) then
    gameState.running = false
  end
end

-- Check if piece can be placed
function canPlacePiece(piece, x, y)
  local shape = piece.shape
  for row = 1, #shape do
    for col = 1, #shape[row] do
      if shape[row][col] == 1 then
        local gridX = x + col - 1
        local gridY = y + row - 1
        
        if gridX < 1 or gridX > GRID_W or gridY > GRID_H then
          return false
        end
        if gridY > 0 and gameState.grid[gridY][gridX] == 1 then
          return false
        end
      end
    end
  end
  return true
end

-- Place piece on grid
local function placePiece(piece, x, y)
  local shape = piece.shape
  for row = 1, #shape do
    for col = 1, #shape[row] do
      if shape[row][col] == 1 then
        local gridX = x + col - 1
        local gridY = y + row - 1
        if gridY > 0 and gridY <= GRID_H then
          gameState.grid[gridY][gridX] = 1
        end
      end
    end
  end
end

-- Clear completed lines
local function clearLines()
  local clearedLines = 0
  for y = GRID_H, 1, -1 do
    local complete = true
    for x = 1, GRID_W do
      if gameState.grid[y][x] == 0 then
        complete = false
        break
      end
    end
    
    if complete then
      clearedLines = clearedLines + 1
      -- Shift lines down
      for shiftY = y, 2, -1 do
        for x = 1, GRID_W do
          gameState.grid[shiftY][x] = gameState.grid[shiftY - 1][x]
        end
      end
      -- Clear top line
      for x = 1, GRID_W do
        gameState.grid[1][x] = 0
      end
    end
  end
  
  if clearedLines > 0 then
    gameState.lines = gameState.lines + clearedLines
    gameState.score = gameState.score + (clearedLines * 100)
    gameState.level = math.floor(gameState.lines / 10) + 1
    gameState.fallSpeed = math.max(5, 30 - gameState.level * 2)
  end
end

-- Rotate piece 90 degrees
local function rotatePiece(piece)
  local shape = piece.shape
  local newShape = {}
  local rows = #shape
  local cols = #shape[1]
  
  for col = 1, cols do
    newShape[col] = {}
    for row = rows, 1, -1 do
      table.insert(newShape[col], shape[row][col])
    end
  end
  
  return { shape = newShape, color = piece.color }
end

-- Read controls
local function readControls()
  local steeringWheel = getValue("ail") or 0  -- Aileron for left/right
  local scrollWheel = getValue("scroll-wheel") or 0  -- Scroll wheel for rotate
  local throttle = getValue("thr") or 0      -- Throttle for drop
  
  return steeringWheel, scrollWheel, throttle
end

-- Update game
local function update()
  if not gameState.running then
    return
  end
  
  if not gameState.currentPiece then
    spawnPiece()
  end
  
  local steeringWheel, scrollWheel, throttle = readControls()
  
  -- Move left/right
  if steeringWheel < -0.3 then
    if canPlacePiece(gameState.currentPiece, gameState.pieceX - 1, gameState.pieceY) then
      gameState.pieceX = gameState.pieceX - 1
    end
  elseif steeringWheel > 0.3 then
    if canPlacePiece(gameState.currentPiece, gameState.pieceX + 1, gameState.pieceY) then
      gameState.pieceX = gameState.pieceX + 1
    end
  end
  
  -- Rotate (scroll wheel)
  if scrollWheel > 0.5 then
    local rotated = rotatePiece(gameState.currentPiece)
    if canPlacePiece(rotated, gameState.pieceX, gameState.pieceY) then
      gameState.currentPiece = rotated
    end
  end
  
  -- Drop (throttle)
  if throttle > 0.5 then
    while canPlacePiece(gameState.currentPiece, gameState.pieceX, gameState.pieceY + 1) do
      gameState.pieceY = gameState.pieceY + 1
    end
  end
  
  -- Natural fall
  gameState.fallTimer = gameState.fallTimer + 1
  if gameState.fallTimer >= gameState.fallSpeed then
    gameState.fallTimer = 0
    
    if canPlacePiece(gameState.currentPiece, gameState.pieceX, gameState.pieceY + 1) then
      gameState.pieceY = gameState.pieceY + 1
    else
      -- Place piece and spawn new one
      placePiece(gameState.currentPiece, gameState.pieceX, gameState.pieceY)
      clearLines()
      gameState.currentPiece = nil
      spawnPiece()
    end
  end
end

-- Draw game grid
local function drawGrid()
  local startX = 10
  local startY = 2
  
  -- Draw grid background
  for y = 1, GRID_H do
    for x = 1, GRID_W do
      local px = startX + (x - 1) * BLOCK_SIZE
      local py = startY + (y - 1) * BLOCK_SIZE
      
      if gameState.grid[y][x] == 1 then
        lcd.drawFilledRectangle(px, py, BLOCK_SIZE - 1, BLOCK_SIZE - 1, SOLID)
      else
        lcd.drawRectangle(px, py, BLOCK_SIZE - 1, BLOCK_SIZE - 1, SOLID)
      end
    end
  end
end

-- Draw current piece
local function drawCurrentPiece()
  if not gameState.currentPiece then return end
  
  local startX = 10
  local startY = 2
  local shape = gameState.currentPiece.shape
  
  for row = 1, #shape do
    for col = 1, #shape[row] do
      if shape[row][col] == 1 then
        local gridX = gameState.pieceX + col - 1
        local gridY = gameState.pieceY + row - 1
        
        if gridY > 0 and gridY <= GRID_H and gridX > 0 and gridX <= GRID_W then
          local px = startX + (gridX - 1) * BLOCK_SIZE
          local py = startY + (gridY - 1) * BLOCK_SIZE
          lcd.drawFilledRectangle(px, py, BLOCK_SIZE - 1, BLOCK_SIZE - 1, SOLID)
        end
      end
    end
  end
end

-- Draw UI
local function drawUI()
  lcd.drawString(75, 2, "Score", SMLSIZE)
  lcd.drawString(75, 10, tostring(gameState.score), SMLSIZE)
  lcd.drawString(75, 20, "Lines", SMLSIZE)
  lcd.drawString(75, 28, tostring(gameState.lines), SMLSIZE)
  lcd.drawString(75, 38, "Level", SMLSIZE)
  lcd.drawString(75, 46, tostring(gameState.level), SMLSIZE)
end

-- Draw game over screen
local function drawGameOver()
  lcd.drawFilledRectangle(20, 20, 88, 24, ERASE)
  lcd.drawRectangle(20, 20, 88, 24, SOLID)
  lcd.drawString(30, 25, "GAME OVER", 0)
  lcd.drawString(25, 35, "Score: " .. gameState.score, SMLSIZE)
end

-- Main draw function
local function draw()
  lcd.clear()
  
  if gameState.running then
    drawGrid()
    drawCurrentPiece()
    drawUI()
  else
    drawGameOver()
  end
end

-- Exit handler
local function onExit()
  return true
end

-- Initialize game
initGrid()
spawnPiece()

return { update=update, draw=draw, run=run, onExit=onExit }
