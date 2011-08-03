local root = celroot
_G.celroot = nil
local cel = require 'cel'

local sandbox = cel.new(100, 100, cel.color.encode(1, 1, 1))

local modules = cel.sequence.y.new()

local function addmodule(name)
  cel.textbutton.new(name):link(modules, 'width').onclick = function(b)
    if sandbox.inner then
      sandbox.inner:unlink()
    end

    sandbox.chunk = name
    sandbox.inner = root:newroot():link(sandbox, 'edges') 
    local sub = require(name)

    if reactor then
      begtime = reactor.timermillis()
      sub(sandbox.inner)
      print('TIME = ', elapsedtime())
    else
      sub(sandbox.inner)
    end
  end
end


local grid = cel.grid.new { 
  {weight = 0, minw = 200, link = 'edges'},
  {weight = 1, minw = 200, link = 'edges'},
}

grid:newrow({modules, sandbox}, {minh=0, weight=1})

grid:link(root, 'edges')

cel.textbutton {
  text = 'print',
  onclick = function()
    cel.printdescription()
  end,
}:link(modules, 'width')

addmodule'celdocs.browser'

addmodule'test.editboxtest'
addmodule'test.sequencetest'
addmodule'test.rowtest'
addmodule'test.gridtest'

addmodule'test.menutest'
addmodule'test.listboxtest'
addmodule'test.windowtest'
addmodule'test.printbuffertest'

addmodule'tutorial.tut_cel'


