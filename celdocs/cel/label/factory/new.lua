namespace 'celdocs'

export[...] {
  functiondef['cel.label.new'] {
    description = [[Creates a new label.]];

    synopsis = [==[
      cel.label.new([text[, face]])
    ]==];

    params = {
      param.string[[text - The text that will be displayed in the label when it is rendered.]];
      param.face {
        name = 'face';
          description = [[The face of the label. If not a valid face for the 'label' metacel then the metacel
          face is used.]];
        tabledef {
          description = [[The follwing value from the face are used to create the label:]];
          key.font[[The font that will be used for the label.]];
          key.layout[[The layout definition for the label. If this is nil then cel.label.layout is used.]];
        };
      };
    };

    returns = {
      rparam.label {
        tabledef {
          description = [[A new label with the specified text and the follwing properties:]];
          key.x[[0]];
          key.y[[0]];
          key.w[[Determined by the font, layout, and text.]];
          key.h[[Determined by the font, layout, and text.]];
          key.minw[[same as w.]];
          key.maxw[[same as w.]];
          key.minh[[same as h.]];
          key.maxh[[same as h.]];
        };
      }
    };
  };

  examples {
    [==[
    local cel = require('cel')
    local host = ...

    cel.label.new('A simple label'):link(host, 'center')
    ]==];
  };
}
