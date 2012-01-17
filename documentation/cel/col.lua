export['cel.col'] {
  [[Factory for the col metacel]];
  
  metaceldef['col'] {
    source = 'cel';
    factory = 'cel.col';

    [[A col(umn) is a vertical sequence of cels.]];
    list {
      [[Each cel linked to a col occupies a virtual slot.  When the linker function of a 
      link is called, it will receive the dimensions of the virtual slot for hw, hh.]];
      [[All slots in a col will have the same width (the width of the col), but can vary in height.]];
      [[A slot derives its w, h, minw, minh and maxh from the cel it holds. 
      The minh of the slot can be set directly when a cel is linked. The maxh of the slot is whatever the current height
      of the cel is by default, the maxh restriction is removed by giving a flex value to the slot when a cel is linked.
      ]];

      [[A col derives its w, h, minw, and minh from its virtual slots.]];

      [[A col cannot be sparsely populated, becuase a col is defined by the cels that are linked to it.]];
      [[The first cel in a col is above the next.]];
    };

    --make this a note
    [[A col is a special cel becuase it alters the layout of its links, instead of the default layout of a stack.
    Becuase of this, cel:raise() and cel:sink() have no effect for a cel linked to a col.]];

    description = { 
      [[A cel linked to a col is contained in a virtual slot.  
      For each visible slot (where visible means not fully clipped) slot this description is given:]];
      
      code[=[
        [n] = {
          id = 0,
          metacel = '[index]',
          [1] = cel,
        }
      ]=];

      params = {
        param.integer[[[n] - index of this description.]];
        param.boolean[[[n].id - always 0, a virtual cel does not have an id.]];
        param.boolean[[[n].metacel - always '['.. index .. ']' where index is the index of the slot in the col.  
        A virtual cel does not have a metacel.]]; 
        param.cel[[[n][1] - the description of the cel linked to the slot.]]; 
      };
    };

    __link = {
      param.table { 
        name = 'slot options';
        tabledef {
          param.face[[face - optional face (not a face name).  If a slot has a face it will be described
          with this face.]];
          param.integer[[minh - optional minimum height of the slot.  If the slot does not flex, the minimum height
          of the slot is math.max(link.minh, slot.minh).  If the slot does flex then then the slots minimum height is
          slotoption.minh or link.minh.]];
          param.integer[[flex - optional flex value for slot.  If a slot flexes then its height is determined by
          first setting its h to slotoption.minh or link.minh, then its height will increase based on its flex value
          relative to the sum of the flex values of all slots until the total height of the column is allocated.]];
        };
      };
    };
  };

  functiondef['cel.col(t)'] {
    [[Creates a new col.]];
    [[The col is influx until this function returns.]];

    code[=[
      cel.col {
        gap = number,
        TODO explain non-cel table entries
      }
    ]=];

    params = {
      param.number[[gap - the amount of space to leave between slots in the col. Default is 0.]];
    };

    returns = {
      param['col'][[a new col.]];
    };
  };

  functiondef['cel.col.new([gap [, face]])'] {
    [[Creates a new col.]];

    params = {
      param.number[[gap - amount of space to leave between slots in the col. Default is 0.]];
      param.face[[face - face or face name.]];
    };

    returns = {
      param['col'][[a new col.]];
    };
  };


  celdef['col'] {
    [[A cel that arranges its links into a vertical sequence or column.]];

    [[A col is a cel that provides automatic layout.  For each link the top/left is aligned with the
  bottom/right (with an optional gap) of the link that comes before it in the col.  For a vertical col its
  height, minh and maxh are always the sum of the heights of its links, and its width is the smallest width necessary
  to ensure that no part of any of its links are clipped.  A col does support linkers as well as it can, but keep
  in mind that the dimensions of a col are calculated from the dimensions and positions of its links, and a linker
  will be enforced when the dimensions of the col change.  Each link is put into a (virtual) slot, for a vertical
  col the width of the slot is the width of the col, the height of the slot is the height of the link.  The
  slot w and h are the hostw and hosth that the linker will see.  Because the slot h is the link h, the any change the 
  y and h returned from a linker are ignored and 0, and slot.h are used.  The height of a link/slot can be changed
  by explicitly resizing the link.
  ]];
    
    [[The position(y for vertical, x for horizontal) of a link in the col is the sum of the 
      link.dimension + gap (dimension is height for vertical, width for horizontal) of the links 
      that precede it in the col. If the col is in flux then the links position is not
      enforced until the col is no longer in flux.]];

    functiondef['col:get(index)'] {
      [[Get a link by index.]];

      params = {
        param.integer[[index - An array index.]];
      };

      returns = {
        param.cel[[the cel that is linked to the col at the specified index, or nil.]];
      };
    };
    functiondef['col:insert(link, index)'] {
      [[links the given cel to the col, inserting it at the given index.]];
      [[This is a shortcut for using link, when a linker is not required.]];

      params = {
        param.integer[[index - An array index.  If not provided then link is appended to the end of the col]];
        param.integer[[link - The cel to link to the col.]];
      };

      returns = {
        param.col[[self]];
      };
    };
    functiondef['col:insert(link)'] {
      [[links the given cel to the end of the col]];
      [[This is a shortcut for using link, when a linker is not required.]];

      params = {
        param.integer[[link - The cel to link to the col.]];
      };

      returns = {
        param.col[[self]];
      };
    };
    functiondef['col:remove(index)'] {
      [[unlinks the cel at the given index.]];
      [[If the index is invalid the col remains unmutated.]];

      params = {
        param.integer[[index - An array index.]];
      };

      returns = {
        param.col[[self]];
      };
    };
    functiondef['col:clear()'] {
      [[effciently unlinks all cels from the col.]];
      [[The col will be in flux for the duration of clear().]];

      returns = {
        param.col[[self]];
      };
    };
    functiondef['col:len()'] {
      [[returns number of cels in the col.]];

      returns = {
        param.integer[[The number of cels in the col.]];
      };
    };
    functiondef['col:next(link)'] {
      [[Get the cel which has an index that is 1 greater than the index of the given link in the col.]];

      params = {
        param.cel[[link - a cel linked to the col, if the cel is not in the col nil is returned.]];
      };

      returns = {
        param.cel[[the link following the given link in the col, or nil]];
      };
    };
    functiondef['col:prev(link)'] {
      [[Get the cel which has an index that is 1 less than the index of the given link in the col.]];

      params = {
        param.cel[[link - a cel linked to the col, if the cel is not in the col nil is returned.]];
      };

      returns = {
        param.cel[[the link preceding the given link in the col, or nil]];
      };
    };
    functiondef['col:indexof(link)'] {
      [[Get the array index of the given link in the col.]];

      params = {
        param.cel[[link - a cel linked to the col, if the cel is not in the col nil is returned.]];
      };

      returns = {
        param.integer[[the array index of the given link in the col, or nil.]];
      };
    };
    functiondef['col:flux(callback, ...)'] {
      [[Puts the col into flux and calls the given function.]];
      [[Before the function is called the col is reconciled, meaning that all links are in
        col and the col dimensions are the minimum size such that no link is clipped by
        the col.  After the callback function returns the col is reconciled again.]];

      params = {
        param['function'][[callback - a callback function, it will be called as callback(...).]];
        param['...'][[... - parameters passed to the callback function.]];
      };

      returns = {
        param.col[[self]];
      };
    };
    functiondef['col:beginflux([reconcile])'] {
      [[Puts the col into flux.]];
      [[When a col is in flux it will not automatically reconcile.]];
      [[An equal number of calls to endflux are required to take the col out of flux.]];

      params = {
        param.boolean[[reconcile - If true the col is reconciled.]];
      };

      returns = {
        param.col[[self]];
      };
    };
    functiondef['col:endflux([reconcile])'] {
      [[Takes a col out of flux and reconciles it.]];
      [[An equal number of calls to beginflux/endflux are required to take the col out of flux.]];

      params = {
        param.boolean[[reconcile - If false the col will not be reconciled if it is still in flux.]];
      };

      returns = {
        param.col[[self]];
      };
    };
    functiondef['col:pick(x, y)'] {
      [[Returns the link at the give xy coordinate in the col.]];
      [[x is ignored for a vertical col, y is ignored for a horizontal col.]];
      [[TODO document which link is picked when it falls on a gap]];

      params = {
        param.number[[x - For a horizontal col the x coordinate.]];
        param.number[[y - For a vertical col the y coordinate..]];
      };

      returns = {
        param.cel[[The link closest to the x coordinate for a horizontal col, 
                   or closest to the y coordinate for a vertical col]];
      };
    };

    functiondef['col:ilinks()'] {
      [[Returns an iterator function and the col.]];
      code[=[
        for index, link in col:ilinks() do end
      ]=];
      [[will iterate over each link in the col starting a the first link.]];

      returns = {
        param.iterator[[an iterator function]];
        param.listbox[[the col, iterator function invariant state]];
      };
    };
    functiondef['sort'] {
      [[TODO]]
    };
    functiondef['swap'] {
      [[TODO]]
    };
    functiondef['replace'] {
      [[TODO]]
    };
  };

  --[===[
  
  --]===]
};
