template['T.cel']
{
  protocel = 'button';

  metacel = 'textbutton';

  factory = 'cel.textbutton';

  description = [[ 
    A button with text.
  ]];

  functions = [[
    gettext
    settext
    printf
  ]];

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
}

