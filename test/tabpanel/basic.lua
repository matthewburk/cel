local cel = require 'cel'

local function newtabsubject(name)
  local window = cel.window.new(300, 300, name)
  return window
end

local function newtabselect(tabpanel, name)
  local b =  cel.textbutton.new(name)
  function b:onmousedown()
    tabpanel:selecttab(name)
  end
  return b
end

return function(root)
  root {
    link = {nil, 40, 40};
    cel.window {
      w = 400, h = 400, title = 'tabs';

      function(window)
        window:adddefaultcontrols()

        local tabpanel = cel.tabpanel.new()


        tabpanel:addtab('a', newtabsubject('a') )
        tabpanel:addtab('b', newtabsubject('b') )
        tabpanel:addtab('c', newtabsubject('c') )

        cel.col {
          link = 'edges',
          cel.row {
            newtabselect(tabpanel, 'a'),
            newtabselect(tabpanel, 'b'),
            newtabselect(tabpanel, 'c'),
          },
          { flex = 1,
            tabpanel,
          },
        }:link(window, 'edges')
      end,
    }
  }

end

