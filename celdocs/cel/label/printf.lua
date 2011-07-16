namespace 'celdocs'

export[...] {
  functiondef['label:printf'] {
    description = [[A shorcut for label:settext(string.format(format, ...)).]];

    synopsis = [=[
      label:printf(format[, ...])
    ]=];

    params = {
      param.label[[self - self]];
      param.string[[format - See lua documentation for string.format.]];
      param['...'][[varargs - See lua documentation for string.format.]];
    };

    returns = {
      rparam.label[[self]];
    };
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local label = cel.label.new(''):link(host, 'center')

    function host:onmousemove(x, y)
      label:printf('mousemoved  %d %d', x, y)
    end
    ]==];
  };
}
