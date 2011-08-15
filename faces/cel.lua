local cel = require 'cel'

return function(_ENV)
  setfenv(1, setmetatable(_ENV, {__index=_G}))

  function _ENV.drawlinks(t)
    for i = #t,1,-1 do
      local t = t[i]
      if t.face.draw then t.face:draw(t) end
    end
  end

  function _ENV.indexvariations(fv)
    if rawget(fv, 'variation') then
      local mt = {__index=fv}
      for k, variation in pairs(rawget(fv, 'variation')) do
        setmetatable(variation, mt)
        indexvariations(variation)
      end
    end
  end

  _ENV.radius = false 
  _ENV.linewidth = 1

  local face = cel.face {
    metacel = 'cel',
    font = cel.loadfont('monospace:bold', 15),
    textcolor = cel.color.encodef(1, 1, 1),
    fillcolor = false,
    linecolor = false,
    linewidth = linewidth,
    radius = radius,
  }

  function face:draw(t)
    local fv = self

    clip(t.clip)

    if setcolor(fv.fillcolor) then
      fillrect(t.x, t.y, t.w, t.h, fv.radius)
    end

    if fv.linewidth and setcolor(fv.linecolor) then
      setlinewidth(fv.linewidth)
      strokerect(t.x, t.y, t.w, t.h, fv.radius)
    end

    return drawlinks(t)
  end

  function face:print(t)
  end

  indexvariations(face)
end



