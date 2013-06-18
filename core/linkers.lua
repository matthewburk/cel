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

M.fixedwidth = function(hw, hh, x, y, w, h, fixedwidth)
  return x, y, fixedwidth, h
end

M.fixedheight = function(hw, hh, x, y, w, h, fixedheight)
  return x, y, w, fixedheight 
end

M.fixedsize = function(hw, hh, x, y, w, h, fixedwidth, fixedheight)
  return x, y, fixedwidth, fixedheight 
end

M['hidden'] = function(hw, hh, x, y, w, h)
  return hw, hh, w, h
end

M['fill'] = function(hw, hh)
  return 0, 0, hw, hh
end

M['fill.margin'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or xval 
  return xval, yval, hw - (xval*2), hh - (yval*2)
end

M['fill.leftmargin'] = function(hw, hh, x, y, w, h, leftmargin, margin)
  leftmargin = leftmargin or 0  
  margin = margin or 0
  return leftmargin, margin, hw-leftmargin-margin, hh-margin*2
end

M['fill.topmargin'] = function(hw, hh, x, y, w, h, topmargin, margin)
  topmargin = topmargin or 0  
  margin = margin or 0
  return margin, topmargin, hw-margin*2, hh-topmargin-margin
end

M['fill.rightmargin'] = function(hw, hh, x, y, w, h, rightmargin, margin)
  rightmargin = rightmargin or 0  
  margin = margin or 0  
  return margin, margin, hw-rightmargin, hh-margin*2
end

M['fill.bottommargin'] = function(hw, hh, x, y, w, h, bottommargin, margin)
  bottommargin = bottommargin or 0  
  margin = margin or 0  
  return margin, margin, hw-margin*2, hh-bottommargin-margin
end

M['fill.aspect'] = function(hw, hh, x, y, w, h, aspect, yval)
  aspect = aspect or 1
  if hw < 1 or hh < 1 then 
    return 0, 0, aspect, 1
  end

  local haspect = hw/hh

  if haspect > aspect then
    w = hh * aspect 
    h = hh
  elseif haspect < aspect then
    w = hw
    h = hw / aspect
  else
    w, h = hw, hh
  end

  return (hw - w)/2, (hh - h)/2, w, h
end

M['scroll'] = function(hw, hh, x, y, w, h, fillx, filly)
  if x >= 0 or w <= hw then 
    x = 0
  elseif x + w < hw then
    x = hw - w
  end

  if y >= 0 or h <= hh then
    y = 0
  elseif y + h < hh then
    y = hh - h
  end

  return x, y, fillx and hw or w, filly and hh or h
end

M['fence'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0

  hw = hw - (xval*2)
  hh = hh - (yval*2)

  if w > hw then w = hw end

  if x <= xval then 
    x = xval
  elseif x + w > hw then
    x = hw - w + xval
  end

  if h > hh then h = hh end
  if y <= yval then
    y = yval
  elseif y + h > hh then
    y = hh - h + yval
  end

  return x, y, w, h
end

M['center'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0
  return (hw - w)/2 + xval, (hh - h)/2 + yval, w, h
end

M['left'] = function(hw, hh, x, y, w, h, pad)
  return pad or 0, y, w, h
end

M['top'] = function(hw, hh, x, y, w, h, pad)
  return x, pad or 0, w, h
end

M['right'] = function(hw, hh, x, y, w, h, pad)
  pad = pad or 0
  return hw - w - pad, y, w, h
end

M['bottom'] = function(hw, hh, x, y, w, h, pad)
  pad = pad or 0
  return x, hh - h - pad, w, h
end

M['center.top'] = function(hw, hh, x, y, w, h, xval, yval)
  x, y, w, h = M.center(hw, hh, x, y, w, h, xval, 0)
  return x, yval or 0, w, h
end

M['center.bottom'] = function(hw, hh, x, y, w, h, xval, yval)
  x, y, w, h = M.center(hw, hh, x, y, w, h, xval, 0)
  return x, hh - h - (yval or 0), w, h
end

M['center.height'] = function(hw, hh, x, y, w, h, xval, yval)    
  xval = xval or 0
  yval = yval or 0
  x, y, w, h = M['center'](hw, hh, x, y, w, h, xval, 0)
  return x, yval, w, hh - (yval * 2)
end

M['left.top'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0  
  return xval, yval, w, h
end

M['left.bottom'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0  
  return xval, hh - h - yval, w, h
end

M['left.center'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0
  local x, y, w, h = M.center(hw, hh, x, y, w, h, xval, yval)
  return xval, y, w, h
end

M['left.height'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0  
  return xval, yval, w, hh - (yval * 2)
end

M['right.top'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0  
  return hw - w - xval, yval, w, h
end

M['right.bottom'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0  
  return hw - w - xval, hh - h - yval, w, h
end

M['right.center'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0 
  local x, y, w, h = M.center(hw, hh, x, y, w, h, xval, yval)
  return hw - w - xval, y, w, h
end

M['right.height'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0  
  return hw - w - xval, yval, w, hh - (yval * 2)
end

M['width'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or xval 
  return xval, y, hw - (xval + yval), h
end

M['width.top'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0
  return xval, yval, hw - (xval * 2), h
end

M['width.bottom'] = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0  
  return xval, hh - h - yval, hw - (xval * 2), h
end

M['width.center'] = function(hw, hh, x, y, w, h, xval, yval)    
  xval = xval or 0
  yval = yval or 0
  return M['center'](hw, hh, 0, y, hw-(xval*2), h, 0, yval)
end

M['height'] = function(hw, hh, x, y, w, h, pad)
  pad = pad or 0  
  return x, pad, w, hh - (pad * 2)
end

M['identity'] = function(hw, hh, x, y, w, h, xval, yval)
  return x, y, w, h
end

return M 
