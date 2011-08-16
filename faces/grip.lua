local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local face = cel.face {
    metacel = 'grip',
    fillcolor = cel.color.encodef(.2, .2, .2),
    linecolor = cel.color.encodef(.4, .4, .4),
    linewidth = 1,
    radius = radius,

    variation = {
      grabbed = {
        fillcolor = cel.color.encodef(.4, .4, .4),
        linecolor = cel.color.encodef(0, 1, 1),
      },
      mousefocusin = {
        fillcolor = cel.color.encodef(.4, .4, .4),
        linecolor = cel.color.encodef(0, 1, 1),
        variation = {
          grabbed = {
            fillcolor = cel.color.encodef(0, .8, .8),
            linecolor = cel.color.encodef(0, 1, 1),
            linewidth = 1,
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
      if t.isgrabbed then
        fv = fv.variation.grabbed
      end
    elseif t.isgrabbed then
      fv = fv.variation.grabbed
    end

    return drawcel(fv, t)
  end

  indexvariations(face)
end

