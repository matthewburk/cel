local cel = require 'cel'

return function(root)

  local doc = cel.document.loadfile('D:/projects/cel-reactor/cel/test/document/testdoc.lua'):link(root, 'edges')

end

