namespace 'celdocs'

export[...] {
  functiondef['cel.new'] {
    description = [[Creates a new cel.]];

    synopsis = [=[
      cel.new([w[, h[, face]]])
      cel.new([w[, h[, facename]]])
    ]=];

    params = {
      param.number[[w - Initial width of the cel. Default is 0.]];
      param.number[[h - Initial height of the cel. Default is 0.]];
      param.face[[face - The face of the cel. 
                         If or not a valid face for the 'cel' metacel then the metacel face is used.]];
      param.any[[facename - The name of a face for the 'cel' metacel.
                            If the facename does not refer to a valid face then the metacel face is used.]];
    };

    returns = {
      param.cel[[newcel - A new cel where x is 0, y is 0, w is math.floor(w), h is math.floor(h).]];
    };
  };

  examples {
    [=[
      local cel = require('cel')

      local acel = cel.new()
      local acel = cel.new(10, 10)
      local acel = cel.new(10, 10, cel.color.rgb(255, 0, 0))
    ]=];
  };
}
