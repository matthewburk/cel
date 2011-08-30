local cel = require 'cel'

return function(root)
  local col = cel.col.new()

  col.debug = false 

  print('root', root.w, root.h)
  col:beginflux()

  for i = 1, 150 do
          cel.row {
            --link = {'edges'},
            {flex=1; 'one',},
            {flex=1; 'two',},
            {flex=2;  minw=100, link='width', cel.text.new([[I have a whole lot of work to do , this takes so long]]),},
            {flex=1; 'four',},
            {flex=1; 'five',},
            {flex=1; 'six',},
            {flex=1; 'seven',},
            {flex=1; 'eight',},
            {flex=1; 'nine',},
            {flex=1; 'ten',},
          }:link(col, 'width')
        end

  local window = cel.window.new():link(root, 'edges', 5, 5):relink()

  col:link(window, 'edges', 5, 5)

  col:endflux()

end

