----------2---------3---------4---------5---------6---------7---------8---------
local cel = require 'cel'

--Notice that for modules dot notation is used to call a function for example cel.new(),
--and for a cel we use colon notation to call a function for example amy:link(bob).

--I find it easier to talk when things have proper names, so i am going to give my cels names
--bob is the cel we use as a sandbox. 
return function(bob, pause)
  pause()

  --Create a new cel that is with the with an initial width of 100 and an initial height of 150,
  --the last parameter is the face that will be used to render the cel, in this case a string encoding a
  --color is the face.
  local amy = cel.new(100, 150, cel.color.encode(.5, .5, .5))

  pause()
  --At this point amy will not be drawn and the user cannot interact with it.  To show amy to the user 
  --we must link it to the root cel.  

  --Here amy is linked to bob.  When a cel is linked the cel that it is linking to becomes
  --its host.  Host is the term used in the cel library becuase parent implies creation which is not 
  --the case.  A cel can host any number of other cels which are referred to as its links.
  --It this case bob is the host of amy, and amy is a link of bob.
  amy:link(bob)
  pause()

  --An important feature of linking is that any cel can be linked to any other cel.
  --In other words there is no special cel that is not a potential host.  The root cel is special
  --in that it cannot be linked to any other cel, and is the only special cel in that sense.
  --Lets link a cel to amy.
  local jim = cel.new(30, 30, cel.color.encode(0, 1, 1))
  jim:link(amy)
  pause()

  --The opposite of linking is unlinking, when a cel is unlinked it will no longer be shown
  --and the user cannot interact with it
  amy:unlink()
  pause()
  
  --Now use a variation of the link method that specifies where in the host the link will be anchored.
  --amy is linked to bob, at the (x,y) position (300, 0)
  amy:link(bob, 300, 0)
  pause()

  --Notice that jim is still linked to amy, because we never unlinked it
  --When you want to change the position of a cel, use the move() method.
  jim:move(10, 10)
  pause()

  --Resize amy.
  amy:resize(300, 300)
  pause()

  --The move method also accepts parameters for w, h and is the most effecient method to move a cels position and
  --resize it.  
  amy:move(bob.w/3, bob.h/3, bob.w/3, bob.h/3)
  pause()
end


