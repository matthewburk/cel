namespace 'celdocs'

export[...] {
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
  ]]

  factorydef['cel.sequence'] {
    functions = {
      functiondef['__call'] {
        [[Creates a new sequence.  The sequence is influx until this function returns.]];

        synopsis = [=[
          cel.sequence.x {
            gap = number,            
          }

          cel.sequence.y {
            gap = number,
          }
        ]=];

        params = {
          param.number[[gap - the amount of space to leave between links in the sequence. Default is 0.]];
        };

        returns = {
          param.sequence[[sequence - a new sequence.]];
        };
      };

      functiondef['new'] {
        [[Creates a new sequence.]];

        synopsis = [=[
          cel.sequence.x.new([gap [, face]])
          cel.sequence.y.new([gap [, face]])
        ]=];

        params = {
          param.number[[gap - amount of space to leave between links in the sequence. Default is 0.]];
          param.face[[face - face or face name.]];
        };

        returns = {
          param.sequence[[sequence - a new sequence.]];
        };
      };
    };
  };


  celdef['sequence'] {
    [[A cel that arranges its links into a vertical or horizontal sequence.]];
    [[The position(y for vertical, x for horizontal) of a link in the sequence is the sum of the 
      link.dimension + gap (dimension is height for vertical, width for horizontal) of the links 
      that precede it in the sequence. If the sequence is in flux then the links position is not
      enforced until the sequence is no longer in flux.]];

    functions = {
      functiondef['get'] {
        [[Get a link by index.]];

        synopsis = [=[
          sequence:get(index)
        ]=];

        params = {
          param.integer[[index - An array index.]];
        };

        returns = {
          param.cel[[the cel that is linked to the sequence at the specified index, or nil.]];
        };
      };
      functiondef['insert'] {
        [[links the given cel to the sequence, inserting it at the given index.]];
        [[This is a shortcut for using link, when a linker is not required.]];

        synopsis = [=[
          sequence:insert(index, link)
          sequence:insert(link)
        ]=];

        params = {
          param.integer[[index - An array index.  If not provided then link is appended to the end of the sequence]];
          param.integer[[link - The cel to link to the sequence.]];
        };

        returns = {
          param.sequence[[self]];
        };
      };
      functiondef['remove'] {
        [[unlinks the cel at the given index.]];
        [[If the index is invalid the sequence remains unmutated.]];

        synopsis = [=[
          sequence:remove(index)
        ]=];

        params = {
          param.integer[[index - An array index.]];
        };

        returns = {
          param.sequence[[self]];
        };
      };
      functiondef['clear'] {
        [[effciently unlinks all cels from the sequence.]];
        [[The sequence will be in flux for the duration of clear().]];

        synopsis = [=[
          sequence:clear()
        ]=];

        returns = {
          param.sequence[[self]];
        };
      };
      functiondef['len'] {
        [[returns array length of the sequence.]];

        synopsis = [=[
          sequence:len()
        ]=];

        returns = {
          param.integer[[The lenght of the sequence]];
        };
      };
      functiondef['next'] {
        [[Get the cel which has an index that is 1 greater than the index of the given link in the sequence.]];

        synopsis = [=[
          sequence:next(link)
        ]=];

        params = {
          param.cel[[link - a cel linked to the sequence, if the cel is not in the sequence nil is returned.]];
        };

        returns = {
          param.cel[[the link following the given link in the sequence, or nil]];
        };
      };
      functiondef['prev'] {
        [[Get the cel which has an index that is 1 less than the index of the given link in the sequence.]];

        synopsis = [=[
          sequence:next(link)
        ]=];

        params = {
          param.cel[[link - a cel linked to the sequence, if the cel is not in the sequence nil is returned.]];
        };

        returns = {
          param.cel[[the link preceding the given link in the sequence, or nil]];
        };
      };
      functiondef['indexof'] {
        [[Get the array index of the given link in the sequence.]];

        synopsis = [=[
          sequence:indexof(link)
        ]=];

        params = {
          param.cel[[link - a cel linked to the sequence, if the cel is not in the sequence nil is returned.]];
        };

        returns = {
          param.integer[[the array index of the given link in the sequence, or nil.]];
        };
      };
      functiondef['flux'] {
        [[Puts the sequence into flux and calls the given function.]];
        [[Before the function is called the sequence is reconciled, meaning that all links are in
          sequence and the sequence dimensions are the minimum size such that no link is clipped by
          the sequence.  After the callback function returns the sequence is reconciled again.]];

        synopsis = [=[
          sequence:flux(callback, ...)
        ]=];

        params = {
          param['function'][[callback - a callback function, it will be called as callback(...).]];
          param['...'][[... - parameters passed to the callback function.]];
        };

        returns = {
          param.sequence[[self]];
        };
      };
      functiondef['beginflux'] {
        [[Puts the sequence into flux.  When a sequence is in flux it will not automatically reconcile.]];
        [[An equal number of calls to endflux are required to take the sequence out of flux.]];

        synopsis = [=[
          sequence:beginflux([reconcile])
        ]=];

        params = {
          param.boolean[[reconcile - If true the sequence is reconciled.]];
        };

        returns = {
          param.sequence[[self]];
        };
      };
      functiondef['endflux'] {
        [[Takes a sequence out of flux and reconciles it.]];
        [[An equal number of calls to beginflux/endflux are required to take the sequence out of flux.]];

        synopsis = [=[
          sequence:beginflux([reconcile])
        ]=];

        params = {
          param.boolean[[reconcile - If false the sequence will not be reconciled if it is still in flux.]];
        };

        returns = {
          param.sequence[[self]];
        };
      };
      functiondef['pick'] {
        [[Returns the link at the give xy coordinate in the sequence.]];
        [[x is ignored for a vertical sequence, y is ignored for a horizontal sequence.]];
        [[TODO document which link is picked when it falls on a gap]];

        synopsis = [=[
          sequence:pick(x, y)
        ]=];

        params = {
          param.number[[x - For a horizontal sequence the x coordinate.]];
          param.number[[y - For a vertical sequence the y coordinate..]];
        };

        returns = {
          param.cel[[The link closest to the x coordinate for a horizontal sequence, 
                     or closest to the y coordinate for a vertical sequence]];
        };
      };
      functiondef['links'] {
        [[Returns an iterator over the links in the sequence, using ipairs()]];
        [[TODO redefine this, ipairs exposes our private table]];

        synopsis = [=[
          sequence:links()
        ]=];
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
    }

    events = {
    }
  };

  metaceldef['sequence'] {
    functions = {
      functiondef['__describeslot'] {
        [[TODO]]
      };
    }
  };
}
