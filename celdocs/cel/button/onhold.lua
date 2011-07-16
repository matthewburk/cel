namespace 'celdocs'

export[...] {
  eventdef['button:onhold'] {
    trigger = [[The metabutton:ontimer event will fire this event as long as the button is pressed.]];

    description = [[Fired periodically when the button is held down.]];

    synopsis = [==[
      button:onhold()
    ]==];

    params = {
      param.button[[self - self]];
    };
  };

  notes {
    [[The interval between onhold events is defined in the button factory.]]
  };

  examples {
    [==[
    local cel = require('cel')
    local host = ...

    local listbox = cel.listbox.new():link(host, 'edges')
    local button = cel.button.new(100, 100):link(host, 'center')

    local function print(...)
      local t = {...}
      for i, v in ipairs(t) do
        t[i] = tostring(v)
      end
      listbox:insert(table.concat(t, ' '))
    end

    function button:onpress(mousebutton, x, y)
      print('press', self, mousebutton, x, y)
    end

    function button:onhold()
      print('hold', self, cel.timer())
      listbox:scrollto(nil, math.huge)
    end
    ]==];
  };
}
