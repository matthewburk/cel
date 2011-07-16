namespace 'celdocs'

export[...] {
  functiondef['cel:hasmousetrapped'] {
    description = [[Returns true if the cel has the mouse trapped.]];

    synopsis = [==[
      acel:hasmousetrapped()
    ]==];

    params = {
      param.cel[[self - self]];
    };

    returns = {
      param.boolean[[hasmousetrapped - true if the cel has trapped the mouse, by calling trapmouse() false otherwise.]];
    };
  };

  notes {
    [[TODO]];
  };
}
