local cel = require 'cel'

return function(root)

  local new = cel.label.new

  local linker = cel.composelinker('width', 'center')
  linker = nil
  cel.window {
    w = 400, h = 400, 
    title = 'row';
    link = 'edges';

    function(self)
      self:adddefaultcontrols()
    end,
    cel.scroll {
      subject = {
        fillwidth = false;
        fillheight = false;
        cel.row {
          function(row)
            for i=1, 10000 do
              new('Hello'):link(row, linker)
              new('Madison'):link(row, linker)
              new('Zoe'):link(row, linker)
              new('Schwab'):link(row, linker)
              new('Burk'):link(row, linker)
              new('I Love YOU!'):link(row, linker)
              new('Volvo'):link(row, linker)
              new('Saab'):link(row, linker)
              new('Mercedes'):link(row, linker)
              new('Audi'):link(row, linker)
            end
          end
        },
      },
    },
  }:link(root)

end

