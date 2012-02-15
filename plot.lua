local cel = require 'cel'

local _data = {}
local _pollinterval = {}
local _poll = {}

local metacel, metatable = cel.newmetacel('plot')

function metatable:setpollinterval(millis)
  self[_pollinterval] = millis
  return self
end

function metatable:setrange(min, max, mod)
  assert(min < max)
  self[_data].range[1] = min
  self[_data].range[2] = max
  self[_data].range.mod = mod
  self:refresh()
  return self
end

--domain is relative to current time
--TODO mod should be part of the face only
function metatable:setdomain(min, max, mod)
  assert(min < max)
  local data = self[_data]
  data.domain[1] = min
  data.domain[2] = max
  if mod then
    data.domain.mod = mod
  end

  for i=1, data.n do
    if data[i][1] - data[data.n][1] >= data.domain[1] then
      break
    else
      data.n=data.n-1
    end
  end

  data.n = math.min(#data, data.n + 1)

  local diff = #data - data.n
  while diff > 0 do 
    
    table.remove(data, 1)
    diff = diff -1
  end

  self:refresh()
  return self
end

function metatable:start()
  self[_poll]()
end

function metatable:stop()
end

function metacel:__describe(graph, t)
  t.data = graph[_data]
  t.pollinterval = graph[_pollinterval]
end

do
  local _new = metacel.new
  function metacel:new(w, h, pollout, face)
    face = self:getface(face)
    local graph = _new(self, w, h, face)

    local data = {
      domain = {-1000, 0},
      range = {0, 1},
      n=0;
    }

    graph[_data] = data

    graph[_poll] = function()
      local time = cel.timer()
      local value = pollout(time)

      assert(value)

      data.n = data.n + 1
      data[data.n] = {time, value}

      graph:setdomain(data.domain[1], data.domain[2])

      cel.doafter(graph[_pollinterval] or 1000, graph[_poll])
    end

    return graph
  end
end

return metacel:newfactory()


