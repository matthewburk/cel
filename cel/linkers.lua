local M =  {}

M.center = function(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0

  --makes this stable so text doesn't shake when centered and the host width adjusts
  --[[
  if w % 2 == 0 then
    hw = hw + 1
  end
  if h % 2 == 0 then
    hh = hh + 1
  end
  --]]
  return (hw - w)/2 + xval, (hh - h)/2 + yval, w, h
end

  M.edges = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0
    w = hw - (xval*2)
    h = hh - (yval*2)
    return M.center(hw, hh, x, y, w, h, 0, 0)
  end

  M.portal = function(hw, hh, x, y, w, h, xval, yval)
    --TODO allow to move freely within host if w, h are samller than host
    --TODO pad hw with xval and hh with yval
    --TODO unstable, jumps around when its samller than host
    if x > 0 then 
      x = 0
    elseif x + w < hw then
      x = hw - w
    end

    if y > 0 then
      y = 0
    elseif y + h < hh then
      y = hh - h
    end

    return x, y, w, h
  end

  M.fence = function(hw, hh, x, y, w, h, xval, yval)
    --TODO restrict w and h to fence, portal will not restrict w and h
    --TODO pad hw with xval and hh with yval
    if x <= 0 then 
      x = 0
    elseif x + w > hw then
      x = hw - w
    end

    if y <= 0 then
      y = 0
    elseif y + h > hh then
      y = hh - h
    end

    return x, y, w, h
  end

  M.bottom = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0  
    return xval, hh - h - yval, w, h, true
  end

  M['width.bottom'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0  
    return xval, hh - h - yval, hw - (xval * 2), h, true
  end
  M['bottom.width'] = M['width.bottom']

  M['width.top'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0
    return xval, yval, hw - (xval * 2), h
  end
  M['top.width'] = M['width.top']

  M.width = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0
    return xval, y, hw - (xval * 2), h
  end

  --xval is smallest width it will shrink to
  M['+width'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0

    if hw < xval then hw = xval end

    return 0, y, hw, h
  end

  M['edges.topunique'] = function(hw, hh, x, y, w, h, xval, yval)
        xval = xval or 0
        yval = yval or 0  
        return xval, yval, hw - (xval * 2), hh - xval - yval
      end

  M['edges.bottomunique'] = function(hw, hh, x, y, w, h, xval, yval)
        xval = xval or 0
        yval = yval or 0  
        return xval, xval, hw - (xval * 2), hh - xval - yval
      end

  M['edges.leftunique'] = function(hw, hh, x, y, w, h, border, unique)
        border = border or 0
        unique = unique or 0  
        return unique, border, hw - border - unique, hh - (border * 2)
      end


  M['left.sharedwidth']  = function(hw, hh, x, y, w, h, left, sharedwidth)
    left = left or 0
    assert(sharedwidth)
    if w > sharedwidth[1] then
      sharedwidth[1] = w
    end

    w = sharedwidth[1]

    return left, y, w, h, true
  end


  M['right.height'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0  
    return hw - w - xval, yval, w, hh - (yval * 2)
  end

  M['left.height'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0  
    return xval, yval, w, hh - (yval * 2)
  end

  M.height = function(hw, hh, x, y, w, h, xval, yval)
    yval = yval or 0  
    return x, yval, w, hh - (yval * 2)
  end

  M.right = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0  
    return hw - w - xval, y, w, h
  end

  M.left = function(hw, hh, x, y, w, h, xval)
    return xval or 0, y, w, h
  end

  M['right.bottom'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0  
    return hw - w - xval, hh - h - yval, w, h, true
  end

  M['left.bottom'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0  
    return xval, hh - h - yval, w, h
  end

  M['right.top'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0  
    return hw - w - xval, yval, w, h
  end

  M['identity'] = function(hw, hh, x, y, w, h, xval, yval)
    return x, y, w, h
  end

  M['left.top'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0  
    return xval, yval, w, h
  end

  M['left.center'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0
    local x, y, w, h = M.center(hw, hh, x, y, w, h, xval, yval)
    return xval, y, w, h
  end

  M['right.center'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0 
    local x, y, w, h = M.center(hw, hh, x, y, w, h, xval, yval)
    return hw - w - xval, y, w, h
  end

  M['center.top'] = function(hw, hh, x, y, w, h, xval, yval)
    x, y, w, h = M.center(hw, hh, x, y, w, h, xval, yval)
    return x, yval or 0, w, h
  end

  M['center.bottom'] = function(hw, hh, x, y, w, h, xval, yval)
    x, y, w, h = M.center(hw, hh, x, y, w, h, xval, yval)
    return x, hh - h - (yval or 0), w, h
  end

  --xval is offcenter x
  --yval is same as yval for 'height'
  M['center.height'] = function(hw, hh, x, y, w, h, xval, yval)    
    xval = xval or 0
    yval = yval or 0
    x, y, w, h = M['center'](hw, hh, x, y, w, h, xval, 0)
    return x, yval, w, hh - (yval * 2)
  end

  --[[
  M['width%.height'] = function(hw, hh, x, y, w, h, xval, yval)    
    xval = xval or 0
    yval = yval or 0
    x, y, w, h = M.center(hw, hh, x, y, w, h, xval, 0)
    x, yval, w, hh - (yval * 2)
  end
  --]]

  M['width%.height%'] = function(hw, hh, x, y, w, h, xval, yval)  
    xval = xval or 1
    yval = yval or 1
    return x, y, hw * xval, hh * yval
  end

  M['edges.right.top'] = function(hw, hh, x, y, w, h, xyval, dims)
    local xval = 0
    local yval = 0 
    if xyval then
      xval = xyval[1] or 0
      yval = xyval[2] or 0
    end

    local sizex = (dims and dims[1]) or .5
    local sizey = (dims and dims[2]) or .5

    local vhw = hw * sizex
    local vhh = hh * sizey

    local xo, yo = M['right.top'](hw, hh, 0, 0, vhw, vhh, 0, 0)

    w = vhw - (xval * 2)
    h = vhh - (yval * 2)
    x = xo + xval
    y = yval
    return x, y, w, h
  end

  M['edges.left.top'] = function(hw, hh, x, y, w, h, xyval, dims)
    local xval = 0
    local yval = 0 
    if xyval then
      xval = xyval[1] or 0
      yval = xyval[2] or 0
    end

    local sizex = (dims and dims[1]) or .5
    local sizey = (dims and dims[2]) or .5

    local vhw = hw * sizex
    local vhh = hh * sizey

    local xo, yo = 0, 0

    w = vhw - (xval * 2)
    h = vhh - (yval * 2)
    x = xo + xval
    y = yval
    return x, y, w, h
  end

  --fillh is used to give the h by hh * fillh, and defaults to .5
  M['width.fillbottom%'] = function(hw, hh, x, y, w, h, fw, fillh)
    fw = fw or 1 --TODO calc xval for width.bottom based on fw
    fillh = fillh or .5
    return M['width.bottom'](hw, hh, 0, 0,  hw, hh * fillh, 0, 0)
  end

  M['width.yval->bottom'] = function(hw, hh, x, y, w, h, xval, yval)
    xval = xval or 0
    yval = yval or 0
    return xval, yval, hw - (xval * 2), hh - yval
  end

  M['leftmargin'] = function(hw, hh, x, y, w, h, margin)
    margin = margin or 0  
    return margin, 0, hw - margin, hh
  end

  M['rightmargin'] = function(hw, hh, x, y, w, h, margin)
    margin = margin or 0  
    return 0, 0, hw - margin, hh
  end

  do
    local empty = {}
    local left = M['left']
    local width = M['width']
    local right = M['right']
    local leftmargin = M['leftmargin']
    local rightmargin = M['rightmargin']

    local function recurse(a, b, hw, hh, x, y, w, h, tvals)
      tvals = tvals or empty
      local vhx, vhy, vhw, vhh = a(hw, hh, x, y, w, h, tvals[1], tvals[2])
      x, y, w, h = b(vhw, vhh, x - vhx, y - vhy, w, h, tvals[3], tvals[4])
      return x + vhx, y + vhy, w, h
    end

    M['leftmargin#width'] = function(...)
      return recurse(leftmargin, width, ...)
    end

     M['rightmargin#width'] = function(...)
      return recurse(rightmargin, width, ...)
    end

    M['right#width'] = function(...)
      return recurse(right, width, ...)
    end

  end

return M 
