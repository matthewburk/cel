namespace 'celdocs'

export[...] {
  functiondef['cel:move'] {
    description = [[Updates position(x, y) and dimensions(w, h) of a cel.]];

    synopsis = [==[
      acel:move(x[, y[, w[, h]]])
    ]==];

    params = {
      param.cel[[self - self]];
      param.number[[x - new x position of self relative to host. Defaults to self.x if nil]];
      param.number[[y - new y position of self relative to host. Defaults to self.y if nil]];
      param.number[[w - new width of self. Defaults to self.w if nil]];
      param.number[[h - new height of self. Defautls to self.h if nil]];
    };

    returns = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[A cel's position and dimension cannot be modified directly.  For example acel.x = 10 will not update the x 
      position of acel (acel.x will return 10 but acel:pget('x') will return acels true x position)]];
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133)):link(host)

    --update cel position
    acel:move(10, 10)
    ]==];

    [==[
    local cel = require 'cel'
    local host = ...

    local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133)):link(host)

    --update cel dimensions 
    acel:move(nil, nil, host.w, host.h)
    ]==];
  };
}
