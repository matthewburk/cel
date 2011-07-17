local cel = require 'cel'
return function(root)

  --[[
cel.face {
  metacel = 'scroll',
  flow = {
    scroll = cel.flows.linear(200),
    --showybar = cel.flows.linear(300),
    --hideybar = cel.flows.linear(100),
    --showxbar = cel.flows.linear(100),
    --hidexbar = cel.flows.linear(100),
  },
}
--]]

cel.face {
  name = 'listbox@item',
  fillcolor = false,
  linecolor = false,
  hovercolor = false,
}

cel.face {
  name = '@divider',
  fillcolor = cel.color.rgb(255, 0, 255),
  linecolor = false,
}

cel.face {
  metacel = 'printbuffer',
  font = cel.loadfont('fixedsys', 12),
  linecolor = false,
  fillcolor = cel.color.rgb(255, 255, 255),
  textcolor = cel.color.rgb(0, 0, 0),
}

cel.face {
  metacel = 'window',
  fillcolor = false,  
}

local tut = {}

local newboard
do
  cel.face {
    metacel = 'board',
    color = cel.color.rgb(255, 255, 255),
  }

  local metacel, metatable = cel.newmetacel('board')

  function metatable.print(board, ...)
    return tut.printbuffer:print(...)
  end

  function metatable.clear(board)
    for link in pairs(board.links) do
      link:unlink()
    end
  end

  function metacel:onlink(board, link)
    board.links[link] = link 
  end

  function metacel:onunlink(board, link)
    board.links[link] = nil 
  end

  do
    local _new = metacel.new
    function metacel:new(w, h, face)
      local board = _new(self, w, h, face) 
      board.links = {}
      return board
    end
  end
  
  newboard = function()
    return metacel:new()
  end
end

if not cel.getlinker('w%.h% r.t') then
  cel.addlinker('w%.h% r.t', cel.composelinker('width%.height%', 'right.top'))
  cel.addlinker('w%.h% l.t', cel.composelinker('width%.height%', 'left.top'))
  cel.addlinker('@(w%.h% r.t) edges', cel.composevhost('w%.h% r.t', 'edges'))
  cel.addlinker('@(w%.h% l.t) edges', cel.composevhost('w%.h% l.t', 'edges'))
  cel.addlinker('@width.fillbottom% : edges', cel.composevhost('width.fillbottom%', 'edges'))
end



function tut:start()
  self.run = coroutine.create(self.run, self)
  self:resume()
end

function tut:resume()
  if self.run then
    local ok, msg = coroutine.resume(self.run, self)

    if not ok then
      error(msg)
    end

    if coroutine.status(self.run) == 'dead' then
      self.run = nil
    end
  end
end

function tut:pause()
  tut.board:print('1', 'we are not yeilding click again to go some more')
  coroutine.yield(true)
end

cel.face {
  metacel = 'label',
  name = '@comment',
  textcolor = cel.color.rgb(0, 100, 0),
  fillcolor = false,
  font = cel.loadfont('monospace:normal:italic', 10)
}

cel.face {
  metacel = 'label',
  name = '@code',
  textcolor = cel.color.rgb(.05, .05, .05),
  fillcolor = false,
  font = cel.loadfont('code', 14)
}

local function loadtut(tut, name)
  tut.window:settitle(name)
  local xval, yval, linker = tut.window.listbox:pget('xval', 'yval', 'linker')
  tut.window.listbox:unlink()
  tut.window.listbox = cel.listbox.new()
  tut.window.listbox:link(tut.window, linker, xval, yval)

  local listbox = tut.window.listbox

  do
    local firstpause = true
    local lines = {}
    local header = lines
    for line in io.lines('../../tutorial/' .. name .. '.lua') do

      if string.find(line, '--', 1, true) then
        lines[#lines + 1] = cel.label.new(line, '@comment')
      elseif string.find(line, ' pause()', 1, true) then
        if firstpause then
          firstpause = false
          iscode = false
        else
          local button = cel.textbutton.new('CONTINUE ...')
          lines[#lines + 1] = button

          function button:onclick()
            local i = listbox:indexof(self)
            self:unlink()
            listbox:selectall(true)
            local hbar = cel.new(2, 1, '@divider'):link(listbox, 'width')
            listbox:insertlist(button.lines)
            print('scrolling to ', hbar.y)
            listbox:scrollto(0, hbar.y)
            tut:resume()
          end

          button.lines = {}
          lines = button.lines
        end
      else
        lines[#lines + 1] = cel.label.new(line, '@code') 
        --print('created label for', line, string.byte(line), string.byte(''), lines[#lines])
      end
    end
    do
      local button = cel.textbutton.new('Next Tutorial')
      lines[#lines + 1] = button

      function button:onclick()
        tut:resume()
      end
    end

    listbox:insertlist(header)
  end

  require('tutorial/' .. name)(tut.board, tut.pause)
  tut.board:clear()
end

function tut:run()

  loadtut(self, 'tut_cel_intro')
  loadtut(self, 'tut_cel_linking_1')
  loadtut(self, 'tut_cel_linking_2')
  loadtut(self, 'tut_autolayout')
  loadtut(self, 'tut_autolayout2')
  --self:reset()
end


--function reactor.load()
  --[[
  --Resize the root cel to cover the whole window.  There is only one root cel and it is always accessible through the
  --cel module.
  --]]
  --cel.root:resize(reactor.graphics.getwidth(), reactor.graphics.getheight())
do
  tut.printbuffer = cel.printbuffer.new():link(root, '@(w%.h% l.t) edges', {{.5, .5; 0, 0}, nil; 1, 2})
  tut.board = newboard():link(root, '@(w%.h% r.t) edges', {{.5, .5; 0, 0}, nil; 1, 2})

  --[[
  cel.textbutton {
    text = 'print',
    onclick = function()
      cel.printdescription()
    end;
  }:link(tut.board)
  --]]

  cel.window {
    function(window)
      tut.window = window
      local button = cel.button {
        w = 24, h = 24,
        onclick = function()
          if window:getstate() == 'maximized' then
            window:restore()
          else
            window:maximize()
          end
        end
      }
      local listbox = cel.listbox.new()

      window:addcontrols(button, 'right')
      listbox:link(window, 'edges')

      tut.window.listbox = listbox
      tut.window.button = button
    end,
  }

  tut.window:link(root, '@width.fillbottom% : edges')

  --displaydocs.showdocs(celdocs.cels.cel)
  --tut.window:link(cel.root, cel.vhost('fillbottom.f', .5, nil, 'edges'))
  --
  --
  --
  --What i want to do
  --tot.window:link(cel.virtualhost(cel.root, xval, yval, 'fillbottom.f'), 'edges')

  tut:start()
end
end
