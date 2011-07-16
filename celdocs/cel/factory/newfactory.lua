namespace 'celdocs'

export[...] {
  functiondef['cel.newfactory'] {

    description = [[Creates a factory for the metacel.]];

    synopsis = [==[
      cel.newfactory(metacel, table)
    ]==];

    params = {
      param.metacel[[metacel - The metacel to create a factory for.]];
      param.table[[table - Each entry in this table is added to the factory.]];
    };

    returns = {
      param.factory[[factory - The new factory]];

    };
  };

  notes {
    [[TODO: A factory interacts with the metacel it should be new factory should be defined as a metacel function.]];
  };

  examples {
    [==[
    --TODO, should look at metacel overview and tuturials for examples
    ]==];
  };
}
