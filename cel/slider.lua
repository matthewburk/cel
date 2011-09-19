local cel = require 'cel'

local _thumb = {}
local _min = {}
local _max = {}
local _value = {}
local _precision = {}

local metacel, metatable = cel.newmetacel('slider')
local thumbmeta = cel.grip.newmetacel('slider.thumb')
local thumbstopmeta = cel.newmetacel('slider.thumbstop')

local layout = {
  size = 20,
  thumb = {
    size = 10,
  },
  thumbstop = {
    size = 10,
  },
}

local function lerp (a, b, p)
  return a + p * (b -a)
end

local function syncmodeltovalue(slider)
  local thumb = slider[_thumb]
  local value = slider[_value] * slider[_precision]
  local min = slider[_min] * slider[_precision]
  local max = slider[_max] * slider[_precision]


  local modelmax = slider.w - thumb.w 
  local modelmin = 0
  local modelvalue = math.floor(modelmax * (value/max) + 0.5)

  thumb:move(modelvalue)
end

local function syncvaluetomodel(slider)
  local thumb = slider[_thumb]
  local modelvalue = thumb.x
  local modelmax = slider.w - thumb.w 
  local modelmin = 0
  local max = slider[_max] * slider[_precision]
  local min = slider[_min] * slider[_precision]
  local value = slider[_value] * slider[_precision]

  --if the current value would have a differnt modelvalue than the current
  --model, then sync it to the new model position
  if modelvalue ~= math.floor(modelmax * (value/max) + 0.5) then
    value = math.floor(max * (modelvalue/modelmax) + .5)
    slider[_value] = value/slider[_precision]
  end
end

function metatable:getstringvalue()
  return string.format('%.3f', self[_value])
end

function metatable:setvalue(value)
  self[_value] = value
  syncmodeltovalue(self)
  return self
end

function metatable:getvalue()
  return self[_value]
end

function metacel:__resize(slider, ow, oh)
  syncmodeltovalue(slider)
end

function metacel:onlinkmove(slider, thumb, ox, oy, ow, oh)
  if thumb == slider[_thumb] then
    syncvaluetomodel(slider)
    if slider.onchange then
      slider:onchange(slider[_value])
    end
  end
end

local function hthumblinker(hw, hh, x, y, w, h, steps, yval)
  yval = yval or 0

  if x <= 0 then
    x = 0
  elseif x + w > hw then
    x = hw - w
  end

  --[[
  if steps > 0 then
    local astep = lerp(0, hw-w, 1/steps)
    local nsteps = math.floor((x/astep) + .5)
    x = astep * nsteps
  end
  --]]

  return x, yval, w, hh-yval
end
do
  local _new = metacel.new
  function metacel:new(direction, min, max, stepby, face)
    face = self:getface(face)
    min = min or 0
    max = max or (min + 1)
    stepby = stepby or 1
    local steps = 0
    if stepby then
      steps = (max-min)/stepby
    end
    local layout = face.layout or layout
    local slider = _new(self, layout.size, layout.size, face)

    slider[_value] = min
    slider[_min] = min
    slider[_max] = max
    slider[_precision] = 1/stepby 

    if layout.thumb then
      local layout = layout.thumb
      local thumb = thumbmeta:new(layout.size, layout.size, layout.face)
      thumb:link(slider, hthumblinker, steps, nil)
      thumb:grip(thumb)
      slider[_thumb] = thumb
    end
    return slider
  end

  local _compile = metacel.compile
  function metacel:compile(t, slider)
    slider = slider or metacel:new(t.direction, t.min, t.max, t.stepby, t.face)
    slider.onchange = t.onchange
    return _compile(self, t, slider)
  end
end

return metacel:newfactory()

