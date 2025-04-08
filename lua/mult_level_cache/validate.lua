local args_util = require('mult_level_cache.args')

local M = {}

---验证键值
---@param expectCount number 期望的键数量
---@param ... any 键值
---@return boolean, string 是否有效，错误信息
function M.validateKeys(expectCount, ...)
  if expectCount ~= args_util.get_args_count(...) then
    return false, string.format("The number of keys must be %d, got %d", expectCount, args_util.get_args_count(...))
  end

  if args_util.is_args_contain_nil(...) then
    return false, "Keys can't contain nil"
  end

  return true, ""
end


return M
