local cel = require 'cel'

local function setcolor(color)
  if not color then return false end
  local r, g, b, a = cel.color.decode(color)
  if a == 0 then return false end
  love.graphics.setColor(r, g, b, a)
  return true
end

local function clip(t)  
  love.graphics.setScissor(t.l, t.t, t.r-t.l, t.b-t.t)
end

local function strokerect(x, y, w, h, r)
  love.graphics.rectangle('line', x+.5, y+.5, w, h)
end

local function fillrect(x, y, w, h, r)
  love.graphics.rectangle('fill', x, y, w, h)
end

local function printstring(font, x, y, text, i, j)
  love.graphics.setFont(font.nativefont)
  if i then text = text:sub(i, j) end
  return love.graphics.print(text, x, y - font.bbox.ymax)
end

local function printstringlt(font, x, y, text, i, j)
  love.graphics.setFont(font.nativefont)

  local xmin = font.bbox.xmin
  if xmin ~= 0 then
    xmin = font:measurebbox(text, i, j) --TODO avoid measuring the text when rendering in all cases 
  end

  if i then text = text:sub(i, j) end

  return love.graphics.print(text, x, y)
end

local function drawlinks(face, t)
  for i = #t,1,-1 do
    local t = t[i]
    t.face:draw(t)
  end
end

do --cel face
  local center = function(hw, hh, x, y, w, h) return (hw - w)/2, (hh - h)/2, w, h end

  local face = cel.face {
    font = cel.loadfont(),
    textcolor = cel.color.rgb(255, 255, 255),
    fillcolor = cel.color.rgb(200, 200, 200),
    linecolor = cel.color.rgb(200, 200, 200),
  }

  --use this one for debugging
  --[[
  function face:draw(t)
    clip(t.clip)
    setcolor(self.linecolor)
    strokerect(t.x, t.y, t.w, t.h)

    local font = t.font or self.font
    local string = t.metacel
    local stringw, stringh = font:measure(string)
    local stringh = font:height()
    local x, y = center(t.w, t.h, 0, 0, stringw, stringh)
    setcolor(self.textcolor)
    printstringlt(font, t.x + math.floor(x), t.y + math.floor(y), string)
    return drawlinks(self, t)
  end
  --]]
  ---[[
  function face:draw(t)
    if self.color then
      if setcolor(self.color) then
        clip(t.clip)
        fillrect(t.x, t.y, t.w, t.h)
      else
        if setcolor(self.fillcolor) then
          clip(t.clip)
          fillrect(t.x, t.y, t.w, t.h)
        end
        if setcolor(self.linecolor) then
          clip(t.clip)
          strokerect(t.x, t.y, t.w, t.h)
        end
      end
    else

    end
    return drawlinks(self, t)
  end
  --]]
end

do --root
  local face = cel.face {
    metacel = 'root',
    fillcolor = false,
    linecolor = false,
  }

  function face:draw(t)
    if setcolor(self.fillcolor) then
      clip(t.clip)
      fillrect(t.x, t.y, t.w, t.h)
    end
    return drawlinks(self, t)
  end
end

do --cel@circle
  local face = cel.face {
    name = '@circle',
    fillcolor = cel.color.encode(0, 0, 0),
    linecolor = false,
  }

  function face:draw(t)
    if setcolor(self.fillcolor) then
      clip(t.clip)
      love.graphics.circle('fill', t.x + t.w/2, t.y + t.h/2, t.w/2, 16)
    end
    return drawlinks(self, t)
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

  function face:draw(t)
    if setcolor(self.fillcolor) then
      clip(t.clip)
      fillrect(t.x, t.y, t.w, t.h)
    end
    if setcolor(self.textcolor) then
      clip(t.clip)
      local font = t.font or self.font
      printstring(font, t.x + t.penx, t.y + t.peny, t.text)
    end
    if setcolor(self.linecolor) then
      clip(t.clip)
      strokerect(t.x, t.y, t.w, t.h)
    end
    return drawlinks(self, t)
  end

  cel.face {
    metacel = 'label',
    name = cel.menu,
    font = cel.loadfont('arial', 10);
    textcolor = cel.color.encode(0, 0, 0),
  }
end

do --text
  local face = cel.face {
    metacel = 'text',
    fillcolor = false,
    linecolor = false,
    textcolor = cel.color.encode(0, 0, 0),
    font = cel.loadfont('monospace', 10)
  }

  function face:draw(t)
    if setcolor(self.fillcolor) then
      clip(t.clip)
      fillrect(t.x, t.y, t.w, t.h)
    end
    if setcolor(self.textcolor) then
      clip(t.clip)
      for i, line in ipairs(t.lines) do
        if t.y + line.y < t.clip.b  and t.y + line.y + line.h > t.clip.t then
          printstring(t.font, t.x + line.penx, t.y + line.peny, t.text, line.i, line.j)
        end
      end
    end
    if setcolor(self.linecolor) then
      clip(t.clip)
      strokerect(t.x, t.y, t.w, t.h)
    end
    
    return drawlinks(self, t)
  end
end

do --button
  local face = cel.face {
    metacel = 'button',
    fillcolor = cel.color.encode(.5, .5, .9),
    lightcolor = cel.color.encode(.8, .8, .8),
    darkcolor = cel.color.encode(.1, .1, .1),      
    hovercolor = cel.color.encode(.5, .8, .5),
    cornerradius = 0,
    bordersize = 1,
  }

  function face:draw(t)
    clip(t.clip)
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

    if setcolor(light) then
      fillrect(x-offset, y-offset, w + offset, h + offset, self.cornerradius)
    end


    if setcolor(dark) then
      fillrect(x, y, w+offset, h+offset, self.cornerradius)
    end

    if t.mousefocus then
      if setcolor(self.hovercolor) then
        fillrect(x, y, w, h, self.cornerradius)
      end
    else
      if setcolor(self.fillcolor) then
        fillrect(x, y, w, h, self.cornerradius)
      end
    end

    return drawlinks(self, t)
  end
end

do --textbutton
  local face = cel.face {
    metacel = 'textbutton',
    layout = {
      fitx = 'bbox',
      padding = {
        l = function(w,h) return 10 + (w * .1) end,
        t = function(w,h) return h * .5 end, 
      },
    },
    cornerradius = 0,
  }

  function face:draw(t)
    local offset = self.bordersize
    local w = t.w - (offset * 2)
    local h = t.h - (offset * 2)
    local x = t.x + offset
    local y = t.y + offset
    local dark, light

    clip(t.clip)
    if t.pressed and t.mousefocus then
      dark, light = self.lightcolor, self.darkcolor
    else
      light, dark = self.lightcolor, self.darkcolor
    end

    if setcolor(light) then
      fillrect(x-offset, y-offset, w + offset, h + offset, self.cornerradius)
    end

    if setcolor(dark) then
      fillrect(x, y, w+offset, h+offset, self.cornerradius)
    end

    if t.mousefocus then
      if setcolor(self.hovercolor) then
        fillrect(x, y, w, h, self.cornerradius)
      end
    else
      if setcolor(self.fillcolor) then
        fillrect(x, y, w, h, self.cornerradius)
      end
    end

    if setcolor(self.textcolor) then
      if t.pressed and t.mousefocus then
        printstring(t.font, t.x + t.penx + offset, t.y + t.peny + offset, t.text)
      else
        printstring(t.font, t.x + t.penx, t.y + t.peny, t.text)
      end
    end

    return drawlinks(self, t)
  end
end

do --scroll
  do
    local bar = cel.scroll.layout.ybar
    bar.autohide = false 
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
      --showybar = cel.flows.linear(1000);
      --hideybar = cel.flows.linear(1100);
      --showxbar = cel.flows.linear(300);
      --hidexbar = cel.flows.linear(100);
    };

    draw = function(self, t)
      if setcolor(self.fillcolor) then
        clip(t.clip)
        fillrect(t.x, t.y, t.w, t.h)
      end
      return drawlinks(self, t)
    end,
  }

  local function draw(face, t)
    clip(t.clip)
    if setcolor(face.fillcolor) then
      fillrect(t.x, t.y, t.w, t.h)
    end
    if setcolor(face.linecolor) then
      strokerect(t.x, t.y, t.w, t.h)
    end
    return drawlinks(face, t)
  end

  cel.face {
    metacel = 'scroll.bar',
    fillcolor = cel.color.encode(118/255, 151/255, 193/255),
    linecolor = cel.color.encode(178/255, 208/255, 246/255),
    draw = function(self, t)
      if setcolor(self.fillcolor) then
        clip(t.clip)
        fillrect(t.x, t.y, t.w, t.h)
      end
      if setcolor(self.linecolor) then
        clip(t.clip)
        strokerect(t.x, t.y, t.w, t.h)
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
      linecolor = cel.color.encode(89/255, 105/255, 145/255),
      fillcolor = cel.color.encode(178/255, 208/255, 246/255),
    }

    function face:draw(t)
      local size = t.host.size
      local axis = t.host.axis
      clip(t.clip)

      if t.mousefocus or t.host.mousefocus then 
        setcolor(self.fillcolor)
        fillrect(t.x, t.y, t.w, t.h)
      end

      if setcolor(self.linecolor) then
        if t.host.mousefocus then strokerect(t.x, t.y, t.w, t.h) end
        local x, y, w, h = t.x, t.y, t.w, t.h
        local x1, y1, x2, y2, x3, y3

        if axis == 'y' then
          x1, y1 = x + (.5*w), y + (.4*h)
          x2, y2 = x + (.75*w), y + (.6*h)
          x3, y3 = x + (.25*w), y + (.6*h)
        else
          x1, y1 = x + (.4*w), y + (.5*h)
          x2, y2 = x + (.6*w), y + (.75*h)
          x3, y3 = x + (.6*w), y + (.25*h)
        end

        love.graphics.triangle('fill', x1, y1, x2, y2, x3, y3)
      end
      return drawlinks(self, t)
    end
  end

  do
    local face = cel.face {
      metacel = 'scroll.bar.inc',
      linecolor = cel.color.encode(89/255, 105/255, 145/255),
      fillcolor = cel.color.encode(178/255, 208/255, 246/255),
    }

    function face:draw(t)
      local size = t.host.size
      local axis = t.host.axis
      clip(t.clip)

      if t.mousefocus or t.host.mousefocus then 
        setcolor(self.fillcolor)
        fillrect(t.x, t.y, t.w, t.h)
      end

      if setcolor(self.linecolor) then
        if t.host.mousefocus then strokerect(t.x, t.y, t.w, t.h) end
        local x, y, w, h = t.x, t.y, t.w, t.h
        local x1, y1, x2, y2, x3, y3

        if axis == 'y' then
          x1, y1 = x + (.5*w), y + (.6*h)
          x2, y2 = x + (.75*w), y + (.4*h)
          x3, y3 = x + (.25*w), y + (.4*h)
        else
          x1, y1 = x + (.6*w), y + (.5*h)
          x2, y2 = x + (.4*w), y + (.75*h)
          x3, y3 = x + (.4*w), y + (.25*h)
        end
        love.graphics.triangle('fill', x1, y1, x2, y2, x3, y3)
      end
      return drawlinks(self, t)
    end
  end

  cel.face {
    metacel = 'scroll.bar.slider',
    fillcolor = cel.color.encode(189/255, 202/255, 219/255),
    linecolor = cel.color.encode(89/255, 105/255, 145/255),
    
    draw = function(self, t)
      local size = t.host.host.size
      if setcolor(self.fillcolor) then
        clip(t.clip)
        fillrect(t.x, t.y, t.w, t.h)
      end
      if setcolor(self.linecolor) then
        clip(t.clip)
        strokerect(t.x, t.y, t.w, t.h)

        love.graphics.circle('fill', t.x + t.w/2, t.y + t.h/2, size * .13, 4)
      end
      return drawlinks(self, t)
    end,
  }
end

do --window
  local face = cel.face {
    metacel = 'window',
    fillcolor = cel.color.encode(1, 1, 1),
    focuscolor = cel.color.encode(0, 0, 1),
    hovercolor = cel.color.encode(.5, 1, .3),
    linecolor = cel.color.encode(1, 0, 0),
    flow = {
      minimize = cel.flows.linear(200),
      maximize = cel.flows.linear(200),
      restore = cel.flows.linear(200),
    }
  }

  function face:draw(t)
    drawlinks(self, t)
    local color
    if t.keyboardfocus then --TODO change t.keyboard to t.focus in cel lib
      color = self.focuscolor
    elseif t.mousefocus then
      color = self.hovercolor
    else
      color = self.linecolor
    end

    if setcolor(color) then
      clip(t.clip)
      strokerect(t.x, t.y, t.w, t.h)
    end
  end

  do --window@handle
    local face = cel.face {
      metacel = 'window@handle',
      fillcolor = cel.color.encode(.1, .1, 1),
      textcolor = cel.color.encode(.5, .5, 1),
    }

    function face:draw(t)
      clip(t.clip)      
      if setcolor(self.fillcolor) then
        fillrect(t.x, t.y, t.w, t.h)
      end
      if t.host.title then
        if setcolor(self.textcolor) then
          printstringlt(self.font, t.x + 4, t.y + 4, t.host.title)
        end
      end
      return drawlinks(self, t)
    end
  end

  do --window@border, window@corner
    local face = cel.face {
      metacels = {'window@border', 'window@corner'},
      grabcolor = cel.color.rgb(123, 231, 132),

      draw = function(self, t)
        local color
        if t.mousefocus == 1 or t.grabbed then
          color = self.grabcolor
        else
          color = self.fillcolor
        end
        if setcolor(color) then
          clip(t.clip)
          fillrect(t.x, t.y, t.w, t.h)
        end
        return drawlinks(self, t)
      end
    }
  end

  do --window@client
    local face = cel.face { 
      metacel = 'window@client',
      fillcolor = cel.color.encode(1, 1, 1),
    }

    function face:draw(t)
      if setcolor(self.fillcolor) then
        clip(t.clip)
        fillrect(t.x, t.y, t.w, t.h)
      end
      return drawlinks(self, t)
    end
  end
end

do --menu
  local menu = cel.face {
    metacel = 'menu',
    fillcolor = cel.color.encode(1, 1, 1),
    linecolor = cel.color.encode(0, 1, 1),
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
    clip(t.clip)
    if setcolor(self.fillcolor) then
      fillrect(t.x, t.y, t.w, t.h)
    end
    if setcolor(self.linecolor) then
      strokerect(t.x, t.y, t.w, t.h)
    end
    return drawlinks(self, t)
  end

  do --menu.slot
    local item = cel.face {
      metacel = 'menu.slot',
      altcolor = cel.color.encode(1, 1, .5, .5),
      textcolor = cel.color.encode(0, 0, 0),
    }

    function item:draw(t)
      drawlinks(self, t)
      clip(t.clip)
      if t.submenu then
        local linker = cel.getlinker('right.center')
        local x, y, w, h = linker(t.w, t.h, 0, 0, t.h/3, t.h/3, t.h/4, 0)
        fillrect(t.x + x, t.y + y, w, h)
      end
      if t.mousefocus or t.submenu == 'active' then
        if setcolor(self.altcolor) then
          fillrect(t.x, t.y, t.w, t.h)
        end
      end
    end
  end

  do --menu.divider
    local divider = cel.face {
      metacel = 'cel';
      name = cel.menu.divider;
      fillcolor = cel.color.encode(.8, .8, .8);
    }

    function divider:draw(t)
      if setcolor(self.fillcolor) then
        clip(t.clip)
        fillrect(t.x, t.y, t.w, t.h)
      end
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
    if setcolor(self.fillcolor) then
      clip(t.clip)
      fillrect(t.x, t.y, t.w, t.h)
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
      if setcolor(self.fillcolor) then
        clip(t.clip)
        fillrect(t.x, t.y, t.w, t.h)
      end
      if setcolor(self.linecolor) then
        clip(t.clip)
        strokerect(t.x, t.y, t.w, t.h)
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
      if setcolor(self.fillcolor) then
        clip(t.clip)
        fillrect(t.x, t.y, t.w, t.h)
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
      if t.selected then
        drawlinks(self, t)
        if setcolor(face.selectedcolor) then
          clip(t.clip)
          fillrect(t.x, t.y, t.w, t.h)
        end
      else
        if t.mousefocus then
          if setcolor(self.hovercolor) then 
            clip(t.clip)
            fillrect(t.x, t.y, t.w, t.h)
          end
        end
        drawlinks(self, t)
      end

      if t.current then
        if setcolor(self.currentcolor) then
          clip(t.clip)
          strokerect(t.x, t.y, t.w, t.h)
        end
      end
    end
  end
end

do --border
  local face = cel.face {
    metacel = 'border',
    fillcolor = cel.color.encode(.7, .7, .7, .5),
    linecolor = false, --reactor.graphics.cel.color.encode(0, 0, 1),
    cornerradius = 4,
  }

  function face:draw(t)
    if setcolor(self.fillcolor) then
      clip(t.clip)
      fillrect(t.x, t.y, t.w, t.h, self.cornerradius)
    end
    if setcolor(self.linecolor) then
      clip(t.clip)
      strokerect(t.x, t.y, t.w, t.h, self.cornerradius)
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
    fillcolor = cel.color.encode(.7, .7, .7, .5),
    linecolor = false, 
    cornerradius = 4,
  }

  function face:draw(t)
    if setcolor(self.fillcolor) then
      clip(t.clip)
      fillrect(t.x, t.y, t.w, t.h, self.cornerradius)
    end
    if setcolor(self.linecolor) then
      clip(t.clip)
      strokerect(t.x, t.y, t.w, t.h, self.cornerradius)
    end
    return drawlinks(self, t)
  end
end

do
  local face = cel.face {
    metacel = 'document.hyperlink',
  }

  function face:draw(t)
    clip(t.clip)
    if t.mousefocus then
      setcolor(self.hovercolor)
      printstring(t.font, t.x + t.penx, t.y + t.peny, t.text)
      fillrect(t.x + t.penx, t.y + t.peny + 2, t.textw, 1)
    else
      setcolor(self.textcolor)
      printstring(t.font, t.x + t.penx, t.y + t.peny, t.text)
    end
  end
end

--[======[
do --editbox
  local face = cel.face {
    metacel = 'editbox',
    fillcolor = cel.color.encode(1, 1, 1),
    linecolor = cel.color.encode(1, 0, 1),
    textcolor = cel.color.encode(0, 0, 0),
    selectedcolor = cel.color.encode(0, 0, 1),
  }

  function face:draw(t)
    clip(t.clip)
    setcolor(self.fillcolor)
    rectangle('fill', t.x, t.y, t.w, t.h)
    setcolor(self.linecolor)
    rectangle('line', t.x, t.y, t.w, t.h)

    if t.text and t.text ~= '' then
      setcolor(self.textcolor)
      gprint(t.font, t.text, t.x + t.penx, t.y + t.peny)
    end

    if t.selection then
      setcolor(self.selectedcolor)
      rectangle('fill', t.x + t.selectionbox.x, t.y + t.selectionbox.y, t.selectionbox.w, t.selectionbox.h)
      local x = t.x + t.selectionbox.x
      local y = t.y + t.selectionbox.y
      clipltrb(math.max(x, t.clip.l),
               math.max(y, t.clip.t),
               math.min(x + t.selectionbox.w, t.clip.r),
               math.min(y + t.selectionbox.h, t.clip.b))
      setcolor(self.fillcolor)
      gprint(t.font, t.text, t.x + t.penx, t.y + t.peny)
      clip(t.clip)
    end

    if t.caret then 
      local elapse = love.cel.graphics.currentdescription.drawtimestamp - (t.carettimestamp or 0)

      --caret is visible for 500ms after it is activated and blinks off for 300ms
      if (elapse % 800) > 500 then --TODO why math.floor? does it matter
        --caret blinks off don't draw it
      else
        --caret blinks on
        setcolor(self.textcolor)
        rectangle('line', t.x + t.caretx, t.y + t.textbox.y, 2, t.textbox.h)
      end
    end
    return drawlinks(self, t) 
  end
end
--]======]
