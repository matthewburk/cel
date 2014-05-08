local function privatekey(name) 
  return function() return name end
end

local CEL = {}

CEL.privatekey = privatekey

CEL._formation = privatekey('_formation')
CEL._host = privatekey('_host')
CEL._links = privatekey('_links')
CEL._next = privatekey('_next')
CEL._prev = privatekey('_prev')
CEL._trap = privatekey('_trap')
CEL._focus = privatekey('_focus')
CEL._name = privatekey('_name')
CEL._x = privatekey('_x')
CEL._y = privatekey('_y')
CEL._w = privatekey('_w')
CEL._h = privatekey('_h')
CEL._metacel = privatekey('_metacel')
  CEL._vectorx = privatekey('_vectorx')
  CEL._vectory = privatekey('_vectory')
CEL._linker = privatekey('_linker')
CEL._xval = privatekey('_xval')
CEL._yval = privatekey('_yval')
CEL._face = privatekey('_face')
CEL._minw = privatekey('_minw')
CEL._minh = privatekey('_minh')
CEL._maxw = privatekey('_maxw')
CEL._maxh = privatekey('_maxh')
  CEL._keys = privatekey('_keys')
  CEL._states = privatekey('_states')
CEL._celid = privatekey('_celid')
CEL._disabled = privatekey('_disabled')
CEL._refresh = privatekey('_refresh')
CEL._appstatus = privatekey('_appstatus')
CEL._hidden = privatekey('_hidden')
CEL._metacelname = privatekey('_metacelname')

CEL.maxdim = 2^31-1
CEL.maxpos = 2^31-1
CEL.minpos = -(2^31) 

CEL.stackformation = {}
CEL.event = {}
CEL.driver = {}
CEL.mousetrackerfuncs = {}
CEL.factories = {}
CEL.updaterect = { l = 0, r = 0, t = 0, b = 0 }
CEL.flows = {}
CEL.timer = {millis = 0}

CEL.M = setmetatable({}, { __index = function(cel, key)
  cel[key] = select(2, assert(pcall(require, 'cel.' .. key)))
  return cel[key]
end})

return CEL
