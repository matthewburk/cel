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
return function(_ENV, M)
setfenv(1, _ENV)

--local _links = _links 
local _weightcols = {}
local _weightrows = {}
local _cols = {}
local _sortedcols = {}
local _sortedrows = {}

local _influx = {}
local _reconciled = {}

local gridformation = {}
local rowformation = {}
local _x, _y, _w, _h = _x, _y, _w, _h
local _host = _host
local _minw, _maxw, _minh, _maxh = _minw, _maxw, _minh, _maxh

--binary search
--TODO change to interpolating search
local function indexof(grid, item)
  local floor = math.floor
  local t = grid[_links]
  local istart,iend,imid = 1,#t,0
  local gridpos = _y
  local griddim = _h
  local inval = item[gridpos]

  while istart <= iend do
    imid = floor( (istart+iend)/2 )
    local value = t[imid][gridpos]
    if inval == value then
      return imid
    elseif inval < value then
      iend = imid - 1
    else
      istart = imid + 1
    end
  end
end

local function pick(t, valueindex, rangeindex, inval)
  local floor = math.floor
  local istart, iend, imid = 1, #t, 0

  assert(istart <= iend)

  while istart <= iend do
    imid = floor( (istart+iend)/2 )
    local value = t[imid][valueindex]
    local range = t[imid][rangeindex] 
    if inval >= value and inval < value + range then
      return t[imid], imid
    elseif inval < value then
      iend = imid - 1
    else
      if not (inval >= value + range) then
        assert(inval >= value + range)
      end
      istart = imid + 1
    end
  end
end

do --gridformation.allocatecols
  function gridformation:allocatecols(grid)
    local w = grid[_w]
    local minw = _getminw(grid)

    if grid[_weightcols] > 0 then
      local weightmultiplier = math.floor((w - minw)/grid[_weightcols])
      for i, col in ipairs(grid[_cols]) do
        col.ow = col.w
        col.w = col.minw + (col.weight * weightmultiplier)
      end

      local extraw = (w-minw) % grid[_weightcols]
      if extraw > 0 then
        for i, col in ipairs(grid[_sortedcols]) do
          local w = extraw - col.weight
          if extraw - col.weight > 0 then
            col.w = col.w + col.weight
            extraw = extraw - col.weight
          else
            col.w = col.w + extraw
            break
          end
        end
      end
    end

    local x = 0
    for i, col in ipairs(grid[_cols]) do
      col.ox = col.x
      col.x = x
      x = x + col.w
    end
  end
end

do --gridformation.allocaterows
  function gridformation:allocaterows(grid)
    local h = grid[_h]
    local w = grid[_w]
    local minh = _getminh(grid)
    local links = grid[_links]

    if grid[_weightrows] > 0 then
      local weightmultiplier = math.floor((h - minh)/grid[_weightrows])
      for i, row in ipairs(links) do
        row.oh = row[_h]
        row[_h] = row[_minh] + (row.weight * weightmultiplier)
        row:refresh()
      end

      local extrah = (h-minh) % grid[_weightrows]
      if extrah > 0 then
        for i, row in ipairs(grid[_sortedrows]) do
          local h = extrah - row.weight
          if extrah - row.weight > 0 then
            row[_h] = row[_h] + row.weight
            extrah = extrah - row.weight
          else
            row[_h] = row[_h] + extrah
            break
          end
        end
      end
    end

    local y = 0
    for i, row in ipairs(links) do
      --row.ow = row[_w]
      row[_w] = w 
      --row.oy = row[_y]
      row[_y] = y
      y = y + row[_h]
    end
  end
end

do --reconcile

  function gridformation:reconcile(grid)
    local w = grid[_w]

    event:wait()

    for i, row in ipairs(grid[_links]) do
      row[_w] = w
      for i, slot in ipairs(row[_links]) do
        local col = grid[_cols][i]
        slot[_x] = col.x
        if slot[_w] ~= col.w or slot[_h] ~= row[_h] then
          slot[_w] = col.w
          slot[_h] = row[_h] 
          for link in links(slot) do
            if rawget(link, _linker) then
              dolinker(slot, link, link[_linker], link[_xval], link[_yval])
            end
          end
        end
      end
    end

    event:signal()
    grid[_reconciled] = true
  end
end

do --gridformation.moved
  --called anytime grid is moved by any method
  function gridformation:moved(grid, x, y, w, h, ox, oy, ow, oh)
    if w ~= ow or h ~= oh then
      event:onresize(grid, ow, oh)

      if grid[_influx] and grid[_influx] > 0 then
        return
      end

      if w ~= ow then self:allocatecols(grid) end
      if h ~= oh then self:allocaterows(grid) end
      gridformation:reconcile(grid)
    end
  end
end

do --gridformation.pick
  function gridformation:pick(grid, x, y)
    return pick(grid[_links], _y, _h, y)
  end
end

do --gridformation.describelinks
  function gridformation:describelinks(grid, host, gx, gy, gl, gt, gr, gb)
    local links = grid[_links]
    local nlinks = #links

    if nlinks > 0 then
      local _, a = self:pick(grid, gl - gx, gt - gy)
      local _, b = self:pick(grid, gr - gx, gb - gy)

      if a and a > 1 then a = a - 1 end
      if b and b < nlinks then b = b + 1 end

      a = a or 1
      b = b or nlinks

      local i = 1
      for index = a, b do
        host[i] = describe(links[index], host, gx, gy, gl, gt, gr, gb)
        i = host[i] and i + 1 or i
      end
    end
  end
end

do --rowformation.pick
  function rowformation:pick(row, x, y)
    return pick(row[_links], _x, _w, x)
  end
end

do --rowformation.describelinks
  function rowformation:describelinks(row, host, gx, gy, gl, gt, gr, gb)
    local links = row[_links]
    local nlinks = #links

    if nlinks > 0 then
      local _, a = self:pick(row, gl - gx, gt - gy)
      local _, b = self:pick(row, gr - gx, gb - gy)

      if a and a > 1 then a = a - 1 end
      if b and b < nlinks then b = b + 1 end

      a = a or 1
      b = b or nlinks

      local i = 1
      for index = a, b do
        host[i] = describe(links[index], host, gx, gy, gl, gt, gr, gb)
        i = host[i] and i + 1 or i
      end
    end
  end
end

local metacel, metatable = metacel:newmetacel('grid')

do --metatable.newcol
  function metatable.newcol(grid, layout) 
    local i = #grid[_cols] + 1
    local col = {
      i = i;
      weight = layout.weight;
      minw = layout.minw or 0;
      w = layout.minw or 0;
      x = 0;
      link = layout.link;
    }
    grid[_sortedcols][i] = col
    grid[_cols][i] = col

    grid[_weightcols] = grid[_weightcols] + col.weight
    grid[_reconciled] = false

    if grid[_weightcols] == 0 then
      grid[_metacel]:setlimits(grid, grid[_minw] + col.minw, grid[_minw] + col.minw, grid[_minh], grid[_maxh])
    else
      grid[_metacel]:setlimits(grid, grid[_minw] + col.minw, nil, grid[_minh], grid[_maxh])
    end

    if grid[_influx] and grid[_influx] > 0 then
      return grid
    end

    if not grid[_reconciled] then
      gridformation.allocatecols(grid)
      gridformation.allocaterows(grid)
      gridformation:reconcile(grid)
    end
  end
end

do --metatable.newrow
  local metacel = _ENV.metacel:newmetacel('grid.row')

  function metacel:__link(row, link, linker, xval, yval, index)
    local slot = row[_links][index or 1] or row[_links][1]
    return slot, linker, xval, yval
  end

  local defaultlayout = {minh=0, weight=0}

  function metatable.newrow(grid, elements, layout)
    layout = layout or defaultlayout

    local row = metacel:new(0, layout.minh or 0)
    row[_minh] = row[_h]
    row.weight = layout.weight or 0
    row.explicitminh = row[_minh]
    row[_formation] = rowformation
    row[_links] = {}

    for i, col in ipairs(grid[_cols]) do
      local slot = M.new(col.w, row[_h])
      row[_links][i]= slot
      slot[_host] = row

      local element = elements[i]

      if element then
        if type(element) == 'string' then
          element = grid.celfromtext(element)
        end
        element:link(slot, col.link)

        if element[_h] > row[_h] then
          row.oh = row[_h]
          row[_h] = element[_h]
          row[_minh] = element[_h]
        end
      end
    end

    --link the row
    do
      local nrows = #grid[_links]
      row[_host] = grid
      grid[_links][nrows + 1] = row
      --only if rows are wieghted do this
      --grid[_sortedrows][nrows + 1] = row
      grid[_sortedrows] = grid[_links] 
    end

    grid[_weightrows] = grid[_weightrows] + row.weight

    grid[_reconciled] = false
    if grid[_weightrows] == 0 then
      grid[_metacel]:setlimits(grid, grid[_minw], nil, _getminh(grid) + _getminh(row),  _getminh(grid) + _getminh(row))
    else
      grid[_metacel]:setlimits(grid, grid[_minw], nil,  _getminh(grid) + _getminh(row), nil)
    end


    if grid[_influx] and grid[_influx] > 0 then
      return grid
    end

    if not grid[_reconciled] then
      gridformation:allocaterows(grid)
      gridformation:reconcile(grid)
    end

    return grid 
  end
end
   
--[=[
do --metatable.clear
  function metatable.clear(grid)
    grid[_influx] = (grid[_influx] or 0) + 1
    event:wait()
    local links = grid[_links] 
    --grid[_links] = nil 

    for i=#links, 1, -1 do
      links[i]:unlink()
    end

    grid[_links] = {}
    grid[_influx] = grid[_influx] - 1
    gridformation:reconcile(grid)
    event:signal()
  end
end

do --metatable.rows
  function metatable.rows(grid)
    return ipairs(grid[_links])
  end
end

--TODO a row should 
function metatable.row(grid, i)
  i = i or 1
  if i < 0 then i = i + 1 + #grid[_links] end
  return grid[_links][i]
end

function metatable.get(grid, col, row)
  row = grid:getrow(row)
  if row then
    col = col or 1
    if col < 0 then col = col + 1 + #row[_links] end
    return row[_links][col]
  end
end



do --metatable.size
  function metatable.size(grid)
    return #grid[_links], #grid[_cols]
  end
end
--]=]

do --metatable.flux
  --when flux is started grid is is reconciled(so it is no longer in flux) 
  --while in flux adjustments don't happen, before flux retruns it is reconciled 
  function metatable.flux(grid, callback, ...)
    grid[_influx] = (grid[_influx] or 0) + 1
    gridformation:allocatecols(grid)
    gridformation:allocaterows(grid)
    gridformation:reconcile(grid)

    if callback then
      callback(...)

      gridformation:allocatecols(grid)
      gridformation:allocaterows(grid)
      gridformation:reconcile(grid)
    end

    grid[_influx] = grid[_influx] - 1
  end
end

local layout = {
  rowface = M.getface('grid.row'),
  slotface = M.getface('grid.slot'),
}

local function colrowtuple(col, row)
  return function()
    return col, row
  end
end

function metacel:__link(grid, link, linker, xval, yval, option)
  if type(option) == 'function' then
    local x, y = option()
    local row = grid[_rows][y] or grid:newrow()
    return row[_links][x] or row[_links][1], liner, xval, yval
  else
    local row =  newrow(grid, grid[_w], link[_h])
    row:link(grid, nil, nil, nil, 'row')
    return row[_links][1], linker, xval, yval
  end
end

do --metacel.new, metacel.compile
  local _new = metacel.new
  function metacel:new(colparams, face)
    face = self:getface(face)
    local layout = face.layout or layout
    local minw = 0
    local weight = 0
    local cols = {}

    for i, t in ipairs(colparams) do
      cols[i] = { 
        i = i;
        weight = t.weight; 
        minw = t.minw or 0;
        w = t.minw or 0;
        x = minw;
        link = t.link;
      }
      weight = weight + t.weight
      minw = minw + (t.minw or 0)
    end

    local grid = _new(self, minw, 0, face)
    grid[_weightcols] = weight
    grid[_weightrows] = 0
    grid[_links] = {}
    grid[_cols] = cols
    grid[_sortedcols] = {unpack(cols)}
    table.sort(grid[_sortedcols], function(cola, colb)
      if cola == colb then
        return false
      elseif -cola.weight < -colb.weight then
        return true
      elseif cola.weight == colb.weight then
        return cola.i < colb.i
      end
    end)
    grid[_sortedrows] = {}

    grid[_minw] = minw
    grid[_minh] = 0
    grid[_maxh] = 0

    grid[_formation] = gridformation

    return grid
  end

  local _compile = metacel.compile
  function metacel:compile(t, grid)
    grid = grid or metacel:new(t.face)
    grid[_influx] = 1
    grid.onchange = t.onchange
    _compile(self, t, grid)
    grid[_influx] = 0 
    gridformation:reconcile(grid)
    return grid
  end
end

return metacel:newfactory({layout=layout})

end
