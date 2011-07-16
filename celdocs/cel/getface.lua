namespace 'celdocs'

export[...] {
  functiondef['cel:getface'] {
    description = [[Returns the face of the cel.]];

    synopsis = [==[
      acel:getface()
    ]==];

    params = {
      param.cel[[self - self]];
    };

    returns = {
      param.face[[face - the cel's face.]];
    };
  };

  notes {
    [[A cel will always have a face, if one is not explicity given when it is created then the cel's face is the unnamed face of its metacel.]];
  };
}
