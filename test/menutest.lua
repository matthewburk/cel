return function(root)
  local cel = require 'cel'

  local menu = cel.menu {
    cel.text.new [[this is a rather large item]],
    'is',
    'a',
    'menu',
    { [cel.menu.fork] = 'submenu';
      'a',
      'b',
      { [cel.menu.fork] = cel.textbutton.new('submenu2');
        '1',
        '2',
        '3';
      };
      'c',
    }
  }

  local window = cel.window.new(200, 200):link(root, 'edges')

  cel.string.link('hello ima string', window, 'center')

  function menu:onchoose(item)
    self:unlink()
  end

  function window:onmouseup(button, x, y, incept)
    if button == cel.mouse.buttons.right then
      menu:showat(x+1, y+1, root)
    end
  end
end
