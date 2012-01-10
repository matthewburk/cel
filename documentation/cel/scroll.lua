export['cel.scroll'] {
  [[Factory for the scroll metacel.]];
  
  metaceldef['scroll'] {
    source = 'cel';
    factory = 'cel.scroll';

    [[A scroll is a container cel with vertical and horizontal scrollbars]];
    [[A scroll is composed of a vertical scrollbar, horizontal scrollbar, and a portal.
    The subject is the cel that is controlled by the scrollbars, and is linked to the portal.    
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
      layout = {
        stepsize = integer, 
        xbar = { 
          face = face,
          show = boolean,
          align = string,
          size = integer,
          track = { 
            face = face,
            size = integer,
            link = {linker[, xval[, yval]]} or string,
            thumb = {
              face = face,
              size = integer,
              minsize = integer,
            },
          },
          decbutton = {
            face = face,
            size = integer,
            link = {linker[, xval[, yval]]} or string,
          },
          incbutton = {
            face = face,
            size = integer,
            link = {linker[, xval[, yval]]} or string,
          },
        },
        ybar = {
          face = face,
          show = boolean,
          align = string,
          size = integer,
          track {
            face = face,
            size = integer,
            link = {linker[, xval[, yval]]} or string,
            thumb = {
              face = face,
              size = integer,
              minsize = integer, 
            },
          },
          decbutton = {
            face = face,
            size = integer,
            link = {linker[, xval[, yval]]} or string,
          },
          incbutton = {
            face = face,
            size = integer,
            link = {linker[, xval[, yval]]} or string,
          },
        },
      }
      ]=];

      params = {
        param.integer[[stepsize - number of units to move the itemlist in a single step.]];
        param.table {
          name='xbar';
          [[horizontal scrollbar layout.]];
          tabledef {
            param.face[[face - face or face name.]];
            param.string[[align - 'bottom' positions scrollbar at bottom of the portal, 'top' at the top of the portal.]];
            param.boolean[[show - if true the scrollbar is shown, if false it is not, if nil the scrollbar will show when portal intersects the subject]];
            param.integer[[size - height of the scrollbar.]];
            param.table {
              name='track';
              [[scrollbar track layout.]];
              tabledef {
                param.face[[face - face or face name.]];
                param.integer[[size - height of the track.]];
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
                param.table {
                  name='thumb';
                  [[scrollbar thumb layout.]];
                  tabledef {
                    param.face[[face - face or face name.]];
                    param.integer[[size - height of the thumb.]];
                    param.integer[[minsize - minimum width of the thumb.]];
                  };
                };
              };
            };
            param.table {
              name='decbutton';
              [[scrollbar decbutton layout.]];
              tabledef {
                param.face[[face - face or face name.]];
                param.integer[[size - width and height of the button.]];
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
              name='incbutton';
              [[scrollbar incbutton layout.]];
              tabledef {
                param.face[[face - face or face name.]];
                param.integer[[size - width and height of the button.]];
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
        param.table {
          name='ybar';
          [[vertical scrollbar layout.]];
          tabledef {
            param.face[[face - face or face name.]];
            param.string[[align - 'right' positions scrollbar at right of the portal, 'left' at the left of the portal.]];
            param.boolean[[show - if true the scrollbar is shown, if false it is not, if nil the scrollbar will show when portal intersects the subject]];
            param.integer[[size - width of the scrollbar.]];
            param.table {
              name='track';
              [[scrollbar track layout.]];
              tabledef {
                param.face[[face - face or face name.]];
                param.integer[[size - width of the track.]];
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
                param.table {
                  name='thumb';
                  [[scrollbar thumb layout.]];
                  tabledef {
                    param.face[[face - face or face name.]];
                    param.integer[[size - width of the thumb.]];
                    param.integer[[minsize - minimum height of the thumb.]];
                  };
                };
              };
            };
            param.table {
              name='decbutton';
              [[scrollbar decbutton layout.]];
              tabledef {
                param.face[[face - face or face name.]];
                param.integer[[size - width and height of the button.]];
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
              name='incbutton';
              [[scrollbar incbutton layout.]];
              tabledef {
                param.face[[face - face or face name.]];
                param.integer[[size - width and height of the button.]];
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
      };
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

    [[A scroll.bar.track contains the scroll thumb.  Clicking on the track, or dragging the thumb
    will scroll the scroll cels subject.]];

    composition = {
      code[=[
        [thumb] = scroll.bar.thumb
      ]=];

      params = {
        param['scroll.bar.thumb'][[[thumb] - thumb grip.]];
      };
    };

    description = {
      [[A button description.]];
      [[host is a scroll.bar description]];

      code[=[
        [thumb] = scroll.bar.thumb,
      ]=];

      params = {
        param['scroll.bar.thumb'][[[thumb] - thumb grip.]];
      };
    };
  };

  metaceldef['scroll.bar.inc'] { 
    source = 'button'; 
    description = {
      [[A button description.]];
    };
  };

  metaceldef['scroll.bar.dec'] { 
    source = 'button'; 
    description = {
      [[A button description.]];
    };
  };

  metaceldef['scroll.bar.thumb'] { 
    source = 'grip'; 
    description = {
      [[A grip description.]];
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
    [[This is the default layout used, define a layout in the face to override.]];
  };

  
  celdef['scroll'] {
    [[A scroll is a container cel with vertical and horizontal scrollbars]];

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
}
