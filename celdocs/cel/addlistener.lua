namespace 'celdocs'

export[...] {
  functiondef['cel:addlistener'] {
    description = [[Adds a listener for the specified event.]];

    synopsis = [==[
      acel:addlistener(event, listener)
    ]==];

    params = {
      param.cel[[self - self]];
      param.string[[event - the name of the event.]];
      param['function'][[listener - function to call when event happens.]];
    };

    returns = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[Any events that were queued before the listener is added will not be seen by the listener.]];
    [[There can be any number of listeners for an event, order of seeing the events is not
      specified between listeners.]];
    [[An event will be seen by the metacel and/or the cel event callback before the listener sees it.]];
    [[When creating a factory or metacel that needs to see events on other cels using a listener is the best choice,
      becuase the event callback function is for use by the creator of a cel (typically an application).]];
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local listbox = cel.listbox.new(host.w/2):link(host, 'edges', 5, 5) 

    function host:onmouseup(button, x, y, intercepted)
      listbox:insert('callback ' ..' '.. button ..' '.. x ..' '.. y ..' '.. tostring(intercepted))
    end

    host:addlistener('onmouseup', function()
      listbox:insert('listener 1')
      listbox:scrollto(nil, math.huge)
    end)
    host:addlistener('onmouseup', function()
      listbox:insert('listener 2')
      listbox:scrollto(nil, math.huge)
    end)
    ]==];
  };
}
