return function(root)
local cel = require 'cel'

--so we can link a string to a cel
string.link = cel.string.link

  --[[
  local menu = cel.menu {
    'this',
    'is',
    'a',
    'menu',

    cel.menu.divider,

    cel.menu {
      name = 'submenu',
      'a',
      'b',
      submenu2 = {
        '1',
        '2',
        '3';
      },
      'c',
    },
  }
  --]]
  ---[[
  local menu = cel.menu {
    root = root,
    cel.text.new [[this is a rather large item]],
    'is',
    'a',
    'menu',
    cel.menu.divider;
    cel.menu.fork {
      fork = 'submenu';
      'a',
      'b',
      cel.menu.fork {
        fork = 'submenu2';
        '1',
        '2',
        '3';
      };
      'c',
    }
  }
  --]]

  string.link('hello ima string', root, 'center')

  cel.window.new(200, 200):link(root)

  function menu:onchoose(item)
    print(item)
    print('unlinking', self)
    self:unlink()
  end

  function root:onmouseup(button, x, y, incept)
    if button == cel.mouse.buttons.right and root:hasfocus(cel.mouse) == 1 then
      menu:showat(x, y)
    end
  end
end
