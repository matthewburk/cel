namespace 'celdocs'

export[...] {
  factorydef['cel.label'] {
    description = [[Creates labels.]];

    functions = {
      '__call',
      'new',
      'newmetacel',
      'newfactory',
    };

    entries = {
      key.layout {
        tabledef {
          description = 'internal label layout';
          key.fit[[The method used to measure text. See cel.text.pad()]];
          key.fitx[[The method used to measure text. See cel.text.pad()]];
          key.fity[[The method used to measure text. See cel.text.pad()]];
          key.padding {
              description = 'padding added to font measurements';
              key.l[[left padding of text.]];
              key.t[[top padding of text.]];
              key.r[[right padding of text, padding.l is used if this is nil.]];
              key.b[[bottom padding of text, padding.t is used if this is nil.]];
          };
        };
      };
    };
  };

  cel.window.new();
  cel.window.new();
  cel.window.new();

  celdef.label {
    metacel = 'label';
    factory = 'cel.label';

    description = [[Displays a string as a single line of non-interactive text.  A label is the simplest
      way to display text in a cel.]];

    functions = {
      'gettext';
      'settext';
      'printf';
    };

    events = {
      'onchange';
    };

    drawtable = {
      description = [[Additional entries.]];
      key.text[[string - The text to display.]];
      key.font[[font - The font to display the text in.]];
      key.penx[[number - The penx(baseline relative to the label) to use as the pen origin when drawing the text.]];
      key.peny[[number - The peny(baseline relative to the label) to use as the pen origin when drawing the text.]];
      key.textw[[number - The advance width of the text.]];
      key.texth[[number - The height of the text.]];
    };
  };

  notes {
    [[A labels dimensions are fixed (label.min == label.maxw and label.minh == label.maxh) based on its font, padding,
      and text.]];
  };
}

