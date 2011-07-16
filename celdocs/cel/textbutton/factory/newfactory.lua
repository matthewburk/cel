namespace 'celdocs'

export[...] {
  functiondef['cel.button.newfactory'] {
    description = [[Creates a new button factory.]];

    synopsis = [==[
      cel.button.newfactory()
    ]==];

    returns = {
      param.factory[[factory - The new factory]]; 
    };
  };

  notes {
    [[The new factory will have the same interface as the source factory.  It may add to or override the source
      factory interface.]];
  };

  examples {
    [==[
    --TODO: give a couple of example use cases
    ]==];
  };
}
