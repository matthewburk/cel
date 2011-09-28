local cel = require 'cel'

require 'cel.textbutton'
return function(_ENV)
  setfenv(1, _ENV)

  local face = cel.getface('textbutton')

  face.layout = {
    padding = {
      fitx = 'bbox',
      l = function(w, h, font) return font.bbox.ymax * .5 end, --TODO need font em
      t = function(w, h, font) return h*.35 end,
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

  do
    face['%pressed'] = face:new {
      fillcolor = cel.color.tint(.5, face.fillcolor),
      linecolor = cel.color.encodef(0, 1, 1),
    }

    face['%mousefocusin'] = face:new {
      fillcolor = cel.color.tint(.5, face.fillcolor),
      linecolor = cel.color.encodef(0, 1, 1),
    }
    
    do
      local face = face['%mousefocusin']

      face['%pressed'] = face:new {
        textcolor = cel.color.encodef(.2, .2, .2),
        fillcolor = cel.color.encodef(0, .8, .8),
        linecolor = cel.color.encodef(0, 1, 1),
        linewidth = 2,
      }
    end
  end
end


