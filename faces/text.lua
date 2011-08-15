local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local face = cel.face {
    metacel = 'text',

    textcolor = cel.color.encodef(.8, .8, .8),
    fillcolor = false,
    linecolor = false,
    linewidth = false,
    radius = radius,

    layout = {
      padding = {
        l = function(w, h, font) return font.bbox.ymax * .1 end,
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
      for i, line in ipairs(t.lines) do
        --uncomment this optimization later
        --if t.y + line.y < t.clip.b  and t.y + line.y + line.h > t.clip.t then
          fillstring(t.font, t.x + line.penx, t.y + line.peny, t.text, line.i, line.j)
        --end
      end
    end

    if fv.linewidth and setcolor(fv.linecolor) then
      setlinewidth(fv.linewidth)
      strokerect(t.x, t.y, t.w, t.h, fv.radius)
    end

    return drawlinks(t)
  end

  indexvariations(face) 
end




