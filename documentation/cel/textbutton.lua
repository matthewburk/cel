export['cel.textbutton'] {
  [[Factory for the textbutton metacel]];

  functiondef['cel.textbutton(t)'] {
    [[Creates a new textbutton]];
    [[The w and h of the textbutton will be initialized to its minw and minh]];

    code[==[
    cel.textbutton {
      text = string,
      onclick = function,
      onpress = function,
      onhold = function,
    }
    ]==];

    params = {
      param.number[[text - text to display]];
      param['function'][[onclick - event callback.]];
      param['function'][[onpress - event callback.]];
      param['function'][[onhold - event callback.]];
    };

    returns = {
      param.textbutton[[a new textbutton.]]
    };
  };

  functiondef['cel.textbutton.new(text[, face])'] {
    [[Creates a new textbutton.]];
    [[The w and h of the textbutton will be initialized to its minw and minh]];

    params = {
      param.string[[text - The text to display.]];
      param.face[[face - face or face name.]];      
    };

    returns = {
      param.textbutton[[a new textbutton]];
    };

    examples = {
      [==[
      local cel = require('cel')

      local tb = cel.textbutton.new('Hello World')

      tb:link(root, 'center')
      ]==];
    };
  };

  tabledef['cel.textbutton.layout'] {
    key.padding[[A table defining how to layout space around the text.
    see font:pad() for definition.]];
  };

  celdef['textbutton'] {
    [[A textbutton is a button for displaying a single line of text.]];
    [[A textbutton has a minimum width and height which is determined by its text and layout]];

    functiondef['textbutton:getfont()'] {
      'Returns the font';
      returns = {
        param.font[[font used by the textbutton]];
      };
    };

    functiondef['textbutton:getbaseline()'] {
      [[Returns the pen origin]];
      
      returns = {
        param.integer[['x coordinate of pen origin to use when drawing the text]];
        param.integer[['y coordinate of pen origin to use when drawing the text]];
      };
    };

    functiondef['textbutton:settext(text)'] {
      [[Changes the text displayed.]];

      params = {
        param.string[[text - text to display]];
      };

      returns = {
        param.textbutton[[self]]
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local textbutton = cel.textbutton.new(''):link(host, 'center')

        function host:onmousemove(x, y)
          textbutton:settext('mousemoved ' .. x ..' '.. y)
        end
        ]==];
      };
    };
    functiondef['textbutton:gettext()'] {
      [[Gets the displayed text.]];

      returns = {
        param.string[[text]]
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local listbox = cel.listbox.new():link(host, 'edges')
        local textbutton = cel.textbutton.new('Hello'):link(listbox)

        function host:onmousemove(x, y)
          textbutton:printf('%s %d %d', textbutton:gettext(), x, y)
        end
        ]==];
      };
    };
    functiondef['textbutton:printf(format, ...)'] {
      [[Changes the text displayed. Shortcut for
      textbutton:settext(string.format(format, ...))]];

      params = {
        param.string[[format - format parameter for string.format]];
        param['...'][[... - additional parameters for string.format]];
      };

      returns = {
        param.textbutton[[self]]
      };

      examples= {
        [==[
        local cel = require 'cel'
        local host = ...

        local textbutton = cel.textbutton.new(''):link(host, 'center')

        function host:onmousemove(x, y)
          textbutton:printf('mousemoved  %d %d', x, y)
        end
        ]==];
      };
    };

    functiondef['textbutton:ispressed()'] { 'inherited from button' };

    eventdef['textbutton:onchange()'] {
      [[called when the textbutton text is changed.]];
      synchronous = true;
    };

    eventdef['textbutton:onclick(mousebutton, x, y)'] { 'inherited from button' };
    eventdef['textbutton:onhold()'] { 'inherited from button' };
    eventdef['textbutton:onpress(mousebutton, x, y)'] { 'inherited from button' };
    
  };
 
  descriptiondef['textbutton'] {
    [[Adds to the a button description]];
    code[=[
    {
      font = font,
      text = string,
      penx = integer,
      peny = integer,
      textw = integer,
      texth = integer,
    }
    ]=];

    params = {
      param.font[[font - font]];
      param.string[[text - text]];
      param.integer[[penx - pen origin to use when rendering text]];
      param.integer[[peny - pen origin to use when rendering text]];
      --TODO change to advancew or penadvance
      param.integer[[textw - width of text returned from font:measure(text)]];
      --TODO change to bbox of text, not font bbox
      param.integer[[texth - height of text to returned from 
                              font:measure(text)]];
    };
  };
};
