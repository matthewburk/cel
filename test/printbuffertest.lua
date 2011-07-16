local cel = require 'cel'

string.link = cel.string.link

return function(root)
  buffer = cel.printbuffer.new():link(cel.window.new(200, 200):link(root), 'edges')
  cprint = function(...)
    buffer:print(...)
  end

  function root:onmousemove(x, y)
    cprint('mouse is at', x, y)
  end
end
