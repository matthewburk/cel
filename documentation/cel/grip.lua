export['cel.grip'] {
  [[Factory for the grip metacel]];

  functiondef['cel.grip(t)'] {
    [[Creates a new grip.]];

    code[==[
      cel.grip {
        w = number,
        h = number,
        target = cel,
        mode = string,
        ongrab = function,
        ondrag = function,
        onrelease = function,
      }
    ]==];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param.cel[[target - target of grip, see grip:grip()]];
      param.string[[mode - mode of grip, see grip:grip()]];
      param['function'][[ongrab - event callback.]];
      param['function'][[ondrag - event callback.]];
      param['function'][[onrelease - event callback.]];
    };

    returns = {
      param.grip[[a new grip.]]
    };
  };

  functiondef['cel.grip.new([w[, h[, face]]])'] {
    [[Creates a new grip.]];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param.face[[face - face or face name.]];
    };

    returns = {
      param.grip[[a new grip.]];
    };
  };

  celdef['grip'] {
    [[A grip is a cel with that can be dragged around by the mouse.]];
    [[It can 'grab' another cel
      and typically its host and resize or move it around.
      A grip is activated by the primary mouse button (mouse.buttons.left)]];
    [[When a grip gets a mousedown event it stores the xy coordinate of the event and traps the mouse,
      and then calls the ongrab event]];
    [[When a grip gets a mousemove event while it is grabbed it will first call the
      mode function to move the target then call the ondrag event.  After the mode function and ondrag
      it calls cel.mouse:pick().  This is done to make keep the mouse focus in sync with the dragged cels.]];
    [[When a grip gets a mouseup event while it is grabbed it will call the onrelease event
      and then free the mouse]];
    list {
      header=[[A grip intercepts these events.]];
      [[mousedown - for mouse.buttons.left only]];
      [[mouseup - for mouse.buttons.left only]];
    };

    functiondef['grip:grip(target[, mode])'] {
      [[Grips the given cel.]];
      [[When the grip is dragged the gripped cel will be moved.]];

      params = {
        param.cel[[target - the cel that the grip moves when it is dragged.]]; 
        param.string {
          name=[[mode]];
          [[Each mode is the name of a function that takes the same parameters as grip:ondrag().
            The mode function is called just before the ondrag event is called]];
          list {
            header = [[The mode can be one of the following and moves the target as shown:]];
            key.sync[[target:moveby(dx, dy)]];
            key.top[[target:moveby(0, dy, 0, -dy)]];
            key.left[[target:moveby(dx, 0, -dx, 0)]];
            key.right[[target:moveby(0, 0, dx, 0)]];
            key.bottom[[target:moveby(0, 0, 0, dy)]];
            key.bottomright[[target:moveby(0, 0, dx, dy)]];
            key.topright[[target:moveby(0, dy, dx, -dy)]];
            key.bottomleft[[target:moveby(dx, 0, -dx, dy)]];
            key.topleft[[target:moveby(dx, dy, -dx, -dy)]];
          };
        };
      };

      returns = {
        param.grip[[self]]
      };
    };

    functiondef['grip:getgrip()'] {
      [[Returns the cel the grip is gripping.]];

      returns = {
        param.cel[[target passed into grip:grip() or nil]]
      };
    };

    functiondef['grip:isgrabbed()'] {
      [[Returns true if the grip is grabbed.]];

      returns = {
        param.boolean[[true if the grip is grabbed.]]
      };
    };

    eventdef['grip:ongrab(x, y)'] {
      [[called when any the grip gets a mousedown event for mouse.buttons.left.]];

      params = {
        param.number[[x - x param of mousedown event.]];
        param.number[[y - y param of mousedown event.]];
      };
    };
    eventdef['grip:ondrag(dx, dy)'] {
      [[called when any the grip gets a mousemove event while it is grabbed.]];

      params = {
        param.number[[dx - offset of mouse x from the mouse x when grabbed (mousedown.x - mousemove.x) .]];
        param.number[[dy - offset of mouse y from the mouse y when grabbed (mousedown.y - mousemove.y) .]];
      };
    };
    eventdef['grip:onrelease()'] {
      [[called when the grip gets a mouseup event while it is grabbed.]];
      [[if mouse:trap() fails after the grip is grabbed then the grip may not get the mouseup event, and
        onrelease will not be called.]]
    };

    descriptiondef['grip'] {
      code[=[
        {
          isgrabbed = boolean,
        }
      ]=];

      params = {
        param.boolean[[isgrabbed - true if the grip is grabbed else false]];
      };
    };
  };
}
