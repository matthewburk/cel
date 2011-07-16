namespace 'celdocs'

export[...] {
  eventdef['button:onclick'] {
    trigger = [[The metabutton:onmouseup event will fire this event if button:ispressed() == true and
      cel.mouse:incel(button) == true.]];

    description = [[Fired when the button is clicked.]];

    synopsis = [==[
      button:onclick(mousebutton, x, y)
    ]==];

    params = {
      param.button[[self - self]];
      param.mousebutton[[button - The mouse button that was used.  A valid entry in mouse.buttons.]];
      param.number[[x - The x position of the mouse relative to the button when the event was created.]];
      param.number[[y - The y position of the mouse relative to the button when the event was created.]];
    };
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
      listbox:scrollto(nil, math.huge)
    end

    function button:onclick(mousebutton, x, y)
      print('click', self, mousebutton, x, y)
      listbox:scrollto(nil, math.huge)
    end
    ]==];
  };
}
