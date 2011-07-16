namespace 'celdocs'

export[...] {
  eventdef['cel:onmousein'] {
    description = [[Singaled when a cel gains focus of the mouse.]];

    synopsis = [==[
      cel:onmousein()
    ]==];

    params = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[Use self:hasfocus(cel.mouse) == 1 to determine if self is the first cel with focus.]];
  };
}
