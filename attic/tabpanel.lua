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
    link = {'fill'}
  },
}

do
  function metatab:__describe(tab, t)
    t.selected = tab.tabpanel[_selected] == tab
    t.align = 'top'
  end
end

function metatable:addtab(name, subject, ...)
  local tabs = self[_tabs]
  local mutex = self[_mutex]

  local tab = metatab:new()
  tab.align = tabs.align
  tab.tabpanel = self
  tab.subjecthost = cel.slot.new()
  tab.subject = subject
  tabs[name] = tab

  tab:link(tabs, 'fill', nil, nil, {flex=1})
  tab.subjecthost:link(mutex, 'fill')
  subject:link(tab.subjecthost, ...)

  if not self[_selected] then
    self:selecttab(name)
  end
  --TODO enable a proxy table to be used for a cel
  --cel.link, etc would have full access becuase it
  --has acess to the private key that holds the cel
  --return metacel:proxyfor(tab, 'link-able', 'event-able')
  return self, tab
end

function metatable:removetab(name)
  local tabs = self[_tabs]
  local mutex = self[_mutex]
  local tab = tabs[name]

  if tab then
    tabs[name] = nil

    if self[_selected] == tab then
      self[_selected] = nil
      --TODO select new tab 
    end

    tab:unlink()
    mutex:remove(tab.subjecthost)
    tab.subject:unlink()
  end
  return self
end

function metatable:selecttab(name)
  local tabs = self[_tabs]
  local mutex = self[_mutex]
  local tab = tabs[name]

  if tab then
    if self[_selected] then
      self[_selected]:refresh()
    end
    self[_selected] = tab
    mutex:select(tab.subjecthost)
    tab:refresh()
    if self.onselect then
      self:onselect(name, tab.subject)
    end
  end
  return self
end

function metatable:getselected()
  return self[_selected] and self[_selected].subject
end

function metatable:getclientrect()
  return self[_mutex]:pget('x', 'y', 'w', 'h')
end

function metatable:gettabalign()
  return self[_tabs].align
end

--just give direct access to tabs
function metatable:breakaway()
  --this assumes slot does not have a get, a slot should not expose any of its links
  --by default
  local slot = cel.slot.new()
  local tabs = self[_tabs]

  local linker, xval, yval = tabs:pget('linker', 'xval', 'yval')

  tabs:link(slot, linker, xval, yval)
  return slot, linker, xval, yval
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
