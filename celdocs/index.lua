namespace('celdocs')

local p = paragraph
local br = linebreak

export[...] {
  text.h1{ [[modules]] };

  list { 
    hyperlink{ text='cel', target='celdocs.cel'};
    hyperlink{ text='cel.button', target='celdocs.cel.button'};
    hyperlink{ text='cel.label', target='celdocs.cel.label'};
    hyperlink{ text='cel.textbutton', target='celdocs.cel.textbutton'};
    hyperlink{ text='cel.scroll', target='celdocs.cel.scroll'};
  };

  p [[About cel.]];

  p [[The name cel is a (whats it called) for (c)ontrol (e)lement (l)ibrary.  cel is a meta gui library,
      in the sense that it does not handle or concern itself with some important aspects that a full gui library
      would provide.  It does not render or draw, and it does not poll input devices such as the mouse and keyboard.  
      This is, however, a positive attribute of cel.  By not rendering or handling input devices it can be easily embedded 
      into another application to provide the guts of a gui such as layout and eventing.]];

  p [[The target audience for cel is game developers.  Most game guis lack polish, even though they look great, 
  not much effort is put into making them feel great.  Cel aims to make them feel great and provide enough flexibility
  so that it is useful .  It would be quite burdensome to require a game to render the gui with an entirely different library
  than what is used to render the game itself.   Game guis have a wide range of complexity, from very minimial or none to 
  extremely complex such as World of Warcraft.  Cel is targeted towards more complex, primarily because the simple ones are
  so simple that the gui can be as simple as a few hundred lines of C code.]];

  p { 
    [[These are the high-level features that make cel useful for a game gui.]];

    list.bulleted {
      [[Rendering is handled by the host application.]];
      [[Cel is lightweight and does not require any libraries outside of standard Lua.]];
      [[Multiple levels of automatic layout.]];
      [[Input is handled by the host application through a simple interface.  
        This means emulating a mouse or keyboard or gamepad is easy.]];
      [[Provides cut/copy/paste. ]];
      [[Very low coupling between the way a cel looks and the way it behaves, which allows for creating the
        graphical output without having to know anything about how cel works.]];
      [[Sandboxing at multiple levels.  This enables a safe way to create user-modable interface such as World of Warcraft.]];
    };
  };

  p { [[Cel is a pure Lua 5.1 library, and it is designed to take advantage of the strenghts of Lua.  
      The following language features are used throughout cel.]];
    list.bulleted {
      [[Closures]];
      [[Function environments]];
      [[Functables]];
      [[Multiple returns]];
      [[Metatables]];
      [[Duck typing]];
    };
  };
  p [[cel is the name of the library but the term is overloaded,  a cel (control element)
  is the primary building block used to make simple and complex controls.  Every cel is a container for cels,
  meaning a cel can contain another cel.  This will naturally form a tree of cels.  
  There can be many independent cel-trees, and one special tree with cel.root as the root.  
  A cel-tree is not an object, just a term used to talk about recursive containment of cels.
  Only cels in the cel.root tree will receive input.]];

  p {	[[How a cel-tree is formed:]];
    section { leftmargin='2em';
      code [[
      local acel = cel.new(100,100) --create a cel
      acel:link(cel.root) --link acel to cel.root
      ]];
      br;
    };
    list.bulleted {
      [[acel is now linked to cel.root.]];
      [[cel.root is now the host of acel]];
      [[acel is a link of cel.root]];
    };
  };

  p [[A cel-tree is dynamic, hosts and links can be changed.
    Note that because of this it is possible to create cycles.  Cel makes no attempt to detect all cycles.
  The built-in cels are very generic, for instance a listbox in a typical gui library is a container for text.  That is useful for most applications, but not so much for games.  The listbox in the cel library simply arranges the cels that it contains to create a list with a scrollbar.  The result is that a listbox naturally supports multiple fonts, embedded buttons, or any complex cel as an item.
  Even complex cels will have relatively few properties.  This is due to them being a generic implementation.]];

  p [[A cel encapsulates(meaning data and functions are not published) information that it typically not encapsulated in a gui.  For example there is no way to get the host of a cel.  This was a deliberate design decision to allow for varying degrees of sandboxing.  The implementation of cel.window exploits this feature in the follwing manner:]];
  list.bulleted { 
    [[When a window is created another cel is created to be the client area for the window.]];
    [[The client cel is linked to the window according to the layout specified at creation.]];
    [[It would be all kinds of bad if the client window were to go away or its behavior changed.]];
    [[When a cel is linked to a window, the window diverts the link to its client cel via
    the __link metamethod.]];
    {
      [[If that cel could access its host it could do something like this]];
      code[[
      mycel.host:unlink() 
      --now the client area is no longer linked to the winodw, uh oh.
      ]];

      br;
      p [[or this]];

      code[[
      --most likely inteding to move the window, because it doesn't
      --know its actually linked to the client cel.
      mycel.host:move(0, 0)
      ]];
    };
  };

  p [[There are in fact an endless stream of problems related to not fully encasulating the containter(host) 
      containee(link) relationship.   Encapsulating this information makes it much easier use a cel,  or a 
      complex relation of cels.]];
};
