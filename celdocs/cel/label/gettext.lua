namespace 'celdocs'

export[...] {
  functiondef['label:gettext'] {
    description = [[Returns the text of the label.]];

    synopsis = [==[
      label:gettext()
    ]==];

    params = {
      param.label[[self - self]];
    };

    returns = {
      rparam.string[[the text of the label.]];
    };
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local listbox = cel.listbox.new():link(host, 'edges')
    local label = cel.label.new('Hello'):link(listbox)

    function host:onmousemove(x, y)
      label:printf('%s %d %d', label:gettext(), x, y)
    end
    ]==];
  };
}
