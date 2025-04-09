local ml_cache = require("mult_level_cache/ml_cache")
local sk_cache = require("mult_level_cache/sk_cache")

-- 计算内存占用的辅助函数
local function get_memory_usage()
  collectgarbage("collect")
  return collectgarbage("count")
end

-- 预先生成测试数据，避免在测试中影响内存测量
local function prepare_test_data(size)
  local values = {}
  for i = 1, size do
    values[i] = "value" .. i
  end
  return values
end

-- 创建空间占用基准测试框架
local function memory_benchmark(name, setup_fn, cleanup_fn)
  -- 打印标题
  print(string.format("Running memory benchmark: %s", name))

  -- 初始基准内存占用
  collectgarbage("collect")
  local base_memory = get_memory_usage()
  print(string.format("  Base memory usage: %.2f KB", base_memory))

  -- 运行初始化函数
  local test_data = setup_fn()

  -- 测量内存占用
  local memory_after = get_memory_usage()
  local memory_used = memory_after - base_memory

  -- 输出结果
  print(string.format("  Memory usage: %.2f KB (%.2f KB increase)", memory_after, memory_used))

  -- 运行清理函数释放内存
  if cleanup_fn then
    cleanup_fn(test_data)
  end

  -- 验证清理是否有效
  collectgarbage("collect")
  local final_memory = get_memory_usage()
  print(
    string.format(
      "  Final memory after cleanup: %.2f KB (%.2f KB difference from base)",
      final_memory,
      final_memory - base_memory
    )
  )

  return memory_used
end

-- 比较两个缓存的内存占用
local function compare_memory_usage(test_name, ml_setup, ml_cleanup, sk_setup, sk_cleanup)
  print("\n===== " .. test_name .. " =====")

  local ml_memory = memory_benchmark("MultLevelCache", ml_setup, ml_cleanup)
  local sk_memory = memory_benchmark("StrKeyCache", sk_setup, sk_cleanup)

  local ratio = sk_memory / ml_memory
  local more_efficient = ratio > 1 and "MultLevelCache" or "StrKeyCache"
  local percent = math.abs(1 - ratio) * 100

  print(string.format("比较结果: %s 内存使用量少 %.2f%%\n", more_efficient, percent))

  return {
    ml_memory = ml_memory,
    sk_memory = sk_memory,
    ratio = ratio,
  }
end

-- 测试场景定义
local TEST_SIZES = {
  SMALL = 100,
  MEDIUM = 1000,
  LARGE = 5000,
}

---------- 内存占用测试用例 ----------

-- 测试 1: 单键缓存 - 空间占用
local function test_single_key_memory()
  -- MultLevelCache 测试
  local function ml_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local cache = ml_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(i, values[i])
    end
    return { cache = cache, values = values }
  end

  local function ml_cleanup(data)
    data.cache = nil
    data.values = nil
  end

  -- StrKeyCache 测试
  local function sk_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local cache = sk_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(i, values[i])
    end
    return { cache = cache, values = values }
  end

  local function sk_cleanup(data)
    data.cache = nil
    data.values = nil
  end

  return compare_memory_usage("单键缓存 - 空间占用", ml_setup, ml_cleanup, sk_setup, sk_cleanup)
end

-- 测试 2: 双键缓存 - 空间占用
local function test_double_key_memory()
  -- MultLevelCache 测试
  local function ml_setup()
    local values = prepare_test_data(50 * 50)
    local cache = ml_cache.new("key1", "key2")
    for i = 1, 50 do
      for j = 1, 50 do
        cache:set(i, j, values[(i - 1) * 50 + j])
      end
    end
    return { cache = cache, values = values }
  end

  local function ml_cleanup(data)
    data.cache = nil
    data.values = nil
  end

  -- StrKeyCache 测试
  local function sk_setup()
    local values = prepare_test_data(50 * 50)
    local cache = sk_cache.new("key1", "key2")
    for i = 1, 50 do
      for j = 1, 50 do
        cache:set(i, j, values[(i - 1) * 50 + j])
      end
    end
    return { cache = cache, values = values }
  end

  local function sk_cleanup(data)
    data.cache = nil
    data.values = nil
  end

  return compare_memory_usage("双键缓存 - 空间占用", ml_setup, ml_cleanup, sk_setup, sk_cleanup)
end

-- 测试 3: 三键缓存 - 空间占用
local function test_triple_key_memory()
  -- MultLevelCache 测试
  local function ml_setup()
    local values = prepare_test_data(10 * 10 * 10)
    local cache = ml_cache.new("key1", "key2", "key3")
    for i = 1, 10 do
      for j = 1, 10 do
        for k = 1, 10 do
          cache:set(i, j, k, values[(i - 1) * 100 + (j - 1) * 10 + k])
        end
      end
    end
    return { cache = cache, values = values }
  end

  local function ml_cleanup(data)
    data.cache = nil
    data.values = nil
  end

  -- StrKeyCache 测试
  local function sk_setup()
    local values = prepare_test_data(10 * 10 * 10)
    local cache = sk_cache.new("key1", "key2", "key3")
    for i = 1, 10 do
      for j = 1, 10 do
        for k = 1, 10 do
          cache:set(i, j, k, values[(i - 1) * 100 + (j - 1) * 10 + k])
        end
      end
    end
    return { cache = cache, values = values }
  end

  local function sk_cleanup(data)
    data.cache = nil
    data.values = nil
  end

  return compare_memory_usage("三键缓存 - 空间占用", ml_setup, ml_cleanup, sk_setup, sk_cleanup)
end

-- 测试 4: 字符串键 vs 数字键 - 空间占用
local function test_string_vs_number_keys_memory()
  -- 数字键测试
  local function ml_num_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local cache = ml_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(i, values[i])
    end
    return { cache = cache, values = values }
  end

  local function ml_num_cleanup(data)
    data.cache = nil
    data.values = nil
  end

  local function sk_num_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local cache = sk_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(i, values[i])
    end
    return { cache = cache, values = values }
  end

  local function sk_num_cleanup(data)
    data.cache = nil
    data.values = nil
  end

  -- 字符串键测试
  local function ml_str_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local keys = {}
    for i = 1, TEST_SIZES.MEDIUM do
      keys[i] = "key" .. i
    end
    local cache = ml_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(keys[i], values[i])
    end
    return { cache = cache, values = values, keys = keys }
  end

  local function ml_str_cleanup(data)
    data.cache = nil
    data.values = nil
    data.keys = nil
  end

  local function sk_str_setup()
    local values = prepare_test_data(TEST_SIZES.MEDIUM)
    local keys = {}
    for i = 1, TEST_SIZES.MEDIUM do
      keys[i] = "key" .. i
    end
    local cache = sk_cache.new("key")
    for i = 1, TEST_SIZES.MEDIUM do
      cache:set(keys[i], values[i])
    end
    return { cache = cache, values = values, keys = keys }
  end

  local function sk_str_cleanup(data)
    data.cache = nil
    data.values = nil
    data.keys = nil
  end

  print("\n===== 数字键空间占用 =====")
  local num_result =
    compare_memory_usage("数字键空间占用", ml_num_setup, ml_num_cleanup, sk_num_setup, sk_num_cleanup)

  print("\n===== 字符串键空间占用 =====")
  local str_result =
    compare_memory_usage("字符串键空间占用", ml_str_setup, ml_str_cleanup, sk_str_setup, sk_str_cleanup)

  print("\n===== 键类型内存占用比较 =====")
  print(
    string.format(
      "MultLevelCache: 字符串键 vs 数字键内存比率: %.2f",
      str_result.ml_memory / num_result.ml_memory
    )
  )
  print(
    string.format(
      "StrKeyCache: 字符串键 vs 数字键内存比率: %.2f",
      str_result.sk_memory / num_result.sk_memory
    )
  )

  return { num = num_result, str = str_result }
end

-- 测试 5: 大量数据空间占用
local function test_large_dataset_memory()
  -- MultLevelCache 测试
  local function ml_setup()
    local values = prepare_test_data(TEST_SIZES.LARGE)
    local cache = ml_cache.new("key")
    for i = 1, TEST_SIZES.LARGE do
      cache:set(i, values[i])
    end
    return { cache = cache, values = values }
  end

  local function ml_cleanup(data)
    data.cache = nil
    data.values = nil
  end

  -- StrKeyCache 测试
  local function sk_setup()
    local values = prepare_test_data(TEST_SIZES.LARGE)
    local cache = sk_cache.new("key")
    for i = 1, TEST_SIZES.LARGE do
      cache:set(i, values[i])
    end
    return { cache = cache, values = values }
  end

  local function sk_cleanup(data)
    data.cache = nil
    data.values = nil
  end

  return compare_memory_usage("大量数据空间占用", ml_setup, ml_cleanup, sk_setup, sk_cleanup)
end

-- 测试 6: 增量式内存增长测试
local function test_incremental_growth()
  local SIZE_STEPS = { 100, 500, 1000, 2000, 5000 }

  print("\n===== 增量式内存增长测试 =====")

  local ml_results = {}
  local sk_results = {}

  for _, size in ipairs(SIZE_STEPS) do
    print("\n--- 数据量: " .. size .. " ---")

    -- MultLevelCache 测试
    local function ml_setup()
      local values = prepare_test_data(size)
      local cache = ml_cache.new("key")
      for i = 1, size do
        cache:set(i, values[i])
      end
      return { cache = cache, values = values }
    end

    local function ml_cleanup(data)
      data.cache = nil
      data.values = nil
    end

    local ml_mem = memory_benchmark("MultLevelCache (" .. size .. " 条目)", ml_setup, ml_cleanup)
    ml_results[size] = ml_mem

    -- StrKeyCache 测试
    local function sk_setup()
      local values = prepare_test_data(size)
      local cache = sk_cache.new("key")
      for i = 1, size do
        cache:set(i, values[i])
      end
      return { cache = cache, values = values }
    end

    local function sk_cleanup(data)
      data.cache = nil
      data.values = nil
    end

    local sk_mem = memory_benchmark("StrKeyCache (" .. size .. " 条目)", sk_setup, sk_cleanup)
    sk_results[size] = sk_mem

    -- 比较
    local ratio = sk_mem / ml_mem
    local more_efficient = ratio > 1 and "MultLevelCache" or "StrKeyCache"
    local percent = math.abs(1 - ratio) * 100

    print(string.format("比较结果: %s 内存使用量少 %.2f%%", more_efficient, percent))
  end

  -- 分析内存增长率
  print("\n内存增长率分析:")
  print("数据量     | MultLevelCache | StrKeyCache")
  print("---------- | -------------- | -----------")

  for i = 2, #SIZE_STEPS do
    local prev_size = SIZE_STEPS[i - 1]
    local curr_size = SIZE_STEPS[i]
    local ml_growth = ml_results[curr_size] / ml_results[prev_size]
    local sk_growth = sk_results[curr_size] / sk_results[prev_size]

    print(string.format("%d -> %d | %.2fx          | %.2fx", prev_size, curr_size, ml_growth, sk_growth))
  end

  return {
    ml_results = ml_results,
    sk_results = sk_results,
  }
end

-- 运行所有内存占用基准测试
local function run_all_memory_benchmarks()
  print("===== 缓存实现空间占用测试 =====")
  print("每个测试都会测量缓存在不同情况下的内存占用情况")
  print("开始测试...\n")

  local results = {}
  results.single_key = test_single_key_memory()
  results.double_key = test_double_key_memory()
  results.triple_key = test_triple_key_memory()
  results.keys_compare = test_string_vs_number_keys_memory()
  results.large_dataset = test_large_dataset_memory()
  results.incremental = test_incremental_growth()

  print("\n===== 测试结果汇总 =====")

  local tests = {
    { name = "单键缓存", result = results.single_key },
    { name = "双键缓存", result = results.double_key },
    { name = "三键缓存", result = results.triple_key },
    { name = "数字键缓存", result = results.keys_compare.num },
    { name = "字符串键缓存", result = results.keys_compare.str },
    { name = "大数据集缓存", result = results.large_dataset },
  }

  -- 汇总结果
  local ml_wins = 0
  local sk_wins = 0

  print("测试项目           | 内存效率更高的实现 | 差异百分比")
  print("------------------ | ----------------- | ----------")

  for _, test in ipairs(tests) do
    local winner = test.result.ratio > 1 and "MultLevelCache" or "StrKeyCache"
    local percent = math.abs(1 - test.result.ratio) * 100

    if winner == "MultLevelCache" then
      ml_wins = ml_wins + 1
    else
      sk_wins = sk_wins + 1
    end

    print(string.format("%-18s | %-17s | %.2f%%", test.name, winner, percent))
  end

  print("\n总体内存效率更高的实现: " .. (ml_wins > sk_wins and "MultLevelCache" or "StrKeyCache"))
  print(string.format("结果: MultLevelCache %d - %d StrKeyCache", ml_wins, sk_wins))

  print("\n测试完成!")
end

-- 运行内存占用基准测试
run_all_memory_benchmarks()
