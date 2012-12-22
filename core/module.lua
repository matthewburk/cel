return setmetatable({}, { __index = function(cel, key)
  cel[key] = select(2, assert(pcall(require, 'cel.' .. key)))
  return cel[key]
end})
