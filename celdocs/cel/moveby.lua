namespace 'celdocs'

export[...] {
  functiondef['cel:moveby'] {
    description = [[Updates position(x, y) and dimensions(w, h) of a cel relative to current values.]];

    synopsis = [==[
      acel:moveby(x[, y[, w[, h]]])
    ]==];

    params = {
      param.cel[[self - self]];
      param.number[[x - add to self.x. Defaults to 0 if nil.]];
      param.number[[y - add to self.y. Defaults to 0 if nil.]];
      param.number[[w - add to self.w. Defaults to 0 if nil.]];
      param.number[[h - add to self.h. Defaults to 0 if nil.]];
    };

    returns = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[moveby(rx, ry, rw, rh) is a shortcut for move(acel.x + rx, acel.y + ry, acel.w + rw, acel.h + rh)]];
    [[When doing a relative move, moveby is more effecient.]];
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133)):link(host)

    --update cel position
    acel:moveby(10, 10)
    acel:moveby(10, 10)
    ]==];

    [==[
    local cel = require 'cel'
    local host = ...

    local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133)):link(host)

    --grow cel 
    acel:moveby(nil, nil, 10, 10)

    --grow cel width
    acel:moveby(nil, nil, 20)
    ]==];
  };
}
