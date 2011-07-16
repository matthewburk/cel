namespace 'celdocs'

export[...] {
  functiondef['cel:unlink'] {
    description = [[unlinks a cel from its host]];

    synopsis = [[
    acel:unlink()
    ]];

    params = {
      param.cel[[self - self]];
    };

    returns = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[If the cel has focus (see cel.hasfocus) when it is unlinked then focus is given to its host via grabfocus.]];
    [[If the cel has the mouse focus when it is unlinked then a new cel is picked. (see mouse.pick).]];
    [[If the cel has the mouse trapped (see cel.trapmouse and cel.hasmousetrapped) when it is unlinked then the mouse
      is released (see cel.releasemouse).
    ]];
  };
}
