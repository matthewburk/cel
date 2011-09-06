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

local _subject = {}
local _bucket = {}
local _links = {}
local _linkparams = {}
local meta, metatable = cel.newmetacel('mutexpanel')

do
  local function it(mutexpanel, prev)
    return next(mutexpanel[_links], prev)
  end

  function metatable:cels()
    return it, self 
  end
end

function metatable:clear(link)
  if link and self[_links][link] ~= nil then
    self[_links][link] = nil
    link:unlink()
    if link == self[_subject] then
      self[_subject] = nil
    end
  else
    for link in pairs(self[_links]) do
      self[_links][link] = nil
      link:unlink()
    end
    self[_subject] = nil
  end
  return self
end

function metatable:show(link)
  if self[_subject] then
    self[_subject]:link(self[_bucket])
  end
  self[_subject] = link
  link:link(self, link[_linkparams])
  return self
end

function meta:__link(mutexpanel, link, linker, xval, yval, option)
  mutexpanel[_links][link] = option or link

  if link ~= mutexpanel[_subject] then
    link[_linkparams] = {linker, xval, yval}
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

  local _compile = meta.compile
  function meta:compile(t, mutexpanel)
    mutexpanel = mutexpanel or meta:new(t.w, t.h, t.face)
    return _compile(self, t, mutexpanel)
  end
end

return meta:newfactory()
