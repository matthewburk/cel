local cel = require 'cel'

local _tabs = {}
local _mutex = {}
local _selected = {}
local metatabpanel, metatable = cel.newmetacel('tabpanel')
local metatab = cel.slot.newmetacel('tabpanel.tab')

local layout = {
  tabs = {
    align = 'top',
    link = {'center'};
    tab = {
      face = nil,
    }
  },
  client = {
    face = nil,
    link = {'edges'}
  },
}

do
  function metatab:__describe(tab, t)
    t.selected = tab.tabpanel[_selected] == tab
    t.align = 'top'
  end
end

local lopt = {flex=1}
function metatable:addtab(name, subject, ...)
  local tabs = self[_tabs]
  local mutex = self[_mutex]

  local tab = metatab:new()
  tab.tabpanel = self
  tab.subjecthost = cel.slot.new()
  tab.subject = subject
  tabs[name] = tab

  tab:link(tabs, 'edges', nil, nil, lopt)
  tab.subjecthost:link(mutex, 'edges')
  subject:link(tab.subjecthost, ...)

  if not self[_selected] then
    self:selecttab(name)
  end
  return self
end

function metatable:removetab(name)
  local tabs = self[_tabs]
  local mutex = self[_mutex]
  local tab = tabs[name]
  if tab then
    tabs[name] = nil

    if self[_selected] == tab then
      self[_selected] = nil
    end

    tab:unlink()
    mutex:clear(tab.subjecthost)
    tab.subject:unlink()
  end

  return self
end

function metatable:selecttab(name)
  local tabs = self[_tabs]
  local mutex = self[_mutex]
  local tab = tabs[name]

  if tab then
    self[_selected] = tab 
    mutex:show(tab.subjecthost)
  end
  return self
end

function metatable:getclientrect()
  return self:pget('x', 'y', 'w', 'h')
end

function metatable:gettabalign()
  return self[_tabs].align
end

--just give direct access to tabs
function metatable:breakaway()

end

function metatabpanel:__link(tabpanel, link, linker, xval, yval, option)
  if option then
    local tab = tabpanel[_tabs][option]
    if tab then
      return tab.subjecthost, linker, xval, yval
    end
  end
end

do
  local _new = metatabpanel.new
  function metatabpanel:new(w, h, face)
    face = self:getface(face)
    local layout = face.layout or layout

    local tabpanel = _new(self, w, h, face)
    local mutex = cel.mutexpanel.new(w, h, layout.client.face)
    local tabs = cel.row.new()
    tabs.align = layout.tabs.align or 'top'
    tabs.tabface = layout.tabs.tab.face

    tabs:link(tabpanel, layout.tabs.link)
    mutex:link(tabpanel, layout.client.link)
    
    tabpanel[_tabs] = tabs
    tabpanel[_mutex] = mutex

    tabpanel.tabs = tabs

    return tabpanel
  end

  local _compile = metatabpanel.compile
  function metatabpanel:compile(t, tabpanel)
    tabpanel = tabpanel or meta:new(t.w, t.h, t.face)
    return _compile(self, t, tabpanel)
  end
end

return metatabpanel:newfactory()
