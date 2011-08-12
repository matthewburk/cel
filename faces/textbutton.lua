local cel = require 'cel'

return function(_ENV)
  local face = cel.face {
    metacel = 'textbutton',
    textcolor = cel.color.encodef(0, 0, 0),
    fillcolor = cel.color.encodef(0, .5, .5),
    linecolor = cel.color.encodef(1, 0, 0),
    linewidth = 1,
    radius = false,

    variation = {
      pressed = {
        fillcolor = cel.color.encodef(0, .8, .8),
        linecolor = cel.color.encodef(0, 1, 1),
        linewidth = 2,
        variation = {
          mousetouch = {
          },
        },
      },
    },

    layout = {
      padding = {
        fitx = 'bbox',
        l = function(w, h, text, font) return font.em end,
        t = function(w, h, text, font) return h*.35 end,
      },
    },
  }

  setvariations(face) 

  function face:draw(t)
    local fv = self

    if t.pressed then
      fv = fv.variation.pressed
      if t.mousetouch then
        fv = fv.variation.mousetouch
      end
    end

    clip(t.clip)
    
    if setcolor(fv.fillcolor) then
      clip(t.clip)
      fillrect(t.x, t.y, t.w, t.h, fv.radius)
    end

    if fv.linewidth and setcolor(fv.linecolor) then
      setlinewidth(fv.linewidth)
      clip(t.clip)
      strokerect(t.x, t.y, t.w, t.h, fv.radius)
    end

    if t.text and setcolor(fv.textcolor) then
      setfont(t.font)
      printstring(t.x + t.penx, t.y + t.peny, t.text)
    end

    return drawlinks(t)
  end
end


