local cel = require 'cel'

return function(root)
  local cels = {}

  local app = cel.newnamespace {
    new = function(metacel, ...)
      if metacel ~= 'cel' then
        return cel[metacel].new(...)
      else
        return cel.new(...)
      end
    end,

    compile = function(metacel, t)
      if metacel ~= 'cel' then
        local ret = cel[metacel](t)
        if t.__name then cels[t.__name] = ret end
        return ret
      else
        return cel(t)
      end
    end,
  }

  function app.find(name)
    return cels[name]
  end

  root {
    link = {nil, 20, 20};
    app.window {
      w = 200, 
      h = 400, 
      title = 'A simple listbox';

      function(window)
        window:adddefaultcontrols()
      end,

      link = 'edges',
      app.listbox {
        function(lb)
          for i = 1, 20 do
            local button = app.textbutton.new('button in a listbox'):link(lb, 'width')
            button.onclick = button.unlink
          end
        end
      },
    },
  }

  root {
    link = {nil, 40, 40};
    cel.window {
      w = 200, h = 400, title = 'A simple listbox';

      function(window)
        window:adddefaultcontrols()
      end,

      link = 'edges';
      app.row {
            link = 'edges';
        {
          app.col {
            function(col)
              local button = app.textbutton.new('remove'):link(col, 'width')
              function button:onclick()
                local lb = app.find 'basic listbox'
                
                for item in lb:selecteditems() do
                  print(item)
                  item:unlink()
                end
              end
            end
          }
        },
        { flex = 1,
          app.listbox {
            __name = 'basic listbox';

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
                lb:select(item)
              end
            end,
            onchange = print,
          },
        },
      },
    }
  }

end

