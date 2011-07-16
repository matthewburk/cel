local cel = require 'cel'

return function(bob, pause)
  pause()
  --0 is the default value for width and height
  local amy = cel.new(100, 100, cel.color.encode(.5, 0, 0))

  amy:link(bob)
  pause()

  --Here we are defining a function to center a link in its host
  --hw is the width of the host
  --hh is the height of the host
  --w, h is the current dimensions of the link
  --We return a new x, y, w, h values that will center it in the host
  local function center(hw, hh, w, h)
    return (hw - w)/2, (hh - h)/2, w, h
  end

  --Now lets center amy in bob.
  do
    local x, y, w, h = center(bob.w, bob.h, amy.w, amy.h)
    --The move function takes up to 4 parameters and will resize and reposition a cel at the same time.
    amy:move(x, y, w, h)
  end
  pause()

  --Doing layout like this is tedious.  When bob is resized amy will not be centerd in bob any more.
  --There is a way to do this kind of layout automatically, lets reset and do it a better way.
  amy:unlink()
  amy:resize(bob.w/2, bob.h/4)
  pause()

  --Lets redefine center so it can be used in automatic layout.
  center = function(hw, hh, x, y, w, h)
    return (hw - w)/2, (hh - h)/2, w, h
  end
  --The center function can now be used as a linker. 
  --
  --A linker is a function that meets the following conditions.  
  --  The linker should determine the layout of a rectangle and return the resuling x, y, w, h of the rectangle.
  --  In general the linker should not have side-effects, becuase it may be called when you do not expect it.
  --
  --A linker is called with these arguments (hw, hh, x, y, w, h, xval, yval, minw, maxw, minh, maxh)
  --  hw and hh are the width and height of the host rectangle(not cel).
  --  x, y, w, h defines the rectangle that the linker is laying out.
  --  minw, maxw, minh, maxh define the min/max dimensions of the rectangle that the linker is laying out.
  --  the meaning of xval, yval is defined by the linker.
  pause()

  --The most basic automatic layout is provided by the link and relink functions.
  --Here we are linking amy to bob again but this time, we aren't specifying an
  --x,y location, but a linker function. When a function is passed as the second parameter to link
  --it must be a linker and is called to determine the initial layout of the link in the host.
  amy:link(bob, center)
  pause()

  --The linker is called when the host is resized or a link is moved
  --(and in other special circumstances).
  --
  --Try resizing bob and you will see the amy remains centered
  --Trying to move amy to a different location will invoke the linker, which will force amy back to center.
  amy:move(0, 0)
  pause()

  --We can resize amy and its position is automatically recalculated so that it remains centered
  amy:resize(amy.w + 100, amy.h + 100)
  pause()

  --The relink function is used to alter how a cel is linked, without unlinking and linking the cel again.
  --Lets relink amy, the if not arguments are passed to relink then the linker is removed.
  amy:relink()
  pause()

  --Now amy will not automatically center when bob is resized, and we can freely position amy.
  amy:move(10, 10, 10, 10)
  pause()

  --Now lets relink amy using a new linker, this time we will use the xval and yval linker params.

  --This linker will stretch or shrink the rectangle so that it is the same width and height as
  --the host rectangle, and then center it.
  --
  --xval and yval must be numbers or nil,
  --xval specifies the horizontal distance between the edges of the two rectangles.
  --yval specifies the vertical distance between the edges of the two rectangles. 
  local function edges(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0
    w = hw - (xval*2)
    h = hh - (yval*2)
    return center(hw, hh, x, y, w, h, 0, 0)
  end

  --relink takes a linker as the first parameter, the second and third parameters are the xval and yval passed 
  --to the linker
  amy:relink(edges, 5, 10)
  pause()

  --A string can be specified for the linker instead of a function, in this case cel will lookup the function
  --by that name in its list of linkers.  Use cel.addlinker(linkername, linkerfunction) to add a linker to the list.
  --Lets add our center linker and try it.  
  cel.addlinker('tutcenter', center)
  amy:relink('tutcenter')
  pause()

  --We did not use the name 'center' becuase there is already a linker
  --named 'center' in the list.  There are many predefined useful linkers,
  --so check the documentation before writing your own.  

  --The predefined 'center' linker can take numbers for xval and yval which are added to x and y of the 
  --result rectangle.  Here we relink amy to bob so that amy is off center.
  
  --first resize amy so that this is visually obvious
  amy:relink(edges, 40, 40)
  amy:relink('center', 15, 5)
  pause()

end
