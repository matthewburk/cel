export['cel.scroll'] {
  [[Factory for the scroll metacel.]];
  list {
    header='TODO:';
    [[a nice feature would be if the layout could define additional cels to be included in the scrollbars.
    Maybe by calling a function or just linking cels directly embedded in the layout.  Would probably want
    it to be a function that could return a cel, so a unique instance could be generated for each scroll cel.]];
    [[Should scroll generate events when it is scrolled, or the subject changed, etc?  Can't think of a use case
    for this, so leaving it out for now.]];
    [[ybar and xbar are not optional in layout, the bars are the value added part of a scroll cel, the rest
    is just a linker]];

  };

  metaceldef['scroll'] {
    source = 'cel';
    factory = 'cel.scroll';

    [[A scroll is a container cel with vertical and horizontal scrollbars]];
    [[A scroll is composed of a vertical scrollbar, horizontal scrollbar, and a portal.
    The subject is the cel that is controlled by the scrollbars, and is linked to the portal.
    Additional cels can be lined to the portal, but only one will be the subject.
    ]];
      

    --composition values are cel or the metacel
    composition = {
      code[=[
        [portal] = cel
        [xbar] = scroll.bar
        [ybar] = scroll.bar
      ]=];

      params = {
        param.cel[[[portal] - scroll portal.]];
        param['scroll.bar'][[[xbar] - horizontal scrollbar.]];
        param['scroll.bar'][[[ybar] - vertical scrollbar.]];
      };
    };

    --description values description
    description = { 
      code[=[
        [portal] = cel,
        [xbar] = scroll.bar,
        [ybar] = scroll.bar,
      ]=];

      params = {
        param.cel[[[portal] - scroll portal.]];
        param['scroll.bar'][[[xbar] - horizontal scrollbar.]];
        param['scroll.bar'][[[ybar] - vertical scrollbar.]];
      };
    };

    layout = {
      [[A table defining the internal layout of a scroll cel]];
      code[=[
      stepsize --number of units to move the subject in a single step
      ybar = { --vertical scrollbar
        face --face or facename
        autohide --if true the scrollbar will hide when the portal.h >= subject.h
        size --width of the scrollbar 
        track = { 
          face --face or facename
          size --width of the track 
          link --linker, xval, yval
          slider = {
            face --face or facename
            size --width of the slider
            minsize --minimum height of the slider
          }
        }
        decbutton = {
          face --face or facename;
          size --width and height;
          link --linker, xval, yval;
        }
        incbutton = {
          face --face or facename;
          size --width and height;
          link --linker, xval, yval;
        }
      }
      xbar = { --horizontal scrollbar
        face --face or facename
        autohide --if true the scrollbar will hide when the portal.w >= subject.w
        size --height of the scrollbar 
        track {
          face --face or facename
          size --height of the track
          link --linker, xval, yval
          slider = {
            face --face or facename
            size --height of the slider
            minsize --minimum width of the slider
          }
        }
        decbutton = {
          face --face or facename;
          size --width and height;
          link --linker, xval, yval;
        }
        incbutton = {
          face --face or facename;
          size --width and height;
          link --linker, xval, yval;
        }
      }
      ]=];
    };

    __link = {
      param['?'] { name = 'default',
        [[If the scroll cel has a subject links are redirected to the subject. 
        If the scroll cel has no subject links are redirected to the portal.]];
      };
      param.string { name = "'raw'"; [[link is not redirected.]] };
      param.string { name = "'portal'"; [[link is redirected to the portal.]] };
      param.string { name = "'xbar'"; [[link is redirected to the horizontal scrollbar.]] };
      param.string { name = "'ybar'"; [[link is redirected to the vertical scrollbar.]] };
    };

    __relink = {
      [[The the scroll will ingnore subject relink parameters.  Effectively the subject cannot be relinked.]];
    };

    flows = {
      key.hidexbar[[called when the xbar is hidden.]];
      key.showxbar[[called when the xbar is unhidden.]];
      key.hideybar[[called when the ybar is hidden.]];
      key.showybar[[called when the ybar is unhidden.]];
      key.scroll[[called when the subject is scrolled.]];
    };
  };

  metaceldef['scroll.bar'] { 
    source = 'cel'; 

    [[A scroll.bar can be horizontal or vertical. It is composed of a increment button, decrement button and 
    track button.  Each of these buttons can be used to scroll the subject of the scroll cel.]];
        

    composition = {
      code[=[
        [inc] = scroll.bar.inc
        [dec] = scroll.bar.dec
        [track] = scroll.bar.track
      ]=];

      params = {
        param['scroll.bar.inc'][[[inc] - increment button.]];
        param['scroll.bar.dec'][[[dec] - decrement button.]];
        param['scroll.bar.track'][[[track] - track button.]];
      };
    };

    description = {
      [[A vertical or horizontal scrollbar.]];
      [[host is not always a scroll description because the scroll metacel can be extended.]];

      code[=[
        axis = string,
        size = integer,
        [inc] = scroll.bar.inc,
        [dec] = scroll.bar.dec,
        [track] = scroll.bar.track,
      ]=];

      params = {
        param.string[[axis - 'x' indicates a horizontal scrollbar, 'y' indicates a vertical scrollbar.]];
        param.integer[[size - height of the scrollbar for horizontal, width of the scrollbar for vertical.]];
        param['scroll.bar.inc'][[[inc] - increment button.]];
        param['scroll.bar.dec'][[[dec] - decrement button.]];
        param['scroll.bar.track'][[[track] - track button.]];
      };
    };
  };

  metaceldef['scroll.bar.track'] { 
    source = 'button'; 

    [[A scroll.bar.track is contains a slider grip.  Clicking on the track, or dragging the slider
    will scroll the scroll cels subject.]];

    composition = {
      code[=[
        [slider] = scroll.bar.slider
      ]=];

      params = {
        param['scroll.bar.slider'][[[slider] - slider grip.]];
      };
    };

    description = {
      [[A button description.]];
      [[host is a scroll.bar description]];

      code[=[
        [slider] = scroll.bar.slider,
      ]=];

      params = {
        param['scroll.bar.slider'][[[slider] - slider grip.]];
      };
    };
  };

  metaceldef['scroll.bar.inc'] { 
    source = 'button'; 
    description = {
      [[A button description.]];
      [[host is a scroll.bar description]];
    };
  };

  metaceldef['scroll.bar.dec'] { 
    source = 'button'; 
    description = {
      [[A button description.]];
      [[host is a scroll.bar description]];
    };
  };

  metaceldef['scroll.bar.slider'] { 
    source = 'grip'; 
    description = {
      [[A grip description.]];
      [[host is a scroll.bar.track description]];
    };
  };


  functiondef['cel.scroll(t)'] {
    [[Creates a new scroll]];

    code[==[
    cel.scroll {
      w = number,
      h = number,
      subject = cel,
      subject = {
        [1] = cel,
        fillwidth = boolean,
        fillheight = boolean,
      },
    }
    ]==];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param.cel[[subject - the subject.]];
      param.table {
        name = 'subject';
        [[This table can be used to define the same options used in scroll:setsubject().]];
        tabledef {
          param.cel'[1] - the subject cel.';
          param.boolean[[fillwidth - if true the subject is resized to the width of the scroll portal,
          default is false.]];
          param.boolean[[fillheight - if true the subject is resized to the height of the scroll portal, 
          default is false.]];
        };
      };
    };

    returns = {
      param.scroll[[a new scroll.]]
    };
  };
  functiondef['cel.scroll.new([w[, h[, face]]])'] {
    [[Creates a new scroll]];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param.face[[face - face or face name.]];   
    };

    returns = {
      param.scroll[[a new scroll.]]
    };
  };

  propertydef['cel.scroll.layout'] {
    [[A table defining the internal layout of a scroll cel.]];
    [[This is the default layout use, define a layout in the face to override.]];
  };

  
  celdef['scroll'] {
    [[A scroll is a container cel with vertical and horizontal scrollbars]];
    --[==[
    [[Compostion of a scroll:]];
    tabledef {
      key['scroll.portal'] { 
        'The client cel for a scroll, cels linked to a scroll are linked to the portal';
      };
      key['scroll.bar'] { 
        [[A scrollbar can be horizontal or vertical.  
        A scrollbar is composed of buttons and track which contains a slider]];
        key['scroll.bar.inc'] { 
          [[A button used to increase the value of the scrollbar]];
        };
        key['scroll.bar.dec'] { 
          [[A button used to decrease the value of the scrollbar]];
        };
        key['scroll.bar.track'] {
          [[A button that hosts the slider]];
          key['scroll.bar.slider'] { 
            [[A grip used to change the value of the scrollbar]];
            [[The sliders size will change in proportion to the size of the portal to the subjet.]];
          };
        };
      };
    };
    --]==]

    [[A scroll contains a subject cel, which is shown in the portal and whose position is controlled by the scroll cel
    functions, or user input.  Important metrics from a scroll cel are minvalue, value and maxvalue.  The minvalue is
    always 0 for x and y axes.  The value for x is -subject.x and for y is -subject.y.  
    The maxvalue fox x is math.max(0, subject.w - portal.w) and for y is math.max(0, subject.h - portal.h).  The value
    as will always be clamped to the min and max values.]];

    functiondef['scroll:setsubject(subject[, fillwidth[, fillheight]])'] {
      [[Replaces current scroll subject.]];
      params = {
        param.cel[[subject - the cel to link to the scroll portal as the subject.]];
        param.boolean[[fillwidth - if true the subject is resized to the portals width.]];
        param.boolean[[fillwidth - if true the subject is resized to the portal height.]];
      };

      returns = {
        param.scroll[[self]];
      };
    };

    functiondef['scroll:getsubject()'] {
      [[Returns the current subject of the scroll cel.]];
      returns = {
        param.cel[[The scroll cels subject.]];
      };
    };

    functiondef['scroll:step([x[, y[, mode]]])'] {
      [[Scrolls the subject x, y number of lines or pages.]];
      [[The size of a line is defined by scroll.stepsize. The size of a page is defined by
      the current width and height of the portal.]];code[[ scroll:scrollto() ]];[[is called to move the subject.]];
      params = {
        param.integer[[x - the number of horizontal lines or pages to scroll, defaults to 0]];
        param.integer[[y - the number of vertical lines to pages to scroll, defaults to 0]];
        param.string[[mode - if 'line' step by line if 'page' step by page, defaults to 'line'.]];
      };

      returns = {
        param.scroll[[self]];
      };
    };

    functiondef['scroll:scrollto([x[, y]])'] {
      [[Scrolls the subject to x, y.]];
      [[The coordinates x,y are a point in the subject, this point will coincide with point 0, 0 of the portal 
      in screen space.]];
      params = {
        param.integer[[x - the x value of the subject, clamped to (0, max) see getmaxvalues(), defaults to 0]];
        param.integer[[y - the y value of the subject, clamped to (0, max) see getmaxvalues(), defaults to 0]];
      };

      returns = {
        param.scroll[[self]];
      };
    };

    functiondef['scroll:getvalues()'] {
      [[Returns the current x, y values of the subject.]];
      returns = {
        param.integer[[current x value, which is roughly -subject.x]];
        param.integer[[current y value, which is roughly -subject.y]];
      };
    };

    functiondef['scroll:getmaxvalues()'] {
      [[Returns the maximum x, y values for the subject]];
      returns = {
        param.integer[[max x value, which is math.max(0, subject.w - portal.w)]];
        param.integer[[max y value, which is math.max(0, subject.h - portal.h)]];
      };
    };

    functiondef['scroll:getportalrect()'] {
      [[Returns the portal x, y, w, h]];
      returns = {
        param.integer[[portal.x]];
        param.integer[[portal.y]];
        param.integer[[portal.w]];
        param.integer[[portal.h]];
      };
    };

    

    
  };

  

  descriptiondef['scroll.portal'] {
    [[A cel description.]];
    [[host is not always a scroll description because the scroll metacel can be extended.]];
  };

  

  

  

  

  
}
