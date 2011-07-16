namespace 'celdocs'

export[...] {
  eventdef['button:onpress'] {
    trigger = [[The metabutton:onmousedown event will fire this event if onmousedown has not intercepted.]];

    description = [[Fired when any mousebutton is pressed.]];

    synopsis = [==[
      button:onpress(mousebutton, x, y)
    ]==];

    params = {
      param.button[[self - self]];
      param.mosuebutton[[button - The mouse button that was used.  A valid entry in mouse.buttons.]];
      param.number[[x - The x position of the mouse relative to the cel when the event was created.]];
      param.number[[y - The y position of the mouse relative to the cel when the event was created.]];
    };
  };

  notes {
    [[An attempt will be made to trap the mouse before onpress is fired.]];
    [[The button is refreshed after onpress is fired.]];
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
    ]==];
  };
}
