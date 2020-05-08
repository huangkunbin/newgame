local idl = require "idl"
local etlua = require "etlua"
local inspect = require("inspect")


local function file_exists(path)
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end


local env = {}
env.mod = idl.mod
env.api = idl.api
env.comment = idl.comment
env.req = idl.req
env.res = idl.res
env.String = idl.String
env.int = idl.int
env.Integer = idl.Integer
env.long = idl.long
env.Long = idl.Long
env.boolean = idl.boolean
env.Boolean = idl.Boolean
env.classdef = idl.classdef
env.class = idl.class
env.list = idl.list

local mod = idl.m
local clz = idl.clz

if file_exists("proto/common_class.lua") then
  loadfile("proto/common_class.lua","t",env)()
  for _,c in pairs(clz) do
    c.iscommon = true
  end
end

local proto = arg[1]
loadfile(proto,"t",env)()

local conf_path = "config.lua"
local conf = loadfile(conf_path,"t")()

local ROOT_PATH = conf.ROOT_PATH
local PROJECT_NAME = conf.PROJECT_NAME:gsub("{{MOD}}",mod.modname)
local TEMPLATES_PATH = ROOT_PATH..conf.TEMPLATES_PATH:gsub("{{MOD}}",mod.modname)
local MESSAGE_PATH = ROOT_PATH..conf.MESSAGE_PATH:gsub("{{MOD}}",mod.modname)
local COMMON_CLASS_PATH = ROOT_PATH..conf.COMMON_CLASS_PATH:gsub("{{MOD}}",mod.modname)
local CLASS_PATH = ROOT_PATH..conf.CLASS_PATH:gsub("{{MOD}}",mod.modname)
local HANDLER_PATH = ROOT_PATH..conf.HANDLER_PATH:gsub("{{MOD}}",mod.modname)
local ROBOT_HANDLER_PATH = ROOT_PATH..conf.ROBOT_HANDLER_PATH:gsub("{{MOD}}",mod.modname)
local MSGID_PATH = ROOT_PATH..conf.MSGID_PATH:gsub("{{MOD}}",mod.modname)
local MARKDOWN_PATH = ROOT_PATH..conf.MARKDOWN_PATH:gsub("{{MOD}}",mod.modname)


local function snake(s)
  return s:gsub('%f[^%l]%u','_%1'):gsub('%f[^%a]%d','_%1'):gsub('%f[^%d]%a','_%1'):gsub('(%u)(%u%l)','%1_%2'):lower()
end

local function array_sort(array)
  local sort_array = {}
  for _,a in pairs(array) do
    sort_array[#sort_array+1] = a
  end
  table.sort(sort_array)
  return sort_array
end

local function create_file(typ,temp_file_path,parameter)
  local template_file = assert(io.open(temp_file_path))
  local template = template_file:read("*a")
  template_file:close()

  local str = etlua.compile(template)
  local file = str(parameter)

  local file_path
  local file_name
  if typ == "Class" then
    if parameter.iscommon then
      file_path = COMMON_CLASS_PATH
    else
      file_path = CLASS_PATH
    end
    file_name = file_path..parameter.name:gsub("%a", string.upper, 1)..".java"
  elseif typ == "Handler" then
    file_path = HANDLER_PATH
    file_name = file_path.."Req"..parameter.name:gsub("%a", string.upper, 1)..typ..".java"
  elseif typ == "Msgid" then
    file_path = MSGID_PATH
    file_name = file_path..parameter.modname:gsub("%a", string.upper, 1).."ModuleMsgIdConstant.java"
  elseif typ == "Markdown" then
    file_path = MARKDOWN_PATH
    file_name = file_path..parameter.modname..".md"
  elseif typ == "RobotHandler" then
    file_path = ROBOT_HANDLER_PATH
    file_name = file_path.."Res"..parameter.name:gsub("%a", string.upper, 1).."Handler"..".java"
  else
    file_path = MESSAGE_PATH
    file_name = file_path..typ..parameter.name:gsub("%a", string.upper, 1).."Msg.java"
  end

  if not file_exists(file_path) then
    os.execute("mkdir -p "..file_path)
  end

  if (typ == "Handler" or typ == "RobotHandler") and file_exists(file_name) then
    return
  end

  local code = assert(io.open(file_name, 'w'))
  code:write(file)
  code:close()
end

local common_class_pkg_path = "import com."..PROJECT_NAME..".game.gamehall.dto."
local class_pkg_path = "import com."..PROJECT_NAME..".game.games."..mod.modname..".dto."

local function get_pkgs(args)
  local pkgs = {}
  for _,a in ipairs(args) do
   if clz[a.type] then
      if clz[a.type].iscommon then
        pkgs[common_class_pkg_path..a.type] = common_class_pkg_path..a.type
      else
        pkgs[class_pkg_path..a.type] = class_pkg_path..a.type
      end
   end
   if a.fieldType then
    pkgs["import com.baidu.bjf.remoting.protobuf.FieldType"] = "import com.baidu.bjf.remoting.protobuf.FieldType"
 end
   if string.sub(a.type,1,4) == "List" then
    pkgs["import java.util.List"] = "import java.util.List"
    local innertype = idl.getinnertype(a.type)
    if clz[innertype] then
      pkgs[class_pkg_path..innertype] = class_pkg_path..innertype
    end
   end
  end
  return array_sort(pkgs)
end

local parameter = {}

parameter.projectname = PROJECT_NAME
parameter.modname = mod.modname
parameter.comment = mod.comment
parameter.methods = mod.methods
parameter.snake = snake
create_file("Msgid",TEMPLATES_PATH.."msgid.etlua",parameter)
parameter.clz = clz
local clz_key = {}
for key,_ in pairs(clz) do
    table.insert(clz_key,key)
end
table.sort(clz_key)
parameter.clz_key = clz_key
parameter.comments = idl.comments
parameter.getinnertype = idl.getinnertype
create_file("Markdown",TEMPLATES_PATH.."markdown.etlua",parameter)

parameter = {}
parameter.projectname = PROJECT_NAME
parameter.modname = mod.modname
for _,m in ipairs(mod.methods) do
    parameter.name = m.name
    parameter.comment = m.comment
    parameter.req = m.req
    parameter.res = m.res
    parameter.snake = snake
    if parameter.req then
    parameter.pkgs = get_pkgs(parameter.req)
    create_file("Req",TEMPLATES_PATH.."req.etlua",parameter)
    create_file("Handler",TEMPLATES_PATH.."handler.etlua",parameter)
    end
    if parameter.res then
    parameter.pkgs = get_pkgs(parameter.res)
    create_file("Res",TEMPLATES_PATH.."/res.etlua",parameter)
    create_file("RobotHandler",TEMPLATES_PATH.."robothandler.etlua",parameter)
    end
end

parameter = {}
parameter.projectname = PROJECT_NAME
parameter.modname = mod.modname
for _,c in pairs(clz) do
  parameter.name = c.name
  parameter.comment = c.comment
  parameter.value = c.value
  parameter.pkgs = get_pkgs(c.value)
  parameter.iscommon = c.iscommon
  create_file("Class",TEMPLATES_PATH.."class.etlua",parameter)
end



