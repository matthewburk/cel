namespace 'celdocs'

export[...] {
  eventdef['cel:onfocus'] {
    description = [[Singaled when a cel gains or loses focus.]];

    synopsis = [==[
      cel:onfocus(focus)
    ]==];

    params = {
      param.cel[[self - self]];
      param.boolean[[focus - true if the cel gained focus, false if the cel lost focus.]];
    };
  };

  notes {
    [[Do not call self:takefocus() in response onfocus when the cel lost focus.  
      That would be a good way to create an infinite loop.]];
    [[Use self:hasfocus() == 1 to determine if self is the first cel with focus.]];
  };
}
