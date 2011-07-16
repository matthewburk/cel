namespace 'celdocs'

export[...] {
  eventdef['cel:onkeyup'] {
    description = [[Signaled when a keyboard key is released.]];

    synopsis = [==[
      cel:onkeyup(key, intercepted)
    ]==];

    params = {
      param.cel[[self - self]];
      param.key[[key - The keyboard key that was released.  A valid entry in keyboard.keys.]];
      param.boolean[[intercepted - If a link of the cel saw this event and intercepted it this will be true.
        If the event was not intercepted this will be nil.]];
    };

    returns = {
      param.boolean[[intercepted - Return true to intercept the event.  This will indicate to any host cels
        that see the event has been intercepted, generally meaning some action was taken.]];
    };
  };

  notes {
    [[The cel will recieve the event if it had the keyboard focus when the event was signaled.]];
    [[Intercepting the event will not stop the event from propogating, it simply sets the intercepted parameter to
      true for any other event handler that sees the event.]];
  };

  examples {
    [==[
    --TODO
    ]==];
  };
}
