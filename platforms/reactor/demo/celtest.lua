local cel = require 'cel'

function reactor.load(arg)
  cel.root:resize(reactor.graphics.getwidth(), reactor.graphics.getheight()) 

  cel.root {
  }

  local acel = cel.new(200, 200, cel.color.rgb(233, 233, 233)):link(cel.root, 'width')
  local bcel = cel.new(100, 100, cel.color.rgb(34, 34, 34)):link(acel, 'center')
  bcel:relink():unlink():link(cel.root, 'center')
  bcel:relink():flow(cel.flows.linear(3000), 0, 0)

  --[[
  local function reflow()
     bcel:flowlink(cel.flows.linear(3000), 'center')
     cel.doafter(3000, function()
       bcel:relink():flow(cel.flows.linear(3000), 0, 0, nil, nil, nil, reflow)
     end)
  end
  --]]

  ---[[
  cel.doafter(3000, reflow)
  --]]
end

function reactor.draw()
  reactor.graphics.clear()
  reactor.cel.draw()
end
