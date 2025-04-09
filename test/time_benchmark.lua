local ml_cache = require("mult_level_cache/ml_cache")
local sk_cache = require("mult_level_cache/sk_cache")

-- 预先生成测试数据，避免在测试中进行字符串拼接
local function prepare_test_data(size)
  local values = {}
  for i = 1, size do
    values[i] = "value" .. i
  end
  return values
end

-- 创建一个简单的基准测试框架
local function benchmark(name, iterations, setup_fn, test_fn)
  -- 打印标题
  print(string.format("Running benchmark: %s (%d iterations)", name, iterations))

  -- 运行初始化函数
  local test_data = setup_fn and setup_fn() or nil

  -- 开始计时前确保垃圾回收完成，最大程度减少干扰
  collectgarbage("collect")

  -- 开始计时
  local start_time = vim.uv.hrtime()

  -- 执行测试
  for i = 1, iterations do
    test_fn(test_data, i)
  end

  -- 结束计时
  local end_time = vim.uv.hrtime()
  local duration_ns = end_time - start_time
  local duration_ms = duration_ns / 1000000

  -- 输出结果
  print(string.format("  Time: %.3f ms (%.3f ns per iteration)", duration_ms, duration_ns / iterations))

  return duration_ns
end

-- 比较两个缓存的相同操作
local function compare_caches(test_name, iterations, ml_setup, ml_test_fn, sk_setup, sk_test_fn)
  print("\n===== " .. test_name .. " =====")

  local ml_time = benchmark("MultLevelCache", iterations, ml_setup, ml_test_fn)
  local sk_time = benchmark("StrKeyCache", iterations, sk_setup, sk_test_fn)

  local ratio = sk_time / ml_time
  local faster = ratio > 1 and "MultLevelCache" or "StrKeyCache"
  local percent = math.abs(1 - ratio) * 100

  print(string.format("Comparison: %s is %.2f%% %s\n", faster, percent, ratio > 1 and "faster" or "slower"))

  return {
    ml_time = ml_time,
    sk_time = sk_time,
    ratio = ratio,
  }
end

-- 预定义测试值集合
local TEST_SIZES = {
  SMALL = 100,
  MEDIUM = 1000,
  LARGE = 5000,
}

---------- 测试用例 ----------

-- 测试 1: 单键缓存 - 设置操作
local function test_single_key_set()
  -- 准备测试数据
  local function setup()
    return prepare_test_data(TEST_SIZES.MEDIUM)
  end

  -- MultLevelCache 测试
  local function ml_test(values)
    local cache = ml_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(i, values[i])
    end
  end

  -- StrKeyCache 测试
  local function sk_test(values)
    local cache = sk_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(i, values[i])
    end
  end

  return compare_caches("单键缓存 - 设置操作", 20, setup, ml_test, setup, sk_test)
end

-- 测试 2: 单键缓存 - 获取操作
local function test_single_key_get()
  -- 准备测试数据和缓存
  local function ml_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local cache = ml_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(i, values[i])
    end
    return { cache = cache, values = values }
  end

  local function sk_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local cache = sk_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(i, values[i])
    end
    return { cache = cache, values = values }
  end

  -- MultLevelCache 测试
  local function ml_test(data)
    for i = 1, TEST_SIZES.MEDIUM do
      local val = data.cache:get(i)
      -- 确保优化器不会移除这个调用
      if val == nil then
        error("Unexpected nil value")
      end
    end
  end

  -- StrKeyCache 测试
  local function sk_test(data)
    for i = 1, TEST_SIZES.MEDIUM do
      local val = data.cache:get(i)
      -- 确保优化器不会移除这个调用
      if val == nil then
        error("Unexpected nil value")
      end
    end
  end

  return compare_caches("单键缓存 - 获取操作", 20, ml_setup, ml_test, sk_setup, sk_test)
end

-- 测试 3: 单键缓存 - has操作
local function test_single_key_has()
  -- 准备测试数据和缓存
  local function ml_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local cache = ml_cache.new("key")
    -- 只设置偶数键
    for i = 1, TEST_SIZES.MEDIUM, 2 do
      cache:set(i, values[i])
    end
    return { cache = cache }
  end

  local function sk_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local cache = sk_cache.new("key")
    -- 只设置偶数键
    for i = 1, TEST_SIZES.MEDIUM, 2 do
      cache:set(i, values[i])
    end
    return { cache = cache }
  end

  -- MultLevelCache 测试
  local function ml_test(data)
    local count = 0
    for i = 1, TEST_SIZES.MEDIUM do
      if data.cache:has(i) then
        count = count + 1
      end
    end
  end

  -- StrKeyCache 测试
  local function sk_test(data)
    local count = 0
    for i = 1, TEST_SIZES.MEDIUM do
      if data.cache:has(i) then
        count = count + 1
      end
    end
  end

  return compare_caches("单键缓存 - has操作", 20, ml_setup, ml_test, sk_setup, sk_test)
end

-- 测试 4: 双键缓存 - 设置操作
local function test_double_key_set()
  -- 准备测试数据
  local function setup()
    return prepare_test_data(TEST_SIZES.MEDIUM)
  end

  -- MultLevelCache 测试
  local function ml_test(values)
    local cache = ml_cache.new("key1", "key2")
    for i = 1, 50 do
      for j = 1, 50 do
        cache:set(i, j, values[(i - 1) * 50 + j])
      end
    end
  end

  -- StrKeyCache 测试
  local function sk_test(values)
    local cache = sk_cache.new("key1", "key2")
    for i = 1, 50 do
      for j = 1, 50 do
        cache:set(i, j, values[(i - 1) * 50 + j])
      end
    end
  end

  return compare_caches("双键缓存 - 设置操作", 20, setup, ml_test, setup, sk_test)
end

-- 测试 5: 双键缓存 - 获取操作
local function test_double_key_get()
  -- 准备测试数据和缓存
  local function ml_setup()
    local values = prepare_test_data(50 * 50)
    local cache = ml_cache.new("key1", "key2")
    for i = 1, 50 do
      for j = 1, 50 do
        cache:set(i, j, values[(i - 1) * 50 + j])
      end
    end
    return { cache = cache }
  end

  local function sk_setup()
    local values = prepare_test_data(50* 50)
    local cache = sk_cache.new("key1", "key2")
    for i = 1, 50 do
      for j = 1, 50 do
        cache:set(i, j, values[(i - 1) * 50 + j])
      end
    end
    return { cache = cache }
  end

  -- MultLevelCache 测试
  local function ml_test(data)
    for i = 1, 50 do
      for j = 1, 50 do
        local val = data.cache:get(i, j)
        if val == nil then
          error(string.format("Unexpected nil value for (%d, %d)", i, j))
        end
      end
    end
  end

  -- StrKeyCache 测试
  local function sk_test(data)
    for i = 1, 50 do
      for j = 1, 50 do
        local val = data.cache:get(i, j)
        if val == nil then
          error("Unexpected nil value")
        end
      end
    end
  end

  return compare_caches("双键缓存 - 获取操作", 20, ml_setup, ml_test, sk_setup, sk_test)
end

-- 测试 6: 三键缓存 - 设置操作
local function test_triple_key_set()
  -- 准备测试数据
  local function setup()
    return prepare_test_data(TEST_SIZES.SMALL)
  end

  -- MultLevelCache 测试
  local function ml_test(values)
    local cache = ml_cache.new("key1", "key2", "key3")
    for i = 1, 10 do
      for j = 1, 10 do
        for k = 1, 10 do
          -- 获取预计算的值
          cache:set(i, j, k, values[(i - 1) * 100 + (j - 1) * 10 + k])
        end
      end
    end
  end

  -- StrKeyCache 测试
  local function sk_test(values)
    local cache = sk_cache.new("key1", "key2", "key3")
    for i = 1, 10 do
      for j = 1, 10 do
        for k = 1, 10 do
          -- 获取预计算的值
          cache:set(i, j, k, values[(i - 1) * 100 + (j - 1) * 10 + k])
        end
      end
    end
  end

  return compare_caches("三键缓存 - 设置操作", 10, setup, ml_test, setup, sk_test)
end

-- 测试 7: 三键缓存 - 获取操作
local function test_triple_key_get()
  -- 准备测试数据和缓存
  local function ml_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local cache = ml_cache.new("key1", "key2", "key3")
    for i = 1, 10 do
      for j = 1, 10 do
        for k = 1, 10 do
          cache:set(i, j, k, values[(i - 1) * 100 + (j - 1) * 10 + k])
        end
      end
    end
    return { cache = cache }
  end

  local function sk_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local cache = sk_cache.new("key1", "key2", "key3")
    for i = 1, 10 do
      for j = 1, 10 do
        for k = 1, 10 do
          cache:set(i, j, k, values[(i - 1) * 100 + (j - 1) * 10 + k])
        end
      end
    end
    return { cache = cache }
  end

  -- MultLevelCache 测试
  local function ml_test(data)
    for i = 1, 10 do
      for j = 1, 10 do
        for k = 1, 10 do
          local val = data.cache:get(i, j, k)
          if val == nil then
            error("Unexpected nil value")
          end
        end
      end
    end
  end

  -- StrKeyCache 测试
  local function sk_test(data)
    for i = 1, 10 do
      for j = 1, 10 do
        for k = 1, 10 do
          local val = data.cache:get(i, j, k)
          if val == nil then
            error("Unexpected nil value")
          end
        end
      end
    end
  end

  return compare_caches("三键缓存 - 获取操作", 10, ml_setup, ml_test, sk_setup, sk_test)
end

-- 测试 8: 字符串键 vs 数字键
local function test_string_vs_number_keys()
  -- 数字键测试
  local function ml_num_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    return { values = values }
  end

  local function sk_num_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    return { values = values }
  end

  local function ml_num_test(data)
    local cache = ml_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(i, data.values[i])
    end
  end

  local function sk_num_test(data)
    local cache = sk_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(i, data.values[i])
    end
  end

  -- 字符串键测试
  local function ml_str_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    -- 预生成字符串键
    local keys = {}
    for i = 1, TEST_SIZES.MEDIUM do
      keys[i] = "key" .. i
    end
    return { values = values, keys = keys }
  end

  local function sk_str_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    -- 预生成字符串键
    local keys = {}
    for i = 1, TEST_SIZES.MEDIUM do
      keys[i] = "key" .. i
    end
    return { values = values, keys = keys }
  end

  local function ml_str_test(data)
    local cache = ml_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(data.keys[i], data.values[i])
    end
  end

  local function sk_str_test(data)
    local cache = sk_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(data.keys[i], data.values[i])
    end
  end

  print("\n===== 数字键操作 =====")
  local num_result = compare_caches("数字键设置操作", 20, ml_num_setup, ml_num_test, sk_num_setup, sk_num_test)

  print("\n===== 字符串键操作 =====")
  local str_result =
    compare_caches("字符串键设置操作", 20, ml_str_setup, ml_str_test, sk_str_setup, sk_str_test)

  print("\n===== 键类型比较 =====")
  print(string.format("MultLevelCache: 字符串键 vs 数字键比率: %.2f", str_result.ml_time / num_result.ml_time))
  print(string.format("StrKeyCache: 字符串键 vs 数字键比率: %.2f", str_result.sk_time / num_result.sk_time))

  return { num = num_result, str = str_result }
end

-- 测试 9: 部分清除
local function test_partial_clear()
  -- 准备测试数据和缓存
  local function ml_setup()
    local cache = ml_cache.new("key1", "key2", "key3")
    -- 填充数据
    for i = 1, 20 do
      for j = 1, 20 do
        for k = 1, 20 do
          cache:set(i, j, k, i * j * k)
        end
      end
    end
    return { cache = cache }
  end

  local function sk_setup()
    local cache = sk_cache.new("key1", "key2", "key3")
    -- 填充数据
    for i = 1, 20 do
      for j = 1, 20 do
        for k = 1, 20 do
          cache:set(i, j, k, i * j * k)
        end
      end
    end
    return { cache = cache }
  end

  -- MultLevelCache 测试
  local function ml_test(data)
    for i = 1, 20 do
      data.cache:clear(i)
    end
  end

  -- StrKeyCache 测试
  local function sk_test(data)
    for i = 1, 20 do
      data.cache:clear(i)
    end
  end

  return compare_caches("部分清除操作", 10, ml_setup, ml_test, sk_setup, sk_test)
end

-- 运行所有基准测试
local function run_all_benchmarks()
  print("===== 高精度缓存性能测试 =====")
  print("每个测试都会预先生成测试数据，以避免额外的字符串拼接开销")
  print("开始测试...\n")

  local results = {}
  results.single_key_set = test_single_key_set()
  results.single_key_get = test_single_key_get()
  results.single_key_has = test_single_key_has()
  results.double_key_set = test_double_key_set()
  results.double_key_get = test_double_key_get()
  results.triple_key_set = test_triple_key_set()
  results.triple_key_get = test_triple_key_get()
  results.keys_compare = test_string_vs_number_keys()
  results.partial_clear = test_partial_clear()

  print("\n===== 测试结果汇总 =====")

  local tests = {
    { name = "单键设置", result = results.single_key_set },
    { name = "单键获取", result = results.single_key_get },
    { name = "单键检查", result = results.single_key_has },
    { name = "双键设置", result = results.double_key_set },
    { name = "双键获取", result = results.double_key_get },
    { name = "三键设置", result = results.triple_key_set },
    { name = "三键获取", result = results.triple_key_get },
    { name = "数字键", result = results.keys_compare.num },
    { name = "字符串键", result = results.keys_compare.str },
    { name = "部分清除", result = results.partial_clear },
  }

  -- 汇总结果
  local ml_wins = 0
  local sk_wins = 0

  print("测试项目           | 获胜者         | 差异百分比")
  print("------------------ | ------------- | ----------")

  for _, test in ipairs(tests) do
    local winner = test.result.ratio > 1 and "MultLevelCache" or "StrKeyCache"
    local percent = math.abs(1 - test.result.ratio) * 100

    if winner == "MultLevelCache" then
      ml_wins = ml_wins + 1
    else
      sk_wins = sk_wins + 1
    end

    print(string.format("%-18s | %-13s | %.2f%%", test.name, winner, percent))
  end

  print("\n总体获胜者: " .. (ml_wins > sk_wins and "MultLevelCache" or "StrKeyCache"))
  print(string.format("结果: MultLevelCache %d - %d StrKeyCache", ml_wins, sk_wins))

  print("\n测试完成!")
end

-- 运行基准测试
run_all_benchmarks()
