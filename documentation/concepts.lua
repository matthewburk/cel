h1'Introduction';
  [[A cel ([c]ontrol [el]ement) is the basic unit or building block of the Cel
  library. To use the libarry effectively you must understand what a cel is
  as well as what it can and can't do.]]
  
  h2'the cel rectangle';
  [[A cel is a rectangle cel.x is the left of the rectangle, cel.y is the top,
  cel.w is the width and cel.h is the height. The orgin of a cels coordinate
  system is at the top left corner of the cel, x increases to the right and
  y increases down.  The right of a cel is cel.x + cel.w, and the bottom is
  cel.y + cel.h.  A cel contains all points where x >= 0 and x < cel.w 
  and y >=0 and y < cel.h.  This set can be restricted but not increased.]];

  h2'hosts and links';
  [[ALL cels are containers.  This means that any cel (with the exception of
  the root cel) can be put into any other cel.  Furthermore the 
  contaier/containee relationship is fully dynamic and can be changed easily.
  This heirarchy or cel tree starts with the root cel (obvious, i know).  
  Often this root cel would be called a parent, and the cels that it contains
  would be called its children.  Thi s is not the terminology used by Cel 
  because parent/child implies that the parent creates the child and that
  the relationship is fixed.  To highlight that the relationship is mutable the
  parent is called the host and the child a link (because it is linked to the
  host).  When reading the documentation, up the cel tree means towards the
  root of the tree.  From here on out the terms host and link will be used.]]

  h2'encapsulation';
  [[A cel enables encapsulation.  A cel has many properties that are not
  exposed outside of the core library, these are considered implementation 
  details in some cases, but it is mostly done so that things 'just work'. 
  For an example cel.scroll is a cel that provides a scrollable area with
  vertical and horizontal scrollbars, the ideal is that any cel can be linked
  to it and in turn the scroll can be linked to any cel and everything works
  as expected.  This ideal is actually required by Cel, becuase the cel tree
  is 100% mutable.  To acheive this ideal Cel was carefully designed so that
  it requires intentionally malicious code to break it (sandboxing address 
  this problem).  The single most influtial design criteria is that the cel
  tree cannot be queried or walked.  This means there is no way to get the host
< p class=MsoNormal>  of a cel or get the links of a cel.  The second criteria is that there
  be no method that exposes a cel that the application did not create.  This 
  means there is no way to get the cel with focus, or under the mouse etc.
  You may think that it is too restrictive, but the effect is the opposite.  
  Putting a window in a listbox, or an editbox in a listbox or a label in a 
  listbox are all identical operations, and this is largely enabled by
  encapsulation.]];
  list{
    header=[[What does encapsulation mean for a cel.scroll:]];
    [[A scroll is a composite cel, and it carefully lays out and depends on
    the layout of its links, and does not expose them.]];
    [[A scroll can depend on the position and dimesions of its composite
    cels to make calculations, and it is robust.  If there was any way to
    access those composite cels the scroll could not rely on them even
    being there and the number of edge cases it would need to handle would 
    dramatically increase.]];
    [[TODO list more examples, really need to sell this concept, its pretty
    non-standard]];
  }
  [[TODO define a composite cel as simply an encapsulated li nk]];

  h2'sandboxing';
  [[]];


  h2'events';
  [[How any gui library defines and implements events is probably the single
  most important feature it provides.  If they are not well defined reacting
  to them reliably can be a challenge.  One of the pimary design goals of Cel
  was to make event handling effortless and natural.  This is harder than it
  sounds, (especially when balanced against encapsulation and sandboxing. 

  
  It can be moved and resized, and can respond to and generate
  events.  The basic
  behaviors that every cel shares are:]]
  list {
    'automatic layout',
    'dynamic hosting',
  };

