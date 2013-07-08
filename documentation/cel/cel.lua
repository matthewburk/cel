export['cel'] {
  [[The main module of the Cel libarary.]];

  metaceldef['cel'] {
    source = 'cel';

    description = {
      [[This table is the description of a cel, which is the information required to render the cel.
      Every cel will contain this information in its description.]];

      code[=[
      {
        id = number,
        host = description,
        x = number,
        y = number,
        w = number,
        h = number,
        mousefocusin = boolean,
        mousefocus = boolean,
        focus = (keyboard)boolean,
        clip = {
          l = number,
          r = number,
          t = number,
          b = number,
        },
        face = face,
        metacel = string,
        metacel = boolean,
        disabled = boolean,
        disabled = 'host',
        flowcontext = any,
        [1,n] = description,
      }
      ]=];

      params = {
        param.userdata[[celhandle - a handle unique to a cel.  This is supplied so that a face may use it
        to as a weak key/value for addressing face resources unique to the cel.]];
        param.number[[id - a unique id for the cel the cel that is described, 
                           this is 0 if the cel has no id (meaning its a virtual cel)]];

        param.description[[host - refers to the host description.]];
        param.number[[x - The x coordinate of the cel.]];
        param.number[[y - The y coordinate of the cel.]];
        param.number[[w - The width of the cel.]];
        param.number[[h - The height of the cel.]];
        param.boolean[[mousefocusin - if true then the mouse cursor is in the cel]];
        param.boolean[[mousefocus - if true then the mouse cursor is touching the cel.]];
        param.boolean[[focus - if true the cel has focus.]];
        param.table{
          name='clip';
          [[defines a rectangle in absolute coordinates, that the cel is cliped to. 
            This will always be at least as restrictive as the clipping recatangle for the host.
            If the area defined by clip is <= 0 for a cel then that cel is not described.
            Which means that clip.l < clip.r is always true and clip.t < clip.b is always true.]];
          tabledef {
            param.number[[l - The left of the clipping rectangle, this is always less than the right]];
            param.number[[r - The right of the clipping rectangle this is always greater than the left side]];
            param.number[[t - The top of the clipping rectangle, this is always less than the bottom.]];
            param.number[[b - the bottom of the clipping rectangle, this is always greater than the top.]];
          };
        };
        param.any[[flowcontext - This is nil by default, if present this cel is 'flowing' and
                   this is the context passed to the flow function. The flow function can put additional
                   information in the context, the suggested usage is event based animations.]];
        param.face[[face - The cel face]];
        param.string[[metacel - This is the name of the metacel for the cel. The metacel is the
                      type of cel such as 'button', 'label', 'listbox', 'root']];
        param.boolean[[metacel - If metacel is false, the description is of a virtual cel, 
        that was never actually created.]]; 
        param.boolean[[disabled - true if cel is disabled.]],
        param.string[[disabled - 'host' if cel's host is disabled.]],

        param['description'][[[1,n] - This is the array portion of the cels description, 
        (it meets the requirements for the # operator to return its length).
        Any cel that is linked to the cel and is not entirely clipped will
        be described in this array in z order. (The topmost link will be at index 1). For cels that define a layout,
        such as a row, the order is not based on z order]];
      };
    };
  };

  functiondef['cel(t)'] {
    [[Creates a new cel]];

    code[=[
    cel {
      w = number,
      h = number,
      face = any,
      link = table|string|function,
      touch = function,
      onresize = function,
      onmousein = function,
      onmouseout = function,
      onmousemove = function,
      onmousedown = function,
      onmouseup = function,
      ontimer = function,
      onfocus = function,
      onblur = function,
      onkeydown = function,
      onkeypress = function,
      onkeyup = function,
      onchar = function,
      oncommand = function,
      [1,n] = cel|function|string|{link = table|string|function, [1,n] = cel|string}
    }
    ]=];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param.face[[face - face or face name.]];
      param['function'][[link - a linker function.  Any cel in the array part will be linked to this cel with using
      this linker function.]];
      param.table[[link - an array defining the linker function at link[1], xval at link[2], yval at link[3] and 
      option at link[4].  Any cel in the array part will be linked to this cel with using 
      this linker function, xval, yval and option.]];
      param.string[[link - the name of a linker function.  Any cel in the array part will be linked to
      this cel with using this linker function.]];
      param['function'][[touch - touch callback.]];
      param['function'][[onresize - event callback.]];
      param['function'][[onmousein - event callback.]];
      param['function'][[onmouseout - event callback.]];
      param['function'][[onmousemove - event callback.]];
      param['function'][[onmousedown - event callback.]];
      param['function'][[onmouseup - event callback.]];
      param['function'][[ontimer - event callback.]];
      param['function'][[onfocus - event callback.]];
      param['function'][[onblur - event callback.]];
      param['function'][[onkeydown - event callback.]];
      param['function'][[onkeypress - event callback.]];
      param['function'][[onkeyup - event callback.]];
      param['function'][[onchar - event callback.]];
      param['function'][[oncommand - event callback.]];
      param['any'] {
        name = '[1,n]';
        [[When the cel is created each entry from 1 to n is evaluated in order 
        where n is #(table).  The entry must be one of the following or it is ignored:]];
        tabledef {
          key.cel[[If the entry is a cel then it is linked to this cel using the
            link parameters defined by the link entry of this table.]];
          key['function'][[If the entry is a function, it is called with the new cel as its only parameter.  
            The return value from this function is ignored.]];
          key.string[[If the entry is a string a new cel.label is created with the string and then
            linked to this cel.]];
          key.table {
            [[If the entry is a table all cels or strings in the array part will be linked to this cel using the
            link parameters defined by the link entry of this table.]];
            tabledef {
              code[=[
              {
                link = table|string|function,
                [1,n] = cel|string,
              }
              ]=];
              key.link[[Any cels in the array part of this table will use this as the definition of the link 
              parameters.  If this is nil then the value of link in the enclosing table is used.]];
              key['[1,n]'][[Each entry from 1 to n is evaluated in order where n is #(table).
              The entry must be a cel or string or it is ignored.]];
            };
          };
        };
      };
    };

    returns = {
      param.cel[[a new cel.]]
    };
  };

  functiondef['cel.new([w[, h[, face]]])'] {
    [[Creates a new cel.]];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param.face[[face - face or face name.]];
    };

    returns = {
      param.cel[[a new cel.]];
    };

    examples = {
      [=[
      local cel = require('cel')

      local acel = cel.new()
      local acel = cel.new(10, 10)
      local acel = cel.new(10, 10, cel.color.rgb(255, 0, 0))
      ]=];
    };
  };

  functiondef['cel.installdriver(mouse, keyboard)'] {
    --TODO document the driver interface
    [[Installs the driver for the Cel libarary.]];
    [[Only one driver is allowed to be installed, installdriver will raise an error if called more than once.]];
    [[See ??? for a detailed documentation of the driver interface.]];

    params = {
      param.table {
        name = 'mouse';
        tabledef {
          [[a table that maps the platform mouse buttons and states to Cel names]];
          key.buttons {
            key.left[[left mouse button]];
            key.right[[right mouse button]];
            key.middle[[middle mouse button]];
          };
          key.states {
            key.unknown[[indicates that Cel does not know if a mouse button is pressed]];
            key.normal[[the mouse button is not pressed]];
            key.pressed[[the mouse button is pressed]];
          };
          key.wheeldirection {
            key.up[[up wheel direction is away from the user.]];
            key.down[[down wheel direction is towards the user.]];
          };
        };
      };

      param.table {
        name = 'keyboard';
        tabledef {
          [[a table that maps the platform key codes and states to Cel names]];
          key.keys {
            --TODO define these
            key.A[[A key]];
          };
          key.states {
            key.unknown[[indicates that Cel does not know if a key is pressed]];
            key.normal[[the key is not pressed]];
            key.pressed[[the key is pressed]];
          };
        };
      };
    };

    returns = {
      param.table[[The interface between the Cel libarary and the driver.]]
    };
  };

  functiondef['cel.newmetacel(name)'] {
    --TODO explain metacels in more detail, see metacel section for this
    [[Returns a new copy of the 'cel' metacel.  A metacel defines a new type of cel.]];
    [[The metacel defines the behavior of a cel. The behavior can be changed by eclipsing(overriding) existing
    metacel functions or defining new ones.]];
    [[The metatable at metacel.metatable defines the interface of a cel created by the metacel.  Typically after a
    new metacel is created new functions are added to the metatable to expose additional functionality.]];
    [[When a new metacel is created a face is created for the metacel if one does not already exist.]];
    params = {
      param.string[[name - The name of the new metacel.]];
    };

    returns = {
      param.metacel[[A new metacel with the specified name, with the same entries as the original metacel 
        (excluding metacel.metatable). The metatable entry is a copy of orginal metacel.metatable with the same
        entries (excluding __index which is redefined for the new metatable).]];
      param.table[[The metatable that is assigned to cels created with the metacel.  This is also an entry 
        in metacel (metacel.metatable).]];
    };
  };

  functiondef['cel.loadfont([name[, size]])'] {
    [[Returns a new or existing font.]];
    [[If the font already exists it is returned, otherwise driver.loadfont(name, size) will
    be invoked to load the font.  If driver.loadfont(name, size) fails it is called again, with 'default' for the font
    name.]];
    [[The driver may choose to not honor the requested name or size]];

    params = {
      param.any {
        name='name';
        [[A string that specifies the font name. The driver will interpert the name.]];

        list {
          header=[[name is interpreted by the driver, the driver must implement the following names.]];
          key.code[[A font suitable for displaying lua source code.]];
          key.monospace[[A monospace font, like courier]];
          key.serif[[A serif font, like times new roman]];
          key.sansserif[[A sansserif font, like arial]];
          key.default[[The driver defined default font face]];
        };
      };
      param.number[[size - the size (in driver specified units) of the font.]];
    };

    returns = {
      param.font[[a new or existing font. If the name is nil, the default font is loaded(defined by driver),
      if size is nil the default size is used(defined by driver)]];
    };
  };

  functiondef['cel.getlinker(name)'] {
    [[Returns the linker function associated with the given name.]];
    params = {
      param.string[[name - the name of the linker function.]];
    };

    returns = {
      param.linker[[a linker function.]];
    };
  };

  functiondef['cel.addlinker(name, linker)'] {
    [[Associates the given linker function to the given name]];
    [[If the given name is already associated to a linker then addlinker fails and returns false
    and an error message.]];
    params = {
      param.string[[name - the name of the linker function.]];
      param.linker[[linker - the linker function.]];
    };

    returns = {
      param.linker[[the linker function.]];
    };
  };

  functiondef['cel.composelinker(a, b)'] {
    [[Returns a linker that is composed of 2 existing linkers.]];
    [[Linker a is executed and the results are
    passed to b whose results are returned as the result of the composite linker.]]; 

    [[In other words the new linker does this:]];
    code[=[
    x, y, w, h = a(hw, hh, x, y, w, h, xval and xval[1], yval and yval[1], minw, maxw, minh, maxh)
    --enforce limits on w, h
    return b(hw, hh, x, y, w, h, xval and xval[2], yval and yval[2], minw, maxw, minh, maxh)
    ]=];

    params = {
      param.linker[[a - the first linker or linker name.]];
      param.linker[[b - the second linker or linker name.]];
    };

    returns = {
      param.linker[[a linker function that takes a table for xval and yval.]];
    };
  };

  functiondef['cel.rcomposelinker(a, b)'] {
    [[Returns a linker that is composed of 2 existing linkers. This is a recursive composition.]];
    [[Linker a is executed and the results represent a virtual host cel, linker b is called
    with the w and h of the virtual host and x, y translated to the position of the virtual host.  
    The results from b are translated back to the real host space and returned.]];

    [[In other words the new linker does this:]];
    code[=[
    local vhx, vhy, vhw, vhh = a(hw, hh, x, y, w, h, xval and xval[1], yval and yval[1], minw, maxw, minh, maxh)
    x, y, w, h = b(vhw, vhh, x - vhx, y - vhy, w, h, xval and xval[2], yval and yval[2], minw, maxw, minh, maxh)
    return x + vhx, y + vhy, w, h
    ]=];

    params = {
      param.linker[[a - the first linker or linker name.]];
      param.linker[[b - the second linker or linker name.]];
    };

    returns = {
      param.linker[[a linker function that takes a table for xval and yval.]];
    };
  };

  functiondef['cel.timer()'] {
    [[A millisecond timer that begins at 0 and, is periodically increased by the driver.]];
    [[The value of the timer will remain fixed (even if multiple milliseconds elapse) until the driver 
    updates it.  For any event the timer will remain fixed until all immediate processing
    for the event is completed.]];

    returns = {
      param.number[[milliseconds.]];
    };
  };

  functiondef['cel.iscel(value)'] {
    [[Returns true if value is a cel.]];
    [[Returns false if value is not a cel.]];

    params = {
      param.any[[value - value to test.]];
    };
    returns = {
      param.boolean[[true if value is a cel, else false.]];
    };
  };

  functiondef['cel.tocel(value[, host])'] {
    [[Returns value if value is a cel.]];
    [[Returns a label (or host defined) cel if value is a string.]];

    params = {
      param.any[[value - value to create cel from.]];
      param.cel[[host - host cel to intepret value.]];
    };
    returns = {
      param.cel[[A cel or nil.]];
    };
  };

  functiondef['cel.doafter(ms, task)'] {
    [[Executes function <em>task</em> after <em>ms</em> milliseconds.]];
    [[Elapsed milliseconds is based on cel.timer().]];

    params = {
      param.number[[ms - minimum number of milliseconds to wait before executing task.
      If ms is 0, then task is executed on the next driver tick.]];
      param['function'][[task - task function.  If task returns a number then it is rescheduled
      to run after (return value) milliseconds.]];
    };
    returns = {
      param['function'][[task - task function.]];
    };
  };

  functiondef['cel.translate(from, x, y, to)'] {
    [[Given a point relative to cel from returns the point relative to cel to.]]; 
    [[Returns nil if to is not a host of from.]];

    params = {
      param.cel[[from - a cel.]];
      param.number[[x - x coordinate of point relative to cel from.]];
      param.number[[y - y coordinate of point relative to cel from.]];
      param.cel[[to - a host cel of from.]];
    };
    returns = {
      param.number[[x coordinate of point relative to cel to.]];
      param.number[[y coordinate of point relative to cel to.]];
    };
  };

  functiondef['cel.getface(metacelname[, name])'] {
    [[Returns a face for the specified metacel.]];
    [[If name is present the face registered with name for the specified metacel is returned.]];

    code[=[
    local celface = cel.getface ('cel')
    local buttonface = cel.getface('button')
    ]=];

    params = {
      param.string[[metacelname - name of the metacel.]];
      param.any[[name - registered name of the face.]];
    };

    returns = {
      param.face[[the face or nil if a name was given but no face was registered with that name.]];
    };
  };


  functiondef['cel.color.rbgtohsl(r, g, b)']{
    'Takes an rgb triplet and returns and hsl triplet';
  };
  functiondef['cel.color.hsltorgb(h, s, l)']{ 
    'Takes an rgb triplet and returns and hsl triplet';
  };
  functiondef['cel.color.hsl(h, s, l, a)']{ 
    'Takes hsl triplet and normalized alpaha and returns a color';
  };
  functiondef['cel.color.rgb(r, g, b, a)']{ 
    'Takes rgb triplet and normalized alpaha and returns a color';
  };
  functiondef['cel.color.rgb8(r, g, b, a)']{ 
    'Takes rgb8 triplet and alpaha and returns a color';
  };
  functiondef['cel.color.tohsl(color)']{
    'Takes a color and returns h, s, l, a';
  };
  functiondef['cel.color.torgb(color)']{ 
    'Takes a color and returns r, g, b, a';
  };
  functiondef['cel.color.torgb8(color)']{ 
    'Takes a color and returns r8, g8, b8, a8';
  };
  functiondef['cel.color.tint(r, color)']{ 
  };
  functiondef['cel.color.shade(r, color)']{ };

  functiondef['cel.flows.linear()'] {
  };

  functiondef['cel.describe()'] {
    [[Returns a table that describes the root cel.]];
    [[This description table is used to render the cels.]];
    [[If the description has not changed the most recently produced description is returned.]];
  
    returns = {
      param.table {
        [[a table describing the root cel.]];
      },

      param.table {
        [[a table with metadata of this description.]];
        tabledef {
          code[=[
          {
            count = number,
            timer = number,
            updaterect = {
              l = number,
              r = number,
              t = number,
              b = number,
            },
          }
          ]=];

          param.number[[count - a counter that starts at 1 and is incremented when a new description is produced.]];
          param.number[[timer - the value of cel.timer() when this description was produced.]];
          param.table {
            name='updaterect';
            [[defines a rectangle in absolute coordinates, defining the area that has a different description 
            from the previous description.]];
            tabledef {
              param.number[[l - The left of the rectangle.]];
              param.number[[r - The right of the rectangle.]];
              param.number[[t - The top of the rectangle.]];
              param.number[[b - the bottom of the rectangle.]];
            };
          };
        }; 
      };

      param.boolean[[true if the root description is new.]];
    };
  };

  functiondef['cel.printdescription(description[, metadata])'] { 
    [[Prints a description to stdout.]];
    
    params = {
      param.table[[description - description obtained from cel.describe().]];
      param.table[[metadata - metadata obtained from cel.describe().]];
    };
  };

  functiondef['cel.trackmouse(tracker)'] { 
    [[Send all mouse events to tracker.]];
   

    params = {
      param['function'] {
        name='tracker';    
        [[Called when a mouse event occurs. Return false to stop tracking. The tracker is called after mouse picking is done 
        and before any cel:onmouse[action]() functions.]];    
        callbackdef["tracker('move', x, y)"] {
          params = {
            param.string[[action - 'move']];
            param.number[[x - The x position of the mouse relative to the cel with mouse focus when the event was created.]];
            param.number[[y - The y position of the mouse relative to the cel with mouse focus when the event was created.]];
          };
        };
        callbackdef["tracker('down', button, x, y)"] {
          params = {
            param.string[[action - 'down']];
            param.any[[button - The mouse button that was pressed down.  A value in cel.mouse.buttons.]];
            param.number[[x - The x position of the mouse relative to the cel with mouse focus when the event was created.]];
            param.number[[y - The y position of the mouse relative to the cel with mouse focus when the event was created.]];
          };
        };
        callbackdef["tracker('up', button, x, y)"] {
          params = {
            param.string[[action - 'up']];
            param.any[[button - The mouse button that was released.  A value in cel.mouse.buttons.]];
            param.number[[x - The x position of the mouse relative to the cel with mouse focus when the event was created.]];
            param.number[[y - The y position of the mouse relative to the cel with mouse focus when the event was created.]];
          };
        };
        callbackdef["tracker('wheel', direction, x, y)"] {
          params = {
            param.string[[action - 'wheel']];
            param.any[[direction - cel.mouse.wheeldirection.up or cel.mouse.wheeldirection.down.]];
            param.number[[x - The x position of the mouse relative to the cel with mouse focus when the event was created.]];
            param.number[[y - The y position of the mouse relative to the cel with mouse focus when the event was created.]];
          };
        };
      };
    };
  };


  functiondef['cel.newnamespace(N)'] { 
    [[Creates a namespace.  When you extend the Cel library by adding new metacels or other 
    functionality it should be done with a namespace.]];
    
    params = {
      param.table[[N - a table that represents the namespace.]];
    };

    returns = {
      param.table[[N]];
    };
  };

  --The name of celdef is the name of its metacel
  celdef['cel'] {
    [[The primary building block of the cel library.]];
    [[The name cel is short for control element.]];
    [[The functions and behavior defined by a cel are shared by all cels.]];

    functiondef['cel:link(host[, x[, y[, option]]])'] {
      [[Links a cel to a host cel.]];
      [[This is a convenience function for]];
      code[=[
      cel:link(host, nil, x, y, option)
      ]=];

      params = {
        param.cel[[host - cel to link to]];
        param.number[[x - x position of the cel relative to host]];
        param.number[[y - y position of the cel relative to host]];
        param.any[[option - Indicates to the host how the link should be made.
                            The meaning of this is dictated by the host.]];
      };

      returns = {
        param.cel[[self]];
      };
    };

    functiondef['cel:link(host[, linkertable[, option]])'] {
      [[Links a cel to a host cel.]];
      [[This is a convenience function for]];
      code[=[
      cel:link(host, linkertable[1], linkertable[2], linkertable[3], option)
      ]=];

      params = {
        param.cel[[host - cel to link to]];
        param.table {
          name='linkertable';
          [[an array that contains arguments passed to cel:link(host, linker, xval, yval, option).]];
          tabledef {
            param.linker[[[1] - linker function or name passed to cel:link(host, linker, xval, yval, option).]];
            param.any[[[2] - xval param passed to cel:link(host, linker, xval, yval, option)]];
            param.any[[[3] - yval param passed to cel:link(host, linker, xval, yval, option)]];
          };
        };
      };

      returns = {
        param.cel[[self]];
      };
    };

    functiondef['cel:link(host[, linker[, xval[, yval[, option]]]])'] {
      [[Links a cel to a host cel.]];
      [[The linker function is applied before this function returns]];

      [[If the cel is already linked to a different host then the cel is unlinked before attempting to link to the
      new host.]];
      [[When a cel is linked, the host metacel may retarget the host to another host cel and may also overrule any
      of the other parameters via the __link metacel method.]];

      params = {
        param.cel[[host - cel to link to]];
        param.linker[[linker - linker function, if nil xval and yval specify x,y position of cel.]];
        param.any[[xval - xval param passed to linker]];
        param.any[[yval - yval param passed to linker]];
        param.any[[option - Indicates to the host how the link should be made.
                            The meaning of this is dictated by the host.]];
      };

      returns = {
        param.cel[[self]];
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

        --links acel to host at 10(left), 50(top)
        acel:link(host, 10, 50)
        ]==],

        [==[
        local cel = require 'cel'
        local host = ...

        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

        --links acel to host and acel is centered using the built in linker 'center'.
        acel:link(host, 'center') 
        ]==],

        [==[
        local cel = require 'cel'
        local host = ...
        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

        --links acel to host and acel is centered using a custom linker.
        function center(hw, hh, x, y, w, h)
          return (hw - w)/2, (hh - h)/2, w, h
        end
         
        acel:link(host, center)
        ]==],

        [==[
        local cel = require 'cel'
        local host = ...
        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

        --link acel to a sequence using the option parameter to specify the index in the sequence
        local sequence = cel.sequence.y {
          'a', 'b', 'c', 'd'
        }
         
        acel:link(sequence, nil, nil, nil, 3)

        --link sequence to host
        sequence:link(host)
        ]==],

        [==[
        local cel = require 'cel'
        local host = ...
        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

        --link acel to a sequence off-centered 10 to the left.
        local sequence = cel.sequence.y {
          'a', 'b', 'c', 'd'
        }

        acel:link(sequence, 'center', -10, nil, 3)
        
        --link sequence to host 'edges' makes it fill the host
        sequence:link(host, 'edges')

        --a vertical center line to make offset obvious
        cel.new(1, 1, cel.color.rgb(255, 0, 0)):link(host, 'center.height')
        ]==],
      };
    };

    functiondef['cel:relink([linker[, xval[, yval]]]'] {
      [[Changes the linker, xval and yval parameters of a linked cel.]];
      [[The cel remains linked to the same host. When a cel is relinked the host metacel may
      overrule the linker, xval and yval.]];

      params = {
        param.cel[[host - cel to link to]];
        param.linker[[linker - linker function or name]];
        param.any[[xval - xval param passed to linker]];
        param.any[[yval - yval param passed to linker]];
      };

      returns = {
        param.cel[[self]];
        param.boolean[[false if relink failed, otherwise true]];
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

        acel:link(host, 'center')

        --changes linker and xval and yval
        function acel:onmousein()
          self:relink('edges', 50, 50)
        end

        --changes only xval and yval by passing in current linker
        function acel:onmouseout()
          self:relink(self.linker, 100, 100)
        end
        ]==],
      };
    };

    functiondef['cel:unlink()'] {
      [[unlinks a cel from its host.]];
      [[If the cel has focus (see cel.hasfocus) when it is unlinked then focus is given to its host via grabfocus.]];
      [[If the mouse is in the cel when it is unlinked then a new cel is picked. (see mouse.pick).]];
      [[If the cel has the mouse trapped (see cel.trapmouse and cel.hasmousetrapped) when it is 
        unlinked then the mouse is released (see cel.releasemouse).]];

      returns = {
        param.cel[[self]];
      };
    };

    functiondef['cel:move(x[, y[, w[, h]]])'] {
      [[changes position(x, y) and dimensions(w, h) of a cel.]];
      [[A cel's position and dimension cannot be modified directly.  For example acel.x = 10 will not change the x 
      position of acel (acel.x will return 10 but acel:pget('x') will return acels true x position)]];

      params = {
        param.number[[x - x position of self relative to host. Defaults to self.x if nil]];
        param.number[[y - y position of self relative to host. Defaults to self.y if nil]];
        param.number[[w - width of the cel. Defaults to self.w if nil]];
        param.number[[h - height of the cel. Defautls to self.h if nil]];
      };

      returns = {
        param.cel[[self]];
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133)):link(host)

        --update cel position
        acel:move(10, 10)
        ]==];

        [==[
        local cel = require 'cel'
        local host = ...

        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133)):link(host)

        --update cel dimensions 
        acel:move(nil, nil, host.w, host.h)
        ]==];
      };
    };

    functiondef['cel:moveby(x[, y[, w[, h]]])'] {
      [[changes position(x, y) and dimensions(w, h) of a cel relative to current values.]];
      [[acel:moveby(x, y, w, h) is a shortcut for move(acel.x + x, acel.y + y, acel.w + w, acel.h + h), and is 
      slightly more effecient.]];

      params = {
        param.number[[x - add to self.x. Defaults to 0 if nil.]];
        param.number[[y - add to self.y. Defaults to 0 if nil.]];
        param.number[[w - add to self.w. Defaults to 0 if nil.]];
        param.number[[h - add to self.h. Defaults to 0 if nil.]];
      };

      returns = {
        param.cel[[self]];
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133)):link(host)

        --update cel position
        acel:moveby(10, 10)
        acel:moveby(10, 10)
        ]==];

        [==[
        local cel = require 'cel'
        local host = ...

        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133)):link(host)

        --grow cel 
        acel:moveby(nil, nil, 10, 10)

        --grow cel width
        acel:moveby(nil, nil, 20)
        ]==];
      };
    };

    functiondef['cel:resize(w[, h])'] {
      [[Changes dimensions(w, h) of a cel.]];
      [[resize(w, h) is a shortcut for move(nil, nil, w, h)]];

      params = {
        param.number[[w - width of the cel. Defaults to self.w if nil]];
        param.number[[h - height of the cel. Defautls to self.h if nil]];
      };

      returns = {
        param.cel[[self]];
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133)):link(host)

        --resize cel 
        acel:resize(host.w, host.h)
        ]==];
      };
    };

    functiondef['cel:raise()'] {
      [[Moves the cel to the front(top of the stack).]];
      [[When a cel is linked it is put in front(top of the stack), unless the host metacel
      changes that behavior via __link.  So acel:unlink():link(host) would put it at the
      top, but unlinking has side-effects such as losing focus, whereas raise does not.]];
      [[The default formation of a cel is a stack, its links have a z-order in which the front
      link is at the top of the stack and the back link is at the bottom.]];
      [[If the host cel does not use a stack formation, such as a sequence, then raise has no effect.]];
      [[raise has no effect if the cel is already in front or is not linked.]];

      returns = {
        param.cel[[self]];
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local a = cel.grip.new(100, 100, cel.color.rgb(233, 133, 133))
        local b = cel.grip.new(100, 100, cel.color.rgb(133, 233, 133))
        local c = cel.grip.new(100, 100, cel.color.rgb(133, 133, 233))

        a:grip(a) b:grip(b) c:grip(c)

        a.ongrab = a.raise
        b.ongrab = b.raise
        c.ongrab = c.raise

        a:link(host, 10, 10)
        b:link(host, 20, 20)
        c:link(host, 30, 30)
        ]==],
      };
    };

    functiondef['cel:sink'] {
      [[Moves the cel to the back(bottom of the stack).]];
      [[sink has no effect if the cel is already on bottom(the back) or is not linked.]];
      [[If the host cel does not use a stack formation, such as a sequence, then sink has no effect.]];

      [[See cel:raise]];

      returns = {
        param.cel[[self]];
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local a = cel.grip.new(100, 100, cel.color.rgb(233, 133, 133))
        local b = cel.grip.new(100, 100, cel.color.rgb(133, 233, 133))
        local c = cel.grip.new(100, 100, cel.color.rgb(133, 133, 233))

        a:grip(a) b:grip(b) c:grip(c)

        a.ongrab = a.raise
        b.ongrab = b.raise
        c.ongrab = c.raise

        a.onrelease = a.sink
        b.onrelease = b.sink
        c.onrelease = c.sink

        a:link(host, 10, 10)
        b:link(host, 20, 20)
        c:link(host, 30, 30)
        ]==],
      };
    };

    functiondef['cel:islinkedto(host)'] {
      [[Returns a number if host is (a) host of the cel.]];

      params = {
        param.cel[[host - host cel.]];
      };

      returns = {
        param.number[[1 indicates that host is the direct host of the cel, > 1 indicates that
          host is (a) host of the cel.  The value represents how far up the cel tree the host 
          is relative to the cel.  nil if the cel is not linked to the host]];
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local a = cel.new(100, 100, cel.color.rgb(233, 133, 133))
        local b = cel.new(100, 100, cel.color.rgb(133, 233, 133))
        local c = cel.new(100, 100, cel.color.rgb(133, 133, 233))
        local label = cel.label.new('nil')

        local function onmousemove(acel)
          if 1 == acel:hasfocus(cel.mouse) then
            label:settext(string.format('islinkedto host(%d) root(%d)', acel:islinkedto(host), acel:islinkedtoroot())) 
          end
        end

        a.onmousemove = onmousemove
        b.onmousemove = onmousemove
        c.onmousemove = onmousemove

        a:link(b:link(c:link(host, 'edges', 20, 20), 'edges', 40, 40), 'edges', 40, 40)
        label:link(host)
        ]==],
      };
    };

    functiondef['cel:islinkedtoroot()'] {
      [[Returns a number if the root cel is (a) host of the cel.]];
      [[If a cel is linked to the root cel then it can receive mouse and keyboard events and be rendered.]];

      returns = {
        param.number[[1 indicates that the root cel is the direct host of the cel, > 1 indicates that
          host is (a) host of the cel.  The value represents how far up the cel tree the root cel 
          is relative to the cel.  nil if the cel is not linked to the root cel.]];
      };
    };

    functiondef['cel:hasfocus([inputsource])'] {
      [[Check if a cel has focus.]];

      params = {
        param.inputsource[[inputsource - Defaults to cel.keyboard if nil.  Can also be cel.mouse.]];
      };

      returns = {
        param.number[[An integer >= 1 if an event generated by the inputsource will be delivered to the cel.
          nil if the cel does not have focus. The value indicates the order in which a cel will
          receive events. 1 means the cel will receive events first.  If the inputsource is a mouse then
          1 means the mouse cursor is touching the cel, >1 indicates the mouse cursor is in the cel.]];
      };
    };

    functiondef['cel:takefocus([inputsource])'] {
      [[Gives a cel the focus.  This has no effect for cel.mouse.]];
      [[This has no effect if self:hasfocus(inputsource) == 1.]];
      [[The onfocus(inputsource, false) event is sent to all cels that lose focus followed by onfocus(inputsource, true)
      for each cel that gains focus.  This means that there is opportunity for another cel to take focus before
      takefoucs returns.]];
      [[The focus of the mouse is controlled by moving the mouse cursor, takefocus will have no effect on the mouse 
      focus.]];

      params = {
        param.inputsource[[inputsource - Defaults to cel.keyboard if nil.]];
      };

      returns = {
        param.number[[self:hasfocus(inputsource)]];
      };
    };

    functiondef['cel:trapmouse([onescape])'] {
      [[Ensures all mouse events will be delivered to the cel.]];
      [[When the mouse is not trapped by a cel it will get mouse events only if it has the mouse focus.]];
      [[Only one cel at a time can have the mouse trapped.]];
      [[The root cel always traps the mouse.]];
      
      list {
        header = 'trapmouse will fail for the following reasons:';
        'The cel does not have the focus of the mouse.';
        'The mouse is already trapped by a cel that is linked to the cel.';
        'The cel is unlinked from the root cel.';
        'When self:freemouse() is called.';
      };

      [[Trapping the mouse changes how mouse focus is determined in the following way.  
        Only the trapping cel and cels linked to it get and lose mouse focus.  
        The hosts of the trapping cel will not lose mouse focus for the duration of the trap.
        More precisely the picking algorithm (responsible for setting the mouse focus and raising onmousein
        and onmouseout events for the mouse) begins at the cel that has the mouse trapped.  If the mouse is not
        in the trapping cel then onmouseout will be raised (if it was in the cel previously) and picking stops. 
        If the mouse is in the trapping cel the onmousein will be raised (if it was not in the cel previously)
        and picking will continue recursively checking the links of the trapping cel.
      ]];
      [[A cel cannot gain focus of the mouse unless it is linked to a cel that has trapped the mouse.]];
      [[When the mouse is trapped it is not constrained to the cel that trapped it]];

      params = {
        param.cel[[self - self]];
        param['function'] {
          name='onescape';
          [[If present this function is called when the mouse is no longer trapped by the cel.]];
          callbackdef['onescape(cel, mouse, reason)'] {
            params = {
              param.cel'cel - cel that had the mouse trapped.';
              param.mouse'mouse - cel.mouse.';
              param.string'reason - an explanatory string.';
            };
          };
        };
      };

      returns = {
        param.boolean[[true if the cel has sucessfully trapped the mouse, false otherwise.
          If false then onescape will be called with the reason prior to returning.]];
      };
    };

    functiondef['cel:freemouse([reason])'] {
      [[Releases the mouse if the cel has the mouse trapped. On return the root cel will have the mouse trapped
      unless the onescape callback traps the mouse elsewhere.]];
      [[When the mouse is freed onescape (given when the mouse was trapped by the cel) is called before returning.
      onescape may retrap the mouse.]];

      params = {
        param.string[[reason - An explanatory string passed to the onescape callback given when the mouse 
        was trapped.]];
      };

      returns = {
        param.cel[[self]];
      };
    };

    functiondef['cel:hasmousetrapped()'] {
      description = [[Returns true if the cel has the mouse trapped.]];

      returns = {
        param.boolean[[true if the cel has trapped the mouse, by calling trapmouse() false otherwise.]];
      };
    };

    functiondef['cel:disable()'] {
      [[Disables the cel preventing user input.]];
      [[Any links will also be prevented from receiving user input.]];
      [[If the cel has focus (see cel.hasfocus) when it is unlinked then focus is given to its host via takefocus.
        If the mouse is in the cel when it is disabled then a new cel is picked. (see mouse.pick).]];
      [[If the cel has the mouse trapped (see cel.trapmouse and cel.hasmousetrapped) when it is 
        disabled then the mouse is released (see cel.releasemouse).]];

      returns = {
        param.cel[[self]];
      };
    };

    functiondef['cel:enable()'] {
      [[Enables the cel.]];
      [[A cel is enabled until cel:disable() is called.]];

      returns = {
        param.cel[[self]];
      };
    };

    functiondef['cel:pget(...)'] {
      [[Get multiple properties of a cel by name.]];
      [[This can be more effecient when you need to get multiple properties, but less effecient for 1.]];

      params = {
        param.string[['x' - cel.x]];
        param.string[['y' - cel.y]];
        param.string[['w' - cel.w]];
        param.string[['h' - cel.h]];
        param.string[['xval' - cel.xval]];
        param.string[['yval' - cel.yval]];
        param.string[['face' - cel.face]];
        param.string[['minw' - cel.minw]];
        param.string[['maxw' - cel.maxw]];
        param.string[['minh' - cel.minh]];
        param.string[['maxh' - cel.maxh]];
        --TODO list all properies
      };

      returns = {
        param['...'][[... - the corresponding value for each property name passed in.]];
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local document = cel.document.new()
        local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

        document:put(acel)
        document:write(string.format('x, y, w, h = %d, %d, %d, %d', acel:pget('x', 'y', 'w', 'h')))

        document:link(host, 'edges')
        ]==],
      };
    };

    functiondef['cel:flow(flowfunction, x, y, w, h[, update[, finalize]])'] {
      [[moves the cel, but 1 or more intermediate states can be injected by the flow callback.]];
      [[If flowfunction is nil or not key to a flowfunction defined in the cel's face then update is called with the 
      final position followed by a call to finalize.  So acel:flow(nil, x, y, w, h) has the same effect as 
      acel:move(x, y, w, h).
      ]];

      [[When a flow starts the flowfunction is called to get its initial position which is passed to update().  
      Thereafter flowfunction/update are called when the cel driver moves cel.timer() forward.]];  

      params = {
        param['function,key'] {
          name='flowfunction';
          [[The flow function can be either a function or key to a flowfunction defined in the cel's face.]];
          callbackdef['flowfunction(context, ox, x, oy, y, ow, w, oh, h)'] {
            [[a function that produces intermediate states]]; 
            params = {
              param.table {
                name='context';
                tabledef {
                  [[Storage for flow life-cycle data.  The context can also be used by the flowfunction to
                  store data.  The context is included in the drawtable of a cel, until the flow is finalized.]];

                  key.iteration[[The number of times the flowfunction has been called, initially 1,
                    incremented by 1 each time the flowfunction is called.]];
                  key.duration[[The number of milliseconds since the flow was started, initially 0]];
                  key.finalize[[initially -1, when the flow is about to be finalized this is set to
                    context.iteration]];
                };
              };
              param.number[[x - x position when flow started.]];
              param.number[[fx - x position when flow ends.]];
              param.number[[y - y position when flow started.]];
              param.number[[fy - y position when flow ends.]];
              param.number[[w - w dimension when flow started.]];
              param.number[[fw - w dimension when flow ends.]];
              param.number[[h - h dimension when flow started.]];
              param.number[[fh - h dimension when flow is ends.]];
            };

            returns = {
              param.number[[intermediate x position.]];
              param.number[[intermediate y position.]];
              param.number[[intermediate width.]];
              param.number[[intermediate height.]];
              param.boolean[[true if the flow is incomplete, if not true this signals the end of the flow.]];
            };
          };
        };
        param.number[[x - x position of self relative to host. Defaults to self.x if nil]];
        param.number[[y - y position of self relative to host. Defaults to self.y if nil]];
        param.number[[w - width of the cel. Defaults to self.w if nil]];
        param.number[[h - height of the cel. Defautls to self.h if nil]];
        param['function'] {
          name='update';    
          [[called to move the cel to a new position.  Defaults to cel.move if nil.]];    
          callbackdef['update(cel, x, y, w, h)'] {
            params = {
              param.cel[[cel - the cel]];
              param.number[[x - x position of cel.]];
              param.number[[y - y position of cel.]];
              param.number[[w - width of cel.]];
              param.number[[h - height of cel.]];
            };
          };
        };
        param['function'] {
          name='finalize';
          [[called when the flow has completed.]];
          callbackdef['finalize(cel)'] {
            params = {
              param.cel[[cel - the cel]];
            };
          };
        };
      };

      returns = {
        param.cel[[self]];
      };

      examples = {
        [==[
        local cel = require 'cel'
        local host = ...

        local button = cel.button.new(100, 100):link(host, 'center'):relink()

        local function lerp(a, b, p)
          return a + p * (b -a)
        end

        local duration = 1000

        local function linearflow(context, ox, x, oy, y, ow, w, oh, h)
          if context.duration >= duration then return x, y, w, h end
          local dt = context.duration/duration
          x = lerp(ox, x, dt)
          y = lerp(oy, y, dt) 
          w = lerp(ow, w, dt)
          h = lerp(oh, h, dt)
          return x, y, w, h, true
        end
        
        function button:onclick()
          local toggle = button.onclick
          local x, y, w, h = button:pget('x', 'y', 'w', 'h')
          function button:onclick()
            self:flow(linearflow, x, y, w, h)
            button.onclick = toggle
          end
          self:flow(linearflow, 
                    math.random(0, 200),
                    math.random(0, 200),
                    math.random(50, 200),
                    math.random(50, 200))
        end

        ]==];
      };
    };

    functiondef['cel:reflow(flowfunction, x, y, w, h)'] {
      [[If the cel is flowing reflow will update the final destination to 
      (x, y, w, h).]];
      [[The next time the flowfunction runs it will see the new destination.]];

      params = {
        param.flowfunction[[flowfunction - if not nil the cel reflows only if this is the current flowfunction
        for the cel.]];
        param.number[[x - x position of self relative to host. Defaults to self.x if nil]];
        param.number[[y - y position of self relative to host. Defaults to self.y if nil]];
        param.number[[w - width of the cel. Defaults to self.w if nil]];
        param.number[[h - height of the cel. Defautls to self.h if nil]];
      };

      returns = {
        param.cel[[self]];
      };
    };

    functiondef['cel:endflow([flowfunction])'] {
      [[If the cel is flowing, forces the flow to finalize.]];  
      [[The current flow function is called with context.finalize set to context.iteration, and the cel
      is updated and the flow is finalized]];

      params = {
        param.flowfunction[[flowfunction - If present the flow is finalized iff the current flow function matches
                            this one.  see cel:flow for description]];
      };
      returns = {
        param.cel[[self]];
      };
    };

    --TODO rename to flowrelink
    functiondef['cel:flowrelink(flowfunction, linker, xval, yval[, update[, finalize]])'] {
      [[relinks the cel at the end of the flow via cel:relink(linker, xval, yval).]];
      [[The current linker is removed before the flow begins.]];
      [[The final x, y, w, h is calculated before each iteration based on the x, y, w, h values if the linker
      were applied at that point in the iteration]];
      [[If flowfunction is nil or not key to a flowfunction defined in the cel's face then update is called with the 
      final position followed by a call to finalize.  So acel:flowrelink(nil, linker, xval, yal) has the same
      effect as acel:relink(linker, xval, yval).
      ]];

      [[When a flow starts the flowfunction is called to get its initial position which is passed to update().  
      Thereafter flowfunction/update are called when the cel driver moves cel.timer() forward.]];  

      params = {
        param['flowfunction'] {
          name='flowfunction';
          [[The flow function can be either a function or key to a flowfunction defined in the cel's face.]];
          callbackdef['flowfunction(context, ox, x, oy, y, ow, w, oh, h)'] {
            [[a function that produces intermediate states]]; 
            params = {
              param.table {
                name='context';
                tabledef {
                  [[Storage for flow life-cycle data.  The context can also be used by the flowfunction to
                  store data.  The context is included in the drawtable of a cel, until the flow is finalized.]];

                  key.iteration[[The number of times the flowfunction has been called, initially 1,
                    incremented by 1 each time the flowfunction is called.]];
                  key.duration[[The number of milliseconds since the flow was started, initially 0]];
                  key.finalize[[initially -1, when the flow is about to be finalized this is set to
                    context.iteration]];
                };
              };
              param.number[[x - x position when flow started.]];
              param.number[[fx - x position when flow ends.]];
              param.number[[y - y position when flow started.]];
              param.number[[fy - y position when flow ends.]];
              param.number[[w - w dimension when flow started.]];
              param.number[[fw - w dimension when flow ends.]];
              param.number[[h - h dimension when flow started.]];
              param.number[[fh - h dimension when flow is ends.]];
            };

            returns = {
              param.number[[intermediate x position.]];
              param.number[[intermediate y position.]];
              param.number[[intermediate width.]];
              param.number[[intermediate height.]];
              param.boolean[[true if the flow is incomplete, if not true this signals the end of the flow.]];
            };
          };
        };
        param.linker[[linker - linker function or name]];
        param.any[[xval - xval param passed to linker]];
        param.any[[yval - yval param passed to linker]];
        param['function'] {
          name='update';    
          [[called to move the cel to a new position.  Defaults to cel.move if nil.]];    
          callbackdef['update(cel, x, y, w, h)'] {
            params = {
              param.cel[[cel - the cel]];
              param.number[[x - x position of cel.]];
              param.number[[y - y position of cel.]];
              param.number[[w - width of cel.]];
              param.number[[h - height of cel.]];
            };
          };
        };
        param['function'] {
          name='finalize';
          [[called when the flow has completed.]];
          callbackdef['finalize(cel)'] {
            params = {
              param.cel[[cel - the cel]];
            };
          };
        };
      };

      returns = {
        param.cel[[self]];
      };
    };

    functiondef['cel:getflow(key)'] {
      [[Returns the flow function defined in the cel's face.flow table with specified key.]];
      
      params = {
        param.string[[name - the key name in face.flow]]; 
      };
      returns = {
        param['function'][[If a function was found in face.flow[key] otherwise nil.]];
      };
    };

    functiondef['cel:isflowing([flow])'] {
      [[Returns true if the cel has begun to flow and not finished.]];
      
      params = {
        param.string[[flow - if present returns true only if this flow function is used.]]; 
      };
      returns = {
        param.boolean[[true if the cel is flowing, if the cel is flowing but is not using the specified
        flow function the false, if the cel is not flowing then false.]];
      };
    };

    functiondef['cel:flowvalue(flowfunction, a, b, update, finalize)'] {
      [[TODO, probably will be removed when overhauling flows]];
    };

    propertydef['cel.x'] {
      [[The x coordinate of the topleft of the cel.]];
    };
    propertydef['cel.y'] {
      [[The y coordinate of the topleft of the cel.]];
    };
    propertydef['cel.w'] {
      [[The width of the cel.]];
    };
    propertydef['cel.h'] {
      [[The height of the cel.]];
    };
    propertydef['cel.minw'] {
      [[The minimum width of the cel.]];
    };
    propertydef['cel.maxw'] {
      [[The maximum width of the cel.]];
    };
    propertydef['cel.minh'] {
      [[The minimum height of the cel.]];
    };
    propertydef['cel.maxh'] {
      [[The maximum height of the cel.]];
    };
    propertydef['cel.linker'] {
      [[The linker function of the cel.]];
    };
    propertydef['cel.xval'] {
      [[The linker function xval.]];
    };
    propertydef['cel.yval'] {
      [[The linker function yval.]];
    };
    propertydef['cel.l'] {
      [[The left of the cel (same as cel.x).]];
    };
    propertydef['cel.r'] {
      [[The right of the cel (cel.x + cel.w).]];
    };
    propertydef['cel.t'] {
      [[The top of the cel (same as cel.y).]];
    };
    propertydef['cel.b'] {
      [[The bottom of the cel (cel.y + cel.h).]];
    };
    propertydef['cel.X'] {
      [[The absolute x coordinate of the topleft of the cel.]];
      [[If cel:islinkedtoroot() is false this is cel.x]];
    };
    propertydef['cel.Y'] {
      [[The absolute y coordinate of the topleft of the cel.]];
      [[If cel:islinkedtoroot() is false this is cel.y]];
    };

    eventdef['cel:onresize(ow, oh)'] {
      [[Triggered by cel width or height changing.]];

      params = {
        param.number[[ow - The width of the cel before it was resized.]];
        param.number[[oh - The height of the cel before it was resize.]];
      };
    };

    eventdef['cel:onmousemove(x, y)'] {
      [[Triggered by mouse cursor moving when the mouse is in the cel, or trapped by the cel.]];

      params = {
        param.cel[[self - self]];
        param.number[[x - The x position of the mouse relative to the cel when the event was created.]];
        param.number[[y - The y position of the mouse relative to the cel when the event was created.]];
      };
    };

    eventdef['cel:onmousedown(button, x, y, intercepted)'] {
      [[Triggered when a mouse button is pressed when the mouse is in the cel, or trapped by the cel.]];

      params = {
        param.any[[button - The mouse button that was pressed down.  A value in cel.mouse.buttons.]];
        param.number[[x - The x position of the mouse relative to the cel when the event was created.]];
        param.number[[y - The y position of the mouse relative to the cel when the event was created.]];
        param.boolean[[intercepted - If a link of the cel saw this event and intercepted it this will be true.]];
      };

      returns = {
        param.boolean[[return true to intercept the event.]];
      };
    };

    eventdef['cel:onmouseup(button, x, y, intercepted)'] {
      [[Triggered when a mouse button is released when the mouse is in the cel, or trapped by the cel.]];

      params = {
        param.any[[button - The mouse button that was released.  A value in cel.mouse.buttons.]];
        param.number[[x - The x position of the mouse relative to the cel when the event was created.]];
        param.number[[y - The y position of the mouse relative to the cel when the event was created.]];
        param.boolean[[intercepted - If a link of the cel saw this event and intercepted it this will be true.]];
      };

      returns = {
        param.boolean[[return true to intercept the event.]];
      };
    };

    eventdef['cel:onmousewheel(direction, x, y, intercepted)'] {
      [[Triggered when the mouse wheel is moved when the mouse is in the cel, or trapped by the cel.]];

      params = {
        param.any[[direction - cel.mouse.wheeldirection.up or cel.mouse.wheeldirection.down.]];
        param.number[[x - The x position of the mouse relative to the cel when the event was created.]];
        param.number[[y - The y position of the mouse relative to the cel when the event was created.]];
        param.boolean[[intercepted - If a link of the cel saw this event and intercepted it this will be true.]];
      };

      returns = {
        param.boolean[[return true to intercept the event.]];
      };
    };

    --TODO replace with onfoucs
    eventdef['cel:onmousein()'] {
      [[Triggered when the cel gains mouse focus.]];
      [[If cel:hasfocus(cel.mouse) == 1 then the mouse cursor touches the cel.]];

      examples = {
        [==[
        local cel = require('cel')
        local host = ...

        local a = cel.new(100, 100, cel.color.rgb(244, 233, 0)):link(host, 'center')
        local b = cel.new(50, 50, cel.color.rgb(231, 0, 23))

        function a:onmousein()
          b:link(a, 'center')
        end

        function a:onmouseout()
          b:unlink()
        end
        ]==];
      };
    };

    --TODO replace with onblur
    eventdef['cel:onmouseout()'] {
      [[Triggered when the cel loses mouse focus.]];
      [[onmousein will always precede by onmouseout.]];
    };

    eventdef['cel:onkeydown(key, intercepted)'] {
      [[Triggered when a keyboard key is pressed down while the cel has the keyboard focus]];

      params = {
        param.key[[key - The keyboard key that was pressed down.  A value in cel.keyboard.keys.]];
        param.boolean[[intercepted - If a link of the cel saw this event and intercepted it this will be true.]];
      };

      returns = {
        param.boolean[[return true to intercept the event.]];
      };
    };

    eventdef['cel:onkeypress(key, intercepted)'] {
      [[Triggered when a keyboard key is pressed down while the cel has the keyboard focus, also triggered
        periodically when a keyboard key is held down while the cel has the keyboard focus]];

      params = {
        param.key[[key - The keyboard key that was pressed down.  A value in cel.keyboard.keys.]];
        param.boolean[[intercepted - If a link of the cel saw this event and intercepted it this will be true.]];
      };

      returns = {
        param.boolean[[return true to intercept the event.]];
      };
    };

    eventdef['cel:onkeyup(key, intercepted)'] {
      [[Triggered when a keyboard key is released while the cel has the keyboard focus]];

      params = {
        param.key[[key - The keyboard key that was released.  A value in cel.keyboard.keys.]];
        param.boolean[[intercepted - If a link of the cel saw this event and intercepted it this will be true.]];
      };

      returns = {
        param.boolean[[return true to intercept the event.]];
      };
    };

    eventdef['cel:onchar(char, intercepted)'] {
      [[Triggered when a character is generated by the keyboard while the cel has the keyboard focus]];

      params = {
        param.string[[char - The string representation of the character.]];
        param.boolean[[intercepted - If a link of the cel saw this event and intercepted it this will be true.]];
      };

      returns = {
        param.boolean[[return true to intercept the event.]];
      };
    };

    --TODO implement this way
    eventdef['cel:onfocus(inputsource)'] {
      [[Triggered when a cel gains focus.]];
      [[If cel:hasfocus(inputsource) == 1 the the cel is the first cel with focus.]];

      params = {
        param.inputsource[[inputsource - always cel.keyboard (for now).]];
      };
    };

    --TODO implement this way
    eventdef['cel:onblur(inputsource)'] {
      [[Triggered when a cel loses focus.]];
      [[Do not call self:takefocus() in response to onblur. That would be a good way to create an infinite loop.]];

      params = {
        param.inputsource[[inputsource - always cel.keyboard (for now).]];
      };
    };

    eventdef['cel:ontimer(value, inputsource)'] {
      [[Triggered when the Cel timer is updated.]];
      [[The cel will recieve the event if it has the focus of any inputsource.  The event
      is triggered for each inputsource focused on the cel.]];

      params = {
        param.number[[value - The value of cel.timer() when the event was triggered.]];
        param.inputsource[[inputsource - The inputsource that is focused on the cel.]];
      };

      examples = {
        [==[
        local cel = require('cel')
        local host = ...

        local list = cel.sequence.y.new(1):link(host, 'center')
        list:takefocus()

        local lastvalue = 0
        function list:ontimer(value, source)
          if source == cel.keyboard then

            if value < lastvalue + 500 then
              return
            end

            lastvalue = value
            cel.textbutton.new('timer = ' .. value):link(self, 'width')

            if list.h > host.h then
              list:remove(list:len())
              list.ontimer = nil
            end
          end
        end
        ]==];
      };
    };

    eventdef['cel:oncommand(comand, data, intercepted)'] {
      [[Triggered when a command is generated by the driver]];
      [[This event is routed to the cels with keyboard focus]];
      [[Three commands are defined and have no data associated to them:  'cut', 'copy', 'paste'. 
      Each indicates that the corresponding clipboard action should be taken.]];
      [[For any other command the driver determines what commands to send and assigns meaning to them.]];

      params = {
        param.any[[command - identifies the command.]];
        param.any[[data - data associated to the command.]];
        param.boolean[[intercepted - If a link of the cel saw this event and intercepted it this will be true.]];
      };

      returns = {
        param.boolean[[return true to intercept the event.]];
      };
    };

  };

}

