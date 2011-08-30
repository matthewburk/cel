local cel = require 'cel'

return function(root)

  local acol
  local aslot = cel.slot {
    --margin={l=20, t=20, r=20, b=20},
    { link = 'width'; minw=100,
      cel.text.new([[print( tostring(collectgarbage('count') / 1000))]]),
    },
  }

  local arow 
  arow = cel.row {
    { link='height'; cel.window.new(200, 200)},
    { link='width'; flex=1;
      cel.textbutton {
        text = 'clk';
        onclick = function()
          print('-----------------------')
          aslot:resize(math.random(1, 300))
          print('aslot.h', aslot.h, 'arow.h', arow.h, 'acol.h', acol.h)
          print('**************')
        end
      },
    },
    {link='height', aslot}, 
    cel.window.new(),
    cel.window.new(),
  }

  acol = cel.col {
    { link = 'width';
      arow,
    },
    --[[
    cel.slot{cel.textbutton.new('there should be a row of buttons below me')},
    cel.row{
      {link='top';cel.button.new(20, 20), minh=20},
      {link='height';cel.button.new(20, 20)},
      {link='height';cel.button.new(20, 20)},
      {link='height';cel.button.new(20, 20)},
      {link='height';cel.button.new(20, 20)},
    },
    cel.slot{cel.textbutton.new('there should be a row of buttons above me')},
    --]]
  }

  acol.debug = true

  root {
    cel.window {
      w = 400, h = 400,
      link = 'edges',
      cel.scroll {
        subject = {
          fillwidth = false,
          acol, 
        },
      }
    }
  }
end

