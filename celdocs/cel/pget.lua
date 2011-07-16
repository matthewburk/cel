namespace 'celdocs'

export[...] {
  functiondef['cel:pget'] {
    description = [[property getter returns properties of a cel by name.]];

    synopsis = [==[
      acel:pget(...)
    ]==];

    params = {
      param.cel[[self - self]];
      param.string[['x' - acel.x]];
      param.string[['y' - acel.y]];
      param.string[['w' - acel.w]];
      param.string[['h' - acel.h]];
      param.string[['xval' - acel.xval]];
      param.string[['yval' - acel.yval]];
      param.string[['face' - acel.face]];
      param.string[['minw' - acel.minw]];
      param.string[['maxw' - acel.maxw]];
      param.string[['minh' - acel.minh]];
      param.string[['maxh' - acel.maxh]];
    };

    returns = {
      param.cel[[self - self]];
      param['...'][[... - the corresponding value for each property name passed in.]];
    };
  };

  notes {
    [[pget can be more efficient when you need to get mulitiple properties, but less effecient for 1.]];
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local document = cel.document.new()
    local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

    document:put(acel)
    document:write(string.format('x, y, w, h = %d, %d, %d, %d', acel:pget('x', 'y', 'w', 'h')))

    document:link(host, 'edges')
    ]==],
  };
}
