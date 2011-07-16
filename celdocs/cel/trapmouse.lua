namespace 'celdocs'

export[...] {
  functiondef['cel:trapmouse'] {
    description = [[Ensures all mouse events will be delivered to the cel, when the mouse is not trapped by a cel
                    it will get mouse events only if it has the mouse focus.]];

    synopsis = [==[
      acel:trapmouse([onescape])
    ]==];

    params = {
      param.cel[[self - self]];
      param['function'][[onescape - If present this function is called when the mouse is no longer trapped by the cel.  
                            onescape(cel, mouse, reason)
                            - cel is self
                            - mouse is cel.mouse
                            - reason is an explanatory string.]];
    };

    returns = {
      param.boolean[[hasmousetrapped - true if the cel has sucessfully trapped the mouse, false otherwise.
        If false then onexcape will be called with the reason prior to returning.]];
    };
  };

  notes {
    [[The root cel always traps the mouse.]];
    [[When a cel recives mouse events, they are delivered to its hosts. So the hosts of the cel effectively have the 
      mouse trapped as well.]];
    paragraph{ 'trapmouse will fail for the following reasons:';
      list {
        '- The cel does not have the focus of the mouse.';
        '- The mouse is already trapped by a cel that is linked to the cel.';
        '- The cel is unlinked from the root cel.';
        '- When self:freemouse() is called.';
      };
    };
    [[Trapping the mouse changes how mouse focus is determined in the following way.  
      Only the trapping cel and cels linked to it get and lose mouse focus.  
      The hosts of the trapping cel will not lose mouse focus for the duration of the trap.

      More precisely the picking algorithm (responsible for setting the mouse focus and raising onmousein and onmouseout
      events for the mouse) begins at the cel that has the mouse trapped.  If the mouse is not in the trapping cel then
      onmouseout will be raised (if it was in the cel previously) and picking stops.  If the mouse is in the trapping 
      cel the onmousein will be raised (if it was not in the cel previously) and picking will continue recursively 
      checking the links of the trapping cel.
    ]];
    [[A cel cannot gain focus of the mouse unless it is linked to a cel that has trapped the mouse.]];
    [[When the mouse is trapped it is not constrained to the cel that trapped it]];
  };
}
