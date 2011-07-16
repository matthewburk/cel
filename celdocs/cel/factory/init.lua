namespace 'celdocs'

export[...] {
  text.h1 {[[cel]]};

  text.h2 {[[Tables]]};
  section { margin ='1em';
    list.links {
      'root',
      'mouse',
      'keyboard',
      'clipboard',
      'color',
      'face',
      'flows',
      'button',
    };
  };

  hline;

  text.h2 {[[Functions]]};
  section { margin ='1em';
    list.links {
      'new',
      'newmetacel',
      'newfactory',
      'installdriver',
      'describe',
      'loadfont',
      'match',
      'getlinker',
      'addlinker',
      'composelinker',
      'rcomposelinker',
      'unpacklink',
      'doafter',
      'printdescription',
      'translate',
      'timer',
    };
  };
}
