local cel = require 'cel'

local metacel, metatable = cel.newmetacel('editbox') 
local textmetacel = cel.text.newmetacel('editbox.text')

metacel['.text'] = textmetacel

local _font = {} 
local _text = {} 
local _padl = {}
local _padr = {}
local _padt = {}
local _padb = {}
local _caret = {}
local _multiline = {}

local keyboard = cel.keyboard

local layout = {
  text =  {
    face = nil
  }
}

do
  --[[
  function metacel:onmousemove(text, x, y)
    local mouse = text.mouse

    if text:hasmousetrapped() and 1 == mouse:buttonstate(1) then
      local newcaretpos, newcaret = nearestpenx(text, x)
      text:movecaret(newcaret, 'select')
      text[_caret]:select(index, penx, peny)
    end
  end
  --]]

  local _settext = textmetacel.metatable.settext
  function textmetacel.metatable:settext(str)
    _settext(self, str)
    if not str or #str == 0 then
      local linepenx, linepeny = self:getbaseline(1)
      assert(linepenx)
      assert(linepeny)
      self[_caret].i = 1
      self[_caret].penx = linepenx
      self[_caret].peny = linepeny
      self[_caret].lineindex = 1
      self:refresh()
    end    
    --self[_caret] = nil
  end

  function textmetacel:onmouseup(text, button, x, y, intercepted)
    text:freemouse()
  end

  function textmetacel:onmousedown(text, state, button, x, y, intercepted)
    if intercepted then return end

    local buttons = cel.mouse.buttons

    if cel.match(button, buttons.left, buttons.right, buttons.middle) then
      text:trapmouse()
      text:takefocus()
      do 
        local lineindex = text:pickline(y)
        
        if lineindex then
          local i, j = text:getlinerange(lineindex)
          local linepenx, linepeny = text:getbaseline(lineindex)
          local caretindex, caretpenx = text:getfont():pickpen(text:gettext(), i, j, x-linepenx)

          text[_caret] = {
            i = caretindex,
            penx = caretpenx + linepenx,
            peny = linepeny,
            lineindex = lineindex,
          }
        end
      end
      return true
    end
  end

  local __describe = textmetacel.__describe
  function textmetacel:__describe(text, t)
    __describe(self, text, t)

    local caret = text[_caret]
    if caret and 1 == text:hasfocus() then
      t.caret = caret.i
      t.caretx = caret.penx
      t.carety = caret.peny
      t.caretline = caret.lineindex
    else
      t.caret = false
      t.caretx = 0
      t.carety = 0
      t.caretline = false
    end
  end
end

function metatable:settext(str)
  return self[_text]:settext(str)
end

function metatable:gettext()
  return self[_text]:gettext()
end

function metatable:isfull()
  return false
end

--metacel functions
function metacel:__describe(editbox, t)
  t.font = editbox[_font]
end

do
  local function movecaret(text, i)
    local caret = text[_caret]
    local str = text:gettext()
    local font = text:getfont()

    if i < 1 then i = 1 end
    if i > #str then i = #str + 1 end

    if caret.i ~= i then
      caret.i = i

      local penx, peny = text:getbaseline(1)

      if i > 1 then
        penx = penx + font:measureadvance(str, 1, i-1)
      end

      caret.penx = penx
      
      text:refresh()
    end

    return caret.i, caret.penx
  end

  function metatable:movecaret(i)
    local text = self[_text]
    local n = i - text[_caret].i
    local peni, penx = movecaret(text, i)

    local left = self[_padl]
    local right = self.w - self[_padr]

    --put penx in editbox space
    penx = penx + text.x

    --make caret visible
    if peni == 1 then
      text:move(math.huge)
    elseif n < 0 then
      if penx < left then
        local newpenx = (left+((right-left)*.33))
        text:moveby(math.abs(penx-newpenx))
      end
    elseif n > 0 then
      if penx > right then
        local newpenx = (left+((right-left)*.66))
        text:moveby(-math.abs(penx-newpenx))
      end
    end
  end
end

function metatable:movecaretby(n)
  local text = self[_text]
  return self:movecaret(n + text[_caret].i)
end

function metatable:getcaret()
  if self[_text][_caret] then
    return self[_text][_caret].i
  end
end

--deletes from string at index of caret
function metatable:delete()
  local text = self[_text]
  local str = text:gettext()
  local i = text[_caret].i
  
  str = str:sub(0, i-1) .. str:sub(i+1, -1)
  text:settext(str)
end

function metacel:onchar(editbox, char, intercepted)
  if intercepted then return end
  local text = editbox[_text]
  local i = text[_caret].i
  local str = text:gettext()
  text:settext(str:sub(0, i-1) .. char .. str:sub(i, -1))
  editbox:movecaret(i+1)
  return true
end

function metacel:onkeypress(editbox, key, intercepted)
  if intercepted then return end

  local keys = cel.keyboard.keys
  if key == keys.left then
    editbox:movecaretby(-1)
    return true
  elseif key == keys.right then
    editbox:movecaretby(1)
    return true
  elseif key == keys.home then
    editbox:movecaret(1)
    return true
  elseif key == keys['end'] then
    editbox:movecaret(#editbox[_text]:gettext() + 1)
    return true
  elseif key == keys.backspace then
    if editbox:getcaret() > 1 then
      editbox:movecaretby(-1)
      editbox:delete()
    end
    return true
  elseif key == keys.delete then
    editbox:delete()
    return true
  end
end

function metacel:onmousemove(editbox, x, y)
end

function metacel:onmousedown(editbox, state, button, x, y, intercepted)
  return true
end

function metacel:onfocus(editbox, focus)
end

function metacel:onmouseup(editbox, button, x, y, intercepted)
  if intercepted then return end
  editbox:freemouse()
  return true
end

function metacel:oncommand(editbox, command, data,  intercepted)
end

function metacel:__dump(editbox)
  editbox[_text]:dump()
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
    local font = face.font 
    local layout = face.layout or layout

      --TODO somehow make a font useable as an alias for a face thats name is the font
      local text = self['.text']:new(str, 'nowrap', layout.text.face or face.font)

      --TODO set editbox font to text:getfont()

      local h = 2 + text.h --padt + padb + h

      local editbox = _new(self, w, h, face, nil, nil, h, h)
      editbox[_text] = text
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
    return _compile(self, t, editbox or metacel:new(t.text, t.w, t.h, t.face))
  end
end

return metacel:newfactory()
--[[
local function synccaret(text, caret)
  if caret then
    local lines = text[_lines]
    --TODO tablex.bsearch
    for index, line in ipairs(lines) do
      if line.i > caret.i then
        break
      end
      caret.lineindex = index
      caret.peny = line.peny
    end
    local line = lines[caret.lineindex]
    --print(string.format('caret.i %d, line.i %d, line.j %d', caret.i, line.i, line.j))
    caret.penx = text[_font]:measureadvance(text[_str], line.i, caret.i - 1) + (text[_padl] or 0)
  end
end
--]]
