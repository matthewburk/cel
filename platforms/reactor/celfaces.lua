local M = {}

local cel = require 'cel'

do
  local decode = cel.color.decode
  function M.setcolor(cr, color)
    assert(type(cr) == 'userdata')
    if not color then 
      return false
    end
    local r, g, b, a = decode(color)
    if a == 0 then
      return false
    end

    cr:set_source_rgba (r/255, g/255, b/255, a/255);
    return true
  end
end

function M.clip(cr, t)  
  cr:reset_clip(t.l, t.t, t.r, t.b)
  cr:rectangle(t.l, t.t, t.r-t.l, t.b-t.t)
  cr:clip()
end

function M.strokerect(cr, x, y, w, h, r)
  cr:rectangle(x+.5, y+.5, w-1, h-1);
  cr:stroke()
end

function M.fillrect(cr, x, y, w, h, r)
  cr:rectangle(x, y, w, h);
  cr:fill()
end

function M.drawlinks(face, t)
  for i = #t,1,-1 do
    local t = t[i]
    t.face:draw(t)
  end
end

local drawlinks = M.drawlinks
local setcolor = M.setcolor
local fillrect = M.fillrect
local strokerect = M.strokerect
local clip = M.clip

local newcolor = cel.color.encode


function reactor.cel.drawcolor(face, t)
  local cr = face.cr
  clip(cr, t.clip)
  if setcolor(cr, face.fillcolor) then
    fillrect(cr, t.x, t.y, t.w, t.h)
  end
  return drawlinks(face, t)
end

do --cel face
  local center = function(hw, hh, x, y, w, h) return (hw - w)/2, (hh - h)/2, w, h end

  local face = cel.face {
    font = cel.loadfont(),
    textcolor = newcolor(1, 1, 1),
    fillcolor = newcolor(.7, .7, .7),
    linecolor = newcolor(.5, .5, .5),
  }

  function face:draw(t)
    local cr = self.cr
    clip(cr, t.clip)
    setcolor(cr, self.linecolor)
    strokerect(cr, t.x, t.y, t.w, t.h)

    local font = t.font or self.font
    local string = t.metacel
    local stringw, stringh = font:measure(string)
    local stringh = font:height()
    local x, y = center(t.w, t.h, 0, 0, stringw, stringh)
    setcolor(cr, self.textcolor)
    font:printlt(cr, t.x + math.floor(x), t.y + math.floor(y), string)
    return drawlinks(self, t)
  end

  ---[[
  function face:draw(t)
    local cr = self.cr
    if self.color then
      if setcolor(cr, self.color) then
        clip(cr, t.clip)
        fillrect(cr, t.x, t.y, t.w, t.h)
      else
        if setcolor(cr, self.fillcolor) then
          clip(cr, t.clip)
          fillrect(cr, t.x, t.y, t.w, t.h)
        end
        if setcolor(cr, self.linecolor) then
          clip(cr, t.clip)
          strokerect(cr, t.x, t.y, t.w, t.h)
        end
      end
    else

    end
    return drawlinks(self, t)
  end
  --]]
end

do --cel@circle
  local face = cel.face {
    name = '@circle',
    fillcolor = false,
    linecolor = false,
    color = newcolor(0, 0, 0)
  }

  function face:draw(t)
    local cr = self.cr
    if self.color then
      if setcolor(cr, self.color) then
        clip(cr, t.clip)
        cr:save()
        cr:translate(t.x + t.w/2, t.y + t.h/2)
        cr:scale(t.w, t.h)
        cr:arc(0, 0, .5, 0, 2 * math.pi)
        cr:fill()
        cr:restore()
      else
      end
    else
    end
    return drawlinks(self, t)
  end
end
do --root
  local frame = 0
  local face = cel.face {
    metacel = 'root',
    fillcolor = false,
    linecolor = false,
  }

  function face:draw(t, cr)
    local cr = self.cr
    if setcolor(cr, self.fillcolor) then
      clip(cr, t.clip)
      fillrect(cr, t.x, t.y, t.w, t.h)
    end
    return drawlinks(self, t, cr)
  end
end

do --sequence
  cel.face {
    metacels = {'sequence.y', 'sequence.x'},
    draw = drawlinks,
  }
end

do --label
  local face = cel.face {
    metacel = 'label',
    fillcolor = false,
    linecolor = false, 
    textcolor = cel.color.encode(0, 0, 0),
    layout = {
      padding = {
        l = 1,
        t = 1,
      },
    },
  }

  function face:draw(t, cr)
    local cr = self.cr
    if setcolor(cr, self.fillcolor) then
      clip(cr, t.clip)
      fillrect(cr, t.x, t.y, t.w, t.h)
    end
    if setcolor(cr, self.textcolor) then
      clip(cr, t.clip)
      local font = t.font or self.font
      font:print(cr, t.x + t.penx, t.y + t.peny, t.text)
    end
    if setcolor(cr, self.linecolor) then
      clip(cr, t.clip)
      strokerect(cr, t.x, t.y, t.w, t.h)
    end
    return drawlinks(self, t, cr)
  end

  cel.face {
    metacel = 'label',
    name = cel.menu,
    font = cel.loadfont('arial', 10);
    textcolor = newcolor(0, 0, 0),
  }

  --[[
  cel.face {
    metacel = 'label',
    name = cel.root,
    font = cel.loadfont('arial', 12);
    textcolor = newcolor(0, 0, 0),
    fillcolor = newcolor(1, 1, 1),
  }
  --]]
end

do --text
  local face = cel.face {
    metacel = 'text',
    fillcolor = false,
    linecolor = false,
    textcolor = newcolor(0, 0, 0),
    font = cel.loadfont('monospace', 10)
  }

  function face:draw(t, cr)
    local cr = self.cr
    if setcolor(cr, self.fillcolor) then
      clip(cr, t.clip)
      fillrect(cr, t.x, t.y, t.w, t.h)
    end
    if setcolor(cr, self.textcolor) then
      clip(cr, t.clip)
      for i, line in ipairs(t.lines) do
        --uncomment this optimization later
        --if t.y + line.y < t.clip.b  and t.y + line.y + line.h > t.clip.t then
          t.font:print(cr, t.x + line.penx, t.y + line.peny, t.text, line.i, line.j)
        --end
      end
    end
    if t.caret then 
      local line = t.caretline
      setcolor(cr, self.textcolor)
      strokerect(cr, t.x + t.caretx - 1, t.y + line.y, 1, line.h)
    end
    
    if setcolor(cr, self.linecolor) then
      clip(cr, t.clip)
      strokerect(cr, t.x, t.y, t.w, t.h)
    end
    
    return drawlinks(self, t, cr)
  end
end

do --button
  local face = cel.face {
    metacel = 'button',
    fillcolor = newcolor(.5, .5, .9),
    lightcolor = newcolor(.8, .8, .8),
    darkcolor = newcolor(.1, .1, .1),      
    hovercolor = newcolor(.5, .8, .5),
    cornerradius = 0,
    bordersize = 1,
  }

  function face:draw(t, cr)
    local cr = self.cr
    clip(cr, t.clip)
    local offset = self.bordersize 
    local w = t.w - (offset * 2)
    local h = t.h - (offset * 2)
    local x = t.x + offset
    local y = t.y + offset
    local light, dark

    if t.pressed and t.mousefocus then
      dark, light = self.lightcolor, self.darkcolor
    else
      light, dark = self.lightcolor, self.darkcolor
    end

    if setcolor(cr, light) then
      fillrect(cr, x-offset, y-offset, w + offset, h + offset, self.cornerradius)
    end


    if setcolor(cr, dark) then
      fillrect(cr, x, y, w+offset, h+offset, self.cornerradius)
    end

    if t.mousefocus then
      if setcolor(cr, self.hovercolor) then
        fillrect(cr, x, y, w, h, self.cornerradius)
      end
    else
      if setcolor(cr, self.fillcolor) then
        fillrect(cr, x, y, w, h, self.cornerradius)
      end
    end

    return drawlinks(self, t, cr)
  end
end

do --textbutton
  local face = cel.face {
    metacel = 'textbutton',
    layout = {
      padding = {
        fitx = 'bbox',
        l = function(w,h) return 10 + (w * .1) end,
        t = function(w,h) return h * .35 end, 
      },
    },
    cornerradius = 0,
  }

  function face:draw(t, cr)
    local cr = self.cr
    local offset = self.bordersize
    local w = t.w - (offset * 2)
    local h = t.h - (offset * 2)
    local x = t.x + offset
    local y = t.y + offset
    local dark, light

    clip(cr, t.clip)
    if t.pressed and t.mousefocus then
      dark, light = self.lightcolor, self.darkcolor
    else
      light, dark = self.lightcolor, self.darkcolor
    end

    if setcolor(cr, light) then
      fillrect(cr, x-offset, y-offset, w + offset, h + offset, self.cornerradius)
    end

    if setcolor(cr, dark) then
      fillrect(cr, x, y, w+offset, h+offset, self.cornerradius)
    end

    if t.mousefocus then
      if setcolor(cr, self.hovercolor) then
        fillrect(cr, x, y, w, h, self.cornerradius)
      end
    else
      if setcolor(cr, self.fillcolor) then
        fillrect(cr, x, y, w, h, self.cornerradius)
      end
    end

    if setcolor(cr, self.textcolor) then
      if t.pressed and t.mousefocus then
        t.font:print(cr, t.x + t.penx + offset, t.y + t.peny + offset, t.text)
      else
        t.font:print(cr, t.x + t.penx, t.y + t.peny, t.text)
      end
    end

    return drawlinks(self, t, cr)
  end
end

do --scroll

  do
    local bar = cel.scroll.layout.ybar
    bar.autohide = true 
    bar.decbutton.link = {'width.top', 1}
    bar.incbutton.link = {'width.bottom', 1}

    do
      local size = bar.size
      do
        local track = bar.track
        track.link = {'edges', 1, size}
        track.slider.size = size-2
      end
    end
  end

  do
    local bar = cel.scroll.layout.xbar
    bar.autohide = true
    bar.decbutton.link = {'left.height', nil, 1}
    bar.incbutton.link = {'right.height', nil, 1}

    do
      local size = bar.size
      do
        local track = bar.track
        track.link = {'edges', size, 1}
        track.slider.size = size-2
      end
    end
  end

  local face = cel.face {
    metacel = 'scroll',
    fillcolor = false,
    linecolor = false,
    flow = {
      scroll = cel.flows.linear(200);
      --showybar = cel.flows.linear(500);
      --hideybar = cel.flows.linear(100);
      --showxbar = cel.flows.linear(500);
      --hidexbar = cel.flows.linear(100);
    };

    draw = function(self, t)
      local cr = self.cr
      if setcolor(cr, self.fillcolor) then
        clip(cr, t.clip)
        fillrect(cr, t.x, t.y, t.w, t.h)
      end
      return drawlinks(self, t)
    end,
  }

  local function draw(face, t)
    local cr = face.cr
    clip(cr, t.clip)
    if setcolor(cr, face.fillcolor) then
      fillrect(cr, t.x, t.y, t.w, t.h)
    end
    if setcolor(cr, face.linecolor) then
      strokerect(cr, t.x, t.y, t.w, t.h)
    end
    return drawlinks(face, t)
  end

  cel.face {
    metacel = 'scroll.bar',
    fillcolor = newcolor(118/255, 151/255, 193/255),
    linecolor = newcolor(178/255, 208/255, 246/255),
    draw = function(self, t)
      local cr = self.cr
      if setcolor(cr, self.fillcolor) then
        clip(cr, t.clip)
        fillrect(cr, t.x, t.y, t.w, t.h)
      end
      if setcolor(cr, self.linecolor) then
        clip(cr, t.clip)
        strokerect(cr, t.x, t.y, t.w, t.h)
      end
      return drawlinks(self, t)
    end,
  }

  cel.face {
    metacel = 'scroll.bar.track',
    linecolor = false,
    fillcolor = false,
    draw = draw,
  }

  do
    local face = cel.face {
      metacel = 'scroll.bar.dec',
      linecolor = newcolor(89/255, 105/255, 145/255),
      fillcolor = newcolor(178/255, 208/255, 246/255),
    }

    function face:draw(t)
      local cr = self.cr

      local size = t.host.size
      local axis = t.host.axis
      clip(cr, t.clip)

      if t.mousefocus or t.host.mousefocus then 
        setcolor(cr, self.fillcolor)
        fillrect(cr, t.x, t.y, t.w, t.h)
      end

      if setcolor(cr, self.linecolor) then
        if t.host.mousefocus then strokerect(cr, t.x, t.y, t.w, t.h) end
        cr:save()
        cr:translate(t.x, t.y)
        cr:scale(t.w, t.h)
        if axis == 'y' then
          cr:move_to(.5, .4)
          cr:line_to(.75, .6)
          cr:line_to(.25, .6)
        else
          cr:move_to(.4, .5)
          cr:line_to(.6, .75)
          cr:line_to(.6, .25)
        end
        cr:fill()
        cr:restore()
      end
      return drawlinks(self, t)
    end
  end

  do
    local face = cel.face {
      metacel = 'scroll.bar.inc',
      linecolor = newcolor(89/255, 105/255, 145/255),
      fillcolor = newcolor(178/255, 208/255, 246/255),
    }

    function face:draw(t)
      local cr = self.cr

      local size = t.host.size
      local axis = t.host.axis
      clip(cr, t.clip)

      if t.mousefocus or t.host.mousefocus then 
        setcolor(cr, self.fillcolor)
        fillrect(cr, t.x, t.y, t.w, t.h)
      end

      if setcolor(cr, self.linecolor) then
        if t.host.mousefocus then strokerect(cr, t.x, t.y, t.w, t.h) end
        cr:save()
        cr:translate(t.x, t.y)
        cr:scale(t.w, t.h)
        if axis == 'y' then
          cr:move_to(.5, .6)
          cr:line_to(.75, .4)
          cr:line_to(.25, .4)
        else
          cr:move_to(.6, .5)
          cr:line_to(.4, .75)
          cr:line_to(.4, .25)
        end
        cr:fill()
        cr:restore()
      end
      return drawlinks(self, t)
    end
  end

  cel.face {
    metacel = 'scroll.bar.slider',
    fillcolor = newcolor(189/255, 202/255, 219/255),
    linecolor = newcolor(89/255, 105/255, 145/255),
    
    draw = function(self, t)
      local size = t.host.host.size
      local cr = self.cr
      if setcolor(cr, self.fillcolor) then
        clip(cr, t.clip)
        fillrect(cr, t.x, t.y, t.w, t.h)
      end
      if setcolor(cr, self.linecolor) then
        clip(cr, t.clip)
        strokerect(cr, t.x, t.y, t.w, t.h)

        cr:save()
        cr:translate(t.x + t.w/2, t.y + t.h/2)
        cr:scale(size, size)
        cr:arc(0, 0, .1, 0, 2 * math.pi);
        cr:fill()
        cr:restore()
      end
      return drawlinks(self, t)
    end,
  }
end

do --window
  local face = cel.face {
    metacel = 'window',
    fillcolor = newcolor(1, 1, 1),
    focuscolor = newcolor(0, 0, 1),
    hovercolor = newcolor(.5, 1, .3),
    linecolor = newcolor(1, 0, 0),
    flow = {
      minimize = cel.flows.linear(200),
      maximize = cel.flows.linear(200),
      restore = cel.flows.linear(200),
    }
  }

  function face:draw(t)
    drawlinks(self, t)
    local cr = self.cr
    local color
    if t.keyboardfocus then --TODO change t.keyboard to t.focus in cel lib
      color = self.focuscolor
    elseif t.mousefocus then
      color = self.hovercolor
    else
      color = self.linecolor
    end

    if setcolor(cr, color) then
      clip(cr, t.clip)
      strokerect(cr, t.x, t.y, t.w, t.h)
    end
  end

  do --window@handle
    local face = cel.face {
      metacel = 'window@handle',
      fillcolor = newcolor(.1, .1, 1),
      textcolor = newcolor(.5, .5, 1),
    }

    function face:draw(t)
      local cr = self.cr
      clip(cr, t.clip)      
      if setcolor(cr, self.fillcolor) then
        fillrect(cr, t.x, t.y, t.w, t.h)
      end
      if t.host.title then
        if setcolor(cr, self.textcolor) then
          self.font:printlt(cr, t.x + 4, t.y + 4, t.host.title)
        end
      end
      return drawlinks(self, t)
    end
  end

  do --window@border, window@corner
    local face = cel.face {
      metacels = {'window@border', 'window@corner'},
      grabcolor = newcolor(123, 231, 132),

      draw = function(self, t)
        local cr = self.cr
        local color
        if t.mousefocus == 1 or t.isgrabbed then
          color = self.grabcolor
        else
          color = self.fillcolor
        end
        if setcolor(cr, color) then
          clip(cr, t.clip)
          fillrect(cr, t.x, t.y, t.w, t.h)
        end
        return drawlinks(self, t)
      end
    }
  end

  do --window@client
    local face = cel.face { 
      metacel = 'window@client',
      fillcolor = newcolor(1, 1, 1),
    }

    function face:draw(t)
      local cr = self.cr
      if setcolor(cr, self.fillcolor) then
        clip(cr, t.clip)
        fillrect(cr, t.x, t.y, t.w, t.h)
      end
      return drawlinks(self, t)
    end
  end
end

do --listbox
  local face = cel.face {
    metacel = 'listbox',
    fillcolor = false,
    linecolor = false,
  }

  function face:draw(t)
    local cr = self.cr
    if setcolor(cr, self.fillcolor) then
      clip(cr, t.clip)
      fillrect(cr, t.x, t.y, t.w, t.h)
    end
    return drawlinks(self, t)
  end

  do
    local face = cel.face {
      metacel = 'listbox.portal',
      fillcolor = cel.color.encode(1, 1, 1),
      linecolor = false, 
    }

    function face:draw(t)
      local cr = self.cr
      if setcolor(cr, self.fillcolor) then
        clip(cr, t.clip)
        fillrect(cr, t.x, t.y, t.w, t.h)
      end
      if setcolor(cr, self.linecolor) then
        clip(cr, t.clip)
        strokerect(cr, t.x, t.y, t.w, t.h)
      end
      return drawlinks(self, t)
    end
  end

  do
    local face = cel.face {
      metacel = 'listbox.items',
      fillcolor = false,
      linecolor = false,
    }

    function face:draw(t)
      local cr = self.cr
      if setcolor(cr, self.fillcolor) then
        clip(cr, t.clip)
        fillrect(cr, t.x, t.y, t.w, t.h)
      end
      return drawlinks(self, t)
    end
  end

  do
    local face = cel.face {
      metacel = 'listbox.items.item',
      fillcolor = false,
      linecolor = false,
      selectedcolor = cel.color.encode(0, 0, .7, .1),
      currentcolor = false,
      hovercolor = false,
    }

    function face:draw(t)
      local cr = self.cr
      if t.selected then
        drawlinks(self, t)
        if setcolor(cr, face.selectedcolor) then
          clip(cr, t.clip)
          fillrect(cr, t.x, t.y, t.w, t.h)
        end
      else
        if t.mousefocus then
          if setcolor(cr, self.hovercolor) then 
            clip(cr, t.clip)
            fillrect(cr, t.x, t.y, t.w, t.h)
          end
        end
        drawlinks(self, t)
      end

      if t.current then
        if setcolor(cr, self.currentcolor) then
          clip(cr, t.clip)
          strokerect(cr, t.x, t.y, t.w, t.h)
        end
      end
    end
  end
end

do --editbox
  local face = cel.face {
    metacel = 'editbox',
    fillcolor = false,
    linecolor = cel.color.encode(0, 0, 0),
    textcolor = newcolor(0, 0, 0),
    selectedcolor = newcolor(0, 0, 1),
    font = cel.loadfont('times new roman', 30),
    layout = {
      text = {
        face = cel.face {
          metacel = 'editbox.text',
          name = cel.loadfont('arial', 44),
          font = cel.loadfont('arial', 44),
        },
      },
    },
  }

  function face:draw(t)
    local cr = self.cr
    clip(cr, t.clip)
    if setcolor(cr, self.fillcolor) then
      fillrect(cr, t.x, t.y, t.w, t.h)
    end
    if setcolor(cr, self.linecolor) then
      strokerect(cr, t.x, t.y, t.w, t.h)
    end
    return drawlinks(self, t) 
  end

  do --editbox.text
    local face = cel.face {
      metacel = 'editbox.text',
      fillcolor = false,
      linecolor = false,
      textcolor = newcolor(0, 0, 0),
      font = cel.loadfont('monospace', 10)
    }

    function face:draw(t, cr)
      local cr = self.cr
      local line = t.lines[1]

      if setcolor(cr, self.fillcolor) then
        clip(cr, t.clip)
        fillrect(cr, t.x, t.y, t.w, t.h)
      end
      if setcolor(cr, self.textcolor) then
        clip(cr, t.clip)
        t.font:print(cr, t.x + line.penx, t.y + line.peny, t.text, line.i, line.j)
      end
      if t.caret then 
        setcolor(cr, self.textcolor)
        strokerect(cr, t.x + t.caretx - 1, t.y + line.y, 1, line.h)
      end
      
      if setcolor(cr, self.linecolor) then
        clip(cr, t.clip)
        strokerect(cr, t.x, t.y, t.w, t.h)
      end
      
      return drawlinks(self, t, cr)
    end
  end
end

--[===[

do --editbox
  local face = cel.face {
    metacel = 'editbox',
    fillcolor = newcolor(1, 1, 1),
    linecolor = newcolor(1, 0, 1),
    textcolor = newcolor(0, 0, 0),
    selectedcolor = newcolor(0, 0, 1),
  }

  function face:draw(t)
    local cr = self.cr

    clip(cr, t.clip)

    if setcolor(self.fillcolor) then
      fillrect(cr, t.x, t.y, t.w, t.h)
    end
    if setcolor(self.linecolor) then
      strokerect(cr, t.x, t.y, t.w, t.h)
    end

    if t.text and t.text ~= '' then
      setcolor(cr, self.textcolor)
      t.font:print(cr, t.x + t.penx, t.y + t.peny, t.text)
    end

    if t.selection then
      setcolor(cr, self.selectedcolor)
      fillrect(cr, t.x + t.selectionbox.x, t.y + t.selectionbox.y, t.selectionbox.w, t.selectionbox.h)
      local x = t.x + t.selectionbox.x
      local y = t.y + t.selectionbox.y
      clipltrb(math.max(x, t.clip.l),
               math.max(y, t.clip.t),
               math.min(x + t.selectionbox.w, t.clip.r),
               math.min(y + t.selectionbox.h, t.clip.b))
      setcolor(cr, self.fillcolor)
      t.font:print(cr, t.x + t.penx, t.y + t.peny, t.text)
      clip(cr, t.clip)
    end

    if t.caret then 
      local elapse = _G.drawtimestamp - (t.carettimestamp or 0)

      --caret is visible for 500ms after it is activated and blinks off for 300ms
      if false or (elapse % 800) > 500 then --TODO why math.floor? does it matter
        --caret blinks off don't draw it
      else
        --caret blinks on
        setcolor(cr, self.textcolor)
        strokerect(cr, t.x + t.caretx, t.y + t.textbox.y, 2, t.textbox.h)
      end
    end
    return drawlinks(self, t) 
  end
end
--]===]

do --border
  local face = cel.face {
    metacel = 'border',
    fillcolor = newcolor(.7, .7, .7, .5),
    linecolor = false, --reactor.graphics.newcolor(0, 0, 1),
    cornerradius = 4,
  }

  function face:draw(t)
    local cr = self.cr
    if setcolor(cr,self.fillcolor) then
      clip(cr, t.clip)
      fillrect(cr, t.x, t.y, t.w, t.h, self.cornerradius)
    end
    if setcolor(cr, self.linecolor) then
      clip(cr, t.clip)
      strokerect(cr, t.x, t.y, t.w, t.h, self.cornerradius)
    end
    return drawlinks(self, t)
  end

  cel.face {
    metacel = 'border',
    name = '@gap',
    draw = drawlinks,
  }
end

do --document.section
  local face = cel.face {
    metacel = 'document.section',
    fillcolor = newcolor(.7, .7, .7, .5),
    linecolor = false, 
    cornerradius = 4,
  }

  function face:draw(t)
    local cr = self.cr
    if setcolor(cr, self.fillcolor) then
      clip(cr, t.clip)
      fillrect(cr, t.x, t.y, t.w, t.h, self.cornerradius)
    end
    if setcolor(cr, self.linecolor) then
      clip(cr, t.clip)
      strokerect(cr, t.x, t.y, t.w, t.h, self.cornerradius)
    end
    return drawlinks(self, t)
  end
end

do
  local face = cel.face {
    metacel = 'document.hyperlink',
  }

  function face:draw(t)
    local cr = self.cr
    clip(cr, t.clip)
    if t.mousefocus then
      setcolor(cr, self.hovercolor)
      t.font:print(cr, t.x + t.penx, t.y + t.peny, t.text)
      fillrect(cr, t.x + t.penx, t.y + t.peny + 2, t.textw, 1)
    else
      setcolor(cr, self.textcolor)
      t.font:print(cr, t.x + t.penx, t.y + t.peny, t.text)
    end
  end
end

do --menu
    local menu = cel.face {
      metacel = 'menu',
      fillcolor = newcolor(1, 1, 1),
      linecolor = newcolor(0, 1, 1),
      options = {
        showdelay = 200;
        hidedelay = 200;
        slot = {
          link = {'+width', 100};
          padding = {
            l = 0,
            r = 30,
            t = function(w, h) return h*.25 end; 
            b = function(w, h) return h*.25 end;
          };
          item = {
            link = {'width'};
          };
        };
        divider = {
          w = 1; h = 1;
          link = {'width', 2};
        }
      };
    }

    function menu:draw(t)
      local cr = self.cr
      clip(cr, t.clip)

      if setcolor(cr, self.fillcolor) then
        fillrect(cr, t.x, t.y, t.w, t.h)
      end
      

      if setcolor(cr, self.linecolor) then
        strokerect(cr, t.x, t.y, t.w, t.h)
      end

      return drawlinks(self, t)
    end

    do --menu.slot
      local item = cel.face {
        metacel = 'menu.slot',
        font = cel.face.get().font,
        altcolor = newcolor(1, 1, .5, .5),
        textcolor = newcolor(0, 0, 0),
      }

      function item:draw(t)

        local cr = self.cr
        drawlinks(self, t)
        clip(cr, t.clip)

        if t.submenu then
          local linker = cel.getlinker('right.center')
          local x, y, w, h = linker(t.w, t.h, 0, 0, t.h/3, t.h/3, t.h/4, 0)
          fillrect(cr, t.x + x, t.y + y, w, h)
        end

        if t.mousefocus or t.submenu == 'active' then
          if setcolor(cr, self.altcolor) then
            fillrect(cr, t.x, t.y, t.w, t.h)
          end
        end
      end
    end

    do --menu.divider
      local divider = cel.face {
        metacel = 'cel';
        name = cel.menu.divider;
        fillcolor = newcolor(.8, .8, .8);
      }

      function divider:draw(t)
        local cr = self.cr
        if setcolor(cr, self.fillcolor) then
          clip(cr, t.clip)
          fillrect(cr, t.x, t.y, t.w, t.h)
        end
      end
    end
  end
return M
