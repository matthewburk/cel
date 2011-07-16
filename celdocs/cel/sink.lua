namespace 'celdocs'

export[...] {
  functiondef['cel:sink'] {
    description = [[Moves the cel to the back(bottom of the stack).  The default formation of a cel is a stack,
    its links have a z-order in which the front link is at the top of the stack and the back link is at the bottom.]];

    synopsis = [==[
      acel:sink()
    ]==];

    params = {
      param.cel[[self - self]];
    };

    returns = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[sink has no effect if the cel is already on bottom(the back) or is not linked.]];
    [[sink has no effect if the host does not have a stack formation for exmaple cel.sequence.* is not a stack.]];
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local a = cel.grip.new(100, 100, cel.color.rgb(233, 133, 133))
    local b = cel.grip.new(100, 100, cel.color.rgb(133, 233, 133))
    local c = cel.grip.new(100, 100, cel.color.rgb(133, 133, 233))

    a:grip(a) b:grip(b) c:grip(c)

    a.ongrab = a.raise
    b.ongrab = b.raise
    c.ongrab = c.raise

    a.onrelease = a.sink
    b.onrelease = b.sink
    c.onrelease = c.sink

    a:link(host, 10, 10)
    b:link(host, 20, 20)
    c:link(host, 30, 30)
    ]==],
  };
}
