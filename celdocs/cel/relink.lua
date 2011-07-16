namespace 'celdocs'

export[...] {
  functiondef['cel:relink'] {
    description = [[changes the linker, xval and yval parameters of a linked cel. 
    The cel remains linked to the same host.]];

    synopsis = [==[
      acel:relink([(nil)linker[, (nil)xval[, (nil)yval]]])
    ]==];

    params = {
      param.cel[[self - self]];
      param.linker[[linker - linker function or name]];
      param.any[[xval - xval param passed to linker]];
      param.any[[yval - yval param passed to linker]];
    };

    returns = {
      param.cel[[self - self]];
      param.boolean[[success - false if relink failed, otherwise true]];
    };
  };

  notes {
    [[When a cel is relinked the host metacel may overrule the linker, xval and yval.]];
    [[If the linker param is present but is not a function then a lookup is done in the linkers table using linker
      as the key.  If the lookup returns nil then relink has no effect and returns self, false.]];
  };

  examples {
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
}


  --[=[


  seealso = {
    'cel.unlink',
    'cel.relink',
    'linkers',
    'cel.sequence',
  }
}
--]=]

