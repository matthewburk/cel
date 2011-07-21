namespace 'celdocs'

export[...] {
  [[A label is a cel for displaying a single line of text.  A label in non-interactive and will never have mouse foucs. (label.touch = false)]];
  [[A label has a fixed size which is determined by its text and layout]];
  
  factorydef['cel.label'] {
    functions = {
      functiondef['__call'] {
        [[Creates a new label.  This function is called by calling the
        cel.label factory.]];

        synopsis = [==[
          cel.label {
            text = string,
            onchange(self) = function, --TODO implement this
          }
        ]==];

        params = {
          param.string[[text - text.]];
          param['function'][[onchange - event callback.]];
        };

        returns = {
          param.label[[a new label.]]
        };
      };

      functiondef['new'] {
        [[Creates a new label.]];

        synopsis = [==[
          cel.label.new(text[, face])
        ]==];

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
    };

    key.layout {
      key.padding[[A table defining how to layout space around the text.
      see font:pad() for definition.]];
    };
  };

  celdef['label'] {
    functions = {
      functiondef['settext'] {
        [[Changes the text displayed.]];

        synopsis = [==[
          label:settext(text)
        ]==];

        params = {
          param.string[[text - text to display]];
        };

        returns = {
          param.label[[self]]
        };
      };
      functiondef['gettext'] {
        [[Gets the displayed text.]];

        synopsis = [==[
          label:gettext()
        ]==];

        returns = {
          param.string[[text]]
        };
      };
      functiondef['printf'] {
        [[Changes the text displayed. Shortcut for
        label:settext(string.format(format, ...))]];

        synopsis = [==[
          label:printf(format, ...)
        ]==];

        params = {
          param.string[[format - format parameter for string.format]];
          param['...'][[... - additional parameters for string.format]];
        };

        returns = {
          param.label[[self]]
        };
      };
    };

    events = {
      eventdef['onchange'] {
        [[called when the label text is changed.]]

        synopsis = [==[
          label:onchange()
        ]==];
      };
    };
  };

  descriptiondef['label'] {
    synopsis = [=[
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
      params.font[[font - font]];
      params.string[[text - text]];
      params.integer[[penx - pen origin to use when rendering text]];
      params.integer[[peny - pen origin to use when rendering text]];
      --TODO change to advancew or penadvance
      params.integer[[textw - width of text returned from font:measure(text)]];
      --TODO change to bbox of text, not font bbox
      params.integer[[texth - height of text to returned from 
                              font:measure(text)]];
    };
  };
}

