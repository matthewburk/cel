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
    cel.window.new(),
    cel.button {
      link='height',
      w=50, h=50,
      onclick = function()
        aslot:resize(math.random(1, 300))
      end
    },
    {link='height', aslot}, 
    { link='height';
      cel.window.new(),
      cel.window.new(),
    },
  }
    --]=]
  root {
    cel.window {
      w = 400, h = 400,
      cel.scroll {
        link = {'edges'},
        subject = {
          cel.sequence.y {
            cel.slot{seq},
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
        },
      }
    }
  }
end

