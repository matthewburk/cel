--local cel = love.filesystem.load('cel/init.lua')()

local cel = require 'cel'

love.cel = setmetatable({}, {__index = cel})

local mouse = {
  buttons = { left = 'l', right = 'r', middle = 'm'},
  buttonstates = { unknown = 'unknown', normal = 'normal', down = 'down'},
  wheeldirection = {up = 'wu', down = 'wd'},
}

local keyboard = {
  keys = setmetatable({}, {__index = function(t, k, v) return k end}),
  keystates = { unknown = 'unknown', normal = 'normal', down = 'down'}
}

local driver = cel.installdriver(mouse, keyboard)

do --driver.timer, driver.mousemove
  if not love.update then
    function love.update(dt)
      love.cel.update(dt)
    end
  end

  function love.cel.update(dt)
    local fps = 0
    local frames = 1
    local dt10 = 0
    function love.cel.update(dt)
      frames = frames + 1
      dt10 = dt10 + dt
      if frames == 10 then
        local lastfps = fps
        fps = 10/dt10
        frames = 0
        dt10 = 0
        if fps ~= lastfps and _G.showfps then
          _G.showfps(string.format('fps %d', fps))
        end
      end

      driver.mousemove(love.mouse.getX(), love.mouse.getY())
      driver.timer(love.timer.getTime()*1000);
    end
    driver.root:resize(love.graphics.getWidth(), love.graphics.getHeight())
    love.cel.update(dt)
  end
end


do --driver.mousewheel, driver.mousedown
  if not love.mousepressed then
    function love.mousepressed(...)
      return love.cel.mousepressed(...)
    end
  end

  function love.cel.mousepressed(x, y, button)
    if 'wu' == button then
      driver.mousewheel(x, y, 'wu', 1)
    elseif 'wd' == button then
      driver.mousewheel(x, y, 'wd', 1)
    else
      driver.mousedown(x, y, button)
    end
  end
end

do --driver.mouseup
  if not love.mousereleased then
    function love.mousereleased(...)
      return love.cel.mousereleased(...)
    end
  end

  function love.cel.mousereleased(x, y, button)
    if 'wu' ~= button and 'wd' ~= button then
      driver.mouseup(x, y, button)
    end
  end
end

do --driver.keydown, driver.keypress, driver.char, driver.command
  if not love.keypressed then
    function love.keypressed(...)
      return love.cel.keypressed(...)
    end
  end

  function love.cel.keypressed(key, unicode)
    if cel.keyboard:isdown(key) then
      driver.keydown(key)
    else
      driver.keypress(key)
    end

    local isDown = love.keyboard.isDown

    if isDown('lctrl') or isDown('rctrl') then
      if key == 'c' then
        driver.command('copy')
        return
      elseif key == 'x' then
        driver.command('cut')
        return
      elseif key == 'v' then
        driver.command('paste')
        return
      end
    end

    if unicode <= 255 and unicode >= 32 then
      driver.char(string.char(unicode))
    end
  end
end

do --driver.keyup
  if not love.keyreleased then
    function love.keyreleased(...)
      return love.cel.keyreleased(...)
    end
  end

  function love.cel.keyreleased(key)
    driver.keyup(key)
  end
end

do --draw
  if not love.draw then
    function love.draw()
      love.cel.draw()
    end
  end

  function love.cel.draw()
    local t, refresh = cel.describe()
    t.drawtimestamp = cel.timer()
    t.description.face:draw(t.description)
  end
end


do --loadfont
  love.graphics.setFont(12) --TODO don't do this

  local namemap = {
    code = 'fonts/cour.ttf',
    monospace = 'fonts/cour.ttf',
    serif = 'fonts/Anonymous Pro.ttf',
    sansserif = 'fonts/VeraMono.ttf',
  }

  --size is in pixels
  function driver.loadfont(name, weight, slant, size)
    name = namemap[name]

    local font = {}

    if name then
      font.nativefont = love.graphics.newFont(name, size)
    else
      font.nativefont = love.graphics.newFont(size)
    end

    local nativeheight = font.nativefont:getHeight()
    do --calculate font bbox
      font.bbox = {
        xmin = 0,
        xmax = 0,
        ymin = -(nativeheight - math.floor(nativeheight * .8)), --fudge it
        ymax = math.floor(nativeheight * .8), --fudge it
      }
    end

    font.lineheight = nativeheight
    font.ascent = font.bbox.ymax
    font.descent = -font.bbox.ymin

    local function newglyph(fontmetrics, glyph)
      local char = string.char(glyph)
      --no glyph metrics from love, we can get the horizontal advance at least
      local xmin, xmax, ymin, ymax = 0, font.nativefont:getWidth(char), font.bbox.ymin, font.bbox.ymax
      fontmetrics[glyph] = {
        glyph = glyph,
        char = char,
        advance = font.nativefont:getWidth(char),
        xmin = xmin,
        xmax = xmax,
        ymin = ymin,
        ymax = ymax,
      }

      return fontmetrics[glyph]
    end

    font.metrics = setmetatable({}, {__index = newglyph}) 

    return font 
  end
end

love.keyboard.setKeyRepeat(450, 35)

return driver.root:newroot():link(driver.root, 'edges') 
