local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local face = cel.getface('text')
  face.textcolor = cel.color.encodef(.8, .8, .8)
  face.fillcolor = false
  face.linecolor = false
  face.linewidth = false

  face.layout = {
    padding = {
      l = function(w, h, font) return font.bbox.ymax * .1 end,
    },
  }

  function face.draw(f, t)
    clip(t.clip)

    if f.fillcolor then
      setcolor(f.fillcolor)
      fillrect(t.x, t.y, t.w, t.h, f.radius)
    end

    if f.textcolor and t.text then
      setcolor(f.textcolor)
      for i, line in ipairs(t.lines) do
        --uncomment this optimization later
        --if t.y + line.y < t.clip.b  and t.y + line.y + line.h > t.clip.t then
          fillstring(t.font, t.x + line.penx, t.y + line.peny, t.text, line.i, line.j)
        --end
      end
    end

    if f.linewidth and f.linecolor then
      setlinewidth(f.linewidth)
      setcolor(f.linecolor)
      strokerect(t.x, t.y, t.w, t.h, f.radius)
    end

    return drawlinks(t)
  end
end




