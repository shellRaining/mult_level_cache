local assert = require("luassert")
local ml_cache = require("mult_level_cache/ml_cache")
local sk_cache = require("mult_level_cache/sk_cache")

-- 测试辅助函数
local function test_both_caches(describe_name, tests)
  describe(describe_name, function()
    describe("MultLevelCache", function()
      for name, test_fn in pairs(tests) do
        it(name, function()
          test_fn(ml_cache)
        end)
      end
    end)

    describe("StrKeyCache", function()
      for name, test_fn in pairs(tests) do
        it(name, function()
          test_fn(sk_cache)
        end)
      end
    end)
  end)
end

-- 开始测试
test_both_caches("基本缓存功能", {
  ["单键缓存操作"] = function(Cache)
    local cache = Cache.new("bufnr")
    assert.equal(nil, cache:get(1))
    cache:set(0, "a")
    cache:set(1, "b")
    assert.equal("a", cache:get(0))
    assert.equal("b", cache:get(1))
    cache:set(0, "c")
    assert.equal("c", cache:get(0))
    assert.is_true(cache:has(0))
    assert.is_false(cache:has(2))
    cache:clear()
    assert.equal(nil, cache:get(0))
  end,

  ["双键缓存操作"] = function(Cache)
    local cache = Cache.new("bufnr", "line")
    assert.equal(nil, cache:get(1, 1))
    cache:set(0, 0, "a")
    cache:set(0, 1, "b")
    cache:set(1, 0, "c")
    cache:set(1, 1, "d")
    assert.equal("a", cache:get(0, 0))
    assert.equal("b", cache:get(0, 1))
    assert.equal("c", cache:get(1, 0))
    assert.equal("d", cache:get(1, 1))
    cache:set(0, 0, "e")
    assert.equal("e", cache:get(0, 0))
    assert.is_true(cache:has(0, 0))
    assert.is_false(cache:has(2, 2))
    cache:clear(0)
    assert.equal(nil, cache:get(0, 0))
    assert.equal("c", cache:get(1, 0))
    cache:clear()
    assert.equal(nil, cache:get(0, 0))
    assert.equal(nil, cache:get(1, 0))
  end,

  ["三键缓存操作"] = function(Cache)
    local cache = Cache.new("bufnr", "line", "col")
    assert.equal(nil, cache:get(1, 1, 1))
    cache:set(0, 0, 0, "a")
    cache:set(0, 0, 1, "b")
    cache:set(0, 1, 0, "c")
    cache:set(0, 1, 1, "d")
    cache:set(1, 0, 0, "e")
    cache:set(1, 0, 1, "f")
    cache:set(1, 1, 0, "g")
    cache:set(1, 1, 1, "h")
    assert.equal("a", cache:get(0, 0, 0))
    assert.equal("b", cache:get(0, 0, 1))
    assert.equal("c", cache:get(0, 1, 0))
    assert.equal("d", cache:get(0, 1, 1))
    assert.equal("e", cache:get(1, 0, 0))
    assert.equal("f", cache:get(1, 0, 1))
    assert.equal("g", cache:get(1, 1, 0))
    assert.equal("h", cache:get(1, 1, 1))
    cache:set(0, 0, 0, "i")
    assert.equal("i", cache:get(0, 0, 0))
    assert.is_true(cache:has(0, 0, 0))
    assert.is_false(cache:has(2, 2, 2))
    cache:clear(0, 0)
    assert.equal(nil, cache:get(0, 0, 0))
    assert.equal("c", cache:get(0, 1, 0))
    cache:clear()
    assert.equal(nil, cache:get(0, 0, 0))
    assert.equal(nil, cache:get(1, 0, 0))
  end,

  ["缓存项删除"] = function(Cache)
    local cache = Cache.new("bufnr", "line", "col")
    cache:set(0, 0, 0, "a")
    cache:set(0, 0, 1, "b")
    cache:set(0, 1, 0, "c")

    cache:remove(0, 0, 0)
    assert.equal(nil, cache:get(0, 0, 0))
    assert.equal("b", cache:get(0, 0, 1))
    assert.equal("c", cache:get(0, 1, 0))
  end,
})

-- 额外的更全面的测试
test_both_caches("高级缓存功能", {
  ["非字符串键值测试"] = function(Cache)
    local cache = Cache.new("key1", "key2")

    -- 测试数字键
    cache:set(1, 2, "数字键")
    assert.equal("数字键", cache:get(1, 2))

    -- 测试布尔键
    cache:set(true, false, "布尔键")
    assert.equal("布尔键", cache:get(true, false))

    -- 测试混合键
    cache:set("字符串", 123, "混合键")
    assert.equal("混合键", cache:get("字符串", 123))

    -- 测试特殊字符
    cache:set("a:b", "c:d", "特殊字符")
    assert.equal("特殊字符", cache:get("a:b", "c:d"))

    -- 测试nil键值
    assert.has_error(function()
      cache:set(nil, "value", "不应该工作")
    end)
    assert.has_error(function()
      cache:set("key", nil, "不应该工作")
    end)
    assert.has_error(function()
      cache:get(nil, "key")
    end)
    assert.has_error(function()
      cache:get("key", nil)
    end)
    assert.has_error(function()
      cache:has(nil, "key")
    end)
    assert.has_error(function()
      cache:has("key", nil)
    end)
    assert.has_error(function()
      cache:remove(nil, "key")
    end)
    assert.has_error(function()
      cache:remove("key", nil)
    end)
  end,

  ["部分清除测试"] = function(Cache)
    local cache = Cache.new("level1", "level2", "level3")

    -- 设置一些值
    cache:set("a", "x", "1", "值1")
    cache:set("a", "x", "2", "值2")
    cache:set("a", "y", "1", "值3")
    cache:set("b", "x", "1", "值4")

    -- 清除部分缓存
    cache:clear("a", "x")

    -- 验证结果
    assert.equal(nil, cache:get("a", "x", "1"))
    assert.equal(nil, cache:get("a", "x", "2"))
    assert.equal("值3", cache:get("a", "y", "1"))
    assert.equal("值4", cache:get("b", "x", "1"))
  end,

  ["错误参数处理"] = function(Cache)
    local cache = Cache.new("key1", "key2")

    -- 测试get参数过少
    assert.has_error(function()
      cache:get("only_one")
    end)

    -- 测试get参数过多
    assert.has_error(function()
      cache:get("one", "two", "three")
    end)

    -- 测试set参数过少
    assert.has_error(function()
      cache:set("only_one")
    end)

    -- 测试set参数过多
    assert.has_error(function()
      cache:set("one", "two", "value", "extra")
    end)

    -- 测试has参数错误
    assert.has_error(function()
      cache:has("only_one")
    end)
    assert.has_error(function()
      cache:has("one", "two", "three")
    end)

    -- 测试remove参数错误
    assert.has_error(function()
      cache:remove("only_one")
    end)
    assert.has_error(function()
      cache:remove("one", "two", "three")
    end)
  end,

  ["不同数据类型存储"] = function(Cache)
    local cache = Cache.new("key")

    -- 存储字符串
    cache:set("str_key", "字符串值")
    assert.equal("字符串值", cache:get("str_key"))

    -- 存储数字
    cache:set("num_key", 12345)
    assert.equal(12345, cache:get("num_key"))

    -- 存储布尔值
    cache:set("bool_key", true)
    assert.equal(true, cache:get("bool_key"))

    -- 存储表
    local table_value = { name = "缓存表", data = { 1, 2, 3 } }
    cache:set("table_key", table_value)
    assert.same(table_value, cache:get("table_key"))

    -- 存储函数
    local function test_func()
      return "函数返回值"
    end
    cache:set("func_key", test_func)
    assert.equal("函数返回值", cache:get("func_key")())

    -- 存储nil (应该会删除该键)
    cache:set("nil_key", nil)
    assert.is_false(cache:has("nil_key"))
  end,

  ["大量键值测试"] = function(Cache)
    local cache = Cache.new("id")

    -- 插入1000个键值对
    for i = 1, 1000 do
      cache:set(i, "值" .. i)
    end

    -- 验证随机10个键值对
    for _ = 1, 10 do
      local random_key = math.random(1, 1000)
      assert.equal("值" .. random_key, cache:get(random_key))
    end

    -- 移除一半的键
    for i = 1, 500 do
      cache:remove(i)
    end

    -- 验证结果
    for i = 1, 500 do
      assert.is_false(cache:has(i))
    end
    for i = 501, 1000 do
      assert.is_true(cache:has(i))
    end
  end,

  ["多级partial clear测试"] = function(Cache)
    local cache = Cache.new("region", "city", "district", "street")

    -- 设置一些值
    cache:set("北京", "朝阳", "三里屯", "工体北路", "地址1")
    cache:set("北京", "朝阳", "三里屯", "工体南路", "地址2")
    cache:set("北京", "朝阳", "望京", "阜通东大街", "地址3")
    cache:set("北京", "海淀", "中关村", "海淀大街", "地址4")
    cache:set("上海", "浦东", "陆家嘴", "世纪大道", "地址5")

    -- 清除特定区域内的所有地址
    cache:clear("北京", "朝阳", "三里屯")

    -- 验证结果
    assert.equal(nil, cache:get("北京", "朝阳", "三里屯", "工体北路"))
    assert.equal(nil, cache:get("北京", "朝阳", "三里屯", "工体南路"))
    assert.equal("地址3", cache:get("北京", "朝阳", "望京", "阜通东大街"))
    assert.equal("地址4", cache:get("北京", "海淀", "中关村", "海淀大街"))
    assert.equal("地址5", cache:get("上海", "浦东", "陆家嘴", "世纪大道"))

    -- 清除更高一级的区域
    cache:clear("北京")

    -- 验证结果
    assert.equal(nil, cache:get("北京", "朝阳", "望京", "阜通东大街"))
    assert.equal(nil, cache:get("北京", "海淀", "中关村", "海淀大街"))
    assert.equal("地址5", cache:get("上海", "浦东", "陆家嘴", "世纪大道"))
  end,
})
