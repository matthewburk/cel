namespace 'celdocs'

export[...] {
  functiondef['cel:flow'] {
    description = [[moves the cel, but 1 or more intermediate states can be injected by the flow callback.]];

    synopsis = [==[
      acel:flow(flowfunction, x, y, w, h[, update[, finalize]])
      acel:flow(flowname, x, y, w, h[, update[, finalize]])
    ]==];

    params = {
      param.cel[[self - self]];
      param.callback {
        name='flowfunction';    
        description=[[a function that produces intermediate states]];    
        functiondef['callback'] {
          synopsis = [==[
            flowfunction(context, ox, x, oy, y, ow, w, oh, h)
            flowfunction(context, ox, x, oy, y, ow, w, oh, h)
          ]==];

          params = {
            param.table {
              name='context';
              
             
              tabledef {
                description=[[Storage for flow life-cycle data.  The context can also be used by the flowfunction to
                store data.  The context is included in the drawtable of a cel, until the flow is finalized.]];

                key.iteration[[The number of times the flowfunction has been called, initially 1,
                  incremented by 1 when the flowfuction returns]];
                key.duration[[The number of milliseconds since the flow was started, initially 0,
                  reset when the flow function returs]];
                key.finalize[[initially -1, when the flow is about to be finalized this is set to
                  context.iteration]];
              };
            };
            param.number[[x - x position when flow started.]];
            param.number[[fx - x position when flow ends.]];
            param.number[[y - y position when flow started.]];
            param.number[[fy - y position when flow ends.]];
            param.number[[w - w dimension when flow started.]];
            param.number[[fw - w dimension when flow ends.]];
            param.number[[h - h dimension when flow started.]];
            param.number[[fh - h dimension when flow is ends.]];
          };

          returns = {
            param.number[[x - intermediate x position.]];
            param.number[[y - intermediate y position.]];
            param.number[[w - intermediate width.]];
            param.number[[h - intermediate height.]];
            param.boolean[[continue - true if the flow is incomplete, if not true this signals the end of the flow.]];
          };
        };
      };

      param.any[[flowname - a key to a flowfunction defined in the cel's face.  (self:getface().flow[flowname]) ]];
      param.number[[x - new x position of self relative to host. Defaults to self.x if nil]];
      param.number[[y - new y position of self relative to host. Defaults to self.y if nil]];
      param.number[[w - new width of self. Defaults to self.w if nil]];
      param.number[[h - new height of self. Defautls to self.h if nil]];
      param.callback {
        name='update';    
        description=[[called to move the cel to a new position.  Defaults to cel.move if nil.]];    
        functiondef['callback'] {
          synopsis = [==[
            update(self, x, y, w, h)
          ]==];

          params = {
            param.cel[[self - self (same self from cel:flow)]];
            param.number[[x - new x position of self.]];
            param.number[[y - new y position of self.]];
            param.number[[w - new width of self.]];
            param.number[[h - new height of self.]];
          };
        };
      };
      param.callback {
        name='finalize';
        description=[[called when the flow has completed --TODO describe what completed means.]];
        functiondef['callback'] {
          synopsis=[==[
            finalize(self)
          ]==];

          params = {
            param.cel[[self - self (same self from cel:flow)]];
          };
        };
      };
    };

    returns = {
      param.cel[[self - self]];
    };
  };

  notes {
    [[
    If flowfunction is nil or flowname does not have an entry in self:getface().flow then update is called with the 
    final position followed by a call to finalize.  So acel:flow(nil, x, y, w, h) has the same effect as 
    acel:move(x, y, w, h).
    ]];

    [[
    When a flow starts the flowfunction is called to get its initial position which is passed to update().  Thereafter
    flowfunction/update are called when the cel driver moves cel.timer() forward.
    ]];    
  };

  examples {
    [==[
    local cel = require 'cel'
    local host = ...

    local button = cel.button.new(100, 100):link(host, 'center'):relink()

    local function lerp(a, b, p)
      return a + p * (b -a)
    end

    local duration = 1000

    local function linearflow(context, ox, x, oy, y, ow, w, oh, h)
      if context.duration >= duration then return x, y, w, h end
      local dt = context.duration/duration
      x = lerp(ox, x, dt)
      y = lerp(oy, y, dt) 
      w = lerp(ow, w, dt)
      h = lerp(oh, h, dt)
      return x, y, w, h, true
    end
    
    function button:onclick()
      local toggle = button.onclick
      local x, y, w, h = button:pget('x', 'y', 'w', 'h')
      function button:onclick()
        self:flow(linearflow, x, y, w, h)
        button.onclick = toggle
      end
      self:flow(linearflow, 
                math.random(0, 200),
                math.random(0, 200),
                math.random(50, 200),
                math.random(50, 200))
    end

    ]==];

  };
}
