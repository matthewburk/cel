do 
  local _print = print
  function print(...)
    _print(...) io.flush() 
  end

  package.path = '../../?.lua;../../?/init.lua;' .. package.path
  print(package.path)
  print(package.cpath)

  if jit then
    jit.opt.start( 'maxside=10', 'hotloop=5', 'loopunroll=32', 'maxsnap=250', 'tryside=2')
    print('JIT')
  else
    print('NO JIT')
  end
end

local cel = require 'celdriver'


--[[begtime = begtime = reactor.timermillis()
function elapsedtime()
  return (reactor.timermillis() - begtime)/1000
end
--]]

function reactor.load(...)
  reactor.cel.load() 

  local root = reactor.celroot

  local sandbox = cel.new(100, 100, cel.color.encode(1, 1, 1))

  local function addmodule(name)
    local button = cel.textbutton.new(name)
    function button:onclick(b)
      if sandbox.inner then
        sandbox.inner:unlink()
      end

      sandbox.inner = root:newroot():link(sandbox, 'edges') 
      local sub = require(name)

      local begtime = reactor.timermillis()
      sub(sandbox.inner)
      print('TIME = ', (reactor.timermillis() - begtime)/1000)
    end

    return button
  end

  local modules = cel.sequence.y {
    {link = 'width'; addmodule'demo.listbox.basic'},
    {link = 'width'; addmodule'demo.listbox.listboxtest'},
    {link = 'width'; addmodule'test.sequencetest'},
    {link = 'width'; addmodule'test.rowtest'},
    {link = 'width'; addmodule'test.gridtest'},
    {link = 'width'; addmodule'test.menutest'},
    {link = 'width'; addmodule'test.listboxtest'},
    {link = 'width'; addmodule'test.windowtest'},
    {link = 'width'; addmodule'test.printbuffertest'},
    {link = 'width'; addmodule'tutorial.tut_cel'},
    {link = 'width';
      cel.textbutton {
        text = 'PRINT';
        onclick = function()
          cel.printdescription()
        end
      }
    };
  }

  root {
    cel.row {
      link = 'edges';
      { link = 'edges';
        modules 
      },
      { link = 'edges'; weight=1,
        sandbox,
      },
    },
  }
end




