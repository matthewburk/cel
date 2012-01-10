export['cel.col'] {
  [[Factory for the col metacel.]];
  
  metaceldef['col'] {
    source = 'ysequence';
    factory = 'cel.col';

    [[A col is a vertical sequence of cels.]];
    [[
    The cels in a col are distributed according to their minimum height.  Any additional
    vertical space is distributed between each slot based on its flex value.
    ]];
      
    composition = {
      code[=[
        [n] = col.slot
          [item] = cel
      ]=];

      params = {
        param['col.slot'][[[n] - a slot at array index n in the col.]];
        param['cel'][[[item] - cel linked to the slot.]];
      };
    };

    description = { 
      [[Each description in col.slot cel that contains a col item.]];
      code[=[
        [n] = {
          [1] = cel,
        }
      ]=];

      params = {
        param.integer[[[n] - index of a description in col.]];
        param.cel[[[n][1] - a col item.]]; 
      };
    };

    __link = {
      param['?'] { name = 'default',
        [[If the col cel has a subject links are redirected to the subject. 
        If the col cel has no subject links are redirected to the portal.]];
      };
    };
  };

  metaceldef['col.slot'] { 
    source = 'slot'; 
  };
}
