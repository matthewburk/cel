namespace 'celdocs'

export[...] {
  functiondef['cel:freemouse'] {
    description = [[Releases the mouse if the cel has the mouse trapped. On return cel.root will have the mouse trapped unless the onescape callback traps the mouse elsewhere.]];

    synopsis = [==[
      acel:freemouse([reason])
    ]==];

    params = {
      param.cel[[self - self]];
      param.string[[reason - An explanatory string passed to the onescape callback given when the mouse was trapped.]];
    };

    returns = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[When the mouse is freed onescape (given when the mouse was trapped by the cel) is called before returning. onescape may retrap the mouse.]]
  };
}
