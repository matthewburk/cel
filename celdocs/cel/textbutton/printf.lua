template['T.function']
{
  description = [[A shorcut for textbutton:settext(string.format(format, ...)).]];

  synopsis = [==[ 
    textbutton:printf(format[, ...])
  ]==];

  params = {
    [[textbutton self - self]];
    [[string format - See lua documentation for string.format.]];
    [[varargs ... - See lua documentation for string.format.]];
  };

  returns = {
    [[textbutton self - self.]]
  };

  notes = {
  };

  examples = {
    [==[
    local cel = require 'cel'
    local host = ...

    local textbutton = cel.textbutton.new(''):link(host, 'center')

    function textbutton:onclick(mousebutton, x, y)
      self:printf('clicked at  %d %d', x, y)
    end
    ]==];
  };
}
