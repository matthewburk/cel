do 
  local _print = print
  function print(...)
    _print(...) io.flush() 
  end
end

package.path = '../../?.lua;../../?/init.lua;' .. package.path


print(package.path)
print(package.cpath)

if jit then
--jit.on()
---[[
jit.opt.start(
'maxside=10', 
'hotloop=5', 
'loopunroll=32', 
'maxsnap=250', 
'tryside=2')
--]]
--jit.off()
--print('jit.status', jit.status())
else
  print('NO JIT')
end

--[[
require 'test.sequencetest'
require 'test.listboxtest'
require 'test.celcairotest'
require 'celdocs.browser'
require 'test.windowtest'
require 'test.sequencetest'
require 'test.gridtest'
require 'test.rowtest'
require 'test.menutest'
require 'celdocs.browser'
--]]

begtime = 0
function elapsedtime()
  return (reactor.timermillis() - begtime)/1000
end
function reactor.load(...)
  _G.celroot = require 'celdriver'
  require 'celfaces'

  reactor.cel.load() 
  --TODO disable root resizing

  begtime = reactor.timermillis()
  --require 'tutorial.tut_cel'
  --require 'test.gridtest'
  require 'test.sandbox'
  print('time = ', elapsedtime())
end

