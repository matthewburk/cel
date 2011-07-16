namespace 'celdocs'

export[...] {
  functiondef['button:ispressed'] {
    description = [[Returns true if the button is pressed else false.]];

    synopsis = [==[
      button:ispressed()
    ]==];

    params = {
      param.button[[self - self]];
    };

    returns = {
      param.boolean[[ispressed - true if the button is pressed else false.]]
    };
  };

  notes {
    [[TODO describe what pressed is precisely, or not does it really matter]];
  };
}
