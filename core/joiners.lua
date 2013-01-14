--[[
cel is licensed under the terms of the MIT license

Copyright (C) 2011 by Matthew W. Burk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]
local M =  {}

M['identity'] = function(jx, jy, jw, jh, x, y, w, h, xval, yval)
  return jx, jy, jw, jh
end

--join top of cel to top of anchor
M['top'] = function(jx, jy, jw, jh, x, y, w, h, distance)
  distance = distance or 0
  y = jy-distance
  return x, y, w, h
end

--join bottom of cel to bottom of anchor
M['bottom'] = function(jx, jy, jw, jh, x, y, w, h, distance)
  distance = distance or 0
  y = jy+jh-h-distance
  return x, y, w, h
end

--join bottom of cel to top of anchor
M['bottom:top'] = function(jx, jy, jw, jh, x, y, w, h, distance)
  distance = distance or 0
  x = jx  
  w = jw
  y = jy-h-distance
  return x, y, w, h
end

--join top of cel to bottom of anchor
M['top:bottom'] = function(jx, jy, jw, jh, x, y, w, h, distance)
  distance = distance or 0
  x = jx  
  w = jw
  y = jy+jh+distance
  return x, y, w, h
end

M['width'] = function(jx, jy, jw, jh, x, y, w, h, xval)
  xval = xval or 0
  return x, y, jw + xval, h
end

M['height'] = function(jx, jy, jw, jh, x, y, w, h, xval)
  xval = xval or 0
  return x, y, w, jh + xval
end

M['size'] = function(jx, jy, jw, jh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0
  return x, y, jw + xval, jh + yval
end

return M 
