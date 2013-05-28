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
metacel['.text'] = cel.text.newmetacel('editbox.text')

local _font = {} 
local _text = {} 
local _padl = {}
local _padr = {}
local _padt = {}
local _padb = {}
local _caret = {}
local _multiline = {}
local _selection = {}
local _nglyphs = {}


local keyboard = cel.keyboard
local mouse = cel.mouse

local layout = {
  textface = cel.getface('editbox.text')
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
  if str == nil or str == '' then
    self[_text]:settext(str)
    return self
  end

  if self.filter then
    str = self.filter(str)
  end

  if str then
    self[_text]:settext(str)
  end
  return self
end

function metatable:printf(format, ...)
  return self:settext(string.format(format, ...))
end

function metatable:gettext()
  return self[_text]:gettext()
end

function metatable:len()
  return self[_text]:len()
end

function metatable:isfull()
  return false
end

function metacel:__describe(editbox, t)
  t.font = editbox[_font]
end

--caret.i 0 is caret position before any text (on the left)
--caret.i 1 is after the first glyh
function metatable:movecaret(i)
  local text = self[_text]
  local caret = self[_caret]
  local str = text:gettext()
  local font = text:getfont()
  local len = text:len()

  if i < 0 then i = 0 end
  if i > len then i = len end

    caret.i = i
    local penx = text:getpenorigin()
    local a = font:measureadvance(str, 0, i)
    local b = 2
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
  local penx = text:getpenorigin()
  local caret = self[_caret]
  local left = self[_padl] + penx
  local right = self.w - self[_padr] - penx
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

--true selects all
--false selects none
function metatable:select(i, j)
  local selection = self[_text].selection
  local text = self[_text]  
  local str = text:gettext()
  local font = text:getfont()
  local penx = text:getpenorigin()

  if i == true then
    i = 1
    j = text:len()
  end

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

function metatable:getselectedtext()
  local selection = self[_text].selection
  if selection.i then
    local i, j = selection.i, selection.j
    
    local text = self[_text]
    local str = text:gettext()
    j = j or i
   
    if i > 0 and i <= text:len() then
      local len, nbytes = 0, 0
      local a, b

      for uchar in string.gmatch(str, '([%z\1-\127\194-\244][\128-\191]*)') do
        len=len+1
        if len == i then
          a = nbytes + 1 
        end

        nbytes=nbytes+#uchar

        if len == j then
          b = nbytes
          return str:sub(a, b) 
        end
      end
    end
  end
end

function metatable:deleteselection()
  local selection = self[_text].selection
  if selection.i then
    local i, j = selection.i, selection.j
    self:select(false)
    self:delete(i, j)
    self:movecaret(i-1)
  end
  return self
end

function metatable:delete(i, j)
  if not i then return self end

  local text = self[_text]
  local str = text:gettext()
  j = j or i
 
  if i > 0 and i <= text:len() then
    local len, nbytes = 0, 0
    local leftpart = ''
    local rightpart = ''

    for uchar in string.gmatch(str, '([%z\1-\127\194-\244][\128-\191]*)') do
      len=len+1
      nbytes=nbytes+#uchar
      if len == i then
        leftpart=str:sub(1, nbytes-#uchar)
      end
      if len == j then
        rightpart=str:sub(nbytes+1, -1)
        break
      end
    end

    self:settext(leftpart..rightpart)
  end
  return self
end

function metatable:insert(newstr)
  self:deleteselection()
  local text = self[_text]
  local i = self[_caret].i
  local str = text:gettext()
  local len, nbytes = 0, 0
  local leftpart = ''
  local rightpart = ''

  if i == 0 then
    rightpart = str
  elseif i == text:len() then
    leftpart = str
  else
    for uchar in string.gmatch(str, '([%z\1-\127\194-\244][\128-\191]*)') do
      len=len+1
      nbytes=nbytes+#uchar
      if len == i then
        leftpart=str:sub(1, nbytes)
        rightpart=str:sub(nbytes+1, -1)
      end
    end
  end

  self:settext(leftpart .. newstr .. rightpart)

  do
    local newlen = 0
    for uchar in string.gmatch(newstr, '([%z\1-\127\194-\244][\128-\191]*)') do
      newlen = newlen+1
    end
    self:movecaretby(newlen)
  end
  return self
end

function metacel:onchar(editbox, char, intercepted)
  if intercepted then return end
  editbox:insert(char)
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
      editbox:movecaret(caret.i)
    end
    return true
  end
end

function metacel:onmousemove(editbox, x, y)
  local text = editbox[_text]

  if editbox:hasmousetrapped() and mouse:isdown(mouse.buttons.left) then
    x = x - text.x --translate x to text
    local penx = text:getpenorigin()
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

function metacel:onfocus(editbox)
  if not editbox:hasmousetrapped() then
    editbox:movecaret(math.huge)
    editbox:select(true)
  end
  editbox[_caret]:unhide()
end

function metacel:onblur(editbox)
  editbox:select(false)
  editbox[_caret]:hide()
end

function metacel:onmousedown(editbox, button, x, y, intercepted)
  if intercepted then return end

  local text = editbox[_text]

  if button == cel.mouse.buttons.left then
    x = x - text.x --translate x to text

    editbox:trapmouse()
    editbox:takefocus()
    local penx = text:getpenorigin()
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

function metacel:oncommand(editbox, command, data, intercepted)
  if intercepted then return end
  if command == 'copy' then
    local data = editbox:getselectedtext()
    if data then
      cel.clipboard('put', data)
    end
  elseif command == 'cut' then
    local data = editbox:getselectedtext()
    if data then
      cel.clipboard('put', data)
      editbox:deleteselection()
    end
  elseif command == 'paste' then
    local data = cel.clipboard('get')
    if data then
      editbox:insert(data)
    end
  end

  return editbox
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
    local text = self['.text']:new(str, layout.textface)
    local font = text:getfont() 

    --TODO set editbox font to text:getfont()

    local h = 2 + text.h --padt + padb + h

    local editbox = _new(self, w, h, face, nil, nil, h, h)
    text.editbox = editbox
    text.selection = {i=false, j=false}
    editbox[_text] = text
    editbox[_caret] = cel.new(2, text.h, '@caret'):link(text, (text:getpenorigin())):hide()
    editbox[_caret].i = 0
    editbox[_font] = font
    editbox[_padl] = 1
    editbox[_padt] = 1
    editbox[_padr] = 1
    editbox[_padb] = 1

    text:link(editbox, linker, editbox[_padl], editbox[_padt]):move(editbox[_padl], editbox[_padt])
    return editbox
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, editbox)
    editbox = editbox or metacel:new(t.text, t.w, t.face)

    editbox.filter = t.filter

    return _assemble(self, t, editbox)
  end
end

return metacel:newfactory {
  filters = {
    --needs improvement
    number = function(str)
      if str == '' or str == '-' or str == '.' then return str end
      local n = tonumber(str)
      if not n then
        return
      end
      if #tostring(n) ~= #str then
        return
      end
      return str
    end,
  }
}
