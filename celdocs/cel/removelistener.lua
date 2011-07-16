namespace 'celdocs'

export[...] {
  functiondef['cel:removelistener'] {
    description = [[Removes a listener from the cel.]];

    synopsis = [==[
      acel:removelistener(event, listener)
    ]==];

    params = {
      param.cel[[self - self]];
      param.string[[event - the name of the event.]];
      param['function'][[listener - function to call when event happens.]];
    };

    returns = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[Does nothing is listener is not a listener that was added via addlistener.]];
    [[The listener will not see any events after removelistner returs.]];
  };

  examples {
    [==[
    --TODO
    ]==],
  };
}
