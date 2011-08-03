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
local pairs = pairs

return function(_ENV, M)
  setfenv(1, _ENV)

  keyboard = { 
    keys = {},
    keystates = {},

    [_focus] = {n = 0},
    [_keys] = {},
    [_keystates] = {}
  }
 
  do
    local modifiers = {shift = {'lshift', 'rshift'}, alt = {'lalt', 'ralt'}, ctrl = {'lctrl', 'rctrl'}}

    --was ispressed
    function keyboard:isdown(key)
      if self[_keys][key] then
        return true
      end

      if modifiers[key] then
        for k,v in pairs(modifiers[key]) do
          if self[_keys][v] then
            return true
          end
        end
      end
      return false
    end
  end

  return keyboard 
end

