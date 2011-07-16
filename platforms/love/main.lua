package.path='./lua/?.lua;./lua/?/init.lua;'..'lua/?.lua;lua/?/init.lua;'.. package.path

do
  local _print = print
  function print(...) _print(...) io.flush() end
end

local luaLoader = function(name)
    -- Replace all '.' by '/'
    name = name:gsub('%.', '/')
    -- Iterate over package.path templates
    for template in package.path:gmatch('[^;]+') do
        -- Replace all '?' by name
        local path = template:gsub('%?', name)
        -- Trim './' at the beginning of the path, as it doesn't work with the LÖVE loader
        path = path:gsub('^%./', '')
        -- Use the LÖVE loader to find the file
        local result = package.loaders[5](path)
        if 'function' == type(result) then
            return result
        end
    end
end

table.insert(package.loaders, luaLoader)


if jit then
  print(jit.status())
end

_G.celroot = require 'lovedriver'
require 'lovefaces'

local cel = require 'cel'

--TODO root is not getting initial focus, and get rid of state for keydown
function _G.celroot:onkeydown(state, key)
  if key == 'escape' then
    love.event.push('q') -- quit the game
  end 
end

function love.load()
  require 'test.sandbox'
end

function love.draw()
  love.graphics.setScissor()
  love.graphics.clear()
  love.cel.draw()
end
