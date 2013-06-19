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

local cel = require 'cel'

local _list = {}
local _col = {}
local _minimized = {}
local _state = {}

local metacel, mt = cel.slot.newmetacel('tree')

local layout = {
  gap=0,

  root = {
    link = 'width',
  },

  list = {
    gap=0,
    link = {'left', 16},
  },
}

local function minimize(tree)
  --tree[_col]:setslotflexandlimits(2, 0, 0, 0)
  tree[_list]:unlink()
  tree[_state] = 'minimized'
  return tree
end

local function maximize(tree)
  local layout = tree.face.layout or layout
  tree[_list]:link(tree[_col], layout.list.link)
  --tree[_col]:setslotflexandlimits(2, 0, true, true)
  tree[_state] = 'maximized'
  return tree
end

function mt:getroot()
  return self[_col]:get(1)
end

function mt:get(i)
  return self[_list]:get(i)
end

function mt:getstate()
  return self[_state]
end

function mt:togglestate()
  if self[_state] == 'minimized' then
    return maximize(self)
  else
    return minimize(self)
  end
end

function mt.maximize(tree)
  return maximize(tree)
end

function mt.minimize(tree)
  return minimize(tree)
end

function mt:flux(callback, ...)
  self[_list]:flux(callback, ...)
  return self
end

function metacel:__link(tree, link, linker, xval, yval, option)
  if not option then
    local layout = tree.face.layout or layout
    if link[_list] then --if link is another tree
      return tree[_list], layout.root.link
    else
      --tree[_list] is nil before it is linked, so this won't have any effect
      return tree[_list], layout.list.link 
    end
  end
end

do
  local _new = metacel.new
  function metacel:new(root, face)
    face = self:getface(face)
    local layout = face.layout or layout

    if type(root) == 'string' then root = cel.label.new(root) end

    local tree = _new(self, face)

    tree[_col] = cel.col.new(layout.gap):link(tree, 'width')

    tree[_col].__debug = true

    root:link(tree[_col], layout.root.link)

    tree.root = root

    tree[_list] = cel.col.new(layout.list.gap)
      :link(tree[_col], layout.list.link)

    tree[_list].__debug = true

    tree[_state] = 'maximized'

    return tree
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, tree)
    tree = tree or metacel:new(t.root, t.face)
    return _assemble(self, t, tree)
  end
end

return metacel:newfactory()

