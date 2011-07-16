local cel = require 'cel'

return function(root)
  local window = cel.window.new(400, 400):link(root):adddefaultcontrols()
end
