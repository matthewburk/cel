export['cel.sequence'] {
  [[Defines the factories for the sequence.x and sequence.y metacels]];
  

  functiondef['cel.sequence.x(t)'] {
    [[Creates a new horizontal sequence.]];
    [[The sequence is influx until this function returns.]];

    code[=[
      cel.sequence.x {
        gap = number,            
      }
    ]=];

    params = {
      param.number[[gap - the amount of space to leave between links in the sequence. Default is 0.]];
    };

    returns = {
      param['sequence.x'][[a new horizontal sequence.]];
    };
  };

  functiondef['cel.sequence.y(t)'] {
    [[Creates a new vertical sequence.]];
    [[The sequence is influx until this function returns.]];

    code[=[
      cel.sequence.y {
        gap = number,
      }
    ]=];

    params = {
      param.number[[gap - the amount of space to leave between links in the sequence. Default is 0.]];
    };

    returns = {
      param['sequence.y'][[a new vertical sequence.]];
    };
  };

  functiondef['cel.sequence.x.new([gap [, face]])'] {
    [[Creates a new horizontal sequence.]];

    params = {
      param.number[[gap - amount of space to leave between links in the sequence. Default is 0.]];
      param.face[[face - face or face name.]];
    };

    returns = {
      param['sequence.x'][[a new horizontal sequence.]];
    };
  };

  functiondef['cel.sequence.y.new([gap [, face]])'] {
    [[Creates a new vertical sequence.]];

    params = {
      param.number[[gap - amount of space to leave between links in the sequence. Default is 0.]];
      param.face[[face - face or face name.]];
    };

    returns = {
      param['sequence.y'][[a new vertical sequence.]];
    };
  };


  celdef['sequence'] {
    [[A cel that arranges its links into a vertical or horizontal sequence.]];

    [[A sequence is a cel that provides automatic layout.  For each link the top/left is aligned with the
  bottom/right (with an optional gap) of the link that comes before it in the sequence.  For a vertical sequence its
  height, minh and maxh are always the sum of the heights of its links, and its width is the smallest width necessary
  to ensure that no part of any of its links are clipped.  A sequence does support linkers as well as it can, but keep
  in mind that the dimensions of a sequence are calculated from the dimensions and positions of its links, and a linker
  will be enforced when the dimensions of the sequence change.  Each link is put into a (virtual) slot, for a vertical
  sequence the width of the slot is the width of the sequence, the height of the slot is the height of the link.  The
  slot w and h are the hostw and hosth that the linker will see.  Because the slot h is the link h, the any change the 
  y and h returned from a linker are ignored and 0, and slot.h are used.  The height of a link/slot can be changed
  by explicitly resizing the link.
  ]];
    
    [[The position(y for vertical, x for horizontal) of a link in the sequence is the sum of the 
      link.dimension + gap (dimension is height for vertical, width for horizontal) of the links 
      that precede it in the sequence. If the sequence is in flux then the links position is not
      enforced until the sequence is no longer in flux.]];

    functiondef['sequence:get(index)'] {
      [[Get a link by index.]];

      params = {
        param.integer[[index - An array index.]];
      };

      returns = {
        param.cel[[the cel that is linked to the sequence at the specified index, or nil.]];
      };
    };
    functiondef['sequence:insert(index, link)'] {
      [[links the given cel to the sequence, inserting it at the given index.]];
      [[This is a shortcut for using link, when a linker is not required.]];

      params = {
        param.integer[[index - An array index.  If not provided then link is appended to the end of the sequence]];
        param.integer[[link - The cel to link to the sequence.]];
      };

      returns = {
        param.sequence[[self]];
      };
    };
    functiondef['sequence:insert(link)'] {
      [[links the given cel to the end of the sequence]];
      [[This is a shortcut for using link, when a linker is not required.]];

      params = {
        param.integer[[link - The cel to link to the sequence.]];
      };

      returns = {
        param.sequence[[self]];
      };
    };
    functiondef['sequence:remove(index)'] {
      [[unlinks the cel at the given index.]];
      [[If the index is invalid the sequence remains unmutated.]];

      params = {
        param.integer[[index - An array index.]];
      };

      returns = {
        param.sequence[[self]];
      };
    };
    functiondef['sequence:clear()'] {
      [[effciently unlinks all cels from the sequence.]];
      [[The sequence will be in flux for the duration of clear().]];

      returns = {
        param.sequence[[self]];
      };
    };
    functiondef['sequence:len()'] {
      [[returns number of cels in the sequence.]];

      returns = {
        param.integer[[The number of cels in the sequence.]];
      };
    };
    functiondef['sequence:next(link)'] {
      [[Get the cel which has an index that is 1 greater than the index of the given link in the sequence.]];

      params = {
        param.cel[[link - a cel linked to the sequence, if the cel is not in the sequence nil is returned.]];
      };

      returns = {
        param.cel[[the link following the given link in the sequence, or nil]];
      };
    };
    functiondef['sequence:prev(link)'] {
      [[Get the cel which has an index that is 1 less than the index of the given link in the sequence.]];

      params = {
        param.cel[[link - a cel linked to the sequence, if the cel is not in the sequence nil is returned.]];
      };

      returns = {
        param.cel[[the link preceding the given link in the sequence, or nil]];
      };
    };
    functiondef['sequence:indexof(link)'] {
      [[Get the array index of the given link in the sequence.]];

      params = {
        param.cel[[link - a cel linked to the sequence, if the cel is not in the sequence nil is returned.]];
      };

      returns = {
        param.integer[[the array index of the given link in the sequence, or nil.]];
      };
    };
    functiondef['sequence:flux(callback, ...)'] {
      [[Puts the sequence into flux and calls the given function.]];
      [[Before the function is called the sequence is reconciled, meaning that all links are in
        sequence and the sequence dimensions are the minimum size such that no link is clipped by
        the sequence.  After the callback function returns the sequence is reconciled again.]];

      params = {
        param['function'][[callback - a callback function, it will be called as callback(...).]];
        param['...'][[... - parameters passed to the callback function.]];
      };

      returns = {
        param.sequence[[self]];
      };
    };
    functiondef['sequence:beginflux([reconcile])'] {
      [[Puts the sequence into flux.]];
      [[When a sequence is in flux it will not automatically reconcile.]];
      [[An equal number of calls to endflux are required to take the sequence out of flux.]];

      params = {
        param.boolean[[reconcile - If true the sequence is reconciled.]];
      };

      returns = {
        param.sequence[[self]];
      };
    };
    functiondef['sequence:endflux([reconcile])'] {
      [[Takes a sequence out of flux and reconciles it.]];
      [[An equal number of calls to beginflux/endflux are required to take the sequence out of flux.]];

      params = {
        param.boolean[[reconcile - If false the sequence will not be reconciled if it is still in flux.]];
      };

      returns = {
        param.sequence[[self]];
      };
    };
    functiondef['sequence:pick(x, y)'] {
      [[Returns the link at the give xy coordinate in the sequence.]];
      [[x is ignored for a vertical sequence, y is ignored for a horizontal sequence.]];
      [[TODO document which link is picked when it falls on a gap]];

      params = {
        param.number[[x - For a horizontal sequence the x coordinate.]];
        param.number[[y - For a vertical sequence the y coordinate..]];
      };

      returns = {
        param.cel[[The link closest to the x coordinate for a horizontal sequence, 
                   or closest to the y coordinate for a vertical sequence]];
      };
    };

    functiondef['sequence:ilinks()'] {
      [[Returns an iterator function and the sequence.]];
      code[=[
        for index, link in sequence:ilinks() do end
      ]=];
      [[will iterate over each link in the sequence starting a the first link.]];

      returns = {
        param.iterator[[an iterator function]];
        param.listbox[[the sequence, iterator function invariant state]];
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
  metaceldef['sequence'] {
    functions = {
      functiondef['__describeslot'] {
        [[TODO]]
      };
    }
  };
  --]===]
};
