local cel = require 'cel'

return function(root)

  local new = cel.textbutton.new

  local face = cel.face.get()

  local linker = cel.composelinker('width', 'center')

  cel.window {
    w = 400, h = 400, 
    title = 'row';
    link = 'edges';

    function(self)
      self:adddefaultcontrols()
    end,
    cel.scroll {
      subject = {
        fillwidth = true;
        fillheight = true;
        cel.row {
          link = 'edges';
          { flex = 1, minw = 10; face=face; 
            new'1.10',
          },
          { flex = 0, minw = 10; face=face; 
            new'0.10',
          },
          { flex = 1, minw = 200; face=face;
            cel.slot {
              cel.label.new('1.200'),
              function(slot) cel.grip.new():link(slot, 'edges'):sink():grip(slot) end,
            },
          },
          { flex = 0, minw = 200; face=face; link = {nil, 10, 10}; 
            cel.slot {
              cel.label.new('0.200'),
              function(slot) cel.grip.new():link(slot, 'edges'):sink():grip(slot) end,
            },
          },
          { flex = 1, minw = 50; face=face; link = {nil, 10, 10}; 
            cel.window.new(0, 0, '1.50'):adddefaultcontrols(),
          },
        },
      },
    },
  }:link(root)

end

