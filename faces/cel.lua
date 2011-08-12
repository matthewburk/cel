local cel = require 'cel'

local drawlinks = function(t)
  for i = #t,1,-1 do
    local t = t[i]
    t.face:draw(t)
  end
end

return function(_ENV)
  local face = cel.face {
    metacel = 'cel',
    font = cel.loadfont(),
    textcolor = cel.color.encodef(1, 1, 1),
    fillcolor = false,
    linecolor = false,
    linewidth = 1,
    radius = false,

    variation = {
      mousetouch = {
        linecolor = cel.color.encodef(1, 1, 1),
        linewidth = 3,
      },
    },
  }

  function face:draw(t)
    local fv = self

    if t.mousetouch then
      fv = fv.variation.mousetouch or fv
    end

    clip(t.clip)

    if setcolor(fv.fillcolor) then
      fillrect(t.x, t.y, t.w, t.h, fv.radius)
    end

    if fv.linewidth and setcolor(fv.linecolor) then
      setlinewidth(fv.linewidth)
      strokerect(t.x, t.y, t.w, t.h, fv.radius)
    end

    return drawlinks(t)
  end

  function face:print(t)
  end
end



