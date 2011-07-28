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

    functiondef['label:settext(text)'] {
      [[Changes the text displayed.]];

      params = {
        param.string[[text - text to display]];
      };

      returns = {
        param.label[[self]]
      };
    };
    functiondef['label:gettext()'] {
      [[Gets the displayed text.]];

      returns = {
        param.string[[text]]
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

