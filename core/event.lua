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

local rawget = rawget
local xpcall = xpcall
local pairs = pairs

local CEL = require 'cel.core.env'

local _metacel = CEL._metacel

local event = CEL.event
local mousetrackerfuncs = CEL.mousetrackerfuncs

event.first = 0
event.last = -1

function event:push(v)
  local last = self.last + 1
  self.last = last
  self[last] = v
end

function event:pop()
  local first = self.first

  if first > self.last then 
    return nil 
  end

  local value = self[first]
  self[first] = nil
  self.first = first + 1

  return value
end

--wait to dispatch events 
function event:wait()
  local count = self.count or 0
  self.count = count + 1
end

do
  local dispatching = false

  local function traceback(err)
    err = string.format('error {\n%s\n}', err)
    return debug.traceback(err, 2)
  end
  local function trydispatch()
    local e = event:pop()

    while e do
      if e.dispatch then
        e.dispatch()
      else
        e[1](e)
      end
      e = event:pop()
    end
    event.first = 0
    event.last = -1
  end

  function event:signal()
    local count = self.count
    --assert(count and count > 0)
    count = count - 1
    self.count = count

    
    if count > 0 or dispatching then return end

    do
      dispatching = true
      repeat
        local ok, msg = xpcall( trydispatch, traceback) 

        if msg then
          dprint(msg)
        end
      until ok

      dispatching = false 
    end
  end
end

local function dispatchtolisteners(cel, listenertype, ...)
  local ret = false
  local listeners = cel[listenertype]
  if listeners then
    for listener, active in pairs(listeners) do
      if active then
        if listener(cel, ...) then
          ret = true
        end
      end
    end
  end
  return ret
end

--TODO remove onlink, only used for scroll, dubious usage
--but maybe it is useful and onunlink needs to be added as well
do --onlink 
  --only send to metacel
  --TODO work out a way to send extra param like onlinkmove and onresize
  local queue = {first = 0, last = -1}
  
  local function push(event, cel, link, index)
    local i = queue.last
    i = i + 1; queue[i] = cel
    i = i + 1; queue[i] = link 
    i = i + 1; queue[i] = index
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local cel = queue[i]; queue[i] = nil; i = i + 1
    local link = queue[i]; queue[i] = nil; i = i + 1
    local index = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return cel, link, index 
  end

  function queue.dispatch()
    local cel, link, index = pop() 
    cel[_metacel]:onlink(cel, link, index)
  end

  function event:onlink(cel, link, index)
    if cel[_metacel].onlink then
      push(self, cel, link, index)
    end
  end
end

do --onlinkmove 
  --only sent to metacel, duplicates merged
  local queue = {first = 0, last = -1}
  local memo = { } --link to cel

  local function push(event, cel, link, ox, oy, ow, oh)
    local i = queue.last
    i = i + 1; 
    queue[i] = {cel, link, ox, oy, ow, oh, i}
    queue.last = i
    event:push(queue)
    return queue[i]
  end

  --TODO if event:push sees the same queue, increment a counter for the queue instead of putting it on 
  --the main queue again
  local function repush(event, e)
    local i = queue.last
    i = i + 1; 
    queue[i] = e
    e[7]=i
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local e = queue[i]; 

    queue[i] = nil;
    queue.first = i+1

    if e[7] == i then
      return e 
    end
  end

  function queue.dispatch()
    local e = pop()
    if e then
      local cel, link, ox, oy, ow, oh = e[1], e[2], e[3], e[4], e[5], e[6]
      if memo[link] == e then
        memo[link]=nil
      end
      cel[_metacel]:onlinkmove(cel, link, ox, oy, ow, oh) 
    end
  end

  function event:onlinkmove(cel, link, ox, oy, ow, oh)
    if rawget(cel[_metacel], 'onlinkmove') then 
      --if link was in another cel and that event was not delivered yet
      --the event will still be delivered but will not coalese if it gets the 
      --same link again
      local e = memo[link]
      if e and e[1] == cel then
        repush(self, e) 
      else
        memo[link] = push(self, cel, link, ox, oy, ow, oh) 
      end
    end
  end
end

do --onresize
  --TODO merge duplicates
  local queue = {first = 0, last = -1}
  
  local function push(event, cel, ow, oh, extra)
    local i = queue.last
    i = i + 1; queue[i] = cel
    i = i + 1; queue[i] = ow 
    i = i + 1; queue[i] = oh
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local cel = queue[i]; queue[i] = nil; i = i + 1
    local ow = queue[i]; queue[i] = nil; i = i + 1
    local oh = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return cel, ow, oh 
  end

  function queue.dispatch()
    local cel, ow, oh = pop() 
    if cel[_metacel].onresize then cel[_metacel]:onresize(cel, ow, oh) end
    if rawget(cel, 'onresize') then cel:onresize(ow, oh) end
  end

  function event:onresize(cel, ow, oh)
    if cel[_metacel].onresize 
    or rawget(cel, 'onresize') then
      push(self, cel, ow, oh) 
    end
  end
end

do --asyncall
  local unpack = unpack
  local dispatch = function(e)
    local metacel, eventname, t, argc = e[2], e[3], e[4], e[5]
    
    if not t.cancel then
      metacel[eventname](metacel, unpack(e, 6, 6 + argc))
    end
  end

  function event:asyncall(metacel, eventname, t, ...)
    self:push({dispatch, metacel, eventname, t, select('#', ...), ...})
  end
end

do --onmousemove
  local queue = {first = 0, last = -1}
  
  local function push(event, cel, x, y)
    local i = queue.last
    i = i + 1; queue[i] = cel
    i = i + 1; queue[i] = x 
    i = i + 1; queue[i] = y
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local cel = queue[i]; queue[i] = nil; i = i + 1
    local x = queue[i]; queue[i] = nil; i = i + 1
    local y = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return cel, x, y
  end

  function queue.dispatch()
    local cel, x, y = pop() 
    if cel[_metacel].onmousemove then cel[_metacel]:onmousemove(cel, x, y) end
    if rawget(cel, 'onmousemove') then cel:onmousemove(x, y) end      
  end

  function event:onmousemove(cel, lx, ly)
    if cel[_metacel].onmousemove 
    or rawget(cel, 'onmousemove') then
      push(self, cel, lx, ly)
    end
  end
end

do --onmousein
  local queue = {first = 0, last = -1}
  
  local function push(event, cel)
    local i = queue.last
    i = i + 1; queue[i] = cel
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local cel = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return cel
  end

  function queue.dispatch()
    local cel = pop() 
    if cel[_metacel].onmousein then cel[_metacel]:onmousein(cel) end
    if rawget(cel, 'onmousein') then cel:onmousein() end      
  end

  function event:onmousein(cel)
    if cel[_metacel].onmousein
    or rawget(cel, 'onmousein') then
      push(self, cel)
    end
  end
end

do --onmouseout
  local queue = {first = 0, last = -1}
  
  local function push(event, cel)
    local i = queue.last
    i = i + 1; queue[i] = cel
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local cel = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return cel
  end

  function queue.dispatch()
    local cel = pop() 
    if cel[_metacel].onmouseout then cel[_metacel]:onmouseout(cel) end
    if rawget(cel, 'onmouseout') then cel:onmouseout() end      
  end

  function event:onmouseout(cel)
    if cel[_metacel].onmouseout 
    or rawget(cel, 'onmouseout') then
      push(self, cel)
    end
  end
end

do --ontimer
  local queue = {first = 0, last = -1}
  
  local function push(event, cel, value, source)
    local i = queue.last
    i = i + 1; queue[i] = cel
    i = i + 1; queue[i] = value 
    i = i + 1; queue[i] = source 
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local cel = queue[i]; queue[i] = nil; i = i + 1
    local value = queue[i]; queue[i] = nil; i = i + 1
    local source = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return cel, value, source
  end

  function queue.dispatch()
    local cel, value, source = pop() 
    if cel[_metacel].ontimer then cel[_metacel]:ontimer(cel, value, source) end
    if rawget(cel, 'ontimer') then cel:ontimer(value, source) end
  end

  function event:ontimer(cel, value, source)
    if cel[_metacel].ontimer 
    or rawget(cel, 'ontimer') then
      push(self, cel, value, source)
    end
  end
end

do --onfocus
  local queue = {first = 0, last = -1}
  
  local function push(event, cel)
    local i = queue.last
    i = i + 1; queue[i] = cel
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local cel = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return cel 
  end

  function queue.dispatch()
    local cel = pop() 
    if cel[_metacel].onfocus then cel[_metacel]:onfocus(cel) end
    if rawget(cel, 'onfocus') then cel:onfocus() end
  end

  function event:onfocus(cel)
    if cel[_metacel].onfocus 
    or rawget(cel, 'onfocus') then
      push(self, cel) 
    end
  end
end

do --onblur
  local queue = {first = 0, last = -1}
  
  local function push(event, cel)
    local i = queue.last
    i = i + 1; queue[i] = cel
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local cel = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return cel 
  end

  function queue.dispatch()
    local cel = pop() 
    if cel[_metacel].onblur then cel[_metacel]:onblur(cel) end
    if rawget(cel, 'onblur') then cel:onblur() end
  end

  function event:onblur(cel)
    if cel[_metacel].onblur 
    or rawget(cel, 'onblur') then
      push(self, cel) 
    end
  end
end

do --onmousedown
  local queue = {first = 0, last = -1}
  
  local function push(event, cel, button, x, y, trigger)
    local i = queue.last
    i = i + 1; queue[i] = cel
    i = i + 1; queue[i] = button 
    i = i + 1; queue[i] = x 
    i = i + 1; queue[i] = y
    i = i + 1; queue[i] = trigger
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local cel = queue[i]; queue[i] = nil; i = i + 1
    local button = queue[i]; queue[i] = nil; i = i + 1
    local x = queue[i]; queue[i] = nil; i = i + 1
    local y = queue[i]; queue[i] = nil; i = i + 1
    local trigger = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return cel, button, x, y, trigger 
  end

  function queue.dispatch()
    local cel, button, x, y, t = pop()
    local intercepted = t[1]
    if cel[_metacel].onmousedown then
      if cel[_metacel]:onmousedown(cel, button, x, y, intercepted) then
        t[1] = true
      end
    end
    --TODO only dispatch to this if it existed at the time the event was pushed, no need to do same for metacel
    --since that is not supposed to be dynamic
    if rawget(cel, 'onmousedown') then
      if cel:onmousedown(button, x, y, intercepted) then
        t[1] = true --TODO make all events handled only if the function returns true
      end
    end
  end

  function event:onmousedown(cel, button, x, y, intercepted)
    if cel[_metacel].onmousedown 
    or rawget(cel, 'onmousedown') then
      push(self, cel, button, x, y, intercepted)
    end
  end
end

do --onmouseup
  local queue = {first = 0, last = -1}
  
  local function push(event, cel, button, x, y, trigger)
    local i = queue.last
    i = i + 1; queue[i] = cel
    i = i + 1; queue[i] = button 
    i = i + 1; queue[i] = x 
    i = i + 1; queue[i] = y
    i = i + 1; queue[i] = trigger
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local cel = queue[i]; queue[i] = nil; i = i + 1
    local button = queue[i]; queue[i] = nil; i = i + 1
    local x = queue[i]; queue[i] = nil; i = i + 1
    local y = queue[i]; queue[i] = nil; i = i + 1
    local trigger = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return cel, button, x, y, trigger 
  end

  function queue.dispatch()
    local cel, button, x, y, t = pop()
    local intercepted = t[1]
    if cel[_metacel].onmouseup then
      if cel[_metacel]:onmouseup(cel, button, x, y, intercepted) then
        t[1] = true
      end
    end
    --TODO only dispatch to this if it existed at the time the event was pushed, no need to do same for metacel
    --since that is not supposed to be dynamic
    if rawget(cel, 'onmouseup') then
      if cel:onmouseup(button, x, y, intercepted) then
        t[1] = true --TODO make all events handled only if the function returns true
      end
    end
  end

  function event:onmouseup(cel, button, x, y, trigger)
    if cel[_metacel].onmouseup 
    or rawget(cel, 'onmouseup') then
      push(self, cel, button, x, y, trigger)
    end
  end
end



do --onmousewheel
  local dispatch = function(e)
    local cel, direction, x, y, t = e[2], e[3], e[4], e[5], e[6]
    if cel[_metacel].onmousewheel then
      if cel[_metacel]:onmousewheel(cel, direction, x, y, t[1]) then
        t[1] = true
      end
    end
    if rawget(cel, 'onmousewheel') then
      cel:onmousewheel(direction, x, y, t[1])
      t[1] = true
    end
  end

  function event:onmousewheel(cel, direction, x, y, trigger)
    if cel[_metacel].onmousewheel 
    or rawget(cel, 'onmousewheel') then
      self:push({dispatch, cel, direction, x, y, trigger})
    end
  end
end

do --onkeydown
  local dispatch = function(e)
    local cel, key, t = e[2], e[3], e[4]
    if cel[_metacel].onkeydown then
      if cel[_metacel]:onkeydown(cel, key, t[1]) then
        t[1] = true
      end
    end
    if rawget(cel, 'onkeydown') then
      cel:onkeydown(key, t[1])
      t[1] = true
    end
  end

  function event:onkeydown(cel, key, trigger)
    if cel[_metacel].onkeydown 
    or rawget(cel, 'onkeydown') then
      self:push({dispatch, cel, key, trigger})
    end
  end
end

do --onkeypress
  local dispatch = function(e)
    local cel, key, t = e[2], e[3], e[4]
    if cel[_metacel].onkeypress then
      if cel[_metacel]:onkeypress(cel, key, t[1]) then
        t[1] = true
      end
    end
    if rawget(cel, 'onkeypress') then
      cel:onkeypress(key, t[1])
      t[1] = true
    end
  end

  function event:onkeypress(cel, key, trigger)
    if cel[_metacel].onkeypress 
    or rawget(cel, 'onkeypress') then
      self:push({dispatch, cel, key, trigger})
    end
  end
end

do --onkeyup
  local dispatch = function(e)
    local cel, key, t = e[2], e[3], e[4]
    if cel[_metacel].onkeyup then
      if cel[_metacel]:onkeyup(cel, key, t[1]) then
        t[1] = true
      end
    end
    if rawget(cel, 'onkeyup') then
      cel:onkeyup(key, t[1])
      t[1] = true
    end
  end

  function event:onkeyup(cel, key, trigger)
    if cel[_metacel].onkeyup 
    or rawget(cel, 'onkeyup') then
      self:push({dispatch, cel, key, trigger})
    end
  end
end

do --onchar
  local dispatch = function(e)
    local cel, char, t = e[2], e[3], e[4]
    if cel[_metacel].onchar then
      if cel[_metacel]:onchar(cel, char, t[1]) then
        t[1] = true
      end
    end
    if rawget(cel, 'onchar') then
      cel:onchar(char, t[1])
      t[1] = true
    end
  end

  function event:onchar(cel, char, trigger)
    if cel[_metacel].onchar 
    or rawget(cel, 'onchar') then
      self:push({dispatch, cel, char, trigger})
    end
  end
end

do --oncommand
  local dispatch = function(e)
    local cel, command, data, t = e[2], e[3], e[4], e[5]
    if cel[_metacel].oncommand then
      if cel[_metacel]:oncommand(cel, command, data, t[1]) then
        t[1] = true
      end
    end
    if rawget(cel, 'oncommand') then
      cel:oncommand(command, data, t[1])
      t[1] = true
    end
  end

  function event:oncommand(cel, command, data, trigger)
    if cel[_metacel].oncommand 
    or rawget(cel, 'oncommand') then
      self:push({dispatch, cel, command, data, trigger})
    end
  end
end

do --task
  local queue = {first = 0, last = -1}
  
  local function push(event, task)
    local i = queue.last
    i = i + 1; queue[i] = task
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local task = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return task 
  end

  function queue.dispatch()
    local task = pop()
    if task then 
      local reup = task(task) 
      if reup then
        CEL.doafter(reup, task)
      end
    end
  end

  function event:task(task)
    push(self, task.func)
  end
end

do --ontrackmouse
  local queue = {first = 0, last = -1}
  
  local function push(event, func, action, p1, p2, p3, p4)
    local i = queue.last
    i = i + 1; queue[i] = func 
    i = i + 1; queue[i] = action
    i = i + 1; queue[i] = p1
    i = i + 1; queue[i] = p2
    i = i + 1; queue[i] = p3
    i = i + 1; queue[i] = p4
    queue.last = i
    event:push(queue)
  end

  local function pop()
    local i = queue.first
    local func = queue[i]; queue[i] = nil; i = i + 1
    local action = queue[i]; queue[i] = nil; i = i + 1
    local p1 = queue[i]; queue[i] = nil; i = i + 1
    local p2 = queue[i]; queue[i] = nil; i = i + 1
    local p3 = queue[i]; queue[i] = nil; i = i + 1
    local p4 = queue[i]; queue[i] = nil; i = i + 1
    queue.first = i
    return func, action, p1, p2, p3, p4 
  end

  function queue.dispatch()
    local func, action, p1, p2, p3, p4  = pop()
    
    if true ~= func(action, p1, p2, p3, p4) then
      mousetrackerfuncs[func] = nil
    end
    
  end

  function event:ontrackmouse(action, p1, p2, p3, p4)
    --pushing individual functions becuase iterating would be bad while calling out to 
    --carefree code, that could alter the talbe beilng iterated.
    for func in pairs(mousetrackerfuncs) do
      push(self, func, action, p1, p2, p3, p4)
    end
  end
end
