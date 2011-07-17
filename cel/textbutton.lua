local cel = require 'cel'

local metacel, metatable = cel.button.newmetacel('textbutton')

local _text = {}
local _font = {}
local _penx = {}
local _peny = {}
local _layout = {}
local _textw = {}
local _texth = {}

local layout = {
  fitx = 'bbox',
  padding = {
    l = 0,
    t = 0,
  },
}

function metatable.printf(button, format, ...)
  return button:settext(string.format(format, ...))
end


function metatable.settext(button, text)
  button[_text] = text

  local font = button[_font]
  local layout = button[_layout]

  --TODO text.fit should not clamp
  local textw, texth, xmin, xmax, ymin, ymax = font:measure(text)
  local penx, peny, w, h = font:pad(layout, textw, texth, xmin, xmax, ymin, ymax) 
  local offsetx = ((button.w-w)/2)
  local offsety = ((button.h-h)/2)
  --button[_font] = font
  button[_text] = text
  button[_penx] = math.floor(penx + offsetx)
  button[_peny] = math.floor(peny + offsety)
  button[_textw] = textw
  button[_texth] = texth
  metacel:setlimits(button, w, nil, h, nil)
  button:refresh()
  return button
end

function metatable.gettext(button)
  return button[_text]
end

--[[returns avance, xmin, xmax, ymin, ymax
function metatable.getmetrics(button)
  advance = advance,
        xmin = xmin,
        xmax = xmax,
        ymin = ymin,
        ymax = ymax,
end
--]]

function metatable.getbaseline(button)
  return button[_penx], button[_peny]
end

function metatable.__tostring(button)
  return 'textbutton[' .. button[_text] .. ']'
end

function metatable:getfont()
  return self[_font]
end

--TODO onresize must include new width and height, or the information is lost
--in the case that multiple resizes happen before the events are disemminated
--TODO this is unstable, the text drifts offcenter after a while
function metacel:__resize(button, ow, oh)
  local w = button[_textw]
  local h = button[_texth]
  local offsetx = ((ow-w)/2)
  local offsety = ((oh-h)/2)
  local penx = math.ceil(button[_penx] - offsetx)
  local peny = math.ceil(button[_peny] - offsety)
  offsetx = ((button.w-w)/2)
  offsety = ((button.h-h)/2)
  button[_penx] = math.floor(penx + offsetx)
  button[_peny] = math.floor(peny + offsety)
end

do
  local _describe = metacel.__describe
  function metacel:__describe(button, t)
    _describe(self, button, t)
    t.text = button[_text]
    t.font = button[_font]
    t.penx = button[_penx]
    t.peny = button[_peny]
    t.textw = button[_textw]
    t.texth = button[_texth]
  end
end

do 
  local floor = math.floor
  local _new = metacel.new
  function metacel:new(text, face)
    face = self:getface(face)

    local layout = face.layout or layout
    local font = face.font
    local textw, texth, xmin, xmax, ymin, ymax = font:measure(text)
    local penx, peny, w, h = font:pad(layout, textw, texth, xmin, xmax, ymin, ymax) 
    local button = _new(self, w, h, face, w, nil, h, nil)
    button[_font] = font
    button[_text] = text
    button[_penx] = floor(penx)
    button[_peny] = floor(peny)
    button[_textw] = textw
    button[_texth] = texth
    button[_layout] = layout

    return button               
  end

  local _compile = metacel.compile
  function metacel:compile(t, button)
    button = button or metacel:new(t.text, t.face)
    return _compile(self, t, button)
  end
end

return metacel:newfactory({layout = layout})

