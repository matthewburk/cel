namespace 'celdocs'

export[...] {
  functiondef['cel.button.newmetacel'] {
    description = [[Creates a copy of the 'button' metacel.]];

    synopsis = [==[
      cel.button.newmetacel(name)
    ]==];

    params = {
      param.string[[name - The name of the new metacel.  TODO what happens when name is already in use?]];
    };

    returns = {
      param.metacel[[metacel - A new metacel with the specified name, with the same entries as the original metacel 
        (excluding metacel.metatable). The metatable entry is a copy of orginal metacel.metatable with the same
        entries (excluding __index which is redefined for the new metatable).]];
      param.metatable[[metatable - The metatable that is assigned to cels created with the metacel.
        This is also an entry in metacel (metacel.metatable).]];
    };
  };

  notes {
    [[The metacel defines the behavior of a cel. The behavior can be changed by overwriting existing methods or 
      defining new ones.]];
    [[The metatable at metacel.metatable defines the interface of a cel.]];
    [[When a new metacel is created a face is created for the metacel if one does not already exist.]];
  };

  examples {
    [==[
    --TODO, should look at metacel overview and tuturials for examples
    ]==];
  };
}
