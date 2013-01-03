local function privatekey(name) 
  return function() return name end
end

return setmetatable({
  _formation = privatekey('_formation'),
  _host = privatekey('_host'),
  _links = privatekey('_links'),
  _next = privatekey('_next'),
  _prev = privatekey('_prev'),
  _trap = privatekey('_trap'),
  _focus = privatekey('_focus'),
  _name = privatekey('_name'),
  _x = privatekey('_x'),
  _y = privatekey('_y'),
  _w = privatekey('_w'),
  _h = privatekey('_h'),
  _metacel = privatekey('_metacel'),
  _vectorx = privatekey('_vectorx'),
  _vectory = privatekey('_vectory'),
  _linker = privatekey('_linker'),
  _xval = privatekey('_xval'),
  _yval = privatekey('_yval'),
  _face = privatekey('_face'),
  _pick = privatekey('_pick'),
  _describe = privatekey('_describe'),
  _movelink = privatekey('_movelink'),
  _variations = privatekey('_variations'),
  _minw = privatekey('_minw'),
  _minh = privatekey('_minh'),
  _maxw = privatekey('_maxw'),
  _maxh = privatekey('_maxh'),
  _mousedownlistener = privatekey('_mousedownlistener'),
  _mouseuplistener = privatekey('_mouseuplistener'),
  _focuslistener = privatekey('_focuslistener'),
  _blurlistener = privatekey('_blurlistener'),
  _timerlistener = privatekey('_timerlistener'),
  _keys = privatekey('_keys'),
  _states = privatekey('_states'),
  _celid = privatekey('_celid'),
  _disabled = privatekey('_disabled'),
  _refresh = privatekey('_refresh'),
  _appstatus = privatekey('_appstatus'),
  _hidden = privatekey('_hidden'),

  maxdim = 2^31-1,
  maxpos = 2^31-1,
  minpos = -(2^31), 

  linkers = require 'cel.core.linkers',
  joiners = require 'cel.core.joiners',

  stackformation = {},
  updaterect = { l = 0, r = 0, t = 0, b = 0 },
  mousetrackerfuncs = {},
  timer = {millis = 0},
  flows = {},
  joins = setmetatable({}, {__mode='k'}),
}, 
{__index = function(_ENV, key)
  local v = _G[key]
  if v then 
    _ENV[key] = v 
    --print('got global', key, v)
  else
    error(string.format('bad index %s', tostring(key)), 2)
  end
  return v
end})
