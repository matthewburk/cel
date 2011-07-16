namespace 'celdocs'

export[...] {
  functiondef['cel:resize'] {
    description = [[Updates dimensions(w, h) of a cel.]];

    synopsis = [==[
      acel:resize(w[, h])
    ]==];

    params = {
      param.cel[[self - self]];
      param.number[[w - new width of self. Defaults to self.w if nil]];
      param.number[[h - new height of self. Defautls to self.h if nil]];
    };

    returns = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[resize(w, h) is a shortcut for move(nil, nil, w, h)]]; 
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133)):link(host)

    --resize cel 
    acel:resize(host.w, host.h)
    ]==];
  };
}
