local cel = require 'cel'

local metacel, mt = cel.scroll.newmetacel('vlistbox')

local _items = {}

--items must support items:pick
--items must support items:next(item)
--items must support items:prev(item)

do
  local _setsubject = mt.setsubject
  function mt:setitems(items)
    self[_items] = items
    _setsubject(self, items, true)
    return self
  end
end

function mt:pick(x, y)
  local items = self[_items]
  local px, py, pw, ph = self:getportalrect()

  if x >= px and x < px + pw and y >= py and y < py + ph then
    return items:pick(x - items.x - px, y - items.y - py)
  end
end

--TODO implement mode, for 'top', 'bottom', 'center', 'current postion of cursor'
function mt:scrolltoitem(item, mode)
  --item must be a cel linked to items

  if not item then
    return self
  end

  local ix, iy = cel.translate(item, 0, 0, self[_items])

  if not ix then
    return self
  end

  local x, y, w, h = self:getportalrect()
  x, y = self:getvalues()

  if y + h < iy + item.h then
    self:scrollto(nil, iy + item.h - h)
  elseif iy < y then
    self:scrollto(nil, iy)
  else
  end
  return self
end

do
  local function map(self, value)
    local items = self[_items]
    local item = items:pick(0, value)

    if item then
      local ix, iy = cel.translate(item, 0, 0, self[_items])

      if value ~= iy then
        item = items:next(item)
        if item then
          ix, iy = cel.translate(item, 0, 0, self[_items])
          return iy
        else
          return items.h
        end
      end
    end
    return value
  end

  local _scrollto = mt.scrollto
  function mt:scrollto(x,  y)
    self[_items]:endflow()
    y = y and map(self, y)
    return _scrollto(self, x, y)
  end

  function mt:step(xstep, ystep, mode)
    local items = self[_items]

    items:endflow()

    local x, y = self:getvalues()
    if ystep and ystep ~= 0 then
      local item = items:pick(0, y)

      if item then
        if ystep > 0 then
          item = items:next(item)
        else 
          local ix, iy = cel.translate(item, 0, 0, items)
          if y <= iy then --to keep step to the top of a cel if we are in the middle of it
            item = items:prev(item)
          end
        end
      end

      if item then
        local ix, iy = cel.translate(item, 0, 0, items)
        y = iy
      elseif ystep > 0 then
        y = items.h
      else
        y = 0
      end
    else
      y = nil
    end

    if xstep then
      x = x + (xstep * self.stepsize)
    else
      x = nil
    end

    return _scrollto(self, x, y)
  end
end

do
  local _setsubject = mt.setsubject
  mt.setsubject = nil
  mt.getsubject = nil

  local _new = metacel.new
  function metacel:new(face)
    face = self:getface(face)

    local vlistbox = _new(self, 0, 0, face)

    return vlistbox
  end

  local _compile = metacel.compile
  function metacel:compile(t, vlistbox)
    vlistbox = vlistbox or metacel:new(t.face)
    _compile(self, t, vlistbox)
    if t.items then
      vlistbox:setitems(t.items)
    end
    return vlistbox
  end
end

return metacel:newfactory()
