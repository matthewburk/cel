--[[
cel is licensed under the terms of the MIT license

Copyright (C) 2011-2103 by Matthew W. Burk

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
local cel = require 'cel'

local newtile

do --datepicker.tile
  local metacel, mt = cel.slot.newmetacel('datepicker.tile')

  local layout = {
    label = {
      face = nil,
      link = 'center',
    },
  }

  local _new = metacel.new
  function metacel:new(face)
    face = self:getface(face)
    local layout = face.layout or layout
    local l, t, r, b 
    if layout.margin then
      l = layout.margin.l
      t = layout.margin.t
      r = layout.margin.r
      b = layout.margin.b
    end
    local tile = _new(self, face, l, t, r, b)
    tile.label = cel.label.new('', layout.label.face)
    tile.label:link(tile, layout.label.link or 'center')
    return tile
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, tile)
    tile = tile or metacel:new(t.face)
    return _assemble(self, t, tile)
  end

  local _setface = metacel.setface
  function metacel:setface(tile, face)
    local layout = face.layout or layout
    tile.label:setface(layout.label.face)
    tile.label:relink(layout.label.link or 'center')
    local l, t, r, b 
    if layout.margin then
      l = layout.margin.l
      t = layout.margin.t
      r = layout.margin.r
      b = layout.margin.b
    end
    --tile:setmargins(l, t, r, b) --TODO need to make slot.setmargins work
    return _setface(self, tile, face)
  end

  function newtile(face, text)
    local tile = metacel:new(face)
    if text then
      tile.label:settext(text)
    end
    return tile
  end
end

local metacel, mt = cel.slot.newmetacel('datepicker')

local _grid = {}
local _year = {}
local _month = {}
local _day = {}
local _time = {}

local layout = {
  weekdayheadertext = {'S', 'M', 'T', 'W', 'T', 'F', 'S'},
  weekdaytiles = { },
  tiles = {
    currentmonth=nil,
    othermonth=nil,
    currentdate=nil,
  },
}

local dateutils = {}

do
  local t = {year=1,month=1,day=0}

  function dateutils.getdaysinmonth(month, year) --credit to http://richard.warburton.it
    t.year=year
    t.month=month+1
    return os.date('*t',os.time(t))['day']
  end
end

local function settiledate(datepicker, layout, tile, year, month, day)
  tile.year = year
  tile.month = month
  tile.day = day

  local face = layout.tiles.othermonth
  if datepicker[_year] == year and datepicker[_month] == month then
    if datepicker[_day] == day then
      face = layout.tiles.currentdate
    else
      face = layout.tiles.currentmonth
    end
  end
  tile:setface(face)
  if tile.label then
    tile.label:settext(tostring(day)) --label could be changed by library user
  end
end

--month and year 
function mt:setdate(date, month, day)
  dprint('setdate', date, month, day)

  if type(date) == 'number' then
    self[_time] = os.time({year=date, month=month, day=day})
    date = os.date('*t', self[_time])
  else 
    self[_time] = os.time(date)
  end

  self[_year] = date.year
  self[_month] = date.month
  self[_day] = date.day

  local layout = self.face.layout or layout
  local grid = self[_grid]

  local year = date.year
  local month = date.month

  local firstday = os.date('*t', os.time{year=year, month=month, day=1})
  local lastday = dateutils.getdaysinmonth(month, year)

  year = month > 1 and year or year-1
  month = month > 1 and month-1 or 12

  local lastdayofprev = os.date('*t', os.time{year=year, month=month, day=dateutils.getdaysinmonth(month, year)})

  do --first row
    local day = lastdayofprev.day
    local row = grid[1]
    for wday=lastdayofprev.wday, 1, -1 do
      settiledate(self, layout, row[wday], lastdayofprev.year, lastdayofprev.month, day) 
      day=day-1
    end

    day = firstday.day
    for wday=firstday.wday, 7 do
      settiledate(self, layout, row[wday], firstday.year, firstday.month, day)
      day=day+1
    end
 
    year = firstday.year
    month = firstday.month

    for i=2, #grid do
      local row = grid[i]
      for wday=1, 7 do
        settiledate(self, layout, row[wday], year, month, day)
        day=day+1
        if day > lastday then 
          day=1 
          month = month+1
          if month > 12 then
            month=1
            year=year+1
          end
        end
      end
    end
  end

  return self
end

function mt:getdate()
  return self[_year], self[_month], self[_day]
end

function mt:gettime()
  return self[_time]
end

function mt:gettilegrid()
  return self:getsubject()
end

function mt:gettilebydate(year, month, day)
end

do
  local ceil = math.ceil
  local function it(datepicker, i)
    i=i+1
    if i <= 42 then
      return datepicker[_grid][ceil(i/7)][i%7]
    end
  end

  function mt:tiles()
    return it, self, 0
  end
end

function mt:gettilesbywday(wday, month)
  local g = self[_grid]
  if wday <= 7 and wday >=1 then
    return g[1][wday], g[2][wday], g[3][wday], g[4][wday], g[5][wday], g[6][wday] 
  end
end

function mt:setdateontileevent(event)
end

do
  local _new = metacel.new
  function metacel:new(face)
    face = self:getface(face)
    local layout = face.layout or layout
    local l, t, r, b 
    if layout.margin then
      l = layout.margin.l
      t = layout.margin.t
      r = layout.margin.r
      b = layout.margin.b
    end
    local datepicker = _new(self, face, l, t, r, b)

    local function tilepicked(tile)
      if datepicker.ondatepicked then
        datepicker:ondatepicked(tile, tile.year, tile.month, tile.day)
      end
    end

    local n = newtile
    local f = layout.tiles.currentmonth
    local grid = {
      {n(f), n(f), n(f), n(f), n(f), n(f), n(f), },
      {n(f), n(f), n(f), n(f), n(f), n(f), n(f), },
      {n(f), n(f), n(f), n(f), n(f), n(f), n(f), },
      {n(f), n(f), n(f), n(f), n(f), n(f), n(f), },
      {n(f), n(f), n(f), n(f), n(f), n(f), n(f), },
      {n(f), n(f), n(f), n(f), n(f), n(f), n(f), },
    }

    for i=1, 6 do
      for wday=1, 7 do
        local tile = grid[i][wday]
        tile.wday = wday
        tile.onmouseup = tilepicked
      end
    end
    
    datepicker[_grid] = grid

    local wkdays = {
      newtile(layout.weekdaytiles[1] or layout.weekdaytiles[1], layout.weekdayheadertext[1]), --sunday
      newtile(layout.weekdaytiles[2] or layout.weekdaytiles[1], layout.weekdayheadertext[2]),
      newtile(layout.weekdaytiles[3] or layout.weekdaytiles[1], layout.weekdayheadertext[3]),
      newtile(layout.weekdaytiles[4] or layout.weekdaytiles[1], layout.weekdayheadertext[4]),
      newtile(layout.weekdaytiles[5] or layout.weekdaytiles[1], layout.weekdayheadertext[5]),
      newtile(layout.weekdaytiles[6] or layout.weekdaytiles[1], layout.weekdayheadertext[6]),
      newtile(layout.weekdaytiles[7] or layout.weekdaytiles[1], layout.weekdayheadertext[7]),
    }
    
    cel.row { gap=layout.rowgap, --TODO make into a regular grid
      cel.col { gap=layout.colgap, link='fill', wkdays[1], grid[1][1], grid[2][1], grid[3][1], grid[4][1], grid[5][1], grid[6][1], }, --sunday
      cel.col { gap=layout.colgap, link='fill', wkdays[2], grid[1][2], grid[2][2], grid[3][2], grid[4][2], grid[5][2], grid[6][2], },
      cel.col { gap=layout.colgap, link='fill', wkdays[3], grid[1][3], grid[2][3], grid[3][3], grid[4][3], grid[5][3], grid[6][3], },
      cel.col { gap=layout.colgap, link='fill', wkdays[4], grid[1][4], grid[2][4], grid[3][4], grid[4][4], grid[5][4], grid[6][4], },
      cel.col { gap=layout.colgap, link='fill', wkdays[5], grid[1][5], grid[2][5], grid[3][5], grid[4][5], grid[5][5], grid[6][5], },
      cel.col { gap=layout.colgap, link='fill', wkdays[6], grid[1][6], grid[2][6], grid[3][6], grid[4][6], grid[5][6], grid[6][6], },
      cel.col { gap=layout.colgap, link='fill', wkdays[7], grid[1][7], grid[2][7], grid[3][7], grid[4][7], grid[5][7], grid[6][7], },
    }:link(datepicker)

    return datepicker:setdate(os.date('*t', os.time()))
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, datepicker)
    datepicker = datepicker or metacel:new(t.face)
    return _assemble(self, t, datepicker)
  end
end

return metacel:newfactory(dateutils)
