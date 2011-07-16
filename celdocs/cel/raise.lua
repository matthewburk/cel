namespace 'celdocs'

export[...] {
  functiondef['cel:raise'] {
    description = [[Moves the cel to the front(top of the stack).  The default formation of a cel is a stack,
    its links have a z-order in which the front link is at the top of the stack and the back link is at the bottom.]];

    synopsis = [==[
      acel:raise()
    ]==];

    params = {
      param.cel[[self - self]];
    };

    returns = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[raise has no effect if the cel is already in front or is not linked.]];
    [[raise has no effect if the host does not have a stack formation for example cel.sequence.* is not a stack.]];
    [[When a cel is linked it is put in front(top of the stack), unless the host metacel
      changes that behavior via __link.  So acel:unlink():link(host) would put it at the
      top, but unlinking has side-effects such as losing focus, whereas raise does not.]];
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

    a:link(host, 10, 10)
    b:link(host, 20, 20)
    c:link(host, 30, 30)
    ]==],
  };
}
