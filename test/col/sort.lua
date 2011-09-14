local cel = require 'cel'

return function(root)

  local new = cel.textbutton.new
  local col = cel.col.new()

  col:flux(function()
    for i=1,20 do
      local b = new(string.rep('*', i)):link(col, 'edges', nil, nil, {flex=1})
    end
  end)
  col:link(root, 'edges')

  local function comp(b1, b2)
    return b1.id < b2.id
  end
  local function rcomp(b1, b2)
    return b2.id < b1.id
  end

  function col:onmousedown()
    col:sort(rcomp)
  end

  function col:onmouseup()
    col:sort(comp)
  end

end

