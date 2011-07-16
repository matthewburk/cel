namespace 'celdocs'

export[...] {
  functiondef['cel.label.__call'] {
    description = [[Creates a new label.  This function is called by calling the cel.label factory, see example.]];

    synopsis = [==[
      cel.label {
        text = string,
        face = any,
        [1,n] = cel or function or string
      }
    ]==];

    params = {
      param.table[[(table) - The table that is passed as the single argument to this function. 
        The other parameters documented here refer to the entries in this table.]];
      param.string[[text - passed as text param of factory.new if present.]];
      param.any[[face - passed as face param of factory.new if present.]];
      param['function'][[onchange - set as event callback if present.]];
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
    local cel = require 'cel'
    local host = ...

    local label = cel.label {
      w = 200, h = 200, --has no effect
      onmousedown = function() end; --will never be called because labels do not receive input
      text = '______OUTER LABEL';

      'inner'; --string will be converted to a label with the metalabel face and linked to outerlabel.
    }

    label:link(host, 'center')

    ]==]
  };
}
