local cel = require 'cel'

return function(root)

  local new = cel.label.new

  local linker = cel.composelinker('width', 'center')
  linker = nil
  cel.window {
    w = 400, h = 400, 
    title = 'col';
    link = 'edges';

    function(self)
      self:adddefaultcontrols()
    end,
    cel.scroll {
      subject = {
        fillwidth = false;
        fillheight = false;
        cel.col {
          function(col)
            for i=1, 10000 do
              new('Hello'):link(col, linker)
              new('Madison'):link(col, linker)
              new('Zoe'):link(col, linker)
              new('Schwab'):link(col, linker)
              new('Burk'):link(col, linker)
              new('I Love YOU!'):link(col, linker)
              new('Volvo'):link(col, linker)
              new('Saab'):link(col, linker)
              new('Mercedes'):link(col, linker)
              new('Audi'):link(col, linker)
            end
          end
        },
      },
    },
  }:link(root)

end

