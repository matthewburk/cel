local cel = require 'cel'

return function(root)

  root {
    cel.col {
      function(self)
        self:resize(400, 400)
        self.debug = true
      end,
      cel.row {
        cel.button {
          w = 100, h = 100,
          cel.label.new'no linker';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'no linker';
        },
      },
      cel.row {
        link = 'top';
        cel.button {
          w = 100, h = 100,
          cel.label.new'top';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'top';
        },
      },
      cel.row {
        link = 'left';
        cel.button {
          w = 100, h = 100,
          cel.label.new'left';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'left';
        },
      },
      cel.row {
        link = 'right';
        cel.button {
          w = 100, h = 100,
          cel.label.new'right';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'right';
        },
      },
      cel.row {
        link = 'bottom';
        cel.button {
          w = 100, h = 100,
          cel.label.new'bottom';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'bottom';
        },
      },
      cel.window {
        link = 'edges';
        function(w) w:adddefaultcontrols() end;
        cel.row {
          link = 'center';
          cel.button {
            w = 100, h = 100,
            cel.label.new'center';
          },
          cel.button {
            w = 100, h = 100,
            cel.label.new'center';
          },
        },
      },
      cel.row {
        link = 'height';
        cel.button {
          w = 100, h = 100,
          cel.label.new'height';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'height';
        },
      },
      cel.row {
        link = 'width';
        cel.button {
          w = 100, h = 100,
          cel.label.new'width';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'width';
        },
      },
      cel.row {
        link = {'edges', -5, -5};
        cel.button {
          w = 100, h = 100,
          cel.label.new'edges';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'edges';
        },
      },
    },
  }

  root {
    link = { nil, 400};

    cel.row {
      function(self)
        self:resize(400, 400)
      end,
      cel.col {
        cel.button {
          w = 100, h = 100,
          cel.label.new'no linker';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'no linker';
        },
      },
      cel.col {
        link = 'top';
        cel.button {
          w = 100, h = 100,
          cel.label.new'top';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'top';
        },
      },
      cel.col {
        link = 'left';
        cel.button {
          w = 100, h = 100,
          cel.label.new'left';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'left';
        },
      },
      cel.col {
        link = 'right';
        cel.button {
          w = 100, h = 100,
          cel.label.new'right';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'right';
        },
      },
      cel.col {
        link = 'bottom';
        cel.button {
          w = 100, h = 100,
          cel.label.new'bottom';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'bottom';
        },
      },
      cel.window {
        link = 'edges';
        function(w) w:adddefaultcontrols() end;
        cel.col {
          link = 'center';
          cel.button {
            w = 100, h = 100,
            cel.label.new'center';
          },
          cel.button {
            w = 100, h = 100,
            cel.label.new'center';
          },
        },
      },
      cel.col {
        link = 'height';
        cel.button {
          w = 100, h = 100,
          cel.label.new'height';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'height';
        },
      },
      cel.col {
        link = 'width';
        cel.button {
          w = 100, h = 100,
          cel.label.new'width';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'width';
        },
      },
      cel.col {
        link = {'edges', -5, -5};
        cel.button {
          w = 100, h = 100,
          cel.label.new'edges';
        },
        cel.button {
          w = 100, h = 100,
          cel.label.new'edges';
        },
      },
    }
  }

end

