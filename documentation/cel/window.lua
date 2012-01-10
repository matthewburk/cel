export['cel.window'] {
  [[Factory for the window metacel.]];
  
  metaceldef['window'] {
    source = 'cel';
    factory = 'cel.window';

    composition = {
      code[=[
        [top] = window.border
        [bottom] = window.border
        [left] = window.border
        [right] = window.border
        [topleft] = window.corner
        [topright] = window.corner
        [bottomleft] = window.corner
        [bottomright] = window.corner
        [handle] = window.handle
        [client] = window.client
      ]=];

      params = {
        param['window.border'][[[top] - border grip.]];
        param['window.border'][[[bottom] - border grip.]];
        param['window.border'][[[left] - border grip.]];
        param['window.border'][[[right] - border grip.]];
        param['window.corner'][[[topleft] - corner grip.]];
        param['window.corner'][[[topright] - corner grip.]];
        param['window.corner'][[[bottomleft] - corner grip.]];
        param['window.corner'][[[bottomright] - corner grip.]];
        param['window.handle'][[[handle] - handle grip.]];
        param['window.client'][[[client] - client cel.]];
      };
    };

    description = { 
      [[A scroll description.]];
      code[=[
        activated = boolean,
        state = string,
        title = string,
        [client] = window.client
        [handle] = window.handle
        [bottomright] = window.corner
        [bottomleft] = window.corner
        [topright] = window.corner
        [topleft] = window.corner
        [right] = window.border
        [left] = window.border
        [bottom] = window.border
        [top] = window.border
      ]=];

      params = {
        param.boolean[[activated - true if the window is activated.]];
        param.string[[state - 'minimizing', 'maximizing', 'maximized', 'minimized', 'restoring', 'normal'.]];
        param.string[[title - the title of the window.]];
        param['window.border'][[[top] - border grip.]];
        param['window.border'][[[bottom] - border grip.]];
        param['window.border'][[[left] - border grip.]];
        param['window.border'][[[right] - border grip.]];
        param['window.corner'][[[topleft] - corner grip.]];
        param['window.corner'][[[topright] - corner grip.]];
        param['window.corner'][[[bottomleft] - corner grip.]];
        param['window.corner'][[[bottomright] - corner grip.]];
        param['window.handle'][[[handle] - handle grip.]];
        param['window.client'][[[client] - client cel.]];
      };
    };

    layout = {
      [[A table defineing the internal layout of a window]];
      code[=[
      minw = integer,
      maxw = integer,
      minh = integer,
      maxh = integer,

      border = {
        face = face,
        size = integer,
      },
      corner = {
        face = face,
        size = integer,
      },
      handle = {
        face = face,
        w = integer,
        h = integer,
        link = {linker[, xval[, yval]]} or string,
      },
      client = {
        face = face,
        w = integer,
        h = integer,
        link = {linker[, xval[, yval]]} or string,
      },
      ]=];

      params = {
        param.face[[face - face or face name]];
        param.integer[[minw - optional min width of window.]];
        param.integer[[maxw - optional max width of window.]];
        param.integer[[minh - optional min height of window.]];
        param.integer[[maxh - optional max height of window.]];
        param.table {
          name='border';
          [[optional border layout, if nil or false no borders are created.]];
          tabledef {
            param.face[[face - face or face name.]];
            param.integer[[size - the size of the border.]];
          };
        };
        param.table {
          name='corner';
          [[optional corner layout, if nil or false no corners are created.]];
          tabledef {
            param.face[[face - face or face name.]];
            param.integer[[size - the size of the corner width and height.]];
          };
        };
        param.table {
          name='handle';
          [[optional handle layout, if nil or false no handle is created.]];
          tabledef {
            param.face[[face - face or face name.]];
            param.integer[[w - width of the handle.]];
            param.integer[[h - height of the handle.]];
            param.table {
              name='link';
              [[If link is a table, it contains arguments passed to cel:link().]];
              tabledef {
                param.linker[[[1] - linker function or name passed to cel:link().]];
                param.any[[[2] - xval param passed to cel:link()]];
                param.any[[[3] - yval param passed to cel:link()]];
              };
            };
            param.string[[link - linker name passed to cel:link()]];
          };
        };
         param.table {
          name='client';
          [[client cel layout.]];
          tabledef {
            param.face[[face - face or face name.]];
            param.integer[[w - width of the client cel.]];
            param.integer[[h - height of the client cel.]];
            param.table {
              name='link';
              [[If link is a table, it contains arguments passed to cel:link().]];
              tabledef {
                param.linker[[[1] - linker function or name passed to cel:link().]];
                param.any[[[2] - xval param passed to cel:link()]];
                param.any[[[3] - yval param passed to cel:link()]];
              };
            };
            param.string[[link - linker name passed to cel:link()]];
          };
        };
      };
    };

    
     __link = {
      param['?'] { name = 'default', [[link is linked to the client cel.]] };
      param.string { name = "'raw'"; [[link is not redirected.]] };
      param.string { name = "'handle'"; [[link is redirected to the handle.]] };
    };

    flows = {
      key.minimize[[called when the window is minimized.]];
      key.maximize[[called when the window is maximized.]];
      key.restore[[called when the window is restored.]];
    };
  };

  metaceldef['window.border'] {
    source = 'grip';
    description = { 
      [[A grip description.]];
    };
  };
  metaceldef['window.corner'] {
    source = 'grip';
    description = { 
      [[A grip description.]];
    };
  };
  metaceldef['window.handle'] {
    source = 'grip';
    description = { 
      [[A grip description.]];
    };
  };
  metaceldef['window.client'] {
    source = 'cel';
    description = { 
      [[A cel description.]];
    };
  };

  functiondef['cel.window(t)'] {
    [[Creates a new window]];

    code[==[
    cel.window {
      w = number,
      h = number,
      title = string,
      onchange = function,
      onclose = function,
    }
    ]==];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param.string[[title - title of the window.]];
      param['function'][[onchange - event callback.]];
      param['function'][[onclose - event callback.]];
    };

    returns = {
      param.window[[a new window.]]
    };
  };

  functiondef['cel.window.new([w[, h[, title[, face]]]])'] {
    [[Creates a new window]];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param.string[[title - title of the window.]];
      param.face[[face - face or face name.]];   
    };

    returns = {
      param.window[[a new window.]]
    };
  };

  celdef['window'] {

    functiondef['window:maximize()'] {
      'Maximizes the window.';
      [[If the windows state is 'normal' then the current postion, dimensions and linker
        of the window are saved before the window is 
        maximized and window:restore() can be called to return to the saved values.
        When the window is maximized it is relinked in its host using the 'edges' linker.
        If the window face defines flows.maximize it will be called.  While the window is flowing its state
        is 'maximizing'.
        After the window is maximized its state is set to 'maximized' and window:onchange() is called.
      ]];
      returns = {
        param.window[[self.]];
      };
    };

    functiondef['window:minimize()'] {
      'Minimizes the window.';
      [[If the windows state is 'normal' then the current postion, dimensions and linker of the window are saved
        before the window is minimized and window:restore() can be called to return to the saved values.
        When the window is minimized it is relinked forcing it to its minimum dimensions positioned at the bottom
        left corner of its host.
        If the window face defines flows.minimize it will be called.  While the window is flowing its state
        is 'minimizing'.
        After the window is minimized its state is set to 'minimized' and window:onchange() is called.
      ]];
      returns = {
        param.window[[self.]];
      };
    };

    functiondef['window:restore()'] {
      'Restores the window to its normal state.';
      [[This function is redefined each time the window state changes from 'normal']];
      [[When the window is restored it is relinked and resized and moved into values saved when it was minimized or 
        maximized.
        If the window face defines flows.restore it will be called.  While the window is flowing its state
        is 'restoring'.
        After the window is restored its state is set to 'normal' and window:onchange() is called.
      ]];
      returns = {
        param.window[[self.]];
      };
    };

  };
}
