--[[
cel is licensed under the terms of the MIT license

Copyright (C) 2011 by Matthew W. Burk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]
return function(_ENV, cel)
  setfenv(1, _ENV)

  local metacel, metatable = metacel:newmetacel('root')

  do
    local _raise = metatable.raise
    metatable.raise = function(root, ...) 
      if root == _ENV.root then return root else return _raise(root, ...) end
    end

    local _link = metatable.link
    metatable.link = function(root, ...) 
      if root == _ENV.root then return root else return _link(root, ...) end
    end 

    local _relink = metatable.relink
    metatable.relink = function(root, ...) 
      if root == _ENV.root then return root else return _relink(root, ...) end
    end

    local _unlink = metatable.unlink
    metatable.unlink = function(root, ...) 
      if root == _ENV.root then return root else return _unlink(root, ...) end
    end
  end

  local root = metacel:new(1, 1)
  local root0 = root
  --TODO hax, need to give root its own metable to avoid this hack, see getX
  root.X = 0 
  root.Y = 0

  --TODO not very elegent to put mouse and keyboard initialization in here
  cel.mouse[_trap] = {trap = root}
  --cel.keyboard[_trap] = {trap = root}

  return root
end

