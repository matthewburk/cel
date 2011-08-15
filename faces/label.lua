local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local face = cel.face {
    metacel = 'label',

    textcolor = cel.color.encodef(.8, .8, .8),
    fillcolor = false,
    linecolor = false,
    linewidth = false,
    radius = radius,

    layout = {
      padding = {
        l = 1,
        t = 1,
      },
    },
  }

  function face:draw(t)
    local fv = self

    clip(t.clip)
    
    if setcolor(fv.fillcolor) then
      fillrect(t.x, t.y, t.w, t.h, fv.radius)
    end

    if t.text and setcolor(fv.textcolor) then
      fillstring(t.font, t.x + t.penx, t.y + t.peny, t.text)
    end

    if fv.linewidth and setcolor(fv.linecolor) then
      setlinewidth(fv.linewidth)
      strokerect(t.x, t.y, t.w, t.h, fv.radius)
    end

    return drawlinks(t)
  end

  indexvariations(face) 
end



