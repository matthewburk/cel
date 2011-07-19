namespace 'celdocs'

export[...] {
  [[A grip is a cel with that can be dragged around by the mouse.  It can 'grab' another cel
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

  factorydef['cel.grip'] {
    functions = {
      functiondef['__call'] {
        [[Creates a new grip.]];

        synopsis = [==[
          cel.grip {
            w = number,
            h = number,
            target = cel,
            mode = string,
            ongrab(self, x, y) = function,
            ondrag(self, dx, dy) = function,
            onrelease(self) = function,
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

      functiondef['new'] {
        [[Creates a new grip.]];

        synopsis = [==[
          cel.grip.new([w[, h[, face]]])
        ]==];

        params = {
          param.number[[w - width, default is 0.]];
          param.number[[h - height, default is 0.]];
          param.face[[face - face or face name.]];
        };

        returns = {
          param.grip[[a new grip.]];
        };
      };
    };
  };

  celdef['grip'] {
    functions = {
      functiondef['grip'] {
        [[Grips the given cel.]];
        [[When the grip is dragged the gripped cel will be moved.]];

        synopsis = [==[
          grip:grip(target[, mode])
        ]==];

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

      functiondef['getgrip'] {
        [[Returns the cel the grip is gripping.]];

        synopsis = [==[
          grip:getgrip()
        ]==];

        returns = {
          param.cel[[target passed into grip:grip() or nil]]
        };
      };

      functiondef['isgrabbed'] {
        [[Returns true if the grip is grabbed.]];

        synopsis = [==[
          grip:isgrabbed()
        ]==];

        returns = {
          param.boolean[[true if the grip is grabbed.]]
        };
      };
    };

    events = {
      eventdef['ongrab'] {
        [[called when any the grip gets a mousedown event for mouse.buttons.left.]]

        synopsis = [==[
          grip:ongrab(x, y)
        ]==];

        params = {
          param.number[[x - x param of mousedown event.]];
          param.number[[y - y param of mousedown event.]];
        };
      };
      eventdef['ondrag'] {
        [[called when any the grip gets a mousemove event while it is grabbed.]]

        synopsis = [==[
          grip:ondrag(dx, dy)
        ]==];

        params = {
          param.number[[dx - offset of mouse x from the mouse x when grabbed (mousedown.x - mousemove.x) .]];
          param.number[[dy - offset of mouse y from the mouse y when grabbed (mousedown.y - mousemove.y) .]];
        };
      };
      eventdef['onrelease'] {
        [[called when the grip gets a mouseup event while it is grabbed.]];
        [[if mouse:trap() fails after the grip is grabbed then the grip may not get the mouseup event, and
          onrelease will not be called.]]

        synopsis = [==[
          grip:onrelease()
        ]==];
      };
    };
  };

  descriptiondef['grip'] {
    synopsis = [=[
      {
        isgrabbed = boolean,
      }
    ]=];

    params = {
      params.boolean[[isgrabbed - true if the grip is grabbed else false]];
    };
  };
}
