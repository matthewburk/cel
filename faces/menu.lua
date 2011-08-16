local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local menu = cel.face {
    metacel = 'menu',
    fillcolor = cel.color.encodef(.4, .4, .4),
    linecolor = cel.color.encodef(.2, .2, .2),
    linewidth = false,
    radius = radius,

    layout = {
      showdelay = 200;
      hidedelay = 200;
      slot = {
        link = {'+width', 100};
        padding = {
          l = 0,
          r = 30,
          t = function(w, h) return h*.25 end; 
          b = function(w, h) return h*.25 end;
        };
        item = {
          link = 'width';
        };
      },
      divider = {
        w = 1; h = 1;
        link = {'width', 2};
      },
    }
  }

  do --menu divider
    cel.face {
      metacel = 'cel';
      name = cel.menu.divider;
      fillcolor = cel.color.encodef(.8, .8, .8);
    }
  end

  do --menu.slot
    local item = cel.face {
      metacel = 'menu.slot',
      forecolor = cel.color.encodef(1, 1, .5, .5),
    }

    function item:draw(t)
      drawlinks(t)

      clip(t.clip)

      if t.submenu then
        local linker = cel.getlinker('right.center')
        local x, y, w, h = linker(t.w, t.h, 0, 0, t.h/3, t.h/3, t.h/4, 0)
        fillrect(t.x + x, t.y + y, w, h)
      end

      if t.mousefocusin or t.submenu == 'active' then
        if setcolor(self.forecolor) then
          fillrect(t.x, t.y, t.w, t.h)
        end
      end
    end
  end

end






