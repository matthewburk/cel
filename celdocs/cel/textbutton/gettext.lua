template['T.function']
{
  description = [[Returns the text string of the textbutton.]];

  synopsis = [==[ 
    textbutton:gettext()
  ]==];

  params = {
    [[textbutton self - self]];
  };

  returns = {
    [[string text - the current text string of the textbutton.]];
  };

  notes = {
  };

  examples = {
    [==[
    local cel = require 'cel'
    local host = ...

    local listbox = cel.listbox.new():link(host, 'edges')
    local textbutton = cel.textbutton.new('Hello'):link(listbox)

    function host:onmousemove(x, y)
      textbutton:printf('%s %d %d', textbutton:gettext(), x, y)
    end
    ]==];
  };
}
