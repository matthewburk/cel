--[[
color functions are derived from http://sputnik.freewisdom.org/lib/colors/

Copyright (c) 2007, 2008 Yuri Takhteyev

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--]]

local color = {}

-----------------------------------------------------------------------------
-- Converts an HSL triplet to RGB
-- (see http://homepages.cwi.nl/~steven/css/hsl.html).
-- 
-- @param h              hue (0-360)
-- @param s              saturation (0.0-1.0)
-- @param l              lightness (0.0-1.0)
-----------------------------------------------------------------------------

do
  local function _h2rgb(m1, m2, h)
    if h<0 then h = h+1 end
    if h>1 then h = h-1 end
    if h*6<1 then 
      return m1+(m2-m1)*h*6
    elseif h*2<1 then 
      return m2 
    elseif h*3<2 then 
      return m1+(m2-m1)*(2/3-h)*6
    else
      return m1
    end
  end
  function color.torgb(h, s, l)
    h = h/360
    local m1, m2
    if l<=0.5 then 
      m2 = l*(s+1)
    else 
      m2 = l+s-l*s
    end
    m1 = l*2-m2
    return _h2rgb(m1, m2, h+1/3), _h2rgb(m1, m2, h), _h2rgb(m1, m2, h-1/3)
  end
end

--(see http://easyrgb.com)
function color.tohsl(r, g, b)
  local min = math.min(r, g, b)
  local max = math.max(r, g, b)
  local delta = max - min

  local h, s, l = 0, 0, ((min+max)/2)

  if l > 0 and l < 0.5 then s = delta/(max+min) end
  if l >= 0.5 and l < 1 then s = delta/(2-max-min) end

  if delta > 0 then
    if max == r and max ~= g then h = h + (g-b)/delta end
    if max == g and max ~= b then h = h + 2 + (b-r)/delta end
    if max == b and max ~= r then h = h + 4 + (r-g)/delta end
    h = h / 6;
  end

  if h < 0 then h = h + 1 end
  if h > 1 then h = h - 1 end

  return h * 360, s, l
end

function color.hueoffset(delta, h, s, l)
  return (h + delta) % 360, s, l
end

function color.complementary(h, s, l) 
  return color.hueoffset(180, h, s, l)
end

function color.tints(n, h, s, l)
  local t = {}
  for i =1,n do
    t[i] = {h, s, l + (1-l)/n*i}    
  end
  return t
end

function color.shades(n, h, s, l)
  local t = {}
  for i =1,n do
    t[i] = {h, s, l - l/n*i}    
  end
  return t
end

--alpha should not be passed in
function color.tint(r, h, s, l, a)
  if type(h) == 'string' then
    h, s, l, a = color.tohsl(color.decodef(h))
    local r, b, g = color.torgb(h, s, l + (1-l)*r)
    return color.encodef(r, g, b, a)
  end
  return h, s, l + (1-l)*r
end

function color.shade(r, h, s, l, a)
  if type(h) == 'string' then
    h, s, l, a = color.tohsl(color.decodef(h))
    local r, b, g = color.torgb(h, s, l-l*r)
    return color.encodef(r, g, b, a)
  end
  return  h, s, l-l*r
end


do
  local math_min = math.min
  local math_max = math.max
  local math_floor = math.floor
  local string_char = string.char
  local string_byte = string.byte
 
  function color.encode(r, g, b, a)
    return string_char(r, g, b, a or 255)
  end

  function color.decode(color)
    return string_byte(color, 1, 4)
  end

  function color.encodef(r, g, b, a)
    r = r and math_min(255, math_max(255 * r, 0)) or 0
    g = g and math_min(255, math_max(255 * g, 0)) or 0
    b = b and math_min(255, math_max(255 * b, 0)) or 0
    a = a and math_min(255, math_max(255 * a, 0)) or 255
    return string_char(r, g, b, a)
  end

  function color.decodef(color)
    local r, g, b, a = string_byte(color, 1, 4)
    return r/255, g/255, b/255, a/255
  end
end

return color
