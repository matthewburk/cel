namespace 'celdocs'

export[...] {
  functiondef['cel.textbutton.new'] {
    description = [[Creates a new textbutton.]];

    synopsis = [==[
      cel.textbutton.new(text, [, face])
      cel.textbutton.new(text, [, facename])
    ]==];

    params = {
      param.string[[text - The text to display.]];
      param.face[[face - The face. 
        If not a valid face for the 'textbutton' metacel then the metacel
        face is used.]];
      param.any[[facename - The name of a textbutton face.  
        If the facename does not refer to a valid face then the metacel
        face is used.]];
    };

    returns = {
      param.textbutton[[textbutton - A new textbutton]];
    };
  };

  examples {
    [==[
    local cel = require('cel')

    local tb = cel.textbutton.new('Hello World')

    tb:link(root, 'center')
    ]==];
  };


}
