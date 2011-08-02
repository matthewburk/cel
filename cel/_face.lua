return function(_ENV, M)
  setfenv(1, _ENV)

  face = {
    [_metafaces] = {cel = {}}
  } 

  local function defineface(metacelname, name, t)
    --TODO set[_isface] on everyface, so resolving is quicker
    if name == metacelname then
      name = nil
    end

    local metaface = face[_metafaces][metacelname]

    if not metaface then
      metaface = {getmetacel = function() return metacelname end}
      face[_metafaces][metacelname] = metaface
      setmetatable(metaface, {__index = face[_metafaces]['cel']})
    end
    
    if name == nil then
      if t then
        for k,v in pairs(t) do
          metaface[k] = v
        end
      end
      return metaface
    end

    local face = rawget(metaface, name)

    if not face then
      face = {}
      metaface[name] = face
      metaface[face] = face
      setmetatable(face, {__index = metaface})
    end

    if t then
      for k,v in pairs(t) do
        face[k] = v
      end
    end

    face[_name] = name
    return face
  end

  function face.get(metacelname, facename)
    metacelname = metacelname or 'cel'

    local metaface = face[_metafaces][metacelname]

    if not metaface then return end

    if not facename then return metaface end

    return rawget(metaface, facename)
  end

  _ENV.defineface = defineface

  --[[
  function face.new(metacelname, facename, t)
    if not facename then
      return false, 'expected a name'
    end

    return defineface(metacelname or 'cel', facename, t)
  end
  --]]

  local function __call(face, t)
    if not t then
      return face[_metafaces]['cel']
    end

    local metacelname = t.metacel
    local name = t.name
    local names = t.names
    local metacelnames = t.metacels

    t.metacel = nil
    t.name = nil
    t.names = nil
    t.metacels = nil

    if not metacelname and not metacelnames then
      metacelname = 'cel'
    end

    if names or metacelnames then
      local ret = {}
      
      metacelnames = metacelnames or {metacelname}

      for i=1, #metacelnames do
        if names and #names > 0 then
          for j=1, #names do
            ret[#ret + 1] = defineface(metacelnames[i], names[j], t)
          end
        else
          ret[#ret + 1] = defineface(metacelnames[i], name, t)
        end
      end

      return ret
    else
      return defineface(metacelname, name, t)
    end
  end

  return setmetatable(face, {__call = __call})
end
