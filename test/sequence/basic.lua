local cel = require 'cel'

return function(root)

  --[[
  local win = cel.window.new(50, 50)
  win:setlimits(200, nil, win.minh, nil)
  local seq = cel.sequence.y {
    { link = 'width',
      win,
      cel.window.new(50, 50),
      cel.button {
        w=50, h=50,
        onclick = function()
          win:setlimits(math.random(1, 300))
          print('win.minw', win.minw)
        end
      },
      cel.button.new(50, 50),
    }
  }
  --]]
    ---[=[

    local aslot = cel.slot {
      --margin={l=20, t=20, r=20, b=20},
      link = 'height';
      { link = 'width'; minw=100,
        cel.text.new([[print( tostring(collectgarbage('count') / 1000))]]),
      },
    }
  local seq = cel.row {
    cel.window.new(200, 200),
    cel.button {
      link='height',
      w=50, h=50,
      onclick = function()
        aslot:resize(math.random(1, 300))
      end
    },
    {link='height', aslot}, 
      cel.window.new(),
      cel.window.new(),
  }

  print('chopped row w', seq.w)
  local slot2 = cel.slot{seq}

  print('slot2 w', slot2.w)

  local acol = cel.col {
            cel.button.new(600, 39),
            slot2,
            cel.slot{cel.textbutton.new('there should be a row of buttons below me')},
            cel.row{
              {link='top';cel.button.new(20, 20), minh=20},
              {link='height';cel.button.new(20, 20)},
              {link='height';cel.button.new(20, 20)},
              {link='height';cel.button.new(20, 20)},
              {link='height';cel.button.new(20, 20)},
            },
            cel.slot{cel.textbutton.new('there should be a row of buttons above me')},
          },

  print('slot2 w', slot2.w)
  print('acol w', acol.w)
  root {
    cel.window {
      w = 400, h = 400,
      cel.scroll {
        link = {'edges'},
        subject = {
          acol, 
        },
      }
    }
  }
  print('chopped row w', seq.w)
    --]=]
    --[[
  cel.window {
    w=400, h=400,
    cel.sequence.y {
      {link = 'width'; cel.slot{ {link = 'edges', cel.window.new(300, 100)} }},
      {link = 'width'; cel.slot{ {link = 'edges', cel.window.new(300, 100)} }},
      {link = 'width'; cel.slot{ {link = 'edges', cel.window.new(300, 100)} }},
      {link = 'width'; cel.slot{ {link = 'edges', cel.window.new(300, 100)} }},
      {link = 'width'; cel.slot{ {link = 'edges', cel.window.new(300, 100)} }},
    },
  }:link(root)
  --]]
end

