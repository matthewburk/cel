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

  mouse = {
    scrolllines = 1,
    buttons = {},
    states = {},
    wheel = {},

    [_x] = 0,
    [_y] = 0,
    [_vectorx] = 0,
    [_vectory] = 0,
    [_focus] = {},
    [_states] = {},
  }

  function mouse:pick()
    event:wait()
    pick(self)
    event:signal()
    return self
  end

  function mouse:xy()
    return self[_x], self[_y]
  end

  function mouse:vector()
    return self[_vectorx], self[_vectory]
  end

  --returns last known button state or self.state.unknown if button state has never been provided
  --was ispressed
  function mouse:isdown(button)
    return self[_states][button] == self.states.down 
  end

  local function getdepth(cel)
    --root is depth 1
    local depth = 0 
    while cel do
      depth = depth + 1
      cel = cel[_host]
    end
    assert(depth >= 0)
    return depth
  end
  --
  --sets mouse[_focus] to cel directly under mouse cursor
  --fires mouseenter/mouseexit events
  --returns x,y in mouse[_focus].focus space
  --put in _cel.lua
  function pick(mouse)
    local mouse_focus = mouse[_focus]
    local mouse_trap = mouse[_trap]
    local x = mouse[_x]
    local y = mouse[_y]
    local z = 1 
    local cel = _ENV.root
    local trap = mouse_trap.trap
    assert(trap)
    cel = trap
    assert(cel)

    if cel[_host] then
      x = x - cel[_host].X
      y = y - cel[_host].Y
      z = getdepth(cel)
      --z should be 1 for root, 2 for next one etc
    end
    --x and y are now relative to cel[_host]
    
    mouse_focus.focus = nil
    --print('TRAP', trap)

    while cel do
      --make x and y relative to cel
      x = x - cel[_x]
      y = y - cel[_y]

      if touch(cel, x, y) then
        if mouse_focus[z] then
          if mouse_focus[z] ~= cel then
            for i = #mouse_focus, z, -1 do
              event:onmouseout(mouse_focus[i])
              assert(mouse_focus[i])
              refresh(mouse_focus[i])
              mouse_focus[mouse_focus[i]] = nil
              mouse_focus[i] = nil
            end
            mouse_focus[z] = cel
            mouse_focus[cel] = z
            event:onmousein(cel)
            assert(cel)
            refresh(cel)
          end
        else
          mouse_focus[z] = cel
          mouse_focus[cel] = z
          event:onmousein(cel)
          assert(cel)
          refresh(cel)
        end

        mouse_focus.focus = cel

        if not cel[_disabled] then
          local formation = rawget(cel, _formation)
          if formation and formation.pick then
            cel = formation:pick(cel, x, y)

            if cel and not touch(cel, x - cel[_x], y - cel[_y]) then
              cel = nil
            end

            if not cel then
              z = z + 1
              if mouse_focus[z] then
                for i = #mouse_focus, z, -1 do
                  event:onmouseout(mouse_focus[i])
                  assert(mouse_focus[i])
                  refresh(mouse_focus[i])
                  mouse_focus[mouse_focus[i]] = nil
                  mouse_focus[i] = nil
                end
              end
            end
          else
            cel = cel[_links]
          end
        else --cel is disabled
          for i = #mouse_focus, z+1, -1 do
            event:onmouseout(mouse_focus[i])
            assert(mouse_focus[i])
            refresh(mouse_focus[i])
            mouse_focus[mouse_focus[i]] = nil
            mouse_focus[i] = nil
          end
          break
        end
        z = z + 1
      else --cel was not touched
        if mouse_focus[z] == cel then
          for i = #mouse_focus, z, -1 do
            event:onmouseout(mouse_focus[i])
            assert(mouse_focus[i])
            refresh(mouse_focus[i])
            mouse_focus[mouse_focus[i]] = nil
            mouse_focus[i] = nil
          end
        end

        if trap == cel then
          break; 
        else
          x = x + cel[_x]
          y = y + cel[_y]
          cel = cel[_next]
        end
      end
    end

    --final fixup
    --[[
    if not _G.tripped then
      print('MOUSE FOCUS')
      for j, k in pairs(mouse_focus) do
        print(j, k)
      end
      print('----------')
    end
    --]]

    for i = #mouse_focus, 1, -1 do
      --assert(mouse_focus[i])

      if mouse_focus[i] then
        if mouse_focus.focus then
          if mouse_focus[i] == mouse_focus.focus then break end

          event:onmouseout(mouse_focus[i])
          assert(mouse_focus[i])
          refresh(mouse_focus[i])
          mouse_focus[mouse_focus[i]] = nil
          mouse_focus[i] = nil
        end
      else
        print('BIG BAD PICK', mouse_focus[1], mouse_focus.focus, i, #mouse_focus)
        print('BIG BAD PICK DATA', unpack(mouse_focus))
        for j, k in pairs(mouse_focus) do
          print(j, k)
        end
        --_G.tripped = true
      end
    end

    return x,y
  end

  return mouse 
end

