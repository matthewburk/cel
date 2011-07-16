namespace 'celdocs'

export[...] {
  factorydef['cel.button'] {
    description = [[Creates buttons.]];

    functions = {
      '__call',
      'new',
      'newmetacel',
      'newfactory',
    };
  };

  celdef.button {
    metacel = 'button';
    factory = 'cel.button';

    description = [[A simple button that responds to mouse and keyboard inputs.]];

    functions = { 
      'ispressed';
    };

    events = {
      'onpress';
      'onhold';
      'onclick';
    };

    drawtable = {
      description = [[Additional entries.]];
      key.pressed[[false if the button is not pressed. true if the button is pressed.]];
    };
  };
}

