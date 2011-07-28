export['cel.button'] {
  [[Factory for the button metacel.]];
  

  functiondef['cel.button(t)'] {
    [[Creates a new button]];

    code[==[
    cel.button {
      w = number,
      h = number,
      onclick = function,
      onpress = function,
      onhold = function,
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
      param.button[[a new button.]]
    };
  };

  functiondef['cel.button.new([w[, h[, face[, minw[, maxw[, minh[, maxh]]]]]]])'] {
    [[Creates a new button.]];

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
      param.button[[a new button.]];
    };
  };

  celdef['button'] {
    metacel = 'button';
    [[A simple button that responds to mouse events.]];
    [[When a button gets a mousedown event it calls onpress and then traps the mouse.]];
    [[While the button is pressed after an initial pause onhold called preiodically,
      if the mouse is not touching the button onhold will not be called.]];
    [[When it gets a mouseup event it frees the mouse and, and calls onclick if the
      button is pressed and the mouse touches the button]];
    
    list {
      header=[[A button intercepts these events:]];
      [[mousedown]];
      [[mouseup]];
    };

    functiondef['button:ispressed()'] {
      [[Returns true is the button is pressed.]];

      returns = {
        param.boolean[[true if the button is pressed else false.]]
      };
    };

    eventdef['button:onpress(mousebutton, x, y)'] {
      [[called when the button gets a mousedown event.]];

      params = {
        param.mousebutton[[mousebutton - the mouse button that was used.]];
        param.number[[x - x param of mousedown event.]];
        param.number[[y - y param of mousedown event.]];
      };
    };

    eventdef['button:onclick(mousebutton, x, y)'] {
      [[called when the gets a mouseup event if it is pressed and the mouse is touching the button.]];

      params = {
        param.mousebutton[[mousebutton - the mouse button that was used.]];
        param.number[[x - x param of mouseup event.]];
        param.number[[y - y param of mouseup event.]];
      };
    };

    eventdef['button:onhold()'] {
      [[called periodically when the button is pressed and the mouse is touching the button.]];
    };

    descriptiondef['button'] {
      code[=[
        {
          ispressed = boolean,
        }
      ]=];

      params = {
        param.boolean[[ispressed - true if the button is pressed else false]];
      };
    };
  };
}
