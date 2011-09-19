local cel = require 'cel'

--this is  a namespace for a document, defines custom tags

local testns = getfenv()['D:/projects/cel-reactor/cel/test/document/testns.lua']
testns.cel = cel

text.h1 = { 
  face = cel.getface('document.text'):new {
    font = cel.loadfont('arial', 34),
  }:register('h1')
}
text.h2 = { 
  face = cel.getface('document.text'):new {
    font = cel.loadfont('arial', 24),
  }:register('h2')
}
text.h3 = { 
  face = cel.getface('document.text'):new {
    font = cel.loadfont('arial', 15),
  }:register('h3')
}

list.links = {
  template = function(L, item)
    local target = L.targetprefix or '.'
    return hyperlink { target=target .. item; text=item };
  end;
}

list.bulleted = {
  template = function(L, item)
    return section { leftmargin='2em';      
      row {
        section { 
          link = {'center.top'};
          cel.label.new('*');
        };
        section {
          item
        }

        --[[
        { minw=100, weight=1,
          cel.document {
            self = cel.document.loadelement(item);
            link = {'width'}
          }
        }
        --]]
      };
    };
  end;
}
