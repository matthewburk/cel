local cel = require 'cel'

return function(root)

  local new = cel.textbutton.new
  local col = cel.col.new()

  col:flux(function()
    for i=1,20 do
      local b = new(string.rep('*', i)):link(col, 'width')
      b.onclick = function()
        b:settext(string.rep('&', math.random(20, 30)))
      end
    end
  end)
  col:link(root)

end

