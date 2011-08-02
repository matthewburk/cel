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

local layout = {
}

function metatable:getbaseline()
  return self[_penx], self[_peny]
end

function metatable:getfont()
  return self[_font]
end

function metatable.gettext(label)
  return label[_text]
end

function metatable.settext(label, text)
  if not rawget(label, _font) then
    return false, 'not a label'
  end

  if label[_text] == text then
    return label
  end

  label[_text] = text

  local font = label[_font]
  local layout = label[_layout]
  local textw, texth, xmin, xmax, ymin, ymax = font:measure(text)
  local penx, peny, w, h = font:pad(layout.padding, textw, texth, xmin, xmax, ymin, ymax)  

  label[_penx] = math.floor(penx)
  label[_peny] = math.floor(peny)
  label[_textw] = textw
  label[_texth] = texth
  metacel:setlimits(label, w, w, h, h)
  label:refresh()
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
  local floor = math.floor
  local _new = metacel.new
  function metacel:new(text, face)
    face = self:getface(face)

    local layout = face.layout or layout
    local font = face.font
    local textw, texth, xmin, xmax, ymin, ymax = font:measure(text)
    local penx, peny, w, h = font:pad(layout.padding, textw, texth, xmin, xmax, ymin, ymax)
    local label = _new(self, w, h, face, w, w, h, h)
    label[_font] = font
    label[_text] = text
    label[_penx] = floor(penx) --TODO this should already be floored
    label[_peny] = floor(peny)
    label[_textw] = textw
    label[_texth] = texth
    label[_layout] = layout

    return label
  end

  local _compile = metacel.compile
  function metacel:compile(t, label)
    return _compile(self, t, label or metacel:new(t.text, t.face))
  end
end

return metacel:newfactory({layout = layout})
