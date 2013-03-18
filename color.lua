--[[
color functions are derived from http://sputnik.freewisdom.org/lib/colors/

Copyright (c) 2007, 2008 Yuri Takhteyev

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--]]

local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local string_char = string.char
local string_byte = string.byte
local M = {}

-----------------------------------------------------------------------------
-- Converts an HSL triplet to RGB
-- (see http://homepages.cwi.nl/~steven/css/hsl.html).
-- 
-- @param h              hue (0-360)
-- @param s              saturation (0.0-1.0)
-- @param l              lightness (0.0-1.0)
-----------------------------------------------------------------------------
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
function M.hsltorgb(h, s, l)
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

--(see http://easyrgb.com)
function M.rgbtohsl(r, g, b)
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

function M.rgb8(r, g, b, a)
  return string_char(r, g, b, a or 255)
end

function M.rgb(r, g, b, a)
  r = r and math_min(255, math_max(255 * r, 0)) or 0
  g = g and math_min(255, math_max(255 * g, 0)) or 0
  b = b and math_min(255, math_max(255 * b, 0)) or 0
  a = a and math_min(255, math_max(255 * a, 0)) or 255
  return string_char(r, g, b, a)
end

function M.hsl(h, s, l, a)
  local r, g, b = M.hsltorgb(h, s, l)
  return M.rgb(r, g, b, a)
end

function M.torgb8(color)
  return string_byte(color, 1, 4)
end

function M.torgb(color)
  local r, g, b, a = string_byte(color, 1, 4)
  return r/255, g/255, b/255, a/255
end

function M.tohsl(color)
  local r, g, b, a = M.torgb(color)
  local h, s, l = M.rgbtohsl(r, g, b)
  return h, s, l, a
end

function M.tint(color, r)
  local h, s, l = M.tohsl(color)
  return M.hsl(h, s, l + (1-l)*r)
end

function M.shade(color, r)
  local h, s, l = M.tohsl(color)
  return  M.hsl(h, s, l-l*r)
end

function M.setalpha(color, a)
  local r, g, b = M.torgb(color)
  return M.rgb(r, g, b, a)
end

function M.setsaturation(color, s)
  local r, g, b, a = M.torgb(color)
  local h, _, l = M.rgbtohsl(r, g, b)
  return M.hsl(h, s, l, a)
end

function M.getcomplement(color, news, newl, newa)
  local h, s, l, a = M.tohsl(color)
  
  return M.hsl(h+180, news or s, newl or l, newa or a)
end

return M
