local _thumb = {}
local _min = {}
local _max = {}
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

function metatable:getvalue()
  local thumb = self[_thumb]
  local value = thumb.x/(self.w - thumb.w)
  return lerp(self[_min], self[_max], value)
end

function metacel:onlinkmove(slider, thumb, ox, oy, ow, oh)
  if thumb == slider[_thumb] and slider.onchange then
    slider:onchange(slider:getvalue())
  end
end

local function hthumblinker(hw, hh, x, y, w, h, steps, yval)
  yval = yval or 0

  if x <= 0 then
    x = 0
  elseif x + w > hw then
    x = hw - w
  end

  if steps > 0 then
    local astep = lerp(0, hw-w, 1/steps)
    local nsteps = math.floor((x/astep) + .5)
    x = astep * nsteps
  end

  return x, yval, w, hh-yval
end
do
  local _new = metacel.new
  function metacel:new(direction, min, max, steps, face)
    face = self:getface(face)
    min = min or 0
    max = max or (min + 1)
    steps = steps or 0
    local layout = face.layout or layout
    local slider = _new(self, layout.size, layout.size, face)

    slider[_min] = min
    slider[_max] = max

    if layout.thumb then
      local layout = layout.thumb
      local thumb = thumbmeta:new(layout.size, layout.size, layout.face)
      thumb:link(slider, hthumblinker, steps, nil)
      thumb:grip(thumb)
      slider[_thumb] = thumb
    end
    print('made lisder', slider)
    return slider
  end

  local _compile = metacel.compile
  function metacel:compile(t, slider)
    slider = slider or metacel:new(t.direction, t.min, t.max, t.steps, t.face)
    slider.onchange = t.onchange
    return _compile(self, t, slider)
  end
end

return metacel:newfactory()
