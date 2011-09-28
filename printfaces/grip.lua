local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local face = cel.getface('grip')
  face.fillcolor = cel.color.encodef(.2, .2, .2)
  face.linecolor = cel.color.encodef(.4, .4, .4)
  face.linewidth = 1

  function face.select(face, t)
    if t.mousefocusin then
      face = face['%mousefocusin'] or face
      if t.isgrabbed then
        face = face['%grabbed'] or face
      end
    elseif t.isgrabbed then
      face = face['%grabbed'] or face
    end
    return face
  end

  do
    face['%grabbed'] = face:new {
      fillcolor = cel.color.encodef(.4, .4, .4),
      linecolor = cel.color.encodef(0, 1, 1),
    }

    face['%mousefocusin'] = face:new {
      fillcolor = cel.color.encodef(.4, .4, .4),
      linecolor = cel.color.encodef(0, 1, 1),
    }
    
    do
      local face = face['%mousefocusin']

      face['%grabbed'] = face:new {
        fillcolor = cel.color.encodef(0, .8, .8),
        linecolor = cel.color.encodef(0, 1, 1),
        linewidth = 1,
      }
    end
  end
end

