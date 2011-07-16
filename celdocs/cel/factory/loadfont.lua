namespace 'celdocs'

export[...] {
  functiondef['cel.loadfont'] {
    description = [[Asks the driver for a font by name and size.]];

    synopsis = [==[
      cel.loadfont(name, size)
    ]==];

    params = {
      param.any[[name - the name of the font, the driver will interpret the name.]];
      param.number[[size - the size of the font.]];
    };

    returns = {
      param.font[[font - a new or existing font.]];
    };

    notes = {
      [[TODO: define the font interface]];
      [[The driver may choose to not honor the requested name or size]];
    };
  };
}

