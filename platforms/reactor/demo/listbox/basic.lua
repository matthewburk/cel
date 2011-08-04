local cel = require 'cel'

return function(root)

  local cels = {}

  root {
    cel.window {
      link = {nil, 20, 20};
      w = 200, 
      h = 400, 
      title = 'A simple listbox';

      function(window)
        window:adddefaultcontrols()
      end,

      cel.listbox {
        link = 'edges',
        function(lb)
          for i = 1, 20 do
            local button = cel.textbutton.new('button in a listbox'):link(lb, 'width')
            button.onclick = button.unlink
          end
        end
      },
    },
  }

  root {
    cel.window {
      link = {nil, 40, 40};
      w = 200, h = 400, title = 'A simple listbox';

      function(window)
        window:adddefaultcontrols()
      end,

      cel.row {
        link = 'edges';
        {
          cel.sequence.y {
            function(sequence)
              local button = cel.textbutton.new('remove'):link(sequence, 'width')
              function button:onclick()
                local lb = cels['basic listbox']
                
                for item in lb:items('selected') do
                  print(item)
                  item:unlink()
                end
              end
            end
          }
        },
        { weight = 1,
          cel.listbox {
            function(self) cels['basic listbox'] = self end;

            link = 'edges';
            'this',
            'is',
            'a',
            'listbox with text',
            'pretty',
            'basic',
            'stuff',
            onmousedown = function(lb, button, x, y, intercepted)
              if not intercepted then
                local item, index = lb:pick(x, y)
                lb:select(index)
              end
            end,
            onchange = print,
          },
        },
      },
    }
  }

end

