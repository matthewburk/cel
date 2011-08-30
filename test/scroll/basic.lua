local cel = require 'cel'

return function(root)

  do
    local scroll = cel.scroll {
      subject = {
        cel.textbutton.new('some text for testing'):resize(300, 300) 
      },
    }

    local border = cel.row {
      { flex=1; link='edges';
        cel.textbutton.new('1'),
        cel.textbutton.new('2'),
        cel.textbutton.new('3'),
        cel.textbutton.new('4'),
      }
    }

    scroll:settopborder(border, 'edges', nil, nil, 'notsubject')

    root {
      cel.window {
        title = [[subject exists before border]];
        w = 400, h = 400,
        { link = 'edges'; scroll },
      }
    }
  end

  do
    local scroll = cel.scroll.new()

    local border = cel.row {
      { flex=1; link='edges';
        cel.textbutton.new('1'),
        cel.textbutton.new('2'),
        cel.textbutton.new('3'),
        cel.textbutton.new('4'),
      }
    }

    scroll:settopborder(border, 'edges', nil, nil, 'subject')
    scroll:settopborder(cel.window.new(100, 100, 'helllo'), nil, nil, nil, 'notsubject')
    scroll:setsubject(cel.textbutton.new('some text for testing'):resize(300, 300))

    root {
      cel.window {
        title = [[border exists before subject]];
        w = 400, h = 400,
        { link = 'edges'; scroll },
      }
    }
  end

  do
    local scroll = cel.scroll {
      subject = {
        cel.textbutton.new('some text for testing'):resize(800, 800) 
      },
    }

    local border = cel.row {
      { flex=1; link='edges';
        cel.textbutton.new('1'),
        cel.textbutton.new('2'),
        cel.textbutton.new('3'),
        cel.textbutton.new('4'),
      }
    }

    scroll:setbottomborder(border, 'edges', nil, nil, 'subject')
    scroll:settopborder(cel.row {
        { flex=1; link='edges';
          cel.textbutton.new('1'),
          cel.textbutton.new('2'),
          cel.textbutton.new('3'),
          cel.textbutton.new('4'),
        }
      }, 'edges', nil, nil, 'subject')


    scroll:setleftborder(cel.col {
        { flex=1; link='edges';
          cel.textbutton.new('1'),
          cel.textbutton.new('2'),
          cel.textbutton.new('3'),
          cel.textbutton.new('4'),
        }
      }, 'edges', nil, nil, 'subject')

    scroll:setrightborder(cel.col {
        { flex=1; link='edges';
          cel.textbutton.new('1'),
          cel.textbutton.new('2'),
          cel.textbutton.new('3'),
          cel.textbutton.new('4'),
        }
      }, 'edges', nil, nil, 'subject')

    root {
      cel.window {
        title = [[subject exists before bottom border]];
        w = 400, h = 400,
        { link = 'edges'; scroll },
        function(self)
          self:dump()
        end
      }
    }

    root:dump()

    scroll:dump()
  end
end

