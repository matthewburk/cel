local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local face = cel.face {
    metacel = 'button',
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
      mousefocusin = {
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
  }

  local drawcel = cel.face.get('cel').draw

  function face:draw(t)
    local fv = self

    if t.mousefocusin then
      fv = fv.variation.mousefocusin
      if t.pressed then
        fv = fv.variation.pressed
      end
    elseif t.pressed then
      fv = fv.variation.pressed
    end

    return drawcel(fv, t)
  end

  indexvariations(face)
end

