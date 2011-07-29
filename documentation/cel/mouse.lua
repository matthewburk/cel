export {
  typedef['mouse'] {
    [[A cel mouse represents the mouse inputsource.]];
    [[ The cel driver defines values for mouse buttons etc.]];
    tabledef.buttons {
      key.left[[The driver assigned value for the left mouse button.]];
      key.middle[[The driver assigned value for the middle mouse button.]];
      key.right[[The driver assigned value for the right mouse button.]];
    };
    tabledef.states {
      key.unknown[[The driver assigned value indicating that Cel does not know if a mouse button is pressed]];
      key.normal[[The driver assigned value indicating the mouse button is not pressed]];
      key.pressed[[The driver assigned value indicating the mouse button is pressed]];
    };
    tabledef.wheeldirection {
      key.up[[The driver assigned value for a wheel scrollup.]];
      key.down[[The driver assigned value for a wheel scrolldown.]];
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
