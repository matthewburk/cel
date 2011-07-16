local cel = require('cel')

celdocs.cel = cel

list.links = {
  template = function(L, item)
    local target = L.targetprefix or '.'
    return hyperlink { target=target .. item; text=item };
  end;
}

list.bulleted = {
  template = function(L, item)
    return section { leftmargin='2em';
      cel.row {
        link = {'width'},
        cel.document.loadelement( 
          section { topmargin = '.4em', margin='.5em';
            link = {'center.top'};
            cel {
              w = 7, h = 7; face = '@circle';
            };
          });

        { minw=100, weight=1,
          cel.document {
            self = cel.document.loadelement(item);
            link = {'width'}
          }
        }
      };
    };
  end;
}

text.h1 = { face = cel.document.face.h1; }
text.h2 = { face = cel.document.face.h2; }
text.h3 = { face = cel.document.face.h3; }

do --params, returns
  
end

do --factorydef

  local function entrytemplate(L, pair)
    return {
      linebreak;
      text.h3 { pair[1] };
        pair[2];
    };
  end

  local function factorydef(name, t)
    t.functions.targetprefix = '.factory.';

    return {
      section { leftmargin=2, topmargin=5, face='highlight';
        text.h1 { name .. ' (factory)' };
        section { leftmargin='.5em'; paragraph(t.description) };
      };

      section { margin='1em';
        text.h2[[Functions]];
        hline;
        linebreak;
        list.links(t.functions);
      };

      t.entries and {
        linebreak;
        section { margin='1em';
          text.h2[[Entries]];
          hline;
          list {
            template = entrytemplate;
            unpack(t.entries);
          };
        };
      } or false;
    }
  end

  celdocs.factorydef = cel.document.newtag(factorydef)
end

do --functiondef
  local function paramtemplate(L, param)
    return {
      sequence {
        hyperlink { text=param.type, target=param.type };
        '- ' .. param.name;
      };
      section { leftmargin='2em';
        param.description;
        param;
      };
    }
  end

  local function rparamtemplate(L, param)
    return {
      sequence {
        hyperlink { text=param.type, target=param.type };
      };
      section { leftmargin='2em';
        param.description;
        param;
      };
    }
  end

  local params = cel.document.newtag(function(name, t)
    t.template = paramtemplate
    return list(t)
  end)

  local rparams = cel.document.newtag(function(name, t)
    t.template = rparamtemplate
    return list(t)
  end)

  local function functiondef(name, t)
    if name == 'callback' then
      return {
        section { leftmargin=2, face='highlight';
          section { margin='1em';
            text.h3[[Synopsis]];
            section { leftmargin='1.5em', topmargin=6, face='roundedge';
              code(t.synopsis);
            };

            t.params and {
              linebreak;

              text.h3[[Parameters]];
              section { leftmargin='1.5em', topmargin=6, face='roundedge';
                params(t.params); 
              };
            } or false; 

            t.returns and {
              linebreak;

              text.h3[[Returns]];
              section { leftmargin='1.5em', topmargin=6, face='roundedge';
                rparams(t.returns); 
              };
            } or false;
          };
        };
      }
    end
    return {
      section { leftmargin=2, topmargin=5, face='highlight';
        text.h1 { 'function ' .. name };
        section { leftmargin='.5em'; paragraph(t.description) };
      };

      section { margin='1em';
        text.h3[[Synopsis]];
        section { leftmargin='1.5em', topmargin=6, face='roundedge';
          code(t.synopsis);
        };

        t.params and {
          linebreak;

          text.h3[[Parameters]];
          section { leftmargin='1.5em', topmargin=6, face='roundedge';
            params(t.params); 
          };
        } or false;

        t.returns and {
          linebreak;

          text.h3[[Returns]];
          section { leftmargin='1.5em', topmargin=6, face='roundedge';
            rparams(t.returns)
          };
        } or false;
      };
    }
  end

  celdocs.functiondef = cel.document.newtag(functiondef)

  celdocs.param = cel.document.newtag( function(typename, value) 
    if type(value) == 'table' then
      value.type = value.type or typename
      return value
    else
      local name, description = value:match('(%S+)%s+.%s+(.*)')
      return {type=typename, name=name, description=description} 
    end
  end)

  celdocs.rparam = cel.document.newtag( function(typename, value) 
    if type(value) == 'table' then
      value.type = value.type or typename
      return value
    else
      return {type=typename, description=value} 
    end
  end)
end

do --eventdef
  local function paramtemplate(L, param)
    return {
      sequence {
        hyperlink { text=param.type, target=param.type };
        '- ' .. param.name;
      };
      section { leftmargin='2em';
        paragraph {
          param.description;
        };

        param;
      };
    }
  end

  local params = cel.document.newtag(function(name, t)
    t.template = paramtemplate
    return list(t)
  end)

  local function eventdef(name, t)
    return {
      section { leftmargin=2, topmargin=5, face='highlight';
        text.h1 { 'event ' .. name };
        section { leftmargin='.5em'; paragraph(t.description) };
      };

      section { margin='1em';
        function()
          if t.trigger then
            return {

              text.h3[[Trigger]];
              section { leftmargin='1.5em', topmargin=6, face='roundedge';
                section { margin = '1em', face = 'listitem';
                  paragraph(t.trigger);
                };
              };

              linebreak;
            }
          end
        end;

        text.h3[[Synopsis]];
        section { leftmargin='1.5em', topmargin=6, face='roundedge';
          code(t.synopsis);
        };

        linebreak;

        text.h3[[Parameters]];
        section { leftmargin='1.5em', topmargin=6, face='roundedge';
          params(t.params); 
        };

        t.returns and {
          linebreak;

          text.h3[[Returns]];
          section { leftmargin='1.5em', topmargin=6, face='roundedge';
            params(t.returns)
          };
        }; 
      };
    }
  end

  celdocs.eventdef = cel.document.newtag(eventdef)
end

do --celdef
  local function celdef(name, t)
     return {
      section { leftmargin=2, topmargin=5, face='highlight';
        text.h1 { name .. ' (cel)' };
        section { leftmargin='.5em'; paragraph(t.description) };
      };

      section { margin='1em';
        text.h2[[Functions]];
        hline;
        linebreak;

        list.links(t.functions);
      };

      section { margin='1em';
        text.h2[[Events]];
        hline;
        linebreak;

        list.links(t.events);
      };

      section { margin='1em';
        text.h2[[Render table]];
        hline;
        linebreak;

        celdocs.tabledef(t.drawtable);
      };
    }
  end

  celdocs.celdef = cel.document.newtag(celdef)
  
end

do  --tabledef

  list.tablekeys = {
    template = function(L, item)

      if not item.iskey then
        return item
      end

      local name, value = item[1], item[2]

      if type(value) == 'table' then
        return section { margin='.5em';
            cel.row {
              cel.document.loadelement(sequence {
                section { margin = '.5em';
                  link = {'center'};
                  cel {
                    w = 7, h = 7; face = '@circle';
                  };
                };
                section {
                  link = {'center'};
                  text {name};
                };
              });
              ' - ';
              {
                weight = 1,
                minw = 20,
                cel.document.loadelement(cel.document { 
                  link = {'width'},
                  value.description,-- or 'table');
                });
              }
            };
          section { leftmargin='2em';
            list.tablekeys(value);
          };
        }
      end

      return section { margin='.5em';
        sequence {
          sequence {
            section { margin = '.5em';
              link = {'center'};
              cel {
                w = 7, h = 7; face = '@circle';
              };
            };
            section { 
              link = {'center'};
              text{ name };
            };
          };
          ' - ';
          function()
            if type(value) == 'string' then
              return section { w = 500; 
                paragraph(value);
              }
            end
            return value
          end;
        }; 
      }
    end;
  }
 
  local tabledef = function(name, t)
    return section {
      section { margin='.5em', face = 'highlight';
        paragraph(t.description or 'table');
      };
      section { leftmargin='1em';
        list.tablekeys(t);
      }
    }
  end

  celdocs.tabledef = cel.document.newtag(tabledef)

  local keydef = function(name, s) 
    if type(s) == 'string' then
      return {name, s, iskey=true} 
    elseif type(s) == 'table' then
      return {name, s, iskey=true}
    end
  end

  celdocs.key = cel.document.newtag(keydef)
end

do --notes
  local function note(L, s)
    return {
      section { margin = '1em', face = 'listitem';
        paragraph(s);
      };
      linebreak;
    }
  end

  local function notes(name, t)
    t.template = note
    return { 
      text.h2 { 'Notes' };
      hline;
      section { margin='1em'; 
        list(t);
      };
    }
  end

  celdocs.notes = cel.document.newtag(notes)
end

do --examples
  local function example(L, s)
    return {
      section { margin='1em', face = 'highlight';
         section { leftmargin = 3, topmargin = 6, face = 'roundedge';
          section { margin = '1em';
            code(s); 
          };
        };
        linebreak;
        section { margin = 1, link = {'center'}, face = 'roundedge';
          cel { 
            w = 300,
            h = 300, 
            face = cel.color.rgb(255, 255, 255),
            link = {'center'},

            function(host) --TODO must have way to lookup a cel by name
              local button = cel.textbutton.new('run example'):link(host, 'center')
              function button:onclick()
                self:unlink()
                assert(loadstring(s))(host)
              end
            end
          };
        };
      };
      linebreak;
    }
  end

  function celdocs.examples(t)
    t.template = example
    return {
      text.h2[[Examples]];
      hline;
      linebreak;
      list(t);
    }
  end
end
