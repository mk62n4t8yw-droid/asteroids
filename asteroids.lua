-- EdgeTX Asteroids Game for RadioMasterMT12
-- Controls: Scroll wheel = Thrust, Steering wheel = Rotate, Throttle = Shoot
-- 128x64 Monochrome LCD

local SCREEN_W = 128
local SCREEN_H = 64
local MAX_ASTEROIDS = 10
local MAX_BULLETS = 5
local SPAWN_DISTANCE = 50

-- Game state
local gameState = {
  running = true,
  score = 0,
  lives = 3,
  level = 1,
  asteroids = {},
  bullets = {},
  ship = {
    x = SCREEN_W / 2,
    y = SCREEN_H / 2,
    angle = 0,
    vx = 0,
    vy = 0,
    radius = 4,
    maxSpeed = 3,
    invulnerable = 180
  }
}

-- Manual table insert (EdgeTX doesn't have table library)
local function tableInsert(tbl, value)
  tbl[#tbl + 1] = value
end

-- Manual table remove (EdgeTX doesn't have table library)
local function tableRemove(tbl, index)
  for i = index, #tbl - 1 do
    tbl[i] = tbl[i + 1]
  end
  tbl[#tbl] = nil
end

-- Initialize asteroids
local function initAsteroids(count)
  gameState.asteroids = {}
  for i = 1, count do
    local angle = math.random() * 2 * math.pi
    local x = gameState.ship.x + math.cos(angle) * SPAWN_DISTANCE
    local y = gameState.ship.y + math.sin(angle) * SPAWN_DISTANCE
    
    -- Clamp to screen
    x = math.max(10, math.min(SCREEN_W - 10, x))
    y = math.max(10, math.min(SCREEN_H - 10, y))
    
    tableInsert(gameState.asteroids, {
      x = x,
      y = y,
      vx = (math.random() - 0.5) * 1.5,
      vy = (math.random() - 0.5) * 1.5,
      size = 3,
      radius = 8
    })
  end
end

-- Read controls
local function readControls()
  local scrollWheel = getValue("scroll-wheel") or 0
  local steeringWheel = getValue("ail") or 0  -- Aileron for steering
  local throttle = getValue("thr") or 0      -- Throttle for shooting
  
  return scrollWheel, steeringWheel, throttle
end

-- Update ship
local function updateShip(scrollWheel, steeringWheel, throttle)
  local ship = gameState.ship
  
  -- Rotation (steering wheel: -1 to 1)
  local rotationSpeed = 0.15
  ship.angle = ship.angle + (steeringWheel * rotationSpeed)
  
  -- Thrust (scroll wheel)
  local thrustPower = scrollWheel * 0.3
  ship.vx = ship.vx + math.cos(ship.angle) * thrustPower
  ship.vy = ship.vy + math.sin(ship.angle) * thrustPower
  
  -- Speed limit
  local speed = math.sqrt(ship.vx^2 + ship.vy^2)
  if speed > ship.maxSpeed then
    ship.vx = (ship.vx / speed) * ship.maxSpeed
    ship.vy = (ship.vy / speed) * ship.maxSpeed
  end
  
  -- Apply friction
  ship.vx = ship.vx * 0.98
  ship.vy = ship.vy * 0.98
  
  -- Position update
  ship.x = ship.x + ship.vx
  ship.y = ship.y + ship.vy
  
  -- Wrap around screen
  if ship.x < -5 then ship.x = SCREEN_W + 5 end
  if ship.x > SCREEN_W + 5 then ship.x = -5 end
  if ship.y < -5 then ship.y = SCREEN_H + 5 end
  if ship.y > SCREEN_H + 5 then ship.y = -5 end
  
  -- Invulnerability timer
  if ship.invulnerable > 0 then
    ship.invulnerable = ship.invulnerable - 1
  end
  
  -- Shoot (throttle > 0.5)
  if throttle > 0.5 and #gameState.bullets < MAX_BULLETS then
    local bullet = {
      x = ship.x + math.cos(ship.angle) * 6,
      y = ship.y + math.sin(ship.angle) * 6,
      vx = ship.vx + math.cos(ship.angle) * 4,
      vy = ship.vy + math.sin(ship.angle) * 4,
      life = 60
    }
    tableInsert(gameState.bullets, bullet)
  end
end

-- Update bullets
local function updateBullets()
  local bullets = gameState.bullets
  for i = #bullets, 1, -1 do
    local bullet = bullets[i]
    bullet.x = bullet.x + bullet.vx
    bullet.y = bullet.y + bullet.vy
    bullet.life = bullet.life - 1
    
    -- Remove if off-screen or expired
    if bullet.life <= 0 or bullet.x < 0 or bullet.x > SCREEN_W or bullet.y < 0 or bullet.y > SCREEN_H then
      tableRemove(bullets, i)
    end
  end
end

-- Update asteroids
local function updateAsteroids()
  for i = 1, #gameState.asteroids do
    local asteroid = gameState.asteroids[i]
    asteroid.x = asteroid.x + asteroid.vx
    asteroid.y = asteroid.y + asteroid.vy
    
    -- Wrap around screen
    if asteroid.x < -10 then asteroid.x = SCREEN_W + 10 end
    if asteroid.x > SCREEN_W + 10 then asteroid.x = -10 end
    if asteroid.y < -10 then asteroid.y = SCREEN_H + 10 end
    if asteroid.y > SCREEN_H + 10 then asteroid.y = -10 end
  end
end

-- Collision detection: bullets vs asteroids
local function checkBulletCollisions()
  for b = #gameState.bullets, 1, -1 do
    local bullet = gameState.bullets[b]
    for a = #gameState.asteroids, 1, -1 do
      local asteroid = gameState.asteroids[a]
      local dx = bullet.x - asteroid.x
      local dy = bullet.y - asteroid.y
      local dist = math.sqrt(dx^2 + dy^2)
      
      if dist < asteroid.radius then
        -- Hit!
        gameState.score = gameState.score + (4 - asteroid.size) * 10
        tableRemove(gameState.bullets, b)
        tableRemove(gameState.asteroids, a)
        
        -- Split asteroid
        if asteroid.size > 1 then
          for _ = 1, 2 do
            tableInsert(gameState.asteroids, {
              x = asteroid.x,
              y = asteroid.y,
              vx = asteroid.vx + (math.random() - 0.5) * 2,
              vy = asteroid.vy + (math.random() - 0.5) * 2,
              size = asteroid.size - 1,
              radius = asteroid.radius * 0.6
            })
          end
        end
        break
      end
    end
  end
end

-- Collision detection: ship vs asteroids
local function checkShipCollisions()
  if gameState.ship.invulnerable > 0 then return end
  
  for i = 1, #gameState.asteroids do
    local asteroid = gameState.asteroids[i]
    local dx = gameState.ship.x - asteroid.x
    local dy = gameState.ship.y - asteroid.y
    local dist = math.sqrt(dx^2 + dy^2)
    
    if dist < gameState.ship.radius + asteroid.radius then
      gameState.lives = gameState.lives - 1
      gameState.ship.invulnerable = 180
      gameState.ship.vx = 0
      gameState.ship.vy = 0
      
      if gameState.lives <= 0 then
        gameState.running = false
      end
    end
  end
end

-- Draw ship
local function drawShip()
  local ship = gameState.ship
  local x = ship.x
  local y = ship.y
  local angle = ship.angle
  
  -- Blink if invulnerable
  if ship.invulnerable > 0 and math.floor(ship.invulnerable / 10) % 2 == 0 then
    return
  end
  
  -- Draw triangle
  local x1 = x + math.cos(angle) * 6
  local y1 = y + math.sin(angle) * 6
  local x2 = x + math.cos(angle + 2.4) * 4
  local y2 = y + math.sin(angle + 2.4) * 4
  local x3 = x + math.cos(angle - 2.4) * 4
  local y3 = y + math.sin(angle - 2.4) * 4
  
  lcd.drawLine(x1, y1, x2, y2, SOLID)
  lcd.drawLine(x2, y2, x3, y3, SOLID)
  lcd.drawLine(x3, y3, x1, y1, SOLID)
end

-- Draw bullets
local function drawBullets()
  for i = 1, #gameState.bullets do
    local bullet = gameState.bullets[i]
    lcd.drawPoint(bullet.x, bullet.y, SOLID)
  end
end

-- Draw asteroids
local function drawAsteroids()
  for i = 1, #gameState.asteroids do
    local asteroid = gameState.asteroids[i]
    lcd.drawCircle(asteroid.x, asteroid.y, asteroid.radius, SOLID)
  end
end

-- Draw UI
local function drawUI()
  lcd.drawString(2, 2, "Score: " .. gameState.score, SMLSIZE)
  lcd.drawString(2, 10, "Lives: " .. gameState.lives, SMLSIZE)
  lcd.drawString(2, 18, "Level: " .. gameState.level, SMLSIZE)
end

-- Draw game over screen
local function drawGameOver()
  lcd.drawFilledRectangle(0, 0, SCREEN_W, SCREEN_H, ERASE)
  lcd.drawString(30, 20, "GAME OVER", 0)
  lcd.drawString(25, 35, "Score: " .. gameState.score, SMLSIZE)
  lcd.drawString(20, 45, "Press RTN to exit", SMLSIZE)
end

-- Main update function
local function update()
  if not gameState.running then
    return
  end
  
  local scrollWheel, steeringWheel, throttle = readControls()
  
  updateShip(scrollWheel, steeringWheel, throttle)
  updateBullets()
  updateAsteroids()
  checkBulletCollisions()
  checkShipCollisions()
  
  -- Level progression
  if #gameState.asteroids == 0 then
    gameState.level = gameState.level + 1
    initAsteroids(3 + gameState.level)
  end
end

-- Main draw function
local function draw()
  lcd.clear()
  
  if gameState.running then
    drawAsteroids()
    drawBullets()
    drawShip()
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
initAsteroids(3)

return { update=update, draw=draw, run=run, onExit=onExit }
