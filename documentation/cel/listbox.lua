export['cel.listbox'] {
  [[Factory for the listbox metacel.]];
  
  metaceldef['listbox'] {
    source = 'scroll';
    factory = 'cel.listbox';

    composition = {
      code[=[
        [portal] = cel
            [list] = listbox.list
        [xbar] = scroll.bar
        [ybar] = scroll.bar
      ]=];

      params = {
        param.cel[[[portal] - listbox portal.]];
        param['listbox.list'][[[list] - a col contianing the items.]];
        param['scroll.bar'][[[xbar] - horizontal scrollbar.]];
        param['scroll.bar'][[[ybar] - vertical scrollbar.]];
      };
    };

    description = { 
      [[A scroll description.]];
      code[=[
        [portal] = cel,
            [list] = listbox.list,
        [xbar] = scroll.bar,
        [ybar] = scroll.bar,
      ]=];

      params = {
        param.cel[[[portal] - scroll portal.]];
        param['listbox.list'][[[list] - a sequence contianing the items.]];
        param['scroll.bar'][[[xbar] - horizontal scrollbar.]];
        param['scroll.bar'][[[ybar] - vertical scrollbar.]];
      };
    };

    layout = {
      [[A table defineing the internal layout of a listbox]];
      code[=[
      layout = {
        list = {
          face = face,
          gap = integer,
        },
        itembox = {
          face = face, 
        },
        stepsize = integer, 
        xbar = table,
        ybar = table,
      }
      ]=];

      params = {
        param.table {
          name='list';
          tabledef {
            param.face[[face - face or face name]];
            param.integer[[gap - amount of space between each item in the list.]];
          };
        };
        param.table {
          name='itembox';
          tabledef {
            param.face[[face - face or face name]];
          };
        };
        param.integer[[stepsize - number of units to move the list in a single step.
        This only applies to horizontal steps.]];
        param.table[[xbar - see cel.scroll for layout.]];
        param.table[[ybar - see cel.scroll for layout.]];
      };
    };

    
     __link = {
      param['?'] { name = 'default', [[link is linked to the end of the list.]] };
      param.number { name = '[1,n]'; [[link is inserted into the list at this index.]] };
      param.string { name = "'raw'"; [[link is not redirected.]] };
      param.string { name = "'portal'"; [[link is redirected to the portal.]] };
      param.string { name = "'xbar'"; [[link is redirected to the horizontal scrollbar.]] };
      param.string { name = "'ybar'"; [[link is redirected to the vertical scrollbar.]] };
    };

    flows = {
      key.hidexbar[[called when the xbar is hidden.]];
      key.showxbar[[called when the xbar is unhidden.]];
      key.hideybar[[called when the ybar is hidden.]];
      key.showybar[[called when the ybar is unhidden.]];
      key.scroll[[called when the list is scrolled.]];
    };
  };

  metaceldef['listbox.list'] {
    source = 'sequence.y';
    description = { 
      [[Each description in listbox.list is for a virtual cel that contains a list item.]];
      code[=[
        [n] = {
          selected = boolean,
          current = boolean,
          [1] = cel,
        }
      ]=];

      params = {
        param.integer[[[n] - index of a description in listbox.list.]];
        param.boolean[[[n].selected - true if the item is selected.]];
        param.boolean[[[n].current - true if the item is the current item.]]; 
        param.cel[[[n][1] - a list item.]]; 
      };
    };
  };

  functiondef['cel.listbox(t)'] {
    [[Creates a new listbox]];

    code[==[
    cel.listbox {
      w = number,
      h = number,
      onchange = function,
    }
    ]==];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param['function'][[onchange - event callback.]];
    };

    returns = {
      param.listbox[[a new listbox.]]
    };
  };

  functiondef['cel.listbox.new([w[, h[, face]]])'] {
    [[Creates a new listbox]];

    params = {
      param.number[[w - width, default is 0.]];
      param.number[[h - height, default is 0.]];
      param.face[[face - face or face name.]];   
    };

    returns = {
      param.listbox[[a new listbox.]]
    };
  };

  celdef['listbox'] {
    [[A listbox is a container cel with vertical and horizontal scrollbars.]];
    [[A listbox is a scroll cel with the subject encapsulated.  The subject is an list sequence,
    when a cel is linked to the listbox it is put in the list.]];

    

    functiondef['listbox:len()'] {
      'Returns the number of items in the list';
      returns = {
        param.integer[[the number of items in the list]];
      };
    };

    functiondef['listbox:flux(callback, ...)'] {
      [[Puts the list into flux and calls the given function.]];
      [[Before the function is called the list is reconciled. After the callback function returns
      the list is reconciled again.]];

      params = {
        param['function'][[callback - a callback function, it will be called as callback(...).]];
        param['...'][[... - parameters passed to the callback function.]];
      };

      returns = {
        param.listbox[[self]];
      };
    };

    functiondef['listbox:insert(link[, index])'] {
      [[links the given cel to the list, inserting it at the given index.]];
      [[This is a shortcut for using link, when a linker is not required.]];

      params = {
        param.cel[[link - The cel (or string) to link.  If this is a string a label is created from the string.]];
        param.integer[[index - An array index.  If not provided then link is appended to the end of the list]];
      };

      returns = {
        param.listbox[[self]];
      };
    };

    functiondef['listbox:pick(x, y)'] {
      [[Returns the item and the index of the item at coordinate x, y in the listbox.]];
      [[If the x,y coordinate falls outside the portal rect then nothing is returned.]];
      [[If no item it at (x,y) then nothing is returned.]];
      params = {
        param.integer[[x - x coordinate.]];
        param.integer[[y - y coordinate.]];
      };

      returns = {
        param.cel[[the listbox item which contains point(x,y).]];
        param.integer[[the index of the listbox item.]];
      };
    };

    functiondef['listbox:insertlist(index, t)'] {
      [[Adds all cels (or strings) in the array t to the list]];
      [[The list is in flux for the duration.]];

      params = {
        param.integer[[index - An array index.  If not provided then t is appended to the end of the list]];
        param.array[[t - The array of cels (or strings) to link.]];
      };

      returns = {
        param.listbox[[self]];
      };
    };

    functiondef['listbox:step([x[, y]])'] {
      [[Scrolls the list x number of lines and, y number of items.]];
      [[The size of a line is defined by listbox.stepsize.]];
      code[[ listbox:scrollto() ]];[[is called to scroll the list.]];
      params = {
        param.integer[[x - the number of horizontal lines or pages to scroll, defaults to 0]];
        param.integer[[y - the number of items to scroll, defaults to 0]];
      };

      returns = {
        param.listbox[[self]];
      };
    };

    functiondef['listbox:scrollto([x[, y]])'] {
      [[Scrolls the list to x, y.]];
      [[The coordinates x,y are a point in the list, this point will coincide with point 0, 0 of the portal 
      in screen space.]];
      params = {
        param.integer[[x - the x value of the list, clamped to (0, max) see getmaxvalues(), defaults to 0]];
        param.integer[[y - the y value of the list, clamped to (0, max) see getmaxvalues(), defaults to 0]];
      };

      returns = {
        param.listbox[[self]];
      };
    };

    functiondef['listbox:getvalues()'] {
      [[Returns the current x, y values of the list.]];
      returns = {
        param.integer[[current x value, which is roughly -subject.x]];
        param.integer[[current y value, which is roughly -subject.y]];
      };
    };

    functiondef['listbox:getmaxvalues()'] {
      [[Returns the maximum x, y values for the list]];
      returns = {
        param.integer[[max x value, which is math.max(0, subject.w - portal.w)]];
        param.integer[[max y value, which is math.max(0, subject.h - portal.h)]];
      };
    };

    functiondef['listbox:getportalrect()'] {
      [[Returns the portal x, y, w, h]];
      returns = {
        param.integer[[portal.x]];
        param.integer[[portal.y]];
        param.integer[[portal.w]];
        param.integer[[portal.h]];
      };
    };

    functiondef['listbox:remove(index)'] {
      [[Removes the item at index from the list.]];
      [[If the index is invalid the listbox remains unmutated.]];

      params = {
        param.integer[[index - An array index.]];
      };

      returns = {
        param.listbox[[self]];
      };
    };

    functiondef['listbox:next(item)'] {
      [[Returns the next item in the list.]];

      params = {
        param.cel[[item - an item in the list, the item after this item is returned.]];
      };

      returns = {
        param.cel[[the next item, or nil]];
      };
    };

    functiondef['listbox:prev(item)'] {
      [[Returns the previous item in the list.]];

      params = {
        param.cel[[item - an item in the list, the item before this item is returned.]];
      };

      returns = {
        param.cel[[the previous item, or nil]];
      };
    };

    functiondef['listbox:items()'] {
      [[Returns an iterator function and the listbox.]];
      code[=[
        for index, item in listbox:items() do end
      ]=];
      [[will iterate over each item in the listbox starting a the first item.]];

      returns = {
        param.iterator[[an iterator function]];
        param.listbox[[the listbox, iterator function invariant state]];
      };
    };

    functiondef['listbox:selecteditems()'] {
      [[Returns an iterator function and the listbox.]];
      code[=[
        for item in listbox:selecteditems() do end
      ]=];
      [[will iterate over each selected item in no particular order.]];

      returns = {
        param.iterator[[an iterator function]];
        param.listbox[[the listbox, iterator function invariant state]];
      };
    };

    functiondef['listbox:first()'] {
      'Returns the first item in the list';
      returns = {
        param.cel[[the first item in the list]];
      };
    };

    functiondef['listbox:last()'] {
      'Returns the last item in the list';
      returns = {
        param.cel[[the last item in the list]];
      };
    };

    functiondef['listbox:get(index)'] {
      [[Returns the item at index.]];
      params = {
        param.integer[[index - an array index.]];
      };
      returns = {
        param.cel[[the item at the index or nil.]];
      };
    };

    functiondef['listbox:indexof(item)'] {
      [[Returns the array index of the item.]];

      params = {
        param.cel[[item - a list time, if item is not in the list nil is returned.]];
      };

      returns = {
        param.integer[[the array index of the item, or nil.]];
      };
    };

    functiondef['listbox:getcurrent()'] {
      [[Returns the current item in the list.]];
      [[The current item is set with listbox:setcurrent().  The current item is intended to indicate 
      the item the user is interacting with.]];
      returns = {
        param.cel[[the current item or nil.]];
      };
    };

    functiondef['listbox:setcurrent(item)'] {
      [[Makes item (or the item at index item) the current item.]];
      [[The item will take focus.]];

      params = {
        param.cel[[item - a listbox item.]];
        param.integer[[item - index of an item in the listbox.]];
      };
      returns = {
        param.listbox[[self]];
      };
    };

    functiondef['listbox:scrolltoitem(item)'] {
      [[Scrolls the listbox to the item (or the item at index item)]];

      params = {
        param.cel[[item - a listbox item.]];
        param.integer[[item - index of an item in the listbox.]];
      };
      returns = {
        param.listbox[[self]];
      };
    };

    functiondef['listbox:clear()'] {
      [[Removes all items from the list.]];
      returns = {
        param.listbox[[self]];
      };
    };

    functiondef['listbox:select(item[, mode])'] {
      [[selects, unselects or toggles selection the item (or item at index item)]];
      params = {
        param.cel[[item - an item in the list.]];
        param.integer[[item - index of a list item.]];
        param.boolean {
          name = 'mode',
          [[If mode == true then the item is selected. If mode == false then the item is unselected.  
          If mode is nil or any other value the item selection is reversed.]];
        };
      };
      returns = {
        param.listbox[[self]];
      };
    };

    functiondef['listbox:selectall([mode])'] {
      [[selects, unselects or toggles selection for all items in the list.]];

      params = {
        param.boolean {
          name = 'mode',
          [[If mode == true then then all items are selected. If mode == false then all items are unselected.  
          If mode is nil or any other value then all items selection is reversed.]];
        };
      };

      returns = {
        param.listbox[[self]];
      };
    };
  };
}
