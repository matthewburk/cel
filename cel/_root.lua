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

  --TODO give this to all cels
  function metatable.__call(root, t)
    linkall(root, t) 
    return root 
  end

  

  local root = metacel:new(1, 1)
  local root0 = root
  root.X = 0 --TODO hax, need to give root its own metable to avoid this hack, see getX
  root.Y = 0

  --TODO not very elegent to put mouse and keyboard initialization in here
  cel.mouse[_trap] = {trap = root}
  cel.keyboard[_trap] = {trap = root}

  root.linkoption = {}
  root.linkoption.popup = function(anchor)
    if anchor == root then return 'popup' end
    return function()
      return 'popup', anchor
    end
  end

  do
    local popups = {}
    local groups = {}
    local _upanchor = {}
    local _downanchor = {}

    function metacel:onmousedown(root, state, button, x, y, intercepted)
      if root == root0 then
        for group, dismiss in pairs(groups) do
          if dismiss then
            group.root:unlink()
            groups[group]=nil
          else
            groups[group]=true
          end
        end
      end
    end

    function metacel:popupdismissed(root, popup)
      if popup.popupdismissed then
        popup:popupdismissed()
      end
    end

    local function savegroup(popup)
      local group = popups[popup]
      if group then
        groups[group]=false --don't dismiss this group
      end
    end

    function metacel:__link(root, link, linker, xval, yval, option)
      if type(option) == 'function' then
        local option, anchor = option(root)
        if popups[anchor] then
          local group = popups[anchor]
          popups[link]=group

          link[_upanchor] = anchor
          anchor[_downanchor] = link
        else
          local group={root=link}          
          popups[link]=group
          groups[group]=true
        end
        link:addlistener('onmousedown', savegroup)
      end
    end

    function metacel:__unlink(root, link)
      if popups[link] then
        local popup = link
        local downanchor = popup[_downanchor]

        popups[popup] = nil

        if popup[_upanchor] then 
          popup[_upanchor][_downanchor] = nil 
        end

        popup[_upanchor] = nil
        popup:removelistener('onmousedown', savegroup)

        if popup.popupdismissed then
          self:asyncall('popupdismissed', root, popup)
        end

        if downanchor then
          return downanchor:unlink() --TODO document that unlinking is safe, to do in __unlink, in fact it is 
          --very safe to do this becuase no external functions are called becuase we are in asyncmode until 
          --__unlink returns
        end
      end
    end
  end
  
  function metacel:__celfromstring(root, s)
    return cel.label.new(s)
  end

  do
    function metatable:newroot(w, h)
      local root = metacel:new(w, h)
      root.linkoption = {}
      root.linkoption.popup = function(anchor)
        if anchor == root then return 'popup' end
        return function()
          return 'popup', anchor
        end
      end
      return root
    end
  end

  return root
end

