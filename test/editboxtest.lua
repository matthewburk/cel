local cel = require 'cel'

return function(root)
 

  local editbox = cel.editbox.new('hello', 200)

  --TODO change the way a face is specified like this
  --cel.editbox.facename.new

  cel.sequence.y {
    editbox,
  }:link(root, 'edges')
end

