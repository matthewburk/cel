local cel = require 'cel'
local keyboard = cel.keyboard

local metacel, metatable = cel.newmetacel('editbox')

local _text = {} 
local _font = {} 
local _caret = {} 
local _caretpos = {} 
local _selection = {} 
local _selectionpos = {} 
local _penx = {} 
local _peny = {} 
local _textwidth = {} 
local _gapl = {} 
local _gapr = {} 
local _carettimestamp = {} 

local layout = {
  ['pad.h'] = 8,
  ['pad.%h'] = 20,    
  ['gap.l'] = 8,
  ['gap.r'] = 8,
}

local function advancepenx(font, text, textlen, currentpenindex, len, currentpenx)
  len = len or 1
  currentpenindex = currentpenindex or 1

  if len == 0 then
    len = 1
  end

  local maxindex = textlen + 1
  local newindex = currentpenindex + len

  if newindex < 1 then newindex = 1 end
  if newindex > maxindex then newindex = maxindex end

  len = newindex - currentpenindex

  if len == 0 then
    --TOOD should not return nil, return currentpenindex
    return currentpenx, nil
  end

  return currentpenx + font:measureadvance(text, currentpenindex, len), newindex 
end

local function setpenx(editbox, penx)
  local textwidth = editbox[_textwidth]
  local portalw = editbox.w - editbox[_gapl] - editbox[_gapr]
  local portall = editbox[_gapl]
  local portalr = portall + portalw

  if penx + textwidth < portalr then
    penx = -textwidth + portalr  
  end

  if penx > portall then 
    penx = portall
  end

  editbox[_penx] = penx 

  print('setpenx.textwidth = ', textwidth)
  print('setpenx.penx = ', penx)
end

local function calctextwidth(editbox)
  local font = editbox[_font]
  local text = editbox[_text]

  if not text then
    editbox[_textwidth] = 0
    return
  end

  editbox[_textwidth] = font:measureadvance(text)--math.max(font:measure(text), font:measureadvance(text))
end

local function updatecaret(editbox)
  editbox[_carettimestamp] = cel.timer()
  editbox:refresh()
end

local _setlimits = metatable.setlimits
function metatable.setlimits()
  return false
end

local function movecaretby(editbox, direction, mode, jumpw)
  jumpw = math.floor(jumpw or 0)

  updatecaret(editbox)

  if direction == 0 then
    if 'select' ~= mode and (editbox[_selection] ~= editbox[_caret]) then
      editbox[_selection] = editbox[_caret] 
      editbox[_selectionpos] = editbox[_caretpos] 
      editbox:refresh()
    end
    return false
  end

  local font = editbox[_font]
  local text = editbox[_text]
  local caret = editbox[_caret]
  local penx = editbox[_penx]
  local caretpos = editbox[_caretpos]
  local portalw = editbox.w - editbox[_gapl] - editbox[_gapr]
  local portall = editbox[_gapl]
  local portalr = portall + portalw

  print(editbox, 'caretpos, caret', caretpos, caret)
  local newcaretpos, newcaret = advancepenx(font, text, text:len(), caret, direction, caretpos)
  print(editbox, 'newcaretpos, newcaret', newcaretpos, newcaret)

  if not newcaret then
    return false
  end

  if direction < 0 then
    if newcaretpos - portall < -penx then 
      setpenx(editbox, -newcaretpos + portall + jumpw)
    end
  elseif direction > 0 then
    if newcaretpos > -penx + portalr then
      setpenx(editbox, -newcaretpos + portalr - jumpw)
    end
  end

  if 'select' ~= mode then
    editbox[_selection] = newcaret
    editbox[_selectionpos] = newcaretpos
  end

  editbox[_caret] = newcaret
  editbox[_caretpos] = newcaretpos

  editbox:refresh()

  return true
end

function metatable.select(editbox, a, b)
  editbox:movecaret(a)
  editbox:movecaret(b + 1, 'select')
end

function metatable.selectall(editbox)
  return editbox:select(1, editbox:gettext():len()) 
end

function metatable.movecaretby(editbox, direction, mode)
  return movecaretby(editbox, direction, mode)
end

function metatable.movecaret(editbox, newcaret, mode)
  return editbox:movecaretby(newcaret - editbox[_caret], mode)
end

local function leftsubstring(text, penindex)
  return string.sub(text, 1, penindex -1)
end

local function rightsubstring(text, penindex)
  return string.sub(text, penindex, -1)
end

function metatable.insert(editbox, s)
  local caret = editbox[_caret]
  local text = editbox[_text]
  local font = editbox[_font]
  local len = string.len(text)

  editbox[_text] = leftsubstring(text, caret) .. s .. rightsubstring(text, caret)

  calctextwidth(editbox)

  if editbox.onchange then
    editbox:onchange('text', editbox[_text])
  end

  editbox:refresh()
end

--deltees the selected text
function metatable.delete(editbox)
  local selection = editbox[_selection] - editbox[_caret]

  if selection == 0 then return end

  local text = editbox[_text]
  local len = text:len()

  if math.abs(selection) >= len then
    editbox:movecaret(1)
    editbox[_text] = ''
    calctextwidth(editbox)
    editbox[_selection] = editbox[_caret]
    editbox[_selectionpos] = editbox[_caretpos]
  else
    local left, right
    if selection > 0 then
      left = editbox[_caret]
      right = editbox[_selection]
    else
      left = editbox[_selection]
      right = editbox[_caret]
    end

    editbox:movecaret(left)
    editbox[_selection] = editbox[_caret]
    editbox[_selectionpos] = editbox[_caretpos]
    editbox[_text] = leftsubstring(text, left) .. rightsubstring(text, right)
    calctextwidth(editbox)
  end

  if editbox.onchange then
    editbox:onchange('text', editbox[_text])
  end

  editbox:refresh()
end

function metatable.settext(editbox, text)
  editbox:movecaret(1)
  editbox[_text] = text
  calctextwidth(editbox)
end

function metatable.getcaret(editbox)
  return editbox[_caret]
end

function metatable.isfull(editbox)
  return false
end

function metatable.getselection(editbox)
  if editbox[_caret] == editbox[_selection] then
    return
  elseif editbox[_caret] < editbox[_selection] then
    return editbox[_caret], editbox[_selection]
  else
    return editbox[_selection], editbox[_caret]
  end
end

function metatable.gettext(editbox)
  return editbox[_text]
end

function metatable.getselectedtext(editbox)
  local a, b = editbox:getselection()

  if a then
    return editbox[_text]:sub(a, b-1)
  end
end

--metacel functions

function metacel:__describe(editbox, t)
  local caret = editbox[_caret]
  local selection = editbox[_selection]
  local penx = editbox[_penx]

  t.font = editbox[_font]
  t.text = editbox[_text]
  t.penx = penx 
  t.peny = editbox[_peny]

  t.textbox = {
    x = penx,
    y = editbox._textboxy,
    w = editbox[_textwidth],
    h = editbox._textboxh,
  }

  if editbox:hasfocus() then
    t.caret = caret
    t.caretx = penx + editbox[_caretpos]
    t.carety = editbox[_peny]
  else
    t.caret = false
    t.caretx = 0
    t.carety = 0
  end

  t.carettimestamp = editbox[_carettimestamp]

  if caret < selection then
    t.selection = selection
    t.selectionbox = {
      x = penx + editbox[_caretpos],
      y = editbox._textboxy,
      w = editbox[_selectionpos] - editbox[_caretpos],
      h = editbox._textboxh,
    }

  elseif caret > selection then
    t.selection = selection
    t.selectionbox = {
      x = penx + editbox[_selectionpos],
      y = editbox._textboxy,
      w = editbox[_caretpos] - editbox[_selectionpos],
      h = editbox._textboxh,
    }
  else
    t.selection = false
  end
end

function metacel:onchar(editbox, char, intercepted)
  if intercepted then return end

  --TODO apply filter here

  editbox:delete()

  if not editbox:isfull() then
    editbox:insert(char)
    editbox:movecaretby(1)
    editbox:refresh()
  end

  return true
end

function metacel:onkeydown(editbox, state, key, intercepted)
  if intercepted then return end

  local keys = cel.keyboard.keys

  if key == keys.left then
    movecaretby(editbox, -1, keyboard:ispressed(keys.shift) and 'select', editbox.w * .3)
    return true
  elseif key == keys.right then
    movecaretby(editbox, 1, keyboard:ispressed(keys.shift) and 'select', editbox.w * .3)
    return true
  elseif key == keys.home then
    editbox:movecaret(1, keyboard:ispressed(keys.shift) and 'select')
    return true
  elseif key == keys['end'] then
    editbox:movecaret(editbox[_text]:len() + 1, keyboard:ispressed(keys.shift) and 'select')
    return true
  elseif key == keys.backspace then
    if editbox[_caret] == editbox[_selection] then
      movecaretby(editbox, -1, 'select', editbox.w * .3)
    end
    editbox:delete()
    return true
  elseif key == keys.delete then
    if editbox[_caret] == editbox[_selection] then
      editbox:movecaretby(1, 'select')
    end
    editbox:delete()
    return true
  end
end

local function nearestpenx(editbox, x)
  local font = editbox[_font]
  local text = editbox[_text]
  local x = -editbox[_penx] + x

  return font:pickpen(text, i, #text, x)
  --[[
  local npenx, npeni

  if x == caretpos then
    return caretpos, editbox[_caret]
  elseif x < caretpos then
    local penx, peni = caretpos, editbox[_caret]
    while true do
      npenx, npeni = cel.text.advancepenx(font, text, textlen, peni, -1, penx)

      if not npeni then return penx, peni end

      if npenx <= x then
        local a, b = x - npenx, penx - x
        if a < b then return npenx, npeni else return penx, peni end
      else
        penx, peni = npenx, npeni
      end
    end
  elseif x > caretpos then
    local penx, peni = caretpos, editbox[_caret]
    while true do
      npenx, npeni = cel.text.advancepenx(font, text, textlen, peni, 1, penx)

      if not npeni then return penx, peni end

      if npenx >= x then
        local a, b = npenx - x, x - penx
        if a < b then return npenx, npeni else return penx, peni end
      else
        penx, peni = npenx, npeni
      end
    end
  end
  --]]
end

function metacel:onmousemove(editbox, x, y)
  local mouse = editbox.mouse

  if editbox:hasmousetrapped() and 1 == mouse:ispressed(mouse.buttons.left) then
    local newcaretpos, newcaret = nearestpenx(editbox, x)
    editbox:movecaret(newcaret, 'select')
  end
end

function metacel:onmousedown(editbox, state, button, x, y, intercepted)
  if intercepted then return end

  editbox:trapmouse()
  editbox:takefocus()

  local newcaretpos, newcaret = nearestpenx(editbox, x)

  editbox:movecaret(newcaret)

  return true
end

function metacel:onmouseup(editbox, button, x, y, intercepted)
  if intercepted then return end
  editbox:freemouse()
  return true
end



function metacel:oncommand(editbox, command, data,  intercepted)
  if intercepted then return end

  print(command)

  if command == 'cut' then
    local text = editbox:getselectedtext()
    if text then
      editbox:delete()
      cel.clipboard('put', text)
    end
  elseif command == 'copy' then
    local text = editbox:getselectedtext()
    if text then
      cel.clipboard('put', text)
    end
  elseif command == 'paste' then
    local text = cel.clipboard('get')

    if type(text) == 'string'then
      editbox:delete()
      editbox:insert(text)
    end
  end
  return true
end

function metacel:onfocus(editbox)
  updatecaret(editbox)
end
do
  local floor = math.floor
  local _new = metacel.new
  function metacel:new(w, text, face)
    face = self:getface(face)
    local layout = face.layout or layout
    local font = face.font 
    local h = font:height()
    local hpad = h * ((layout['pad.%h'])/100) + layout['pad.h']

    h = h + hpad 

    local editbox = _new(self, w, h, face)

    editbox._textboxh = h - hpad
    
    editbox[_caret] = 1
    editbox[_selection] = 1
    editbox[_font] = font
    editbox[_text] = text or '' --TODO use nil instead of ''
    editbox[_peny] = h + font.bbox.ymin - floor(hpad/2)
    editbox._textboxy = editbox[_peny] - font.bbox.ymax
    editbox[_penx] = layout['gap.l']
    editbox[_gapl] = layout['gap.l']
    editbox[_gapr] = layout['gap.r']
    calctextwidth(editbox)
    editbox[_caretpos] = 0 
    editbox[_selectionpos] = 0 
    self:setlimits(editbox, nil, nil, h, h)

    return editbox
  end

  local _compile = metacel.compile
  function metacel:construct(t, editbox)
    return _compile(self, t, editbox or metacel:new(t.w, t.text, t.face))
  end
end

return metacel:newfactory()



