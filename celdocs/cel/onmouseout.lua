namespace 'celdocs'

export[...] {
  eventdef['cel:onmouseout'] {
    description = [[Singaled when a cel loses focus of the mouse.]];

    synopsis = [==[
      cel:onmouseout()
    ]==];

    params = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[onmouseout will always be preceeded by onmousein.]];
  };

  examples {
    [==[
    local cel = require('cel')
    local host = ...

    local a = cel.new(100, 100, cel.color.rgb(244, 233, 0)):link(host, 'center')
    local b = cel.new(50, 50, cel.color.rgb(231, 0, 23))

    function a:onmousein()
      b:link(a, 'center')
    end

    function a:onmouseout()
      b:unlink()
    end

    ]==];
  }
}
