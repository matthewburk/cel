do --string interpolation via % operator 
  local function dostring(w, t)
    local s = 'setfenv(1, ...); return ' .. w
    local f = assert(loadstring(s))
    local ok, r = pcall(f, t)
    if ok then
      return r;
    end
  end

  local function psub(p, t)
    local w = p:sub(3, -2)
    return t[w] or dostring(w, t) or p
  end

  getmetatable('').__mod = function(s, t)
    return (s:gsub('($%b{})', function(p) return tostring(psub(p, t)) end))
  end
end

local fname = string.gsub((...), '%.', '/') .. '.html'
fname = string.gsub(fname, 'lua/celdocs', 'celdocumentation')
print(fname) io.flush()

local fout = io.open(fname, 'w')

function namespace(name) end

export = setmetatable({}, {
  __index = function(t, k)
    return function(t)
      local html = [[<html><body>
        ${content}
      </body></html>]] % {content=table.concat(t)} 
      fout:write(html)
    end
  end
})

functiondef = setmetatable({}, {
  __index = function(t, k)
    return function(t)
      local sinterp = { 
        name = k,
        description = t.description or '',
        synopsis = t.synopsis,
        params = '',
        returns = '',
      }

      if t.params then
        for k, v in ipairs(t.params) do
          t.params[k] = [[<li>
            <span>${type}</span> <span>${name}</span> <span>${description}</span>
          </li>]] % v
        end
        sinterp.params = [[<div class="arguments">
          <h2>arguments</h2>
          <ul>${arguments}</ul>
          </div>
        ]] % {arguments=table.concat(t.params)}
      end

      if t.returns then
        for k, v in ipairs(t.returns) do
          t.returns[k] = [[<li>
            <span>${type}</span> <span>${name}</span> <span>${description}</span>
          </li>]] % v
        end
        sinterp.returns = [[<div class="arguments">
          <h2>returns</h2>
          <ul>${returns}</ul>
          </div>
        ]] % {returns=table.concat(t.returns)}
      end

      if sinterp.name == 'callback' then
        return [[
          <p>${description}</p>
          <p><code><pre>${synopsis}</pre></code></p>
          ${params}
          ${returns}
        ]] % sinterp
      else
        return [[
          <h1>${name}</h1>
          <p>${description}</p>
          <p><code><pre>${synopsis}</pre></code></p>
          ${params}
          ${returns}
        ]] % sinterp
      end
    end
  end
})

notes = function(t)
  for k, v in ipairs(t) do
    t[k] = '<p>' .. v .. '</p>'
  end
  return [[
    <h2>notes</h2>
    <p>${notes}</p>
    ]] % {notes=table.concat(t)}
end

examples = function(t)
  for k, v in ipairs(t) do
    t[k] = '<p><code><pre>' .. v .. '</pre></code></p>'
  end
  return [[
    <h2>examples</h2>
    <p>${examples}</p>
    ]] % {examples=table.concat(t, '<hr>')}
end

param = setmetatable({}, {
  __index = function(t, k)
    return function(s)
      if type(s) == 'table' then
        local t = s
        local name = t.name
        local description = [[
        ${description}
        ${content}]] % {
          description = t.description or '',
          content = table.concat(t, '\n') or '', 
        }

        return {type=k, name=name, description=description}
      else
        local name, description = s:match('(%S+)%s+.%s+(.*)')
        return {type=k, name=name, description=description}
      end
    end
  end
})

paragraph = function(t)
  return [[ <p>${content}</p> ]] % {content=table.concat(t, '\n')}
end

list = function(t) 
  for k, v in ipairs(t) do
    t[k] = '<li>' .. v .. '</li>'
  end
  return [[ <ul>${list}</ul> ]] % {list=table.concat(t)}
end

tabledef = function(t)
  for k, v in ipairs(t) do
    t[k] = '<li>' .. v.key .. ' - ' .. v.value .. '</li>'
  end
  return [[ <ul>${description}${list}</ul> ]] % {list=table.concat(t), description=t.description or ''}
end

key = setmetatable({}, {
  __index = function(t, k)
    return function(s)
      if type(s) == 'table' then
        local t = s
        return {key=k, value=t[1]}
      else
        return {key=k, value=s}
      end
    end
  end
})

require(...)
