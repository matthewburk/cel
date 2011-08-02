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

    examples = {
    [==[
    local cel = require 'cel'
    local host = ...

    local function flowjiggle(context, ox, x, oy, y, ow, w, oh, h)
      if context.iteration < 10 or context.duration < 250 then
        return x + math.random(-4, 4), y + math.random(-4, 4), w, h, true
      else
        return x, y, w, h
      end
    end

    local function jiggle(c)
      c:flow(flowjiggle, c.x, c.y)
    end

    local button = cel.button {
      w = 200, h = 200,
      onclick = jiggle;

      cel.button {
        w = 33, h = 77, link = {'right.bottom', 10, 10};
      }
    }

    button:link(host, 'center'):relink()

    ]==]
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

      examples = {
      [==[
      local cel = require('cel')
      local host = ...

      local listbox = cel.listbox.new():link(host, 'edges')
      local button = cel.button.new(100, 100):link(host, 'center')

      local function print(...)
        local t = {...}
        for i, v in ipairs(t) do
          t[i] = tostring(v)
        end
        listbox:insert(table.concat(t, ' '))
      end

      function button:onpress(mousebutton, x, y)
        print('press', self, mousebutton, x, y)
        listbox:scrollto(nil, math.huge)
      end
      ]==];
      };
    };

    eventdef['button:onclick(mousebutton, x, y)'] {
      [[called when the gets a mouseup event if it is pressed and the mouse is touching the button.]];

      params = {
        param.mousebutton[[mousebutton - the mouse button that was used.]];
        param.number[[x - x param of mouseup event.]];
        param.number[[y - y param of mouseup event.]];
      };

      examples = {
      [==[
      local cel = require('cel')
      local host = ...

      local listbox = cel.listbox.new():link(host, 'edges')
      local button = cel.button.new(100, 100):link(host, 'center')

      local function print(...)
        local t = {...}
        for i, v in ipairs(t) do
          t[i] = tostring(v)
        end
        listbox:insert(table.concat(t, ' '))
      end

      function button:onpress(mousebutton, x, y)
        print('press', self, mousebutton, x, y)
        listbox:scrollto(nil, math.huge)
      end

      function button:onclick(mousebutton, x, y)
        print('click', self, mousebutton, x, y)
        listbox:scrollto(nil, math.huge)
      end
      ]==];
      };
    };

    eventdef['button:onhold()'] {
      [[called periodically when the button is pressed and the mouse is touching the button.]];

      examples = {
      [==[
      local cel = require('cel')
      local host = ...

      local listbox = cel.listbox.new():link(host, 'edges')
      local button = cel.button.new(100, 100):link(host, 'center')

      local function print(...)
        local t = {...}
        for i, v in ipairs(t) do
          t[i] = tostring(v)
        end
        listbox:insert(table.concat(t, ' '))
      end

      function button:onpress(mousebutton, x, y)
        print('press', self, mousebutton, x, y)
      end

      function button:onhold()
        print('hold', self, cel.timer())
        listbox:scrollto(nil, math.huge)
      end
      ]==];
      };
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
