export['cel.panel'] {
  [[Factory for the panel metacel.]];
  
  metaceldef['panel'] {
    source = 'cel';
    factory = 'cel.panel';

    [[A panel is a simple container cel.]];
    [[A panel exposes its links through the panel:links() function.]];
      
    description = { 
      [[A cel description.]];
    };

    __link = {
      param['?'] { name = '?',
        [[The link option is the second parameter return from the iterator function of panel:links().]]
      };
    };
  };

  functiondef['cel.panel(t)'] {
    [[Creates a new panel]];

    code[==[
    cel.panel {
      w = number,
      h = number,
    }
    ]==];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
    };

    returns = {
      param.panel[[a new panel.]]
    };
  };
  functiondef['cel.panel.new([w[, h[, face]]])'] {
    [[Creates a new panel]];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param.face[[face - face or face name.]];   
    };

    returns = {
      param.panel[[a new panel.]]
    };
  };

  celdef['panel'] {
    [[A panel is a simple container cel.]];
    [[A panel exposes its links through the panel:links() function.]];

    functiondef['panel:links()'] {
      [[Returns an iterator function and the listbox.]];

      code[=[
        for link, option in panel:links() do end
      ]=];
      [[will iterate over each link in the panel in no particular order.]];

      returns = {
        param.iterator[[an iterator function]];
        param.panel[[the panel used as the iterator functions invariant state]];
      };
    };

    functiondef['panel:clear()'] {
      [[unlinks all links in the panel.]];
      returns = {
        param.panel[[self.]];
      };
    };
  };
}
