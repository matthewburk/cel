local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local window = cel.face {
    metacel = 'window',
    textcolor = false,
    fillcolor = false,
    linecolor = cel.color.encodef(.2, .2, .2),
    linewidth = 4,
    radius = radius,

    flow = {
      minimize = cel.flows.linear(200),
      maximize = cel.flows.linear(200),
      restore = cel.flows.linear(200),
    };

    variation = {
      focus = {
        linecolor = cel.color.encodef(0, 1, 1),
      },
      mousein = {
        linecolor = cel.color.encodef(.4, .4, .4),
      },
    },
  }

  local drawcel = cel.face.get('cel').draw

  function window:draw(t)
    local fv = self

    if t.focus then
      fv = fv.variation.focus
    elseif t.mousein then
      fv = fv.variation.mousein
    end

    return drawcel(fv, t)
  end

  indexvariations(window)

  do
    local handle = cel.face {
      metacel = 'window.handle',
      fillcolor = cel.color.encodef(.4, .4, .4),
      radius=false,
      font = cel.loadfont('arial:bold'),

      variation = {
        focus = {
          textcolor = cel.color.encodef(.2, .2, .2),
          fillcolor = cel.color.encodef(0, 1, 1),
        },
      },
    }

    function handle:draw(t)
      local fv = self

      if t.host.focus then
        fv = fv.variation.focus or fv
      end

      clip(t.clip)

      if setcolor(fv.fillcolor) then
        fillrect(t.x, t.y, t.w, t.h, fv.radius)
      end

      if t.host.title and setcolor(fv.textcolor) then
        fillstringlt(fv.font, t.x + 4, t.y + 4, t.host.title)
      end

      if fv.linewidth and setcolor(fv.linecolor) then
        setlinewidth(fv.linewidth)
        strokerect(t.x, t.y, t.w, t.h, fv.radius)
      end

      return drawlinks(t)
    end

    indexvariations(handle)
  end

  do --client
    cel.face {
      metacel = 'window.client',
      fillcolor = cel.color.encodef(.2, .2, .2),
      linecolor = false,
      linewidth = false,
      radius = radius,
    }
  end

  do --border
    local face = cel.face {
      metacels = {'window.border', 'window.corner'},
      draw = false,
    }
  end
end



