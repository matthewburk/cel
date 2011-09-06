local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local face = cel.getmetaface('button')

  face.textcolor = cel.color.encodef(.8, .8, .8)
  face.fillcolor = cel.color.encodef(.2, .2, .2)
  face.linecolor = cel.color.encodef(.4, .4, .4)
  face.linewidth = 1

  function face.select(face, t)
    if t.mousefocusin then
      face = face['%mousefocusin'] or face
      if t.pressed then
        face = face['%pressed'] or face
      end
    elseif t.pressed then
      face = face['%pressed'] or face
    end
    return face
  end

  do
    face['%pressed'] = face:new {
      fillcolor = cel.color.encodef(.4, .4, .4),
      linecolor = cel.color.encodef(0, 1, 1),
    }

    face['%mousefocusin'] = face:new {
      fillcolor = cel.color.encodef(.4, .4, .4),
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

  do --red button
    local face = cel.getmetaface('button'):new {
      fillcolor = cel.color.encodef(1, 0, 0),
    }

    face:register('red')
  end
end


