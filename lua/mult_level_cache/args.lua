local ArgsModule = {}

function ArgsModule.get_args_count(...)
  return select("#", ...)
end

function ArgsModule.get_last_arg(...)
  local n = select("#", ...)
  if n == 0 then
    return nil
  end
  return select(n, ...)
end

function ArgsModule.is_args_contain_nil(...)
  for i = 1, select("#", ...) do
    if select(i, ...) == nil then
      return true
    end
  end
  return false
end

function ArgsModule.args_to_table(...)
  local args = {}
  for i = 1, select("#", ...) do
    args[i] = select(i, ...)
  end
  return args
end

return ArgsModule
