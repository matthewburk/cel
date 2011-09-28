local cel = require 'cel'

return function(_ENV)
  setfenv(1, _ENV)

  local scroll = cel.getface('scroll')
  scroll.textcolor = false
  scroll.fillcolor = false
  scroll.linecolor = false
  scroll.linewidth = false

  scroll.flow = {
    scroll = cel.flows.linear(100);
    showybar = cel.flows.linear(500);
    hideybar = cel.flows.linear(100);
    showxbar = cel.flows.linear(500);
    hidexbar = cel.flows.linear(100);
  }

  local size = 20
  scroll.layout = {
    stepsize = 20,
    ybar = {
      align = 'right',
      size = size, 
      track = {
        size = size,
        link = {'edges', nil, size},
        slider = {
          minsize = 20,
          size = size,
        };
      },
      decbutton = {
        size = size,
        link = {'width.top'},
      },
      incbutton = {
        size = size,
        link = {'width.bottom'},
      },
    },
    xbar = {
      align = 'bottom',
      size = size,
      track = {
        size = size,
        link = {'edges', size, nil},
        slider = {
          minsize = 10,
          size = size,
        },
      },
      decbutton = {
        size = size,
        link = {'left.height'},
      },
      incbutton = {
        size = size,
        link = {'right.height'},
      },
    },
  }

  scroll.draw = function(f, t) return drawlinks(t) end

  --scrollbar
  local scrollbar = cel.getface('scroll.bar')
  scrollbar.fillcolor = cel.color.encodef(.4, .4, .4)

  --track
  local track = cel.getface('scroll.bar.track')
  track.select = false
  track.draw = scroll.draw

  --slider
  local slider = cel.getface('scroll.bar.slider')
  slider.fillcolor = cel.color.encodef(.2, .2, .2)
  slider.linecolor = cel.color.encodef(0, 1, 1)
  slider.accentcolor = cel.color.encodef(0, 1, 1)
  slider.select = false

  function slider.draw(f, t, size)
    local size = size or t.host.host.size

    clip(t.clip)

    if f.fillcolor then
      setcolor(f.fillcolor)
      fillrect(t.x, t.y, t.w, t.h, f.radius)
    end

    if f.linewidth and f.linecolor then
      setlinewidth(f.linewidth)
      setcolor(f.linecolor)
      strokerect(t.x, t.y, t.w, t.h, f.radius)
    end

    if f.accentcolor then
      setcolor(f.accentcolor)
      save()
      translate(t.x + t.w/2, t.y + t.h/2)
      scale(size, size)
      fillarc(0, 0, .1, 0, 2 * math.pi);
      restore()
    end

    return drawlinks(t)
  end

  --incbutton
  local incbutton = cel.getface 'scroll.bar.inc'
  incbutton.fillcolor = cel.color.encodef(.2, .2, .2)
  incbutton.linecolor = cel.color.encodef(0, 1, 1)
  incbutton.accentcolor = cel.color.encodef(0, 1, 1)
  incbutton.draw = function(f, t) return slider.draw(f, t, t.host.size) end

  do
    local face = incbutton
    face['%pressed'] = face:new {
      fillcolor = cel.color.encodef(.4, .4, .4),
      linecolor = cel.color.encodef(0, 1, 1),
    }

    face['%mousefocusin'] = face:new {
      fillcolor = cel.color.encodef(.4, .4, .4),
      linecolor = cel.color.encodef(0, 1, 1),
    }
    
    do
      local face = face['%mousefocusin']

      face['%pressed'] = face:new {
        textcolor = cel.color.encodef(.2, .2, .2),
        fillcolor = cel.color.encodef(0, .8, .8),
        linecolor = cel.color.encodef(0, 1, 1),
        linewidth = 2,
      }
    end
  end

  --decbutton
  local decbutton = cel.getface 'scroll.bar.dec'
  decbutton.fillcolor = cel.color.encodef(.2, .2, .2)
  decbutton.linecolor = cel.color.encodef(0, 1, 1)
  decbutton.accentcolor = cel.color.encodef(0, 1, 1)
  decbutton.draw = function(f, t) return slider.draw(f, t, t.host.size) end

  do
    local face = decbutton
    face['%pressed'] = face:new {
      fillcolor = cel.color.encodef(.4, .4, .4),
      linecolor = cel.color.encodef(0, 1, 1),
    }

    face['%mousefocusin'] = face:new {
      fillcolor = cel.color.encodef(.4, .4, .4),
      linecolor = cel.color.encodef(0, 1, 1),
    }
    
    do
      local face = face['%mousefocusin']

      face['%pressed'] = face:new {
        textcolor = cel.color.encodef(.2, .2, .2),
        fillcolor = cel.color.encodef(0, .8, .8),
        linecolor = cel.color.encodef(0, 1, 1),
        linewidth = 2,
      }
    end
  end
end


