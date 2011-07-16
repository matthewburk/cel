template['T.function']
{
  description = [[Changes the text of the textbutton.  When the text is changed the textbutton is resized and refreshed.]];

  synopsis = [==[ 
    textbutton:settext(text)
  ]==];

  params = {
    [[textbutton self - self]];
    [[string text - the new text string of the textbutton.  No effect if it is equal to the current text.]];
  };

  returns = {
    [[textbutton self - self.]]
  };

  notes = {
    [[TODO determine behavior for a nil text value in settext]];
    [[TODO describe behavior for a '' text value in settext]];
  };

  examples = {
    [==[
    local cel = require 'cel'
    local host = ...

    local textbutton = cel.textbutton.new(''):link(host, 'center')

    function host:onmousemove(x, y)
      textbutton:settext('mousemoved ' .. x ..' '.. y)
    end
    ]==];
  };
}
