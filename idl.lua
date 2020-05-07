local T = {
  string = "String",
  int = "int",
  Integer = "Integer",
  long = "long",
  Long = "Long",
  boolean = "boolean",
  Boolean = "Boolean"
}

local function typedef(_, name)
  local function def(val)
    local t = {type = T[name],value = val}
    if name == "Integer" then
      t.fieldType = "FieldType.INT32"
    elseif name == "Long" then
      t.fieldType = "FieldType.INT64"
    elseif name == "Boolean" then
      t.fieldType = "FieldType.BOOL"
    end
    return function(str)
      t.comment = str
      return t
    end
  end
  return def
end

local idl = setmetatable({}, {__index = typedef})

idl.T = T

local mods = {}

idl.mods = mods

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function sort_methods(a,b)
  return tonumber(a.id) < tonumber(b.id)
end

local function add_method(t)
    for id, m in pairs(t) do
       m.id=id
       local id_t = idl.int "id" "ID"
       id_t.default=id
       if m.req then
        table.insert( m.req, 1,id_t)
       end
       if m.res then
        table.insert( m.res, 1,id_t)
       end
       mods.methods[#mods.methods+1] = m
    end
    table.sort(mods.methods,sort_methods)
end

function idl.mod(modname)
    mods.modname = modname
    mods.methods = {}
    return function (v)
        mods.comment = v
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
        elseif v.type == "comment" then
          f.comment = v.value
        end
      end
      return f
    end
    return function (t)
      f.comment = t
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

local function class(_, classname)
  local function def(val)
    local t = {type = clz[classname].name,value = val}
    return function(str)
      clz[classname].isused = true
      clz[classname].comment = str
      t.comment = str
      return t
    end
  end
  return def
end

idl.class = setmetatable({}, {__index = class})

function idl.classdef(name)
  name = trim(name)
  if not T[name] then
    T[name] = name
  end
  local t = {type = "classdef", name = name}
  return function(value)
        t.value = value
        clz[t.name] = t
  end
end

function idl.list(E)
  E = trim(E)
  local t = {type = "List<"..E..">",value = ""}
  t.innertype = T[E]
  if t.innertype == T.Integer then
    t.fieldType = "FieldType.INT32"
  elseif t.innertype == T.Long then
    t.fieldType = "FieldType.INT64"
  elseif t.innertype ==T.Boolean then
    t.fieldType = "FieldType.BOOL"
  end
  if clz[E] then
    clz[E].isused = true
  end
  return function (val)
    t.value = val
    return function(str)
      t.comment = str
      return t
    end
  end
end

return idl