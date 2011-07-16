namespace 'celdocs'

export[...] {
  functiondef['cel:islinkedto'] {
    description = [[Returns a number if host is (a) host of the cel.]];

    synopsis = [==[
      acel:islinkedto(host)
    ]==];

    params = {
      param.cel[[host - the target host cel.]];
    };

    returns = {
      param.number[[difference - 1 indicates that host is (the) host of the cel, > 1 indicates that
        host is (a) host of the cel.  The difference represent how far up the tree the host the host 
        is relative to the cel.  nil if the cel is not linked to the host]];
    };
  };

  notes {
    [[TODO.]];
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local a = cel.new(100, 100, cel.color.rgb(233, 133, 133))
    local b = cel.new(100, 100, cel.color.rgb(133, 233, 133))
    local c = cel.new(100, 100, cel.color.rgb(133, 133, 233))
    local label = cel.label.new('nil')

    local function onmousemove(acel)
      if 1 == acel:hasfocus(cel.mouse) then
        label:settext(string.format('islinkedto host(%d) root(%d)', acel:islinkedto(host), acel:islinkedtoroot())) 
      end
    end

    a.onmousemove = onmousemove
    b.onmousemove = onmousemove
    c.onmousemove = onmousemove

    a:link(b:link(c:link(host, 'edges', 20, 20), 'edges', 40, 40), 'edges', 40, 40)
    label:link(host)
    ]==],
  };
}
