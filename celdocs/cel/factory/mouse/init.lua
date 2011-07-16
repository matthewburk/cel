section.description {
  paragraph[[
    cel.mouse represents a mouse (or mouselike) input device.  The cel driver defines values for mouse buttons etc.
    The cel mouse does not define what these values are so that integration into the host system is more seamless.
    The host system will already have a name that is analogous to cel.mouse.buttons.left but it will probably be 
    something different.  For example in love2d love.mouse.l is the name used for the left mousebutton.  A love2d game
    could then use the native name whenever it sees a cel.mouse.button.
  ]];

  section {
    [[For example:]];

    code [==[
      function acel:onmousedown(state, button, x, y)
        if button == love.mouse.l then
          --do something
        end
      end
    ]==];

    [[When authoring a cel that is intended for use in different host systems that should be written as:]];

    code [==[
      function acel:onmousedown(state, button, x, y)
        if button == cel.mouse.buttons.left then
          --do something
        end
      end 
    ]==];
  };
};

tabledef.mouse {
  [[number scrolllines - The number of lines to scroll when the mouse wheel is moved.]];

  tabledef.buttons {
    [[any left - The driver assigned value for the left mouse button.]];
    [[any middle - The driver assigned value for the middle mouse button.]];
    [[any right - The driver assigned value for the right mouse button.]];
  };

  tabledef.buttonstates {
    [[any unknown - The driver assigned value for an unknown button state.  All mouse buttons will have this state
      until the first state change in the button.]];
    [[any normal - The driver assigned value indicating the button is not pressed.]];
    [[any pressed - The driver assigned value indicating the button is pressed.]];
  };

  tabledef.wheeldirection {
    [[any up - The driver assigned value for a wheel scrollup.]];
    [[any down - The driver assigned value for a wheel scrolldown.]];
  };

  [[function pick]];
  [[function xy]];
  [[function vector]];
  [[function incel]];
  [[function ispressed]];
};
