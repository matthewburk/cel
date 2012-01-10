export['cel.label'] {
  [[Factory for the label metacel]];
  
  
  functiondef['cel.label(t)'] {
    [[Creates a new label]];

    code[=[
    cel.label {
      text = string,
      onchange(self) = function, --TODO implement this
    }
    ]=];

    params = {
      param.string[[text - text.]];
      param['function'][[onchange - event callback.]];
    };

    returns = {
      param.label[[a new label.]]
    };

    examples = {
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
  };

  functiondef['cel.label.new(text[, face])'] {
    [[Creates a new label.]];

    params = {
      param.string[[text - text.]];
      param.face[[face - face or face name. After resolving the face, the 
      label looks for a font at face.font(required) and a layout at 
      face.layout(optional).]];
    };

    returns = {
      param.label[[a new label.]];
    };
  };

  tabledef['cel.label.layout'] {
    key.padding[[A table defining how to layout space around the text.
    see font:pad() for definition.]];
  };

  celdef['label'] {
    [[A label is a cel for displaying a single line of text.]];
    [[A label in non-interactive and will never have mouse foucs. (label.touch = false)]];
    [[A label has a fixed size which is determined by its text and layout]];

    functiondef['label:getfont()'] {
      'Returns the font';
      returns = {
        param.font[[font used by the label]];
      };
    };

    functiondef['label:getbaseline()'] {
      [[Returns the pen origin]];
      
      returns = {
        param.integer[['x coordinate of pen origin to use when drawing the text]];
        param.integer[['y coordinate of pen origin to use when drawing the text]];
      };
    };

    functiondef['label:settext(text)'] {
      [[Changes the text displayed.]];

      params = {
        param.string[[text - text to display]];
      };

      returns = {
        param.label[[self]]
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local label = cel.label.new(''):link(host, 'center')

        function host:onmousemove(x, y)
          label:settext('mousemoved ' .. x ..' '.. y)
        end
        ]==];
      };
    };
    functiondef['label:gettext()'] {
      [[Gets the displayed text.]];

      returns = {
        param.string[[text]]
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local listbox = cel.listbox.new():link(host, 'edges')
        local label = cel.label.new('Hello'):link(listbox)

        function host:onmousemove(x, y)
          label:printf('%s %d %d', label:gettext(), x, y)
        end
        ]==];
      };
    };
    functiondef['label:printf(format, ...)'] {
      [[Changes the text displayed. Shortcut for
      label:settext(string.format(format, ...))]];

      params = {
        param.string[[format - format parameter for string.format]];
        param['...'][[... - additional parameters for string.format]];
      };

      returns = {
        param.label[[self]]
      };

      examples= {
        [==[
        local cel = require 'cel'
        local host = ...

        local label = cel.label.new(''):link(host, 'center')

        function host:onmousemove(x, y)
          label:printf('mousemoved  %d %d', x, y)
        end
        ]==];
      };
    };

    eventdef['label:onchange()'] {
      [[called when the label text is changed.]];
      synchronous = true;
    };
  };

  descriptiondef['label'] {
    code[=[
    {
      font = font,
      text = string,
      penx = integer,
      peny = integer,
      textw = integer,
      texth = integer,
    }
    ]=];

    params = {
      param.font[[font - font]];
      param.string[[text - text]];
      param.integer[[penx - pen origin to use when rendering text]];
      param.integer[[peny - pen origin to use when rendering text]];
      --TODO change to advancew or penadvance
      param.integer[[textw - width of text returned from font:measure(text)]];
      --TODO change to bbox of text, not font bbox
      param.integer[[texth - height of text to returned from 
                              font:measure(text)]];
    };
  };
}

