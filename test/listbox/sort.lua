local cel = require 'cel'

return function(root)

  local function comp(b1, b2)
    return b1:gettext() < b2:gettext()
  end

  local function rcomp(b1, b2)
    return b2:gettext() < b1:gettext()
  end

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
      onmousedown = function(listbox)
        listbox:sort(rcomp)
      end,
      onmouseup = function(listbox)
        listbox:sort(comp)
      end,

      function(listbox)
        for i=1, 30 do
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

