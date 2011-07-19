namespace 'celdocs'

export[...] {
  factorydef['cel.textbutton'] {

    functions = {
      '__call',
      'new',
      'newmetacel',
      'newfactory',
      'gettext',
      'settext',
      'printf',
    };

    entries = {
      key.layout {
        tabledef {
          description=[[textbutton layout table. The layout table controls how much space surrounds the text.]];
          key.padding[[padding options table, see font:pad(...)]];
        }
      }
    }

    --[=[
  drawtable = {
    --include description of button
    [[string text - The text to display.]];
    [[font font - The font to display the text in.]];
    [[number penx - The penx(baseline relative to the textbutton) to use as the pen origin when drawing the text.]];
    [[number peny - The peny(baseline relative to the textbutton) to use as the pen origin when drawing the text.]];
    [[number textw - The advance width of the text.]];
    [[number texth - The height of the text.]];
  };

  notes = {
    [[A textbutton could easily be made by linking a label to a button, but it is so common that a specialized slightly
      more efficient cel is worth having.]];
    [[A textbutton has a minimum width and height to ensure the text is always displayed in full, based on its font,
      padding, and text.]];
  };
  --]=]
  }
}

