local cel = require 'cel'

return function(root)

  local grid = cel.grid.new { 
    {weight = 1, minw = 50, link = 'left'}, {weight = 0, minw = 15},
    {weight = 1, minw = 50, link = 'left'}, {weight = 0, minw = 15},
    {weight = 1, minw = 50, link = 'center'}, {weight = 0, minw = 15},
    {weight = 1, minw = 50, link = 'right'}, {weight = 0, minw = 15},
    {weight = 1, minw = 50, link = 'width'},
  }

  grid.celfromtext = cel.textbutton.new

  local window = cel.window.new():link(root, 'edges', 5, 5):relink()

  grid:link(window, 'edges')

  do
    local L = cel.label.new
    local gap = function() return cel.new(1, 10, cel.color.encode(1, 0, 0)) end
    grid:newrow {L'label', gap(), L'left', gap(), L'center',gap(), L'right', gap(), L'width'}
  end

  grid:newrow {
    'firstname', cel.new(), 'firstname', cel.new(), 'firstname', cel.new(), 'firstname', cel.new(), 'firstname',
  }
end
