local cel = require 'cel'

local _thumb = {}
local _min = {}
local _max = {}
local _value = {}
local _step = {}

local metacel, metatable = cel.newmetacel('slider')
local thumbmeta = cel.grip.newmetacel('slider.thumb')

local layout = {
  size = 30,
  thumb = {
    size = 20,
  },
}

local function lerp (a, b, p)
  return a + p * (b -a)
end

local function rlerp(a, b, c)
  return (c - a)/(b - a);
end

function metatable.setvalue(slider, value)
  local thumb = slider[_thumb]
  local min = slider[_min]
  local max = slider[_max]

  if value < min then value = min end
  if value > max then value = max end

  slider[_value] = value

  local p = rlerp(min, max, value)

  thumb:relink(thumb.linker, p)
    --[[
  if steps > 0 then
    local astep = lerp(0, hw, 1/steps)
    local nsteps = math.floor((x)/astep +.5)
    x = math.floor((astep * nsteps))
  end
  --]]
  
  if slider.onchange then
    slider:onchange(slider[_value])
  end
  return slider 
end

function metatable:getvalue()
  return self[_value]
end

function metatable:getminvalue()
  return self[_min]
end

function metatable:getmaxvalue()
  return self[_max]
end

function metatable:getstepvalue()
  return self[_step]
end

function metacel:__describe(slider, t)
  t.minvalue = slider[_min]
  t.maxvalue = slider[_max]
  t.value = slider[_value]
  t.step = slider[_step]
  t.thumbsize = slider[_thumb].w
end

local function dragthumb(thumb, x, y)
  local slider = thumb.slider

  local p = rlerp(0, slider.w-thumb.w, thumb.x+x)


  local value = lerp(slider[_min], slider[_max], p)

  --dprint('p', p, 'value', value)

  slider:setvalue(value)
end

local function hthumblinker(hw, hh, x, y, w, h, p, yval)
  assert(p)
  yval = yval or 0

  x = lerp(0, hw-w, p)
  return x, yval, w, hh-yval
end
do --TODO min, max and step should not be new params, but set via setrange, setstep functions
  local _new = metacel.new
  function metacel:new(direction, min, max, step, face)
    face = self:getface(face)
    min = min or 0
    max = max or (min + 1)
    step = step or 1

    local layout = face.layout or layout
    local slider = _new(self, layout.size, layout.size, face)

    slider[_value] = min
    slider[_min] = min
    slider[_max] = max
    slider[_step] = step 

    if layout.thumb then
      local layout = layout.thumb
      local thumb = thumbmeta:new(layout.size, layout.size, layout.face)
      thumb:link(slider, hthumblinker, 0, 0)
      thumb.slider = slider
      --thumb:grip(thumb)
      thumb.ondrag = dragthumb
      slider[_thumb] = thumb
    end
    return slider
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, slider)
    slider = slider or metacel:new(t.direction, t.min, t.max, t.step, t.face)
    slider.onchange = t.onchange
    return _assemble(self, t, slider)
  end
end

return metacel:newfactory()

