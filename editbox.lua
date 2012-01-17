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
local cel = require 'cel'

local metacel, metatable = cel.newmetacel('editbox') 
metacel['.text'] = cel.label.newmetacel('editbox.text')

local _font = {} 
local _text = {} 
local _padl = {}
local _padr = {}
local _padt = {}
local _padb = {}
local _caret = {}
local _multiline = {}
local _selection = {}

local keyboard = cel.keyboard
local mouse = cel.mouse

local layout = {
  text = cel.getface('editbox.text')
}


do --editbox.text
  local textmetacel = metacel['.text']
  local __describe = textmetacel.__describe
  function textmetacel:__describe(text, t)
    __describe(self, text, t)
    t.selectioni = text.selection.i
    t.selectionj = text.selection.j
    t.selectionx = text.selection.x
    t.selectiony = text.selection.y
    t.selectionw = text.selection.w
    t.selectionh = text.selection.h
  end
end

function metatable:settext(str)
  self:select(false)
  return self[_text]:settext(str)
end

function metatable:gettext()
  return self[_text]:gettext()
end

function metatable:isfull()
  return false
end

function metacel:__describe(editbox, t)
  t.font = editbox[_font]
end

function metatable:movecaret(i)
  local text = self[_text]
  local caret = self[_caret]
  local str = text:gettext()
  local font = text:getfont()

  if i < 0 then i = 0 end
  if i > #str then i = #str end

    caret.i = i
    local penx, peny = text:getbaseline()
    local a = font:measureadvance(str, 0, i)
    local b = 2 --math.max(font:measureadvance(str, i+1, i+1), 2)
    caret:move(penx + a, 0, b, text.h)

    local selection = text.selection

    selection.pivot = false
    selection.x = false
    selection.y = false
    selection.w = false
    selection.h = false
  
  text:refresh()
  return self:showcaret():select(false)
end

function metatable:showcaret()
  local text = self[_text]
  local caret = self[_caret]
  local left = self[_padl]
  local right = self.w - self[_padr]
  local caretleft = cel.translate(text, caret.x, caret.y, self)
  local caretright = caretleft + caret.w

  if caret.i == 0 then
    text:move(math.huge)
  elseif caretleft < left then
    text:move(-caret.l + left)
  elseif caretright > right then        
    text:move(-caret.r + right)
  end 

  return self
end

function metatable:dragcaret(i)
  local text = self[_text]
  local caret = self[_caret]
  local str = text:gettext()
  local font = text:getfont()
  local selection = text.selection

  local pivot = selection.pivot or caret.i 

  self:movecaret(i)

  selection.pivot = pivot 
    
  local len = caret.i-pivot

  if len > 0 then
    self:select(selection.pivot+1, caret.i)
  elseif len < 0 then
    self:select(caret.i+1, selection.pivot)
  else
    --select none
  end
end

function metatable:select(i, j)
  local selection = self[_text].selection
  local text = self[_text]  
  local str = text:gettext()
  local font = text:getfont()
  local penx = text:getbaseline()

  j = j or i
  selection.i = i
  selection.j = j

  if i then
    selection.x = penx + font:measureadvance(str, 0, i-1)
    selection.y = 0
    selection.w = font:measureadvance(str, i, j)
    selection.h = text.h 
  else
    selection.pivot = false
    selection.x = false
    selection.y = false
    selection.w = false
    selection.h = false
  end

  text:refresh()

  return self
end

function metatable:dragcaretby(n)
  return self:dragcaret(n + (self[_caret].i or 0))
end

function metatable:movecaretby(n)
  return self:movecaret(n + (self[_caret].i or 0))
end

function metatable:getcaret()
  if self[_caret] then
    return self[_caret].i
  end
end

function metatable:getselection()
  local selection = self[_text].selection
  return selection.i, selection.j
end

function metatable:deleteselection()
  local selection = self[_text].selection
  local i, j = selection.i, selection.j
  self:select(false)
  return self:delete(i, j)
end

function metatable:delete(i, j)
  if not i then return self end

  local text = self[_text]
  local str = text:gettext()
  j = j or i
  
  if i > 0 then
    str = str:sub(0, i-1) .. str:sub(j+1, -1)
    text:settext(str)
  end
  return self
end

function metacel:onchar(editbox, char, intercepted)
  if intercepted then return end
  local text = editbox[_text]
  local i = editbox[_caret].i
  editbox:deleteselection()
  local str = text:gettext()
  editbox:settext(str:sub(0, i) .. char .. str:sub(i+1, -1))
  editbox:movecaret(i+1)
  return true
end

function metacel:onkeypress(editbox, key, intercepted)
  if intercepted then return end

  local keys = cel.keyboard.keys
  local caret = editbox[_caret]
  local selection = editbox[_text].selection
  local movecaret = keyboard:isdown(keys.shift) and editbox.dragcaret or editbox.movecaret

  if key == keys.left then
    movecaret(editbox, caret.i-1)
    return true
  elseif key == keys.right then
    movecaret(editbox, caret.i+1)
    return true
  elseif key == keys.home then
    movecaret(editbox, 0)
    return true
  elseif key == keys['end'] then
    movecaret(editbox, math.huge)
    return true
  elseif key == keys.backspace then
    if editbox:getselection() then
      local i = selection.i
      editbox:deleteselection()
      editbox:movecaret(i-1)
    else
      editbox:delete(caret.i)
      editbox:movecaretby(-1)
    end
    return true
  elseif key == keys.delete then
    if editbox:getselection() then
      editbox:deleteselection()
    else
      editbox:delete(caret.i+1)
    end
    editbox:movecaret(caret.i)
    return true
  end
end

function metacel:onmousemove(editbox, x, y)
  local text = editbox[_text]

  if editbox:hasmousetrapped() and mouse:isdown(mouse.buttons.left) then
    x = x - text.x --translate x to text
    local penx = text:getbaseline()
    local caretindex = text:getfont():pick(x-penx, text:gettext())
    editbox:dragcaret(caretindex)
  end
end

function metacel:onmouseup(editbox, button, x, y, intercepted)
  local text = editbox[_text]
  if button == cel.mouse.buttons.left then
    editbox:freemouse()
  end
end

function metacel:onmousedown(editbox, button, x, y, intercepted)
  if intercepted then return end

  local text = editbox[_text]

  if button == cel.mouse.buttons.left then
    x = x - text.x --translate x to text

    editbox:trapmouse()
    editbox:takefocus()
    local penx = text:getbaseline()
    local caretindex = text:getfont():pick(x-penx, text:gettext())

    if keyboard:isdown(keyboard.keys.shift) then
      editbox:dragcaret(caretindex)
    else
      editbox:movecaret(caretindex)
    end
    return true
  end
end

function metacel:onmouseup(editbox, button, x, y, intercepted)
  if intercepted then return end
  editbox:freemouse()
  return true
end

function metacel:oncommand(editbox, command, data,  intercepted)
end

--TODO document that the font of a cel should always check the 
--description for the font used
do
  local function linker(hw, hh, x, y, w, h, xval, yval)
    if x > xval then x = xval end
    return x, yval, w, h
  end

  local _new = metacel.new
  function metacel:new(str, w, face)
    face = self:getface(face)
    local layout = face.layout or layout

    --TODO somehow make a font useable as an alias for a face thats name is the font
    local text = self['.text']:new(str, layout.text.face)
    local font = text:getfont() 

    --TODO set editbox font to text:getfont()

    local h = 2 + text.h --padt + padb + h

    local editbox = _new(self, w, h, face, nil, nil, h, h)
    text.editbox = editbox
    text.selection = {i=false, j=false}
    editbox[_text] = text
    editbox[_caret] = cel.new(2, text.h, '@caret'):link(text)
    editbox[_caret].i = 0
    editbox[_font] = font
    editbox[_padl] = 1
    editbox[_padt] = 1
    editbox[_padr] = 1
    editbox[_padb] = 1

    text:link(editbox, linker, editbox[_padl], editbox[_padt]):move(editbox[_padl], editbox[_padt])
    return editbox
  end

  local _compile = metacel.compile
  function metacel:construct(t, editbox)
    return _compile(self, t, editbox or metacel:new(t.text, t.w, t.face))
  end
end

return metacel:newfactory()