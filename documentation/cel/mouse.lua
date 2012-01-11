export['cel.mouse'] {
  [[Refers to the mouse inputsource.]];

  typedef['mouse'] {
    propertydef['mouse.buttons'] {
      [[A table with each entry identifying a unique mouse button.]];
      [[Each entry is assigned a value by the driver.]];
      tabledef {
        key.left[[The driver assigned value for the left mouse button.]];
        key.middle[[The driver assigned value for the middle mouse button.]];
        key.right[[The driver assigned value for the right mouse button.]];
      };
    };

    propertydef['mouse.states'] {
      [[A table with each entry identifying a unique mouse button state.]];
      [[Each entry is assigned a value by the driver.]];
      tabledef {
        key.up[[The driver assigned value indicating the mouse button is not pressed]];
        key.down[[The driver assigned value indicating the mouse button is pressed]];
      };
    };

    propertydef['mouse.wheel'] {
      [[A table with each entry identifying a mouse wheel scroll direction.]];
      [[Each entry is assigned a value by the driver.]];
      tabledef {
        key.up[[The driver assigned value for a wheel scrollup.]];
        key.down[[The driver assigned value for a wheel scrolldown.]];
      };
    };

    --key.scrollines[[The driver assigned value for the number of lines to scroll when the mousewheel is moved.]];

    functiondef['mouse:xy()'] {
      [[Returns the x and y position of the mouse cursor relative to the root cel.]];
      returns = {
        param.number[[x position of mouse cursor.]];
        param.number[[y position of mouse cursor.]];
      };
    };

    functiondef['mouse:vector()'] {
      [[Returns the difference of the current mouse cursor position and the previous position.]];
      returns = {
        param.number[[x component of vector.]];
        param.number[[y component of vector.]];
      };
    };

    functiondef['mouse:isdown(button)'] {
      [[Returns true if specified button is down.]];
      params = {
        param.any[[button - a value present in the mouse.buttons table.]];
      };
      returns = {
        param.boolean[[true if the button is down, else false.]]
      };
    };

    functiondef['mouse:pick()'] {
      [[Forces picking algorithm that determines which cel(s) the mouse is in to run.]];
      [[This is normally only run when the mouse cursor is moved or a button state changes.
      It is too costly to always run when a cel moves, but can be necessary in special cases.]];
      returns = {
        param.mouse[[self]];
      };
    };
  }
}
