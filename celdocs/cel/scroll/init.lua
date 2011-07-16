namespace 'celdocs'

export[...] {
  factorydef['cel.scroll'] {
    description = [[Creates scrolls.]];

    functions = {
      '__call',
      'new',
      'newmetacel',
      'newfactory',
    };

    entries = {
      key.layout {
        tabledef {
          description = 'Internal scroll options and layout';
          key.stepsize[[The number of units to move the subject in a single step.  This is used in scroll:step()]];
          key.ybar {
              description = [[Options and internal layout for the vertical scrollbar]];
              key.autohide[[If true the scrollbar will hide when the portal height >= subject height]];
              key.size[[The width of the scrollbar]]; 
              key.track {
                  description = [[Options and internal layout for the track]];
                  key.size[[The width of the track]];
                  key.link[[The linker, xval, yval of the track]];
                  key.slider {
                      description = [[Options for the slider]];
                      key.size[[The width of the slider]];
                      key.minsize[[The minimum height of the slider]];
                  };
              };
              key.decbutton {
                  description = [[Options and internal layout for the decrement button]];
                  key.size[[The width and height of the button]];
                  key.link[[The linker, xval, yval of the button]];
              };
              key.incbutton {
                  description = [[Options and internal layout for the increment button]];
                  key.size[[The width and height of the button]];
                  key.link[[The linker, xval, yval of the button]];
              };
          };
          key.xbar {
              description = [[Options and internal layout for the horizontal scrollbar]];
              key.autohide[[If true the scrollbar will hide when the portal width >= subject width]];
              key.size[[The height of the scrollbar]]; 
              key.track {
                  description = [[Options and internal layout for the track]];
                  key.size[[The height of the track]];
                  key.link[[The linker, xval, yval of the track]];
                  key.slider {
                      description = [[Options for the slider]];
                      key.size[[The height of the slider]];
                      key.minsize[[The minimum width of the slider]];
                  };
              };
              key.decbutton {
                  description = [[Options and internal layout for the decrement button]];
                  key.size[[The width and height of the button]];
                  key.link[[The linker, xval, yval of the button]];
              };
              key.incbutton {
                  description = [[Options and internal layout for the increment button]];
                  key.size[[The width and height of the button]];
                  key.link[[The linker, xval, yval of the button]];
              };
          };
        };
      };
    };
  };

  celdef.scroll {
    metacel = 'scroll';
    factory = 'cel.scroll';

    description = [[A simple scroll that responds to mouse and keyboard inputs.]];

    functions = { 
      'step'; --
      'scrollto';
      'getvalue';
      'getmaxvalue';
      'setsubject';
      'getsubject';
      'getportal';
    };

    events = {
      'onchange'; --fired when the value of the scroll changes
    };

    metamethods = {
      '__link';
    };

    metaevents = {
      'onmousewheel';
    };

    innercels = {
      key['scroll.portal'] { 
        description = 'The client cel for a scroll, cels linked to a scroll are linked to the portal';
      };
      key['scroll.bar'] { 
        description = [[A scrollbar can be horizontal or vertical.  
        A scrollbar is composed of buttons and track which contains a slider']];
      };
      key['scroll.bar.inc'] { 
        description = 'A button that increases value of the scrollbar';
        inheritsfrom = 'button';
      };
      key['scroll.bar.dec'] { 
        description = 'A button that decreases value of the scrollbar';
        inheritsfrom = 'button'; 
      };
      key['scroll.bar.track'] {
        description = [[The slider sits in the track.  ]];
        inheritsfrom = 'button'; 
      };
      key['scroll.bar.slider'] { 
        description = [[The sliders size will change in proportion to the size of the portal to the subjet.]];
        inheritsfrom = 'grip';
      };
    };

    drawtable = {
      description = [[A scroll does not define any additional properties.  A scroll is a composite cel so the structure
      of it can be exploited during rendering.
      
      This is a representation of the internal structure of a scroll
      ]];
      section { margin='1em';
        code [[
          scroll.portal
          scroll.bar {
            scroll.bar.inc
            scroll.bar.dec
            scroll.bar.track {
              scroll.bar.slider
            }
          }
          scroll.bar {
            scroll.bar.inc
            scroll.bar.dec
            scroll.bar.track {
              scroll.bar.slider
            }
          }
        ]];
      };
    };
  };
}

