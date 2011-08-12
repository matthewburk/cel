local cel = require 'cel'

return function(_ENV)
  local face = cel.face {
    metacel = 'button',
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
  }

  local drawcel = cel.face.get('cel').draw

  function face:draw(t)
    local fv = self

    if t.pressed then
      fv = fv.variation.pressed or fv
    end

    return drawcel(fv, t)
  end
end

