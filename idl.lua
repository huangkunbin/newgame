local function getinnertype(typ)
  if string.sub(typ,1,4) == "List" then
    return string.sub(typ,6,#typ-1)
  end
  return typ
end

local function addfieldtype(t)
  local innertype = getinnertype(t.type)
  if innertype == "Integer" then
    t.fieldType = "FieldType.INT32"
  elseif innertype == "Long" then
    t.fieldType = "FieldType.INT64"
  elseif innertype == "Boolean" then
    t.fieldType = "FieldType.BOOL"
  end
  return t
end

local function typedef(_, name)
  local function def(val)
    local t = {type = name,value = val}
    return function(str)
      t.comment = str
      return addfieldtype(t)
    end
  end
  return def
end

local idl = setmetatable({}, {__index = typedef})

idl.getinnertype = getinnertype

local m = {}
idl.m = m

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function sort_methods(a,b)
  return tonumber(a.id) < tonumber(b.id)
end

local function add_method(t)
    for id, method in pairs(t) do
       method.id = id
       local id_t = idl.int "id" "ID"
       id_t.default = id
       if method.req then
        table.insert(method.req, 1,id_t)
       end
       if method.res then
        table.insert(method.res, 1,id_t)
       end
       m.methods[#m.methods+1] = method
    end
    table.sort(m.methods,sort_methods)
end

function idl.mod(modname)
    m.modname = modname
    m.methods = {}
    return function (v)
        m.comment = v
      return add_method
    end
  end

local comments = {}
idl.comments = comments

function idl.comment (str)
    comments[#comments+1] = str
end

function idl.api(funcname)
    local f = {name = funcname}
    local function add_val(t)
      for _,v in ipairs(t) do
        if v.type == "req" then
          f.req = v.value
        elseif v.type == "res" then
          f.res = v.value
        end
      end
      return f
    end
    return function (str)
      f.comment = str
      return add_val
    end
end

function idl.req(t)
    return {type = "req",value = t}
end

function idl.res(t)
    return {type = "res",value = t}
end

local clz = {}
idl.clz = clz

local function classdef(_, name)
  name = trim(name)
  local t = {type = "classdef", name = name}
  return function(value)
        t.value = value
        clz[t.name] = t
  end
end

local function class(_, classname)
  clz[classname].isused = true
  local name = clz[classname].name
  return idl[name]
end

idl.class = setmetatable({}, {__index = class, __call = classdef})

function idl.list(E)
  E = trim(E)
  if clz[E] then
    clz[E].isused = true
  end
  local name = "List<"..E..">"
  return idl[name]
end

return idl