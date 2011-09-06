local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local face = cel.getmetaface('label')
  face.textcolor = cel.color.encodef(.8, .8, .8)
  face.fillcolor = false
  face.linecolor = false
  face.linewidth = false

  face.layout = {
    padding = {
      l = 1,
      t = 1,
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
      fillstring(t.font, t.x + t.penx, t.y + t.peny, t.text)
    end

    if f.linewidth and f.linecolor then
      setlinewidth(f.linewidth)
      setcolor(f.linecolor)
      strokerect(t.x, t.y, t.w, t.h, f.radius)
    end

    return drawlinks(t)
  end
end



