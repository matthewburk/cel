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

--[[
--A mutexpanel is a container and exposes its contents.
--]]

local cel = require 'cel'

local _subject = {}
local _bucket = {}
local _links = {}
local _linkparams = {}

local meta, mt = cel.newmetacel('mutexpanel')

do
  local function it(mutexpanel, prev)
    return next(mutexpanel[_links], prev)
  end

  function mt:cels()
    return it, self 
  end
end

function mt:add(name, subject, linker, xval, yval)
  subject:link(self, linker, xval, yval, name)
  return self
end

function mt:remove(name)
  local link = self[_links][name]
  if link then
    self[_links][name] = nil
    link:unlink()
    if link == self[_subject] then
      self[_subject] = nil
    end
  end
  return self
end

function mt:clear()
  for name, link in pairs(self[_links]) do
    self[_links][link] = nil
    link:unlink()
  end
  self[_subject] = nil
  return self
end

function mt:select(name)
  local link = self[_links][name]

  if not link then
    return self
  end

  if self[_subject] then
    self[_subject]:link(self[_bucket])
  end

  self[_subject] = nil
  link:link(self, link[_linkparams])

  return self, link
end

function mt:find(name)
  return self[_links][name]
end

function mt:current()
  return self[_subject]
end

function mt:iscurrent(name)
  return self[_subject] and self[_subject] == self[_links][name]
end

function meta:__link(mutexpanel, link, linker, xval, yval, name)
  if name then
    mutexpanel[_links][name] = link
  else
    mutexpanel[_links][link] = link
  end

  link[_linkparams] = {linker, xval, yval}

  if not mutexpanel[_subject] then
    mutexpanel[_subject] = link
  else
    return mutexpanel[_bucket]
  end
end

do
  local _new = meta.new
  function meta:new(w, h, face)
    face = self:getface(face)
    local mutexpanel = _new(self, w, h, face)
    mutexpanel[_links] = {}
    mutexpanel[_bucket] = cel.new(w, h)
    return mutexpanel
  end

  local _assemble = meta.assemble
  function meta:assemble(t, mutexpanel)
    mutexpanel = mutexpanel or meta:new(t.w, t.h, t.face)
    return _assemble(self, t, mutexpanel)
  end

  function meta:assembleentry(mutexpanel, entry, entrytype, linker, xval, yval, option)
    if 'table' == entrytype then
      --TODO interpret link how _cel does, need function like { linker, xval, yval, option = cel.decodelink(entry.link) }
      if entry.link then
        if type(entry.link) == 'table' then
          linker, xval, yval, option = unpack(entry.link, 1, 4)
        else
          linker, xval, yval, option = entry.link, nil, nil, nil
        end
      end

      for i = 1, #entry do
        local link = cel.tocel(entry[i], mutexpanel)
        if link then
          link:link(mutexpanel, linker, xval, yval, option or entry.name)
        end
      end 
    end
  end
end

return meta:newfactory()
