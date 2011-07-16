namespace 'celdocs'

export[...] {
  functiondef['cel.__call'] {
    description = [[Creates a new cel.  This function is called by calling the cel factory, see example.]];

    synopsis = [==[
      cel {
        w = number,
        h = number,
        face = any,
        onresize = function,
        onmousein = function,
        onmouseout = function,
        onmousemove = function,
        onmousedown = function,
        onmouseup = function,
        onfocus = function,
        onkeydown = function,
        onkeyup = function,
        onchar = function,
        oncommand = function,
        ontimer = function,
        [1,n] = cel or function or string
      }
    ]==];

    params = {
      param.table[[(table) - The table that is passed as the single argument to this function. 
        The other parameters documented here refer to the entries in this table.]];
      param.number[[w - passed as w param of factory.new if present.]];
      param.number[[h - passed as h param of factory.new if present.]];
      param.any[[face - passed as face param of factory.new if present.]];
      param['function'][[onresize - set as event callback if present.]];
      param['function'][[onmousein - set as event callback if present.]];
      param['function'][[onmouseout - set as event callback if present.]];
      param['function'][[onmousemove - set as event callback if present.]];
      param['function'][[onmousedown - set as event callback if present.]];
      param['function'][[onmouseup - set as event callback if present.]];
      param['function'][[onfocus - set as event callback if present.]];
      param['function'][[onkeydown - set as event callback if present.]];
      param['function'][[onkeyup - set as event callback if present.]];
      param['function'][[onchar - set as event callback if present.]];
      param['function'][[oncommand - set as event callback if present.]];
      param['function'][[ontimer - set as event callback if present.]];
      param['[1,n]'] {
        name = 'links';
        tabledef {
          description = [[When the cel is created each entry from 1 to n is evaluated in order 
            where n is #(table).  The entry is must be on of the following:]];
            key.cel[[If the entry is a cel then it is linked to cel being created. cel:link is called
              with cel.linker, cel.xval, cel.yval.]];
            key.string[[If the entry is a string a new cel.label is created with the string and then
              linked to the cel being created.]];
            key['function'][[If the entry is a function, it is called with the new cel as its only parameter.  
              The return value from this function is ignored.]];
        };
      };
    };

    returns = {
      param.cel[[cel - a new cel.]]
    };
  };
}
