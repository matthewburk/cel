namespace 'celdocs'

export[...] {
  functiondef['cel.button.new'] {
    description = [[Creates a new button.]];

    synopsis = [==[
      cel.button.new([w[, h[, face[, minw[, maxw[, minh[, maxh]]]]]]])
      cel.button.new([w[, h[, facename[, minw[, maxw[, minh[, maxh]]]]]]])
    ]==];

    params = {
      param.number[[w - Initial width of the button. Default is 0.]];
      param.number[[h - Initial height of the button. Default is 0.]];
      param.face[[face - The face of the button. 
        If not a valid face for the 'button' metacel then the metacel face is used.]];
      param.any[[facename - The name of a face for the 'button' metacel.  
        If the facename does not refer to a valid face then the metacel face is used.]];
    };

    returns = {
      --TODO what to do for type button is a factory and button is an instance
      param.button[[button - A new button where x is 0, y is 0, w is math.floor(w), h is math.floor(h).]];
    };
  };

  examples {
    [==[
    local cel = require('cel')

    local button = cel.button.new(40, 20)
    ]==];
  };
}
