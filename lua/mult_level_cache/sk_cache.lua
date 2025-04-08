local args_util = require("mult_level_cache.args")
local validateKeys = require("mult_level_cache.validate").validateKeys

---@class StrKeyCacheModule
local CacheModule = {}

---@class StrKeyCache
---@field private keys table 缓存键名称数组
---@field separator string 键值分隔符
---@field private cache table 缓存数据存储
local Cache = {}
local Cache_mt = { __index = Cache }

--- 创建新的缓存实例
---@param ... string 缓存键名称
---@return StrKeyCache
function CacheModule.new(...)
  local separator = ":"
  local keys = args_util.args_to_table(...)

  if args_util.is_args_contain_nil(unpack(keys)) then
    error("Keys can't contain nil")
  end

  local self = {
    keys = keys,
    separator = separator,
    cache = {},
  }
  return setmetatable(self, Cache_mt)
end

--- 生成缓存键
---@param self StrKeyCache
---@param values table 键值数组
---@return string 连接后的缓存键
local function generateKey(self, values)
  local key = tostring(values[1])
  for i = 2, #values do
    key = key .. self.separator .. tostring(values[i])
  end
  return key
end

--- 获取缓存值
---@param ... any 键值
---@return any 缓存值
function Cache:get(...)
  local valid, err = validateKeys(#self.keys, ...)
  if not valid then
    error(err)
  end

  local key = generateKey(self, args_util.args_to_table(...))
  return self.cache[key]
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
    error("The number of arguments must be " .. #self.keys + 1 .. ", got " .. args_util.get_args_count(...))
  end

  local key = generateKey(self, keys)
  self.cache[key] = value
end

--- 检查缓存键是否存在
---@param ... any 键值
---@return boolean
function Cache:has(...)
  local valid, err = validateKeys(#self.keys, ...)
  if not valid then
    error(err)
  end

  local key = generateKey(self, args_util.args_to_table(...))
  return self.cache[key] ~= nil
end

--- 清除缓存
---@param ... any 要清除的键路径(可选)
function Cache:clear(...)
  if args_util.get_args_count(...) == 0 then
    self.cache = {}
    return
  end

  if args_util.is_args_contain_nil(...) then
    error("Keys can't contain nil")
  end

  local values = args_util.args_to_table(...)

  -- 验证提供的键数量不超过定义的键数量
  if #values > #self.keys then
    error(string.format("The number of keys must be at most %d, got %d", #self.keys, #values))
  end

  -- 生成前缀
  local prefix = generateKey(self, values)

  -- 找出并删除所有以该前缀开头的缓存项
  local keysToRemove = {}
  for k in pairs(self.cache) do
    -- 检查键是否与前缀匹配
    if k:sub(1, #prefix) == prefix then
      -- 如果完全匹配或者下一个字符是分隔符
      if #k == #prefix or k:sub(#prefix + 1, #prefix + 1) == self.separator then
        keysToRemove[#keysToRemove + 1] = k
      end
    end
  end

  -- 删除匹配的键
  for _, k in ipairs(keysToRemove) do
    self.cache[k] = nil
  end
end

--- 删除缓存项
---@param ... any 键值
function Cache:remove(...)
  local valid, err = validateKeys(#self.keys, ...)
  if not valid then
    error(err)
  end

  local key = generateKey(self, args_util.args_to_table(...))
  self.cache[key] = nil
end

return CacheModule
