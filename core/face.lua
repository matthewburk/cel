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

local _ENV = require 'cel.core.env'
local M = require 'cel.core.module'
setfenv(1, _ENV)

local _metacelname = {} 
local _variations = _variations 

local celfacemt = {}

celfacemt.__index = celfacemt

function celfacemt:new(t)
  t = t or {}
  t.__index = t
  self[_variations][t] = t
  return setmetatable(t, self)
end

function celfacemt:register(name)
  assert(name)
  self[_variations][name] = self
  return self
end

function celfacemt:gettype()
  return self[_metacelname]
end

function celfacemt.print(f, t, pre, facename)
  local s = string.format('%s[%d:%s] { x:%d y:%d w:%d h:%d [refresh:%s]',
    t.metacel, t.id, tostring(facename), t.x, t.y, t.w, t.h, tostring(t.refresh))
  io.write(pre, s)
  if t.mousefocusin then io.write('\n>>>>>>>>MOUSEFOCUSIN') end
  if t.font then
    io.write('\n', pre, '  @@', string.format('font[%s:%d]', t.font.name, t.font.size))
  end
end

local celface = {
  [_metacelname] = 'cel',
  [_variations] = {},
}

celface.__index = celface

do
  local metafaces = {
    ['cel'] = setmetatable(celface, celfacemt)
  }

  local function getmetaface(metacelname)
    assert(type(metacelname) == 'string')

    local metaface = metafaces[metacelname]

    if not metaface then
      metaface = {
        [_metacelname] = metacelname,
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

  function M.getface(metacelname, name)
    local face = getmetaface(metacelname)

    if name then
      local result = face[_variations][name]

      --TODO remove this from here, it slows down everything, not worth the convenience
      if not result 
      and type(name) == 'string'
      and #name == 7 
      and name:sub(1,1)=="#" then
        local r = tonumber(name:sub(2,3), 16)
        local g = tonumber(name:sub(4,5), 16)
        local b = tonumber(name:sub(6,7), 16)

        result = metafaces['cel']:new {
          color = M.color.rgb8(r, g, b)
        }:register(name)
      end

      return result
    else
      return face
    end
  end

  function M.isface(test)
    return type(test) == 'table' and test[_metacelname] and true or false
  end

  --called when a new metacel is created
  function _ENV.newmetaface(metacelname, proto)
    assert(type(metacelname) == 'string')

    local metaface = metafaces[metacelname]

    if metaface then
      setmetatable(metaface,  proto)
    else
      metaface = {
        [_metacelname] = metacelname,
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

