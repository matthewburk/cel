namespace 'celdocs'

export[...] {
  functiondef['cel.button.__call'] {
    description = [[Creates a new button.  This function is called by calling the cel.button factory, see example.]];

    synopsis = [==[
      cel.button {
        w = number,
        h = number,
        face = any,
        [1,n] = cel or function or string
      }
    ]==];

    params = {
      param.table[[(table) - The table that is passed as the single argument to this function. 
        The other parameters documented here refer to the entries in this table.]];

      param.number[[w - passed as w param of factory.new if present.]];
      param.number[[h - passed as h param of factory.new if present.]];
      param.any[[face - passed as face param of factory.new if present.]];
      param['function'][[onclick - set as event callback if present.]];
      param['function'][[onpress - set as event callback if present.]];
      param['function'][[onhold - set as event callback if present.]];
    };

    returns = {
      param.button[[button - a new button.]]
    };
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local function flowjiggle(context, ox, x, oy, y, ow, w, oh, h)
      if context.iteration < 10 or context.duration < 250 then
        return x + math.random(-4, 4), y + math.random(-4, 4), w, h, true
      else
        return x, y, w, h
      end
    end

    local function jiggle(c)
      c:flow(flowjiggle, c.x, c.y)
    end

    local button = cel.button {
      w = 200, h = 200,
      onclick = jiggle;

      cel.button {
        w = 33, h = 77, link = {'right.bottom', 10, 10};
      }
    }

    button:link(host, 'center'):relink()

    ]==]
  };
}
