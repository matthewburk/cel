local cel = require 'cel'

 cel.document.face.h1 {
  font = cel.loadfont('calibri:bold', 24),
  textcolor = cel.color.rgb(20, 40, 62),
}

cel.document.face.h2 {
  font = cel.loadfont('calibri:bold', 18),
  textcolor = cel.color.rgb(20, 40, 62),
}

cel.document.face.h3 {
  font = cel.loadfont('calibri:bold', 12),
  textcolor = cel.color.rgb(89, 126, 154),
}

cel.document.face['@code'] {
  font = cel.loadfont('courier new:bold', 11),
}

cel.document.face['@paramdescription'] {
  --font = cel.loadfont('tahoma', 12),
  font = cel.loadfont('arial', 12),
  textcolor = cel.color.rgb(0, 0, 0),
}

cel.document.face['@reading'] {
  --font = cel.loadfont('arial', 11),
  font = cel.loadfont('arial', 12),
  textcolor = cel.color.rgb(0, 0, 0),
}

local function main(root)
local _ENV = setmetatable({}, {__index = cel.util.memo__index(_G)})
setfenv(1, _ENV)

documents = {}

function root:onkeydown(state, key)
  print('onkeydown', cel.keyboard.keys[' '], cel.keyboard.keystates.pressed)
  if key == cel.keyboard.keys[' '] and state == cel.keyboard.keystates.pressed then

    cel.printdescription()
  end
  print('keypressed', state, key)
end

do
  local t = {}
  template = setmetatable({},
  {
    __newindex = function(proxy, k, v)
      t[k] = v
    end;

    __index = function(proxy, k)
      return setfenv(t[k], getfenv(2))
    end;
  })
end

do
  stack = {}

  function fetch(name)
    print('fetching ', name)

    local document = documents[name]

    if not document then
      document = cel.document.loadfile(name)
      documents[name] = document
      ---[[
      function document:onhyperlinkevent(target, etype)
        print('link clicked', target)
        local newdoc = fetch(target)
        SCROLL:setsubject(newdoc, true, true)
        print('link handled', target, SCROLL, newdoc)
      end
      --]]
    end

    stack[#stack + 1] = document
      assert(document)
    return document
  end
end

do --toolbar
  toolbar = cel.sequence.x {
    cel.textbutton {
      text = '<--',
      onclick = function(button)
        print('clicked', button, #stack)
        stack[#stack] = nil
        if stack[#stack] then
          SCROLL:setsubject(stack[#stack], true, true)
        end
      end;
    };
    cel.textbutton {
      text = 'print',
      onclick = function()
        cel.printdescription()
      end;
    };
    cel.textbutton {
      text = 'fps';
      function(self)
        _G.showfps = function(fps)
          self:settext(fps)
        end
      end;
    };
  }

end



  cel.face {
    metacel = 'document.divider',
    fillcolor = cel.color.rgb(213, 227, 238),
    --color = reactor.cel.drawcolor,
  }


  cel.face {
    metacel = 'document.text',
    --font = cel.loadfont('corbel', 10),
    --font = cel.loadfont('tahoma', 11),
    font = cel.loadfont('times new roman', 12),
  }

  cel.face {
    metacel = 'document.border',
    --fillcolor = cel.color.rgb(229, 241, 250),
    linecolor = cel.color.rgb(213, 227, 238),
  }

  cel.face {
    metacel = 'document.section',
    fillcolor = false,
    linecolor = false,
    cornerradius = 0,
  }

  cel.face {
    metacel = 'document.section',
    name = 'highlight',
    fillcolor = cel.color.rgb(233, 245, 255),
    linecolor = cel.color.rgb(215, 232, 247),
    cornerradius = 0,
  }

  cel.face {
    metacel = 'document.section',
    name = 'roundedge',
    fillcolor = false,
    linecolor = cel.color.rgb(115, 132, 147),
    cornerradius = 4,
  }

  cel.face {
    metacel = 'document.section',
    name = 'listitem',
    fillcolor = cel.color.rgb(233, 245, 255),
    linecolor = cel.color.rgb(115, 132, 147),
    cornerradius = 4,
  }

  cel.face {
    metacel = 'document',
    fillcolor = cel.color.rgb(248, 252, 255),
    --draw = reactor.cel.drawcolor,
  }

  cel.face {
    metacel = 'document.hyperlink',
    font = cel.loadfont('Arial', 12),
    hovercolor = cel.color.rgb(0, 65, 255),
    textcolor = cel.color.rgb(0, 0, .3 * 255),
    layout = {
      padding = {
        l = 2,
        t = 1,
      },
    },
  }

    cel.scroll {
      link = {cel.rcomposelinker('width.yval->bottom', 'edges'), {0, toolbar.h; nil, nil}},
      subject = fetch('celdocs.index'),
      subjectfillx = true,
      subjectfilly = true,
      function(scroll)
        SCROLL = scroll
      end,
    }:link(root, {cel.rcomposelinker('width.yval->bottom', 'edges'), {0, toolbar.h; nil, nil}})
    toolbar:link(root)

  end

  return main
