namespace 'celdocs'

export[...] {
  factorydef.cel {
    description = [[This is the main module for the cel libarary.]];

    functions = {
      '__call',
      'new',
      'newmetacel',
      'newfactory',
      'installdriver',
      'describe',
      'loadfont',
      'match',
      'getlinker',
      'addlinker',
      'composelinker',
      'rcomposelinker',
      'unpacklink',
      'doafter',
      'printdescription',
      'translate',
    };
  };

  celdef.cel {
    metacel = 'cel';
    factory = 'cel';

    description = [[
    The primary building block of the cel library. The name cel is short for control element.
    ]];

    functions = { 
      'link',
      'relink',
      'unlink',
      'move',
      'moveby',
      'resize',
      'raise',
      'sink',
      'islinkedto',
      'hasfocus',
      'takefocus',
      'trapmouse',
      'freemouse',
      'hasmousetrapped',
      'getface',
      'addlistener',
      'removelistener',
      'flow',
      'flowvalueTODO',
      'flowlinkTODO',
      'getflowTODO',
      'isflowingTODO',
      'reflowTODO',
      'endflowTODO',
      'pget',
    };

    events = { 
      'onresize',
      'onfocus',
      'onmousein',
      'onmouseout',
      'onmousemove',
      'onmousewheel',
      'onmousedown',
      'onmouseup',
      'onkeydown',
      'onkeyup',
      'onchar',
      'ontimer',
      'oncommand',
    };

    drawtable = {
      description = {
        [[This table is the description of a cel intended to be used to render the cel.]];
        linebreak;
        [[If the area defined by the drawtable.clip is <= 0 for a cel then that cel is not described.  Which means that 
          clip.l < clip.r is always true and clip.t < clip.b is always true.]];
      };

      key['[1,n]'][[The render tables for cels linked to the described cel. The order is front
          to back(top to bottom) meaning drawtable[1] is the frontmost link and drawtable[n] is the backmost.]];
      key.host[[The host drawtable.]];
      key.x[[The x value of the described cel in driver space.]];
      key.y[[The y value of the described cel in driver space.]];
      key.w[[The w value of the described cel in driver space.]];
      key.h[[The h value of the described cel in driver space.]];
      key.mousefocus {
        description = [[Indicates if the mouse is focused on the cel, can be one of these values:]];
        key['1'] [[If cel:hasfocus(cel.mouse) == 1.]];
        key['true'] [[If cel:hasfocus(cel.mouse) > 1.]];
        key['false'] [[If cel:hasfocus(cel.mouse) return false.]];
      };
      key.keyboardfocus {
        description = [[Indicates if the keyborad is focused on the cel, can be one of these values:]];
        key['1'][[If cel:hasfocus(cel.keyboard) == 1.]];
        key['true'][[If cel:hasfocus(cel.keyboard) > 1.]];
        key['false'][[If cel:hasfocus(cel.keyboard) return false.]];
      };
      key.clip {
        description = [[
          Defines the clipping rectangle for the described cel.  This will always be as or more restrictive
          than the clipping recatangle for the host.
        ]];

        key.l[[The left of the clipping rectangle in driver space.]];
        key.t[[The top of the clipping rectangle in driver space.]];
        key.r[[The right of the clipping rectangle in driver space.]];
        key.b[[The bottom of the clipping rectangle in driver space.]];
      };
    };
  };

  --[===[
   metaceldef.cel {
    description = [[
      The metacel for all cels.  A metacel is an object that creates cels and is similar to a class in the OOP sense.
      The metacel defines the behavior of cels that it creates through a collection of metamethods.  
    ]];

    functions = {
      'new';
      'compile';
      'newmetacel';
      'asyncall';
      'getface';
      'setlimits';
    };

    metamethods = {
      '__link';
      '__relink';
      '__unlink';
      '__describe';
      '__resize'; --called sync, do not call unknown functions in this metamethod
      '__linkmove'; --called sync, do not call unknown functions in this metamethod
    };
  };
  --]===]
}

