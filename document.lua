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

local metacel, metatable = cel.slot.newmetacel('document')
metacel['.text'] = cel.text.newmetacel('document.text')
metacel['.divider'] = cel.newmetacel('document.divider')
metacel['.section'] = cel.slot.newmetacel('document.section')
metacel['.hyperlink'] = cel.textbutton.newmetacel('document.hyperlink')

local _font = {}
local _host = {}
local _facestack = {}
local _hoststack = {}
local _stack = {}
local _col = {}
local _facename = {} --TODO lame hack to use this, do another way
local _filename = {} --the name of the document



local function parseunit(s)
  if not s then
    return 0, 'px'
  end
  if type(s) == 'number' then
    return s, 'px'
  end
  local n, unit = s:match('(.+)(..)$')
  if 'px' == unit then
    return tonumber(n), unit
  elseif 'pt' == unit then
    return tonumber(n), unit
  elseif 'em' == unit then
    return tonumber(n), unit
  else
    return tonumber(s), 'px' 
  end
end

local function newtext(text, wrapmode, face)
  return metacel['.text']:new(text, wrapmode, face)
  --return cel.label.new(text)
end

local function getcurrentface(document)
  local facestack = document[_facestack]
  return facestack[#facestack]
end

local function getface(document)
  return getcurrentface(document)
end

local function getfont(document)
  return cel.getface('document.text', face).font
end

local function getpxvalue(document, value, unit)
  if unit == 'px' then
    return value
  elseif unit == 'em' then
    assert(getface(document))
    return value * getface(document).font:measure('m')
  elseif unit == 'pt' then
    return value --TODO do conversion
  end
end

function metatable.pushface(document, face)
  face = cel.getface('document.text', face)
  assert(face)
  local facestack = document[_facestack]
  facestack[#facestack + 1] = face
  return document
end

function metatable.popface(document)
  local facestack = document[_facestack]
  facestack[#facestack] = nil 
  return document
end

--TODO this must go into the document.text cel
function metatable.append(document, acel)

end

--TODO this must go into the document.text cel
function metatable.appendtext(document, s)
end


local function pushhost(document, host)
  if not document[_hoststack] then
    document[_hoststack] = {document[_host]}
  else
    local stack = document[_hoststack]
    stack[#stack + 1] = document[_host]
  end
  document[_host] = host
end

local function pophost(document)
  local old = document[_host]
  local stack = document[_hoststack]
  document[_host] = stack[#stack]
  stack[#stack] = nil
  return old
end

local function push(document, acel, linker, xval, yval)
  print('option',  document[_host].option and document[_host].option.flex)
  if not acel then
    acel = cel.col.new()
    acel:link(document[_host], linker, xval, yval, document[_host].option)
    --acel:beginflux()
  else
    acel:link(document[_host], linker, xval, yval, document[_host].option)
  end
  pushhost(document, acel)
  return document
end

local function pop(document, n)
  n = n or 1
  for i = 1, n do
    local old = pophost(document)
    --if old.endflux then old:endflux() end
  end
  return document
end

do --metatable.pushsection
  local metacel = metacel['.section']

  function metatable.pushsection(document, t)
    local m = getpxvalue(document, parseunit(t.margin))
    local left = getpxvalue(document, parseunit(t.leftmargin or m))
    local right = getpxvalue(document, parseunit(t.rightmargin or left))
    local top = getpxvalue(document, parseunit(t.topmargin or m))
    local bottom = getpxvalue(document, parseunit(t.bottommargin or top))
    local face = t.face
    local link = t.link 
    local w = parseunit(t.w)
    local h = parseunit(t.h)

    local section = metacel:new(left, top, right, bottom, nil, nil, face)
    print('pushing section')
    push(document, section, link or 'fill')
    print('pushed section')
    push(document, nil, 'fill')
    section:resize(w, h)
    return document
  end

  function metatable.popsection(document)
    return pop(document, 2)
  end
end


do
  local metacel = metacel['.divider']
  function metatable.putdivider(document, face)
    return document:put(metacel:new(1, 1, face), 'width')
  end
end

do
  local option = {flex=1, minw=0}
  local newrow = cel.row.new
  function metatable.pushrow(document, face, linker, xval, yval)
    local row = newrow(nil, face)
    --row:beginflux()
    row.option = option
    linker = linker or 'fill'
    return push(document, row, 'fill.margin', xval, yval)
  end

  function metatable.poprow(document)
    return pop(document)
  end
end

function metatable.newline(document)
  local font = getfont(document)
  return document:put(cel.new(font:height(), font:height()))
end

--format 'nowrap'
function metatable.write(document, s, mode)
  if 'nowrap' == mode then
    local text = newtext(s, mode, getface(document))
    text:link(document[_host], nil, nil, nil, document[_host].option)
  else
    local text = newtext(s, mode, getface(document))
    text:link(document[_host], 'width', nil, nil, document[_host].option)
  end
  return document
end

function metatable.put(document, acel, linker, xval, yval)
  ---[[
  if acel.getfontorigin then
    local penx, peny = acel:getfontorigin()
    
  end
  --]]
  acel:link(document[_host], linker or 'fill', xval, yval, document[_host].option)
  return document
end

do
  local function onclick(hyperlink)
    local document = hyperlink.document
    if document.onhyperlinkevent then
      document:onhyperlinkevent(hyperlink.target, 'click')
    end
  end

  function metatable.puthyperlink(document, text, target)
    if target:sub(1, 1) == '.' then
      target = document[_filename] .. target
    end

                
    local acel = cel.document.hyperlink.new(text, target)
    acel.document = document
    --TODO make these listeners
    acel.onclick = onclick
    document:put(acel)
  end
end

metatable.get = nil

function metacel:__link(document, link, ...)
  local col = document[_col]
  if col then
    return col, ...
  else
    return document, ...
  end  
end

function metatable.open(doc)
  --doc[_col]:beginflux()
  return doc
end

function metatable.close(doc)
  --doc[_col]:endflux()
  return doc
end

do
  local _new = metacel.new
  function metacel:new(face)
    face = self:getface(face)
    local col = cel.col.new()
    local document = _new(self, 0, 0, 0, 0, nil, nil, face)
    col:link(document, 'fill')
    document[_col] = col
    document[_host] = col
    document[_facestack] = {cel.getface('document.text')}
    return document
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, doc)
    doc = doc or t.self or metacel:new(t.face)
    return _assemble(self, t, doc)
  end
end

local document = metacel:newfactory()

--[[
document.face = setmetatable({}, {__index = function(face, k)
  return function(t)
    t.metacels = nil
    t.names = nil
    t.metacel = 'document.text' 
    t.name = k
    face[k] = cel.face(t)
    face[k][_facename] = k
    return face[k]
  end
end;
})
--]]

function document.newtag(f)
  return setmetatable({}, 
  {
    __index = function(param, name)
      param[name] = function(...)
        return f(name, ...)
      end
      return param[name]
    end;

    __call = function(param, ...)
      return f(nil, ...)
    end;
  })
end

do --hyperlink
  local metacel = metacel['.hyperlink']

  local _new = metacel.new
  function metacel:new(text, target, face)
    face = self:getface(face)
    local hyperlink = _new(self, text, face)
    hyperlink.target = target
    return hyperlink 
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, hyperlink)
    return _assemble(self, t, hyperlink or metacel:new(t.text, t.target, t.face))
  end

  document.hyperlink = metacel:newfactory() 

  --[[
  hyperlink.face = cel.face {
    metacel = 'textbutton',
    name = '@hyperlink',
    font = cel.loadfont('Arial', 12),
    hovercolor = cel.color.rgb(0, 65, 255),
    textcolor = cel.color.rgb(0, 0, .3 * 255),
    layout = {
      padding = {
        l = 2,
        t = 1,
      },
    },
  }

  function hyperlink.face:draw(t)
    reactor.graphics.clipltrb(t.clip.l, t.clip.t, t.clip.r, t.clip.b)

    if t.mousefocus then
      reactor.graphics.setcolor4b(self.hovercolor)
      t.font:print(t.x + t.penx, t.y + t.peny, t.text)
      reactor.graphics.fillrect(t.x + t.penx, t.y + t.peny + 2, t.textw, 1)
    else
      reactor.graphics.setcolor4b(self.textcolor)
      t.font:print(t.x + t.penx, t.y + t.peny, t.text)
    end
  end
  --]]

  
end

do --document.usenamesapce

  local _linebreak = {}
  local _hline = {}

  local function newelementfactory(call)
    local function __newindex(t, key, template)
      local mt = {__index = template, __call = call, __element = true}
      rawset(t, key, function(t)
        if type(t) == 'table' then
          return setmetatable(t, mt)
        else
          return setmetatable({t}, mt)
        end
      end)
    end

    local mt = {__call = call, __element = true}
    local function __call(self, t)
      if type(t) == 'table' then
        return setmetatable(t, mt)
      else
        return setmetatable({t}, mt)
      end
    end

    return setmetatable({}, {__newindex = __newindex; __call = __call})
  end

  local function iselement(t)
    local typeis = type(t)
    if typeis == 'string' then
      return 'string'
    elseif typeis == 'function' then
      return 'function'
    elseif typeis == 'table' then
      if cel.iscel(t) then 
        return 'cel' 
      end
      local mt = getmetatable(t)

      if mt and mt.__element then
        return 'element'
      end

      return 'table'
    end
  end

  local function callelement(element, D, elemtype)
    if not element then return end
    assert(D)
    elemtype = elemtype or iselement(element)
    if elemtype == 'string' then
      D:write(element:gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1'))
    elseif elemtype == 'table' then
      if element == _linebreak then
        D:newline()
      elseif element == _hline then
        D:putdivider()
      else
        for index, element in ipairs(element) do
          if element then
            callelement(element, D)
          end
        end
      end
    elseif elemtype == 'function' then
      callelement(element(), D) --TODO probably have to setfenv of elemtype before its called
    elseif elemtype == 'element' then
      element(D)
    elseif elemtype == 'cel' then
      D:put(element, element.linker, element.xval, element.yval)
    end  
  end

  local function mapelementsof(t, D, map)
    assert(D)
    for index, element in ipairs(t) do
      if element then
        local elemtype = iselement(element)
        map(t, element, index, elemtype, D)
      end
    end
  end

  local function callelementsof(t, D)
    assert(D)
    for index, element in ipairs(t) do
      if element then
        callelement(element, D)
      end
    end
  end

  local factory = {}

  do --factory.hyperlink 
    local function call(hyperlink, D)
      D:puthyperlink(hyperlink.text, hyperlink.target)
    end

    factory.hyperlink = call
  end

  do --factory.list
    local function map(list, element, index, elemtype, D)
      if list.template then
        callelement(list.template(list, element, index), D)
      else
        callelement(element, D, elemtype)
      end
    end

    local function call(list, D)
      mapelementsof(list, D, map)
      D:newline()
    end
    factory.list = call
  end

  do --factory.code
    local function map(code, element, index, elemtype, D)
      if elemtype == 'string' then
        local line = element:match('(.-)\r?\n')
        local spaces = #(line:match('^(%s+)') or '')
        local pattern = '\r?\n' .. string.rep(' ', spaces)
        element = element:gsub(pattern, '\n'):sub(1 + spaces)
        
        for line in element:gmatch('(.-)\n') do
          D:write(line, 'nowrap') --TODO need richtext option to break only on \n to make this way more effecient
        end
      else
        callelement(element, D, elemtype)
      end
    end

    local function call(code, D)
      D:pushface('@code') 
      mapelementsof(code, D, map) 
      D:popface(element)
    end
    factory.code = call
  end

  do --factory.paragraph
    local mws = function(s)
      return s:gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')
    end
    local function map(paragraph, element, index, elemtype, D)
      if elemtype == 'string' then
        D:write(mws(element))--D:newline() 
      else
        callelement(element, D, elemtype)
      end
    end

    local function call(paragraph, D)    
      mapelementsof(paragraph, D, map) 
      
    end
    factory.paragraph = call
  end

  do --factory.text
    local function map(text, element, index, elemtype, D)
      if elemtype == 'string' then
        D:write(element, 'nowrap')
      else
        callelement(element, D, elemtype)
      end
    end

    local function call(text, D)
      if text.face then
        D:pushface(text.face)
        mapelementsof(text, D, map)
        D:popface()
      else
        mapelementsof(text, D, map)
      end
    end

    factory.text = call
  end

  do--factory.section
    local function call(section, D)
      D:pushsection(section) 
      callelementsof(section, D) 
      D:popsection(section)
    end
    factory.section = call
  end

  do--factory.row
    local function call(row, D)
      D:pushrow()
      callelementsof(row, D)
      D:poprow()
    end
    factory.row = call
  end

  function document.newnamespace()
    local namespace = {
      linebreak = _linebreak,
      hline = _hline,
    }
    for k, v in pairs(factory) do
      namespace[k] = newelementfactory(v) 
    end

    return namespace
  end

  do --document.loadfile
    local _exports = {} 
    local export

    do 
      local mt = {}

      function mt.__index(t, key)
        local env = getfenv(2)
        env[_exports] = env[_exports] or {}
        return function(element)
          env[_exports][key] = element
        end        
      end

      export = setmetatable({}, mt)
    end

    local function loadfilein(_ENV, name)
      local f, err = _G._G.loadfile(name)
      if not f then
        error (string.format("error loading file `%s' (%s)", name, err))
      end
      return setfenv(f, _ENV)
    end

    local function importnamespace(namespace)
      local ns = cel.document.newnamespace()
      ns[namespace] = ns
      ns.documentname = documentname

      setmetatable(ns, {__index = _G})

      local chunk 
      --pcall( function()
        local t = loadfilein(ns, namespace)
        if t then
          t() 
        else
          error('file not found ['..namespace..']')
        end
      --end)

      local env = getfenv(2)
      for k, v in pairs(ns) do
        env[k] = v;
      end
    end

    

    function document.loadfile(filename)
      local env = setmetatable({
        export = export,
        namespace = importnamespace,        
      }, {__index = _G})

     
      local chunk 
      --pcall( function()
        local t = loadfilein(env, filename)
        if t then
          print('calling', filename)
          t(filename) 
        else
          error('file not found ['..filename..']')
        end
      --end)

      local name, element = next(env[_exports])

      print('FOUND export', name, element)
      print('FILENAME', filename)
      local doc = cel.document.new()
      doc[_filename] = filename
      doc:open()
      callelement(element, doc)
      doc:close()
      return doc
    end

    function document.loadelement(anelement)
      local doc = cel.document.new()
      doc[_filename] = [[~!@#$FROM ELEMENT///\\\//]]
      doc:open()
      callelement(anelement, doc)
      doc:close()
      return doc
    end
  end
end

return document
