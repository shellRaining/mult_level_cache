local args_util = require("mult_level_cache.args")
local validateKeys = require("mult_level_cache.validate").validateKeys

---@class MultLevelCacheModule
local CacheModule = {}

---@class MultLevelCache
---@field private keys table 缓存键数组
---@field private cache table 缓存数据存储
local Cache = {}
local Cache_mt = { __index = Cache }

--- 创建新的缓存实例
---@param ... string 缓存键名称
---@return MultLevelCache
function CacheModule.new(...)
  if args_util.is_args_contain_nil(...) then
    error("Keys can't contain nil")
  end
  local self = {
    keys = { ... },
    cache = {},
  }
  return setmetatable(self, Cache_mt)
end

--- 导航到缓存中的特定位置
---@param cache table 缓存表
---@param values table 键值数组
---@param createIfMissing boolean 如果路径不存在是否创建
---@param isSetValue? boolean 是否设置值
---@param setValue? any 要设置的值
---@return any
local function navigateCache(cache, values, createIfMissing, isSetValue, setValue)
  local tableRef = cache
  local searchSteps = #values
  for i = 1, searchSteps - 1 do
    local key = values[i]
    if tableRef[key] == nil then
      if createIfMissing then
        tableRef[key] = {}
      else
        return nil
      end
    end
    tableRef = tableRef[key]
  end

  if isSetValue then
    tableRef[values[searchSteps]] = setValue
  else
    return tableRef[values[searchSteps]]
  end
end

--- 获取缓存值
---@param ... any 键值
---@return any 缓存值
function Cache:get(...)
  local valid, err = validateKeys(#self.keys, ...)
  if not valid then
    error(err)
  end
  return navigateCache(self.cache, args_util.args_to_table(...), false)
end

--- 设置缓存值
---@param ... any 键值和要存储的值(最后一个参数)
function Cache:set(...)
  local args = args_util.args_to_table(...)
  local keys = { unpack(args, 1, #self.keys) }
  local value = args_util.get_last_arg(...)

  local valid, err = validateKeys(#self.keys, unpack(keys))
  if not valid then
    error(err)
  end
  if args_util.get_args_count(...) ~= #self.keys + 1 then
    error("The number of keys must be " .. #self.keys .. ", got " .. args_util.get_args_count(...))
  end

  navigateCache(self.cache, keys, true, true, value)
end

--- 检查缓存键是否存在
---@param ... any 键值
---@return boolean
function Cache:has(...)
  local valid, err = validateKeys(#self.keys, ...)
  if not valid then
    error(err)
  end
  return navigateCache(self.cache, args_util.args_to_table(...), false) ~= nil
end

--- 清除缓存
---@param ... any 要清除的键路径(可选)
function Cache:clear(...)
  if args_util.get_args_count(...) == 0 then
    self.cache = {}
  else
    if args_util.is_args_contain_nil(...) then
      error("Keys can't contain nil")
    end
    navigateCache(self.cache, args_util.args_to_table(...), false, true, {})
  end
end

--- 删除缓存项
---@param ... any 键值
function Cache:remove(...)
  local valid, err = validateKeys(#self.keys, ...)
  if not valid then
    error(err)
  end
  navigateCache(self.cache, args_util.args_to_table(...), false, true, nil)
end

return CacheModule
