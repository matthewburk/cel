namespace 'celdocs'

export[...] {
  eventdef['cel:onresize'] {
    description = [[Singaled when the width or height of a cel changes.]];

    synopsis = [==[
      cel:onresize(ow, oh)
    ]==];

    params = {
      param.cel[[self - self]];
      param.number[[ow - The width of the cel before it was resized.]];
      param.number[[oh - The height of the cel before it was resize.]];
    };
  };
}
