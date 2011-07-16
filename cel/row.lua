local cel = require 'cel'

local rowmetacel, rowmt = cel.sequence.x.newmetacel('row')
local slotmetacel = cel.slot.newmetacel('row.slot')

local _weight = {}
local _minw = {}
local _row = {}

local row_items = rowmt.items
local row_get = rowmt.get

rowmt.next = nil
rowmt.prev = nil
rowmt.indexof = nil

do
  local memo = setmetatable({}, {__mode = "kv"})
  
  local function filter(iter)
    local filter = memo[iter] 
    if not filter then
      filter = function(...)
        local i, slot = iter(...)
        if slot and slot[_weight] then
          return i, slot:get() 
        else
          return i, slot
        end
      end
      memo[iter] = filter
    end
    return filter
  end
  
  function rowmt.items(row)
    local iter, state, i = row_items(row)
    return filter(iter), state, i 
  end
end

function rowmt.get(row, i)
  local slot = row_get(row, i)
  if slot and slot[_weight] then
    return slot:get()
  end
  return slot
end

do
  local _setlimits = slotmetacel.setlimits
  function slotmetacel:setlimits(slot, minw, maxw, minh, maxh) 
    slot[_row][_minw] = slot[_row][_minw] - slot.minw + math.max(minw, slot[_minw])
    return _setlimits(self, slot, math.max(minw, slot[_minw]), maxw, minh, maxh)
  end
end

do
  local _setlimits = rowmetacel.setlimits
  function rowmetacel:setlimits(row, minw, maxw, minh, maxh)
    minw = row[_minw]
    return _setlimits(self, row, minw, nil, minh, maxh)
  end
end

local function allocateslots(row, w)
  if row[_weight] <= 0 then return end

  local excess = w-(row.minw or 0)

  if excess > 0 then
    local extra = excess % row[_weight]
    local mult = math.floor((excess)/row[_weight])

    for i, slot in row_items(row) do
      local weight = slot[_weight]

      if weight then
        local w = slot.minw + (weight * mult)

        if extra > 0 then
          w = w + math.min(weight, extra)
          extra = extra - weight
        end

        slot:resize(w)
      end
    end
  end
end

local function slotlayout(minw, weight)
  return function()
    return minw, weight
  end
end

function rowmetacel:__link(row, link, linker, xval, yval, option)
  if type(option) == 'function' then
    local minw, weight = option()

    row[_weight] = row[_weight] + weight

    local slot = slotmetacel:new()
    slot[_minw] = minw
    slot[_weight] = weight
    slot[_row] = row

    slotmetacel:setlimits(slot, slot:pget('minw', 'maxw', 'minh', 'maxh'))

    slot:link(row, 'height')

    return slot, linker, xval, yval
  elseif not link[_weight] then
    row[_minw] = row[_minw] + link.w
  end
end

function rowmetacel:__linkmove(row, link, ox, oy, ow, oh)
  if link.w ~= ow and not link[_weight] then
    row[_minw] = row[_minw] - ow + link.w
  end
end

function rowmetacel:__resize(row, ow, oh)
  if row[_weight] > 0 and row.w ~= ow then
    row:flux(allocateslots, row, row.w)
  end
end

do
  local _new = rowmetacel.new
  function rowmetacel:new(face) --TODO don't need to define this, just let it pass to slot
    local row = _new(self, 0, self:getface(face))
    row[_weight] = 0
    row[_minw] = 0
    return row
  end

  local _compile = rowmetacel.compile
  function rowmetacel:compile(t, row)
    return _compile(self, t, row or rowmetacel:new(t.face))
  end

  local _up = rowmetacel.compilelistentry
  function rowmetacel:compilelistentry(t, row, index, entry, typ)
    if 'table' == typ then
      local minw = entry.minw or 0
      local weight = entry.weight or 0

      local link = cel.tocel(entry[1], row)
      
      if link then
        local linker, xval, yval = link:pget('linker', 'xval', 'yval')
        link:link(row, linker, xval, yval, slotlayout(minw, weight))
      else
      end
    end
  end
end

return rowmetacel:newfactory()


