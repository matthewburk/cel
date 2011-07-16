namespace 'celdocs'

export[...] {
  eventdef['cel:onmouseup'] {
    description = [[Signaled when a mouse button is released.]];

    synopsis = [==[
      cel:onmouseup(button, x, y, intercepted)
    ]==];

    params = {
      param.cel[[self - self]];
      param.mousebutton[[button - The mouse button that was released.  A valid entry in mouse.buttons.]];
      param.number[[x - The x position of the mouse relative to the cel when the event was created.]];
      param.number[[y - The y position of the mouse relative to the cel when the event was created.]];
      param.boolean[[intercepted - If a link of the cel saw this event and intercepted it this will be true.
      If the event was not intercepted this will be nil.]];
    };

    returns = {
      param.boolean[[intercepted - Return true to intercept the event.  This will indicate to any host cels that see the event                             has been intercepted, generally meaning some action was taken.]];
    };
  };

  notes {
    [[The cel will recieve the event if it had the mouse focus or had the mouse trapped when the event was signaled.]];
    [[Intercepting the event will not stop the event from propogating, it simply sets the intercepted parameter to
      true for any other event handler that sees the event.]];
  };

  examples {
    [==[
    --TODO
    ]==];
  };
}
