--This module takes reactor input and provides then to cel
local cel = require 'cel' 

local mouse = {
  buttons = {
    left = 1,
    middle = 2,
    right = 3,
  },
  states = {
    unknown = 'unknown',
    normal = 'normal',
    pressed = 'pressed',
  },
  wheeldirection = {
    up = 1,
    down = -1,
  },
}

local keyboard = {
  keys = setmetatable({}, {__index = function(t, k, v) return k end}),
  keystates = {
    unknown = 'unknown',
    normal = 'normal',
    pressed = 'pressed',
  }
}

local driver = cel.installdriver(mouse, keyboard)

reactor.cel = setmetatable({}, {__index = cel})

function driver.clipboard(command, data)
  if command == 'get' then
    return reactor.clipboard.get()
  elseif command == 'put' then
    reactor.clipboard.put(data)
  end
end

function reactor.cel.command(command)
  driver.command(command)
end

function reactor.cel.mousepressed(x, y, button, alt, ctrl, shift)
  driver.mousedown(x, y, button, alt, ctrl, shift)
end

function reactor.cel.mousereleased(x, y, button, alt, ctrl, shift)
  driver.mouseup(x, y, button, alt, ctrl, shift)
end

function reactor.cel.mousewheel(delta, step)
  local direction 

  if delta > 0 then
    direction = mouse.wheeldirection.up
  else
    direction =  mouse.wheeldirection.down
  end

  local x, y = cel.mouse:xy()

  delta = math.abs(delta)
  for i=1,delta do
    driver.mousewheel(x, y, direction, step)
  end
end

function reactor.cel.mousemove(x, y)
  driver.mousemove(x, y)
end

function reactor.cel.keypressed(key, alt, ctrl, shift, autorepeat)
  if autorepeat then
    driver.keypress(key, alt, ctrl, shift)
  else
    driver.keydown(key, alt, ctrl, shift)
  end
end

function reactor.cel.keyreleased(key)
  driver.keyup(key)
end

function reactor.cel.character(c)
  driver.char(c)
end

do
  local lastfps
  local function initgraphics(w, h)
    if reactor.w ~= w or reactor.h ~= h then
      reactor.w = w
      reactor.h = h
      if reactor.texture then reactor.texture:destroy() end
      if reactor.surface then reactor.surface:destroy() end
      if reactor.cr then reactor.cr:destroy() end
      reactor.texture = reactor.graphics.texture.create(w, h)
      reactor.surface = cairo.surface.create(w, h)
      reactor.cr = cairo.create(reactor.surface)
    end
  end

  function reactor.cel.load()
    initgraphics(reactor.graphics.getwidth(), reactor.graphics.getheight())
    driver.root:resize(reactor.w, reactor.w)
  end

  function reactor.cel.resized(nw, nh)
    initgraphics(nw, nh)
    driver.root:resize(nw, nh)
  end

  function reactor.cel.update(fps)
    driver.timer(reactor.timermillis());
    if _G.showfps and fps ~= lastfps then
      lastfps = fps
      _G.showfps(string.format('fps %d', fps))
    end
  end

  function reactor.cel.draw(cr)
    local w, h = reactor.w, reactor.h
    reactor.graphics.pushstate2d(w,h)
    reactor.graphics.setcolor(1, 1, 1)

    do
      local t, altered = cel.describe()
      if altered then
        local cr = reactor.cr
        cr:set_source_rgb(0, 0, 0)
        cr:rectangle(0, 0, w, h)
        cr:fill()

        cr:save()
        cr:set_line_width(1)
        cel.face.get().cr = cr
        t.drawtimestamp = cel.timer()
        _G.drawtimestamp = t.drawtimestamp
        t.description.face:draw(t.description)
        cr:restore()
        reactor.graphics.updatetexture(reactor.texture, reactor.surface)
      end
    end

    reactor.graphics.drawtexture(reactor.texture, 0, 0, w, h)
    reactor.graphics.popstate()
  end
end



--Install hooks to pass events to cel
if not reactor.mousepressed then
  function reactor.mousepressed(...)
    return reactor.cel.mousepressed(...)
  end
end

if not reactor.mousereleased then
  function reactor.mousereleased(...)
    return reactor.cel.mousereleased(...)
  end
end

if not reactor.mousewheel then
  function reactor.mousewheel(delta, step)
    reactor.cel.mousewheel(delta, step)
  end
end

if not reactor.mousemove then
  function reactor.mousemove(x, y)
    return reactor.cel.mousemove(x, y) 
  end
end

if not reactor.keypressed then
  function reactor.keypressed(...)
    return reactor.cel.keypressed(...)
  end
end

if not reactor.keyreleased then
  function reactor.keyreleased(...)
    return reactor.cel.keyreleased(...)
  end
end

if not reactor.resized then
  function reactor.resized(w, h)
    reactor.cel.resized(w,h)
  end
end

if not reactor.draw then
  function reactor.draw()
    reactor.cel.draw()
  end
end

if not reactor.charcater then
  function reactor.character(c)
    reactor.cel.character(c)
  end
end

if not reactor.command then
  function reactor.command(c)
    reactor.cel.command(c)
  end
end

if not reactor.update then
  function reactor.update(fps)
    reactor.cel.update(fps)
  end
end


do
  local namemap = {
    code = 'fixedsys',
    monospace = 'courier new',
    serif = 'times new roman',
    sansserif = 'arial',
    default = 'arial'
  }

  function driver.loadfont(name, weight, slant, size)
    name = namemap[name] or name 

    local surface = cairo.surface.create(0, 0)
    local nativefont = cairo.font.face_create(name, slant, weight)
    local cr = cairo.create(surface)

    cr:set_font_face(nativefont)
    cr:set_font_size(size)

    local font = {
      nativefont = nativefont;
    }

    --[==[ native textmetrics
    function font:measure(text, i, j)
      if not text or #text < 1 then
        return 0, 0
      end
      local xbr, ybr, w, h, xadv, yadv = cr:text_extents(text, i, j)
      return w, h 
    end

    function font:measurebbox(text, i, j)
      if not text or #text < 1 then
        return 0, 0, 0, 0
      end
      local xbr, ybr, w, h, xadv, yadv = cr:text_extents(text, i, j)
      return xbr, xbr + w, -(ybr + h), -ybr
    end

    function font:measureadvance(text, i, j)
      if not text or #text < 1 then
        return 0
      end
      local xbr, ybr, w, h, xadv, yadv = cr:text_extents(text, i, j)
      return xadv
    end
    --]==]

    local charset = 
    [[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghifklmnopqrstuvwxyz`1234567890-=~!@#$%^&*()_+[]\\{}|;:\'"<>?,./]]

    local xbr, ybr, w, h, xadv, yadv = cr:text_extents(charset)

    local ymin = -(ybr + h)
    local ymax = -ybr

    local xmin = 32000 
    local xmax = -32000 
    for i = 1, #charset do
      local xbr, ybr, w, h, xadv, yadv = cr:text_extents(charset:sub(i, i))
      if xbr < xmin then xmin = xbr end
      if xbr + w > xmax then xmax = xbr + w end
    end

    font.bbox = {
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax,
    }

    do
      local ascent, descent, height = cr:font_extents()
      font.lineheight = height
      font.ascent = ascent
      font.descent = descent

      if ascent > font.bbox.ymax then
        --this is not acceptable, cel algorithms need to look as ascent instaed of 
        --looking at bbox alone
        print('useing ascent as ymax for', name, weight, slant, size)
        font.bbox.ymax = ascent
      end
    end

    local function newglyph(fontmetrics, glyph)
      local char = string.char(glyph)
      local xbr, ybr, w, h, xadv, yadv = cr:text_extents(char)      

      fontmetrics[glyph] = {
        glyph = glyph,
        char = char,
        advance = xadv,
        xmin = xbr,
        xmax = xbr + w,
        ymin = -(ybr + h),
        ymax = -ybr,
      }

      return fontmetrics[glyph]
    end

    font.metrics = setmetatable({}, {__index = newglyph})

    function font.print(font, cr, x, y, text, i, j)
      i = i or 1
      j = j or #text
      if j < i then return end
      cr:set_font_face(font.nativefont)
      cr:set_font_size(size)
      cr:save()
      cr:move_to(x, y)
      cr:show_text(text, i, j)
      cr:restore()
    end

    --x, y specify left top of string
    function font.printlt(font, cr, x, y, text, i, j)      
      i = i or 1
      j = j or #text
      if j < i then return end

      cr:set_font_face(font.nativefont)
      cr:set_font_size(size)

      if font.bbox.xmin ~= 0 then
        local xmin = font:measurebbox(text) --TODO must avoid this shit
        cr:save()
        cr:move_to(x - xmin, y + font.bbox.ymax)
        cr:show_text(text, i, j)
        cr:restore()
      else
        cr:save()
        cr:move_to(x, y + font.bbox.ymax)
        cr:show_text(text, i, j)
        cr:restore()
      end
    end

    return font 
  end
end

reactor.celroot = driver.root:newroot():link(driver.root, 'edges')

require 'celfaces'

return cel
