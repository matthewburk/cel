local cel = require 'cel'
require 'cel.grip'
require 'cel.button'
require 'cel.label'

local metacel, metatable = cel.newmetacel('console')
local _buffer = {}
local _buffersize = {}


local function initbuffer(buffer)
  buffer.first = 0
  buffer.last = -1
  buffer.size = 0
end

local function push(buffer, text)
  local last = buffer.last + 1
  buffer.last = last
  buffer[last] = text
  buffer.size = buffer.size + 1
end

local function pop(buffer)
  local first = buffer.first

  if first > buffer.last then 
    return 
  end

  buffer[first] = nil
  buffer.first = first + 1
  buffer.size = buffer.size - 1
end

local function putline(console, text)
  local buffer = console[_buffer]
  push(buffer, text)

  if buffer.size > console[_buffersize] then
    pop(buffer)
  end

  
end

function metatable.print(console, text)

end

function metatable.input(console, text)
  local inputbuffer = console[_inputbuffer]


end

local displaybuffer = {
  lines = 10,

}
function metacel:__describe(console, t)
  local buffer = console[_buffer]
  t.buffer = buffer 
  t.begin = beginlinenumber
  t.lines = endlinenumber - beginlinenumber
  t.font = font
  t.penx = 0
  t.peny = 0
  t.linegap = 0
end

do
  local _new = metacel.new
  function metacel:new(buffer, face)
    face = self:getface(face)
    orientation = orientation or 'vertical'

    local layout = face.layout or layout
    layout = layout[orientation]

    local console = _new(self, layout.size, layout.size, face)

    console.orientation = orientation
    console[_stepsize] = stepsize
    console[_size] = layout.size
    console[_minmodelsize] = layout.track.slider.minsize
    console[_value] = 0
    console[_range] = 0
    console[_max] = 0
    console[_modelvalue] = 0

    do
      local layout = layout.track
      console[_track] = cel.button.new(layout.size, layout.size, layout.face)
      console[_track][_console] = console
      console[_track].onpress = trackpressed
      console[_track].onhold = trackpressed
      console[_track]:link(console, layout.x, layout.y, layout.linker)

      do
        local layout = layout.slider
        console[_slider] = cel.grip.new(layout.size, layout.size, layout.face)
        console[_slider][_console] = console
        console[_slider].ondrag = sliderdragged
        console[_slider]:link(console[_track], nil, nil, 'fence')
      end
    end

    if layout.incbutton then 
      local layout = layout.incbutton
      local button = cel.button.new(layout.size, layout.size, layout.face)
      button[_console] = console
      button.onpress = incpressed
      button.onhold = incpressed
      button:link(console, layout.x, layout.y, layout.linker)
    end

    if layout.decbutton then
      local layout = layout.decbutton
      local button = cel.button.new(layout.size, layout.size, layout.face)
      button[_console] = console
      button.onpress = decpressed
      button.onhold = decpressed
      button:link(console, layout.x, layout.y, layout.linker)
    end

    console:range(console[_size])
    return console
  end

  local _construct = metacel.construct
  function metacel:construct(console, t)
    return _construct(self, console, t)
  end
end

cel.console = setmetatable(
  {
    step = metatable.step,
    stepsize = 20,
    new = function(orientation, face) return metacel:new(orientation, cel.console.stepsize, face) end,
    newmetacel = function(name) return metacel:newmetacel(name) end,
    layout = layout,
  },
  {__call = 
    function(self, t)
      local console = metacel:new(t.orientation, cel.console.stepsize, t.face)
      return metacel:construct(console, t)
    end
  })

return cel.console

--TODO do a better job with orientation maybe 'N' for vertical and 'Z' for horizontal, becuase of their shapes.
