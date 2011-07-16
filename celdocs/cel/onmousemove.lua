namespace 'celdocs'

export[...] {
  eventdef['cel:onmousemove'] {
    description = [[Signaled when the mouse is moved.]];

    synopsis = [==[
      cel:onmousemove(x, y)
    ]==];

    params = {
      param.cel[[self - self]];
      param.number[[x - The x position of the mouse relative to the cel when the event was created.]];
      param.number[[y - The y position of the mouse relative to the cel when the event was created.]];
    };
  };

  notes {
    [[The cel will recieve the event if it had the mouse focus or had the mouse trapped when the mouse was moved.]];
  };

  examples {
    [==[
    TODO
    ]==];
  };
}
