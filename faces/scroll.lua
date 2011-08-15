local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local face = cel.face {
    metacel = 'scroll',
    textcolor = false,
    fillcolor = false,
    linecolor = false,
    linewidth = false,
    radius = false,

    flow = {
      scroll = cel.flows.linear(100);
      showybar = cel.flows.linear(500);
      hideybar = cel.flows.linear(300);
      --showxbar = cel.flows.linear(500);
      --hidexbar = cel.flows.linear(100);
    };
  }

  do
    local scrollbar = cel.face {
      metacel = 'scroll.bar',
      --fillcolor = cel.color.encodef(118/255, 151/255, 193/255),
      --linecolor = cel.color.encodef(178/255, 208/255, 246/255),
      fillcolor = cel.color.encodef(.4, .4, .4),
    }

    do --track
      cel.face {
        metacel = 'scroll.bar.track',
        textcolor = false,
        fillcolor = false,
        linecolor = false,
        linewidth = false,
        radius = false,
        draw = function(face, t) return drawlinks(t) end,
      }
    end

    do --slider
      local slider = cel.face {
        metacel = 'scroll.bar.slider',
        fillcolor = cel.color.encodef(.2, .2, .2),
        linecolor = cel.color.encodef(0, 1, 1),
        forecolor = cel.color.encodef(0, 1, 1),
      }

      function slider:draw(t)
        local fv = self
        local size = t.host.host.size

        clip(t.clip)

        if setcolor(fv.fillcolor) then
          fillrect(t.x, t.y, t.w, t.h, fv.radius)
        end

        if fv.linewidth and setcolor(fv.linecolor) then
          setlinewidth(fv.linewidth)
          strokerect(t.x, t.y, t.w, t.h, fv.radius)
        end

        if setcolor(fv.forecolor) then
          save()
          translate(t.x + t.w/2, t.y + t.h/2)
          scale(size, size)
          fillarc(0, 0, .1, 0, 2 * math.pi);
          restore()
        end

        return drawlinks(t)
      end
    end

    do --incbutton
      local incbutton = cel.face {
        metacel = 'scroll.bar.inc',
        fillcolor = cel.color.encodef(.2, .2, .2),
        linecolor = cel.color.encodef(0, 1, 1),
        forecolor = cel.color.encodef(0, 1, 1),
      }

      function incbutton:draw(t)
        local fv = self
        local size = t.host.size
        local axis = t.host.axis

        clip(t.clip)

        if (t.mousein or t.host.mousein) and setcolor(fv.fillcolor) then
          fillrect(t.x, t.y, t.w, t.h, fv.radius)
        end

        if fv.linewidth and setcolor(fv.linecolor) and t.host.mousein then
          setlinewidth(fv.linewidth)
          strokerect(t.x, t.y, t.w, t.h, fv.radius)
        end

        if setcolor(fv.forecolor) then
          save()
          translate(t.x + t.w/2, t.y + t.h/2)
          scale(size, size)
          fillarc(0, 0, .1, 0, 2 * math.pi);
          restore()
        end

        return drawlinks(t)
      end
    end
    do --decbutton
      local decbutton = cel.face {
        metacel = 'scroll.bar.dec',
        fillcolor = cel.color.encodef(.2, .2, .2),
        linecolor = cel.color.encodef(0, 1, 1),
        forecolor = cel.color.encodef(0, 1, 1),
      }

      function decbutton:draw(t)
        local fv = self
        local size = t.host.size
        local axis = t.host.axis

        clip(t.clip)

        if (t.mousein or t.host.mousein) and setcolor(fv.fillcolor) then
          fillrect(t.x, t.y, t.w, t.h, fv.radius)
        end

        if fv.linewidth and setcolor(fv.linecolor) and t.host.mousein then
          setlinewidth(fv.linewidth)
          strokerect(t.x, t.y, t.w, t.h, fv.radius)
        end

        if setcolor(fv.forecolor) then
          save()
          translate(t.x + t.w/2, t.y + t.h/2)
          scale(size, size)
          fillarc(0, 0, .1, 0, 2 * math.pi);
          restore()
        end

        return drawlinks(t)
      end
    end
  end
end


