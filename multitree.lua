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

local _trees = {}

local metacel, mt = cel.row.newmetacel('multitree')

local layout = {
  root = {
    link = 'width',
  },

  list = {
    link = {'left', 16},
  },
}

do
  blank = cel.new

  local _new = metacel.new
  function metacel:new(recorddef, face)
    face = self:getface(face)
    local layout = face.layout or layout

    local mtree = _new(self, 0, face)

    local trees = {}
    for i, name in ipairs(recorddef) do
      trees[i] = cel.tree.new(name):link(mtree)
      trees[i].name = name
    end

    local records = {root=trees}
    records.__index = records

    function records:newrecord(record)
      for i, tree in ipairs(self.root) do
        local link = record[tree.name] or blank()

        if type(link) == 'string' then
          link = cel.label.new(link)
        end

        link:link(tree)
      end
      return self
    end

    function records:newtree(record)
      local trees = {}
      for i, tree in ipairs(self.root) do
        trees[i] = cel.tree.new(record[tree.name] or blank())
        trees[i].name = tree.name
        trees[i]:link(tree)
      end

      return setmetatable({root=trees}, records)
    end

    function mtree:newrecord(record)
      records:newrecord(record) 
      return self
    end

    function mtree:newtree(record)
      return records:newtree(record)
    end

    return mtree
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, mtree)
    mtree = mtree or metacel:new(t.recorddef, t.face)
    return _assemble(self, t, mtree)
  end
end

return metacel:newfactory()

