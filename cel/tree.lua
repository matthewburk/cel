local cel = require 'cel'
require 'cel.label'
require 'cel.button'


local _seq = {}
local _minimized = {}
local _offset = {}

local metacel, metatable = cel.newmetacel('tree')

do --tree.button
  local button_metacel = cel.button.newmetacel('tree.button')

  function button_metacel:__describe(button, t)
    t.minimized = button.tree[_minimized]
    t.len = button.tree[_seq]:len()
  end

  function metacel:newbutton(w, h, face)
    return button_metacel:new(w, h, face)
  end
end

local layout = {
  offset = 19,

  button = {
    face = nil,
    w = 13, 
    h = 13,
    xval = 3,
    yval = nil,
    linker = 'left.center',
  },
}

local function onclick(button)
  local tree = button.tree
  
  if tree[_minimized] then
    tree:maximize()
  else
    tree:minimize()
  end
end

function metatable.maximize(tree)
  if tree[_minimized] then
    tree[_minimized] = nil
    --tree:resize(nil, tree[_seq].h)
    tree:flow(nil, nil, tree[_seq].w, tree[_seq].h, 'maximize')
  end
end

function metatable.flux(tree, callback, ...)
  return tree[_seq]:flux(callback, ...)
end

function metatable.minimize(tree)
  if not tree[_minimized] then 
    tree[_minimized] = true
    --tree:resize(nil, tree[_seq]:get(1).h)
    tree:flow(nil, nil, tree[_seq]:get(1).w, tree[_seq]:get(1).h, 'minimize')
  end
end

function metatable.add(tree, item, index)
  if type(item) == 'string' then
    item = cel.label.new(item)
  end

  
  return item:link(tree, nil, index and index + 1)
end

function metatable.get(tree, index, ...)
  local item = tree[_seq][index]

  --if itme is tree
  --
  --

  if index == 1 then 
    return
  end

  return item
end

function metacel:onlinkmove(tree, link)
  if link == tree[_seq] and not tree[_minimized] then
    tree:resize(link.w, link.h)
  end
end

function metacel:__link(tree, link, linker, xval, yval, option)
  if tree[_seq] then
    local offset
    if link[_offset] then
      offset = tree[_offset]
    else
      offset = tree[_offset] --* 2
    end
  
    return tree[_seq], nil, offset, nil, option 
  end
  return tree, linker, xval, yval, option
end

function metacel:__describe(tree, t)
  t.minimized = tree[_minimized]
  t.len = tree[_seq]:len()
end

do
  local _new = metacel.new
  function metacel:new(root, face)
    face = self:getface(face)
    local layout = face.layout or layout

    if type(root) == 'string' then root = cel.label.new(root) end

    local w = root.w + layout.offset
    local h = root.h

    local tree = _new(self, w, h, face)
    local seq = cel.sequence.y.new()
    local roothost = cel.new(w, h)

    do
      local layout = layout.button
      local button = self:newbutton(layout.w, layout.h, layout.face)
      button:link(roothost, layout.xval, layout.yval, layout.linker)
      button.onclick = onclick 
      button.tree = tree 
    end

    root:link(roothost, layout.offset, nil)
    roothost:link(seq)
    seq:link(tree)

    tree[_offset] = layout.offset
    tree[_seq] = seq 

    return tree
  end

  local _construct = metacel.construct
  function metacel:construct(tree, t)
    return _construct(self, tree, t)
  end
end


cel.tree = setmetatable(
  {
    new = function(root, face) return metacel:new(root, face) end,
    newmetacel = function(name) return metacel:newmetacel(name) end,
    layout = nil,
  },
  {__call = 
    function(self, t)
      local tree = metacel:new(t.root, t.face)
      return metacel:construct(tree, t)
    end
  })

return cel.tree

