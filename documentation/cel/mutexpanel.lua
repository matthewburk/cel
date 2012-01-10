export['cel.mutexpanel'] {
  [[Factory for the mutexpanel metacel.]];
  
  metaceldef['mutexpanel'] {
    source = 'cel';
    factory = 'cel.mutexpanel';

    [[A mutexpanel is a container cel that only hosts one link at a time, known as the subject.]];
    [[When a cel is linked to the mutexpanel it is redirected to a bucket. The mutexpanel:cels()
    function exposes the cel linked to the mutexpanel and the cels linked to the bucket.]];
      
    description = { 
      [[A cel description.]];
    };

    __link = {
      param['?'] { name = '?',
        [[The link option is the second parameter return from the iterator function of mutexpanel:cels().]]
      };
    };
  };

  functiondef['cel.mutexpanel(t)'] {
    [[Creates a new mutexpanel]];

    code[==[
    cel.mutexpanel {
      w = number,
      h = number,
    }
    ]==];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
    };

    returns = {
      param.mutexpanel[[a new mutexpanel.]]
    };
  };
  functiondef['cel.mutexpanel.new([w[, h[, face]]])'] {
    [[Creates a new mutexpanel]];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param.face[[face - face or face name.]];   
    };

    returns = {
      param.mutexpanel[[a new mutexpanel.]]
    };
  };

  celdef['mutexpanel'] {
    [[A mutexpanel is a container cel that only hosts one link at a time, known as the subject.]];
    [[When a cel is linked to the mutexpanel it is redirected to a bucket. The mutexpanel:cels()
    function exposes the cel linked to the mutexpanel and the cels linked to the bucket.]];

    functiondef['mutexpanel:cels()'] {
      [[Returns an iterator function and the mutexpanel.]];

      code[=[
        for link, option in mutexpanel:links() do end
      ]=];
      [[will iterate over each link in the mutexpanel bucket and the subject in no particular order.]];

      returns = {
        param.iterator[[an iterator function]];
        param.mutexpanel[[the mutexpanel used as the iterator functions invariant state]];
      };
    };

    functiondef['mutexpanel:clear([cel])'] {
      [[Removes the specified cel or all cels from the mutexpanel.]];
      [[When a cel is unlinked from the mutexpanel, a reference is still held to it, clearing will remove
      that reference as well.]];

      params = {
        param.cel[[cel - the cel to clear.]];
      };
      returns = {
        param.mutexpanel[[self.]];
      };
    };

    functiondef['mutexpanel:show(cel[, ...])'] {
      [[Makes cel the subject of the mutex panel.]];

      params = {
        param.cel[[cel - the new subject cel.]];
        param['...'][[... - passed to cel:link(mutexpanel, ...)]];
      };
      returns = {
        param.mutexpanel[[self.]];
      };
    };
  };
}
