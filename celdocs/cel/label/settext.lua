namespace 'celdocs'

export[...] {
  functiondef['label:settext'] {
    description = [[Changes the text of the label.  When the text is changed the label is resized and refreshed.]];

    synopsis = [=[
      label:settext(text)
    ]=];

    params = {
      param.label[[self - self]];
      param.string[[text - the new text of the label.  No effect if it is equal to the current text.]];
    };

    returns = {
      rparam.label[[self]];
    };
  };

  notes {
    [[TODO determine behavior for a nil text value in settext]];
    [[TODO describe behavior for a '' text value in settext]];
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local label = cel.label.new(''):link(host, 'center')

    function host:onmousemove(x, y)
      label:settext('mousemoved ' .. x ..' '.. y)
    end
    ]==];
  };
}
