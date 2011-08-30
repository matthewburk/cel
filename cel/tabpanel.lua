local cel = require 'cel'

local _tabs = {}
local _mutex = {}
local _current = {}
local meta, metatable = cel.newmetacel('tabpanel')
local metahandle = cel.grip.newmetacel('tab.handle')
--local metatrack = cel.newmetacel('tab.handletrack')

local layout = {
  tabs = {
  },
  client = {
  },
}

--[[ do this later, implement full drag and drop
function metatrack:__linkmove(track, handle, ox, oy, ow, oh)
  if handle == track.active then
  end
end


function metatrack:onmousemove(track, x, y)
  if track.flux then
    local pick, index = track.sequence:pick(x, y)

    if pick ~= track.fluxhandle then

    end
    --if 
    --find slot in track at x,y
    --if slot is not the slot of the active handle
    --vacate slot if not vacated and make it the slot of the active handle
  end
end
--]]

do
  local grip__describe = metahandle.__describe
  function metahandle:__describe(handle, t)
    grip__describe(t)
    t.selected = handle.selected
    t.active = handle.active
    t.placement = 'top'
    t.title = handle.title
  end
end

function metatable:addtab(name, title, subject, ...)
  local tabs = self[_tabs]
  local mutex = self[_mutex]

  local handle = cel.tocel(title, self)--metahandle:new(self, title)

  tabs[name] = function() return handle, subject end

  handle:link(tabs)
  subject:link(mutex, ...)

  if not self[_current] then
    self:selecttab(name)
  end
  return self
end

function metatable:removetab(name)
  local tabs = self[_tabs]
  local mutex = self[_mutex]
  local f = tabs[name]
  if f then
    local handle, subject = f()
    handle:unlink()
    mutex:clear(subject)
  end

  return self
end

function metatable:selecttab(name)
  local tabs = self[_tabs]
  local mutex = self[_mutex]

  local f = tabs[name]
  if f then
    local handle, subject = f()
    self[_current] = name
    mutex:show(subject)
  end
  return self
end

function meta:__link(tabpanel, link, linker, xval, yval, option)
  if option ~= 'raw' then
    return select(2, self[_tabs][self[_current]]), linker, xval, yval, option
  end
end

do
  local _new = meta.new
  function meta:new(w, h, face)
    face = self:getface(face)
    local tabpanel = _new(self, w, h, face)
    local mutex = cel.mutexpanel.new()
    local tabs = cel.row.new()

    local col = cel.col.new()

    tabs:link(col, 'edges', nil, nil,  {minh=30})
    mutex:link(col, 'edges', nil, nil, {flex=1})
    
    tabpanel[_tabs] = tabs
    tabpanel[_mutex] = mutex

    col:link(tabpanel, 'edges', nil, nil, 'raw')
    return tabpanel
  end

  local _compile = meta.compile
  function meta:compile(t, tabpanel)
    tabpanel = tabpanel or meta:new(t.w, t.h, t.face)
    return _compile(self, t, tabpanel)
  end
end

return meta:newfactory()
