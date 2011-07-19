namespace 'celdocs'

export[...] {
  [[A button provides button that responds to mouse events.]];
  [[When a button gets a mousedown event it calls onpress and then traps the mouse.]];
  [[While the button is pressed after an initial pause onhold called preiodically,
    if the mouse is not touching the button onhold will not be called.]];
  [[When it gets a mouseup event it frees the mouse and, and calls onclick if the
    button is pressed and the mouse touches the button]];
  
  list {
    header=[[A button intercepts these events.]];
    [[mousedown]];
    [[mouseup]];
  };

  factorydef['cel.button'] {
    functions = {
      functiondef['__call'] {
        [[Creates a new button.  This function is called by calling the cel.button factory.]];

        synopsis = [==[
          cel.button {
            w = number,
            h = number,
            onclick(self, mousebutton, x, y) = function,
            onpress(self, mousebutton, x, y) = function,
            onhold(self) = function,
          }
        ]==];

        params = {
          param.number[[w - width, default is 0.]];
          param.number[[h - height, default is 0.]];
          param['function'][[onclick - event callback.]];
          param['function'][[onpress - event callback.]];
          param['function'][[onhold - event callback.]];
        };

        returns = {
          param.button[[button - a new button.]]
        };
      };

      functiondef['new'] {
        [[Creates a new button.]];

        synopsis = [==[
          cel.button.new([w[, h[, face[, minw[, maxw[, minh[, maxh]]]]]]])
        ]==];

        params = {
          param.number[[w - width, default is 0.]];
          param.number[[h - height, default is 0.]];
          param.face[[face - face or face name.]];
          param.number[[minw - min width.]];
          param.number[[maxw - max width.]];
          param.number[[minh - min height.]];
          param.number[[maxh - max height.]];
        };

        returns = {
          param.button[[button - a new button.]];
        };
      };
    };
  };

  celdef['button'] {
    functions = {
      functiondef['ispressed'] {
        [[Returns true is the button is pressed.]];

        synopsis = [==[
          button:ispressed()
        ]==];

        returns = {
          param.boolean[[true if the button is pressed else false.]]
        };
      };
    };

    events = {
      eventdef['onpress'] {
        [[called when the button gets a mousedown event.]]

        synopsis = [==[
          button:onpress(mousebutton, x, y)
        ]==];

        params = {
          param.mosuebutton[[mousebutton - the mouse button that was used.]];
          param.number[[x - x param of mousedown event.]];
          param.number[[y - y param of mousedown event.]];
        };
      };
      eventdef['onclick'] {
        [[called when the gets a mouseup event if it is pressed and the mouse is touching the button.]];

        synopsis = [==[
          button:onclick(mousebutton, x, y)
        ]==];

        params = {
          param.mosuebutton[[mousebutton - the mouse button that was used.]];
          param.number[[x - x param of mouseup event.]];
          param.number[[y - y param of mouseup event.]];
        };
      };
      eventdef['onhold'] {
        [[called periodically when the button is pressed and the mouse is touching the button.]];

        synopsis = [==[
          button:onhold()
        ]==];
      };
    };
  };

  descriptiondef['button'] {
    synopsis = [=[
      {
        ispressed = boolean,
      }
    ]=];

    params = {
      params.boolean[[ispressed - true if the button is pressed else false]];
    };
  };
}
