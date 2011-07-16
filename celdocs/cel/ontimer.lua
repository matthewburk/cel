namespace 'celdocs'

export[...] {
  eventdef['cel:ontimer'] {
    description = [[Signaled when the value returned by cel.timer() is updated by the driver.]];

    synopsis = [==[
      cel:ontimer(value, source)
    ]==];

    params = {
      param.cel[[self - self]];
      param.number[[value - The value of cel.timer() when the event was signaled.]];
      param.inputdevice[[source - The inputdevice that is focused on the cel.]];
    };
  };

  notes {
    [[The cel will recieve the event if it had the focus of any inputdevice when the event was signaled.  The event
      is signaled for each inputdevice focused on the cel.]];
  };

  examples {
    [==[
    local cel = require('cel')
    local host = ...

    local list = cel.sequence.y.new(1):link(host, 'center')
    list:takefocus()

    local lastvalue = 0
    function list:ontimer(value, source)
      if source == cel.keyboard then

        if value < lastvalue + 500 then
          return
        end

        lastvalue = value
        cel.textbutton.new('timer = ' .. value):link(self, 'width')

        if list.h > host.h then
          list:remove(list:len())
          list.ontimer = nil
        end
      end
    end
    ]==];
  };
}
