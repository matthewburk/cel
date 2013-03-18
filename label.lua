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
local math = math
local cel = require 'cel'

local metacel, metatable = cel.newmetacel('label') 

local _text = {} 
local _font = {} 
local _layout = {}
local _penx = {}
local _peny = {}
local _textw = {}
local _texth = {}
local _len = {}

local layout = {
  padding={}
}

function metatable:getbaseline()
  return self[_peny]
end

function metatable:getpenorigin()
  return self[_penx], self[_peny]
end

function metatable:getfont()
  return self[_font]
end

function metatable.gettext(label)
  return label[_text]
end

function metatable.len(label)
  return label[_len]
end

local function settext(label, text)
  label[_text] = text

  local font = label[_font]
  local layout = label[_layout]
  local textw, texth, xmin, xmax, ymin, ymax, len = font:measure(text)
  local penx, peny, w, h = font:pad(layout.padding, textw, texth, xmin, xmax, ymin, ymax)  

  label[_len] = len
  label[_penx] = penx
  label[_peny] = peny
  label[_textw] = textw
  label[_texth] = texth
  label:setlimits(w, w, h, h)
  label:refresh()
end

function metatable.settext(label, text)
  if label[_text] == text then
    return label
  else
    settext(label, text)
  end
  
  return label
end

function metatable.printf(label, format, ...)
  return label:settext(string.format(format, ...))
end

function metatable.__tostring(label)
  return string.format('%s[%s]', label:pget('name'), label[_text])
end

function metacel:touch(label)
  return false
end

function metacel:__describe(label, t)
  t.text = label[_text]
  t.font = label[_font]
  t.penx = label[_penx]
  t.peny = label[_peny]
  t.textw = label[_textw]
  t.texth = label[_texth]
end

do
  local _new = metacel.new
  function metacel:new(text, face)
    face = self:getface(face)

    local layout = face.layout or layout
    local font = face.font
    local textw, texth, xmin, xmax, ymin, ymax, len = font:measure(text)
    local penx, peny, w, h = font:pad(layout.padding, textw, texth, xmin, xmax, ymin, ymax)
    local label = _new(self, w, h, face, w, w, h, h)
    label[_len] = len
    label[_font] = font
    label[_text] = text
    label[_penx] = penx
    label[_peny] = peny
    label[_textw] = textw
    label[_texth] = texth
    label[_layout] = layout

    return label
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, label)
    return _assemble(self, t, label or metacel:new(t.text, t.face))
  end

  local _setface = metacel.setface
  function metacel:setface(label, face)
    local font = face.font
    label[_font] = face.font
    label[_layout] = face.layout or layout
    settext(label, label[_text])
    return _setface(self, label, face)
  end
end

return metacel:newfactory({layout = layout})
