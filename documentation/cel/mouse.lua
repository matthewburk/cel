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

    functiondef['cel.mouse:pick()'] {
    };

    functiondef['cel.mouse:xy()'] {
    };

    functiondef['cel.mouse:vector()'] {
    };

    functiondef['cel.mouse:isdown(button)'] {
    };
  };
};
