local cel = require 'cel'

return function(root)

  local new = cel.text.new

  local linker = cel.composelinker('width', 'center')

  local win = cel.window.new():adddefaultcontrols()
  win.debugme = true
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
          --link = 'edges';
          { flex = 5;
            win,
          },
          { link = {linker, nil, nil, {flex = 1, minw = 50}};
            new'hello row wrapable',
          },
          { link = {linker, nil, nil, {flex = 2, minw = 100}};
            new'hello row wrapable',
          },
          cel.window.new():adddefaultcontrols(),
        },
      },
    },
  }:link(root)

end

