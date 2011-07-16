namespace 'celdocs'

export[...] {
  functiondef['cel:link'] {
    description = [[links a cel to a host cel.]];

    synopsis = [=[
      acel:link(host[, (0)x[, (0)y[, (nil)option]]])
      acel:link(host[, (nil)linker[, (nil)xval[, (nil)yval[, (nil)option]]]])
    ]=];

    params = {
      param.cel[[self - self]];
      param.cel[[host - cel to link to]];
      param.number[[x - x position of the cel relative to host]];
      param.number[[y - y position of the cel relative to host]];
      param.linker[[linker - linker function]];
      param.any[[xval - xval param passed to linker]];
      param.any[[yval - yval param passed to linker]];
      param.any[[option - Indicates to the host how the link should be made.
                          The meaning of this is dictated by the host.]];
    };

    returns = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[If the cel is already linked to a different host then the cel is unlinked before attempting to link to the
      new host.]];

    [[
      When a cel is linked, the host metacel may retarget the host to another host cel and may also overrule any
      of the other parameters via the __link metacel method.        
    ]];

    [[When cel a is linked to cel b we call cel b the host and cel a the link.]];

    [[When a cel is linked it is the top-most link of the host.  Conceptually it is put on the top of the hosts
      links stack.]];
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

    --links acel to host at 10(left), 50(top)
    acel:link(host, 10, 50)
    ]==],

    [==[
    local cel = require 'cel'
    local host = ...

    local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

    --links acel to host and acel is centered using the built in linker 'center'.
    acel:link(host, 'center') 
    ]==],

    [==[
    local cel = require 'cel'
    local host = ...
    local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

    --links acel to host and acel is centered using a custom linker.
    function center(hw, hh, x, y, w, h)
      return (hw - w)/2, (hh - h)/2, w, h
    end
     
    acel:link(host, center)
    ]==],

    [==[
    local cel = require 'cel'
    local host = ...
    local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

    --link acel to a sequence using the option parameter to specify the index in the sequence
    local sequence = cel.sequence.y {
      'a', 'b', 'c', 'd'
    }
     
    acel:link(sequence, nil, nil, nil, 3)

    --link sequence to host
    sequence:link(host)
    ]==],

    [==[
    local cel = require 'cel'
    local host = ...
    local acel = cel.new(100, 100, cel.color.rgb(133, 133, 133))

    --link acel to a sequence off-centered 10 to the left.
    local sequence = cel.sequence.y {
      'a', 'b', 'c', 'd'
    }

    acel:link(sequence, 'center', -10, nil, 3)
    
    --link sequence to host 'edges' makes it fill the host
    sequence:link(host, 'edges')

    --a vertical center line to make offset obvious
    cel.new(1, 1, cel.color.rgb(255, 0, 0)):link(host, 'center.height')
    ]==],
  };
}
