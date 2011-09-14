local cel = require 'cel'

return function(_ENV)
  setfenv(1, setmetatable(_ENV, {__index=_G}))

  function _ENV.drawlinks(t, func)
    local _t = t
    for i = #t,1,-1 do
      local t = t[i]
      if func then 
        if not fucn(i, t) then
          local face = t.face.select and t.face:select(t) or t.face
          if face.draw then face:draw(t) end
        end
      else
        --[[
        for k, v in pairs(t.face) do
          print('t.face', k, v)
        end
        local mt = getmetatable(t.face)
          print('t.facemt', mt)
        for k, v in pairs(mt) do
          print('t.facemt', k, v)
        end
        print('t.facemt.mt', getmetatable(mt))

        print('t.face.select', t.face.select)
        --]]
        local face = t.face.select and t.face:select(t) or t.face
        if face.draw then face:draw(t) end
      end
    end
  end

  local face = cel.getface('cel')

  face.font = cel.loadfont('code')
  face.textcolor = cel.color.encodef(1, 1, 1)
  face.fillcolor = false
  face.linecolor = false
  face.linewidth = false
  face.radius = false

  function face.draw(f, t)
    clip(t.clip)

    if f.fillcolor then
      setcolor(f.fillcolor)
      fillrect(t.x, t.y, t.w, t.h, f.radius)
    end

    if f.linewidth and f.linecolor then
      setlinewidth(f.linewidth)
      setcolor(f.linecolor)
      strokerect(t.x, t.y, t.w, t.h, f.radius)
    end

    return drawlinks(t)
  end

  function face.print(f, t)
  end
end





