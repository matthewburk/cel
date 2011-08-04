local cel = require 'cel'

return function(root)
  local col = cel.sequence.y.new()

  col:beginflux()

  for i = 1, 100 do
          cel.row {
            --link = {'edges'},
            'noslot',
            cel.textbutton.new('who in the what'),
            {'1', minw=19, weight=1},
            {
              minw=100, weight=8,
              cel.text {
                text = [[I have a whole lot of work to do , this takes so long]],
                link = {'width'},
              },

            },
            {'22', minw=19, weight=2},
            {'333', minw=19, weight=3},
            {'4444', minw=19, weight=4},
          }:link(col, 'width')
        end

  local window = cel.window.new():link(root, 'edges', 5, 5):relink()

  col:link(window, 'edges', 5, 5)

  col:endflux()

  do
    local row = col:get(1) 
    for j, item in row:items() do
      print(j, item)
    end
  end
end

