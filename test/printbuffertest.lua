local cel = require 'cel'

string.link = cel.string.link

return function(root)
  buffer = cel.printbuffer.new():link(cel.window.new(200, 200):link(root), 'edges')
  function root:onmousedown()
    buffer:printdescription()
  end
end
