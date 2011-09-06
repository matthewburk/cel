local cel = require 'cel'

return function(root)

  local new = cel.label.new

  local linker = cel.composelinker('width', 'center')
  linker = nil
  cel.window {
    w = 400, h = 400, 
    title = 'listbox';

    link = 'edges';
    function(self)
      self:adddefaultcontrols()
    end,
    cel.listbox {
      w = 400, 
      function(listbox)
        for i=1, 3000 do
          new('Hello'):link(listbox, linker)
          new('Madison'):link(listbox, linker)
          new('Zoe'):link(listbox, linker)
          new('Schwab'):link(listbox, linker)
          new('Burk'):link(listbox, linker)
          new('I Love YOU!'):link(listbox, linker)
          new('Volvo'):link(listbox, linker)
          new('Saab'):link(listbox, linker)
          new('Mercedes'):link(listbox, linker)
          new('Audi'):link(listbox, linker)
        end
        print(listbox:len())
      end
    },
  }:link(root)

  

end

