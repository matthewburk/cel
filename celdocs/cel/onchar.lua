namespace 'celdocs'

export[...] {
  eventdef['cel:onchar'] {
    description = [[Signaled when a character is generated by the keyboard.]];

    synopsis = [==[
      cel:onchar(char, intercepted)
    ]==];

    params = {
      param.cel[[self - self]];
      param.string[[char - The string representation of the character.]];
      param.boolean[[intercepted - If a link of the cel saw this event and intercepted it this will be true.
                                   If the event was not intercepted this will be nil.]];
    };

    returns = {
      param.boolean[[intercepted - Return true to intercept the event.  This will indicate to any host cels that see
                    the event has been intercepted, generally meaning some action was taken.]];
    };
  };

  notes {
    [[The cel will recieve the event if it had the keyborad focus when the event was signaled.]];
    [[Intercepting the event will not stop the event from propogating, it simply sets the intercepted parameter to
      true for any other event handler that sees the event.]];
  };

  examples {
    [==[
    --TODO
    ]==];
  };
}
