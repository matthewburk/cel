export['cel.row'] {
  [[Factory for the row metacel]];
  

  functiondef['cel.row(t)'] {
    [[Creates a new row.]]; 
    [[The row is influx until this function returns.]];

    code[=[
      cel.row {
        {minw = number, weight = number, [1] = cel}
      }
    ]=];

    params = {
      param.table{
        name = 'slot definition';
        [[When a table (that is not a cel) appears in the array part of
        the row constructor the row interprets it as a slot definition.]];
        [[If the entry at array index 1 is a cel (or string) it is
          linked to the row and the slot is created.  minw is the minimum
          width of the slot(default 0) and weight is the weight
          of the slot(default 0)]];
      };
    };

    returns = {
      param.row[[a new row]];
    };
  };

  functiondef['cel.row.new([gap [, face]])'] {
    [[Creates a new row.]];

    params = {
      param.number[[gap - amount of space to leave between slots.  Default is 0.]];
      param.face[[face - face or face name.]];
    };

    returns = {
      param.row[[a new row]];
    };
  };

  celdef['row'] {
    [[A row is horizontal sequence, however unlike a horizontal sequence a rows 
    width is more flexible.]];
    [[Every cel linked to a row is hosted in a cel.slot.  
    When the row width is increased the extra space is allocated to each slot
    based on a weighting algorithm.  This behavior allows for more flexible 
    layout than a standard sequence.]];

    [[Slot width allocation is determined by the weight of the slot, which is set
    when a cel is linked to the row.  The weight of the row is the sum of the
    weights of its slots.  The ratio of the slot weight to the row weight is
    used to determine how much space is allocated to the slot.]];
    --TODO explain allocation/weights better
    --
    functiondef['row:get(index)'] {
      [[Get a link by index.]];

      params = {
        param.integer[[index - an array index.]];
      };

      returns = {
        param.cel[[the cel that is linked to the row at the specified index, or nil.]];
      };
    };
    functiondef['row:insert(link[, index[, weight[, minw]]])'] {
      [[links the given cel to the row, inserting it at the given index.]];
      [[This is a shortcut for using link, when a linker is not required.]];

      params = {
        param.cel[[link - cel to link to the row.]];
        param.integer[[index - An array index.  If not provided then link is
        appended to the end of the row]];
        param.number[[weight - weight of the slot the link occupies, default
        is 0]];
        param.number[[minw - minimum width of the slot the link occupies,
        default is 0]];
      };

      returns = {
        param.row[[self]];
      };
    };
    functiondef['row:remove(index)'] {
      [[unlinks the cel at the given index.]];
      [[If the index is invalid the row remains unmutated.]];
      [[When the link is removed the slot it occupies is also removed]];

      params = {
        param.integer[[index - an array index.]];
      };

      returns = {
        param.row[[self]];
      };
    };
    functiondef['row:clear()'] {
      [[effciently unlinks all cels from the row.]];
      [[The row will be in flux for the duration of clear().]];

      returns = {
        param.row[[self]];
      };
    };
    functiondef['row:len()'] {
      [[returns array length of the row.]];

      returns = {
        param.integer[[The length of the row]];
      };
    };
    functiondef['row:next(link)'] {
      [[Get the cel which has an index that is 1 greater than the index
      of the given link in the row.]];

      params = {
        param.cel[[link - a cel linked to the row, if the cel is not in
        the row nil is returned.]];
      };

      returns = {
        param.cel[[the link following the given link in the row, or nil]];
      };
    };
    functiondef['row:prev(link)'] {
      [[Get the cel which has an index that is 1 less than the index of the
      given link in the row.]];

      params = {
        param.cel[[link - a cel linked to the row, if the cel is not in the
        row nil is returned.]];
      };

      returns = {
        param.cel[[the link preceding the given link in the row, or nil]];
      };
    };
    functiondef['row:indexof(link)'] {
      [[Get the array index of the given link in the row.]];

      params = {
        param.cel[[link - a cel linked to the row, if the cel is not in the
        row nil is returned.]];
      };

      returns = {
        param.integer[[the array index of the given link in the row,
        or nil.]];
      };
    };
    functiondef['flux'] {
      [[inherited from sequence]];
    };
    functiondef['beginflux'] {
      [[inherited from sequence]];
    };
    functiondef['endflux'] {
      [[inherited from sequence]];
    };
    functiondef['pick'] {
      [[TODO make note of reimplementation]]
    };
    functiondef['sort'] {
      [[TODO make note of reimplementation]]
    };
    functiondef['swap'] {
      [[TODO make note of reimplementation]]
    };
    functiondef['replace'] {
      [[TODO make note of reimplementation]]
    };

    --TODO implement in celdef
    linkoption = {
      [[A row supports the same link option as a sequence.]];
      [[In addition if the link option is a function it is called to get
      the weight, minw, index like this:]];
      code [=[
        local weight, minw, index = option()
      ]=];
    };
  };  
}

