local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local face = cel.face {
    metacel = 'textbutton',

    textcolor = cel.color.encodef(.8, .8, .8),
    fillcolor = cel.color.encodef(.2, .2, .2),
    linecolor = cel.color.encodef(.4, .4, .4),
    linewidth = linewidth,
    radius = radius,

    variation = {
      pressed = {
        fillcolor = cel.color.encodef(.4, .4, .4),
        linecolor = cel.color.encodef(0, 1, 1),
      },
      mousein = {
        fillcolor = cel.color.encodef(.4, .4, .4),
        linecolor = cel.color.encodef(0, 1, 1),
        variation = {
          pressed = {
            textcolor = cel.color.encodef(.2, .2, .2),
            fillcolor = cel.color.encodef(0, .8, .8),
            linecolor = cel.color.encodef(0, 1, 1),
            linewidth = 2,
          },
        },
      },
    },

    layout = {
      padding = {
        fitx = 'bbox',
        l = function(w, h, font) return font.bbox.ymax * .5 end, --TODO need font em
        t = function(w, h, font) return h*.35 end,
      },
    },
  }

  function face:draw(t)
    local fv = self

    if t.mousein then
      fv = fv.variation.mousein
      if t.pressed then
        fv = fv.variation.pressed
      end
    elseif t.pressed then
      fv = fv.variation.pressed
    end

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


