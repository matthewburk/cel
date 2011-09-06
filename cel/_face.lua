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
return function(_ENV, M)
  setfenv(1, _ENV)

  local _variations = _variations 

  local celfacemt = {
  }

  local nfaces = 1

  celfacemt.__index = celfacemt

  function celfacemt:new(t)
    nfaces = nfaces + 1
    print('nfaces', nfaces)
    t = t or {}
    t.__index = t
    self[_variations][t] = t
    return setmetatable(t, self)
  end

  function celfacemt:register(name)
    assert(name)
    self[_variations][name] = self
  end

  local celface = {
    [_variations] = {},
  }

  celface.__index = celface

  do
    local metafaces = {
      ['cel'] = setmetatable(celface, celfacemt)
    }

    function M.getmetaface(metacelname)
      assert(type(metacelname) == 'string')

      local metaface = metafaces[metacelname]

      if not metaface then
        metaface = {
          [_variations]={},
          __index = true,
        }
        metaface.__index = metaface

        setmetatable(metaface, celface)
        metafaces[metacelname] = metaface
      end

      assert(metaface)

      return metaface
    end

    --called when a new metacel is created
    function _ENV.newmetaface(metacelname, proto)
      assert(type(metacelname) == 'string')

      local metaface = metafaces[metacelname]

      if metaface then
        setmetatable(metaface,  proto)
      else
        metaface = {
          [_variations]={},
          __index = true,
        }
        metaface.__index = metaface
        setmetatable(metaface, proto)
        metafaces[metacelname] = metaface
      end

      assert(metaface)
      return metaface
    end
  end
end
