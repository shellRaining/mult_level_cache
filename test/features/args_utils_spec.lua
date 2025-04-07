local assert = require("luassert")
local ArgsModule = require("mult_level_cache.args") -- 请替换为实际路径

describe("ArgsModule", function()
  describe("get_args_count", function()
    it("returns 0 for empty args", function()
      assert.equal(0, ArgsModule.get_args_count())
    end)

    it("returns correct count for single arg", function()
      assert.equal(1, ArgsModule.get_args_count(1))
      assert.equal(1, ArgsModule.get_args_count("string"))
      assert.equal(1, ArgsModule.get_args_count(nil))
    end)

    it("returns correct count for multiple args", function()
      assert.equal(3, ArgsModule.get_args_count(1, "string", true))
      assert.equal(3, ArgsModule.get_args_count(1, nil, 3))
      assert.equal(5, ArgsModule.get_args_count(1, 2, 3, 4, 5))
    end)
  end)

  describe("get_last_arg", function()
    it("returns nil for empty args", function()
      assert.equal(nil, ArgsModule.get_last_arg())
    end)

    it("returns the arg for single arg", function()
      assert.equal(1, ArgsModule.get_last_arg(1))
      assert.equal("string", ArgsModule.get_last_arg("string"))
      assert.equal(nil, ArgsModule.get_last_arg(nil))
    end)

    it("returns the last arg for multiple args", function()
      assert.equal(3, ArgsModule.get_last_arg(1, 2, 3))
      assert.equal("c", ArgsModule.get_last_arg("a", "b", "c"))
      assert.equal(nil, ArgsModule.get_last_arg(1, 2, nil))
    end)

    it("works with complex data types", function()
      local tbl = { key = "value" }
      local func = function()
        return true
      end

      assert.equal(tbl, ArgsModule.get_last_arg(1, tbl))
      assert.equal(func, ArgsModule.get_last_arg("string", func))
    end)
  end)

  describe("is_args_contain_nil", function()
    it("returns false for empty args", function()
      assert.is_false(ArgsModule.is_args_contain_nil())
    end)

    it("returns true if arg is nil", function()
      assert.is_true(ArgsModule.is_args_contain_nil(nil))
      assert.is_true(ArgsModule.is_args_contain_nil(nil, 1))
      assert.is_true(ArgsModule.is_args_contain_nil(1, nil))
    end)

    it("returns false if no args are nil", function()
      assert.is_false(ArgsModule.is_args_contain_nil(1))
      assert.is_false(ArgsModule.is_args_contain_nil(1, "string", true))
      assert.is_false(ArgsModule.is_args_contain_nil(0, false, ""))
    end)

    it("detects nil in various positions", function()
      assert.is_true(ArgsModule.is_args_contain_nil(nil, 2, 3))
      assert.is_true(ArgsModule.is_args_contain_nil(1, nil, 3))
      assert.is_true(ArgsModule.is_args_contain_nil(1, 2, nil))
      assert.is_true(ArgsModule.is_args_contain_nil(1, nil, nil, 4))
    end)
  end)

  describe("args_to_table", function()
    it("returns empty table for empty args", function()
      local result = ArgsModule.args_to_table()
      assert.equal(0, #result)
    end)

    it("returns table with single element for single arg", function()
      local result = ArgsModule.args_to_table(1)
      assert.equal(1, #result)
      assert.equal(1, result[1])

      local result2 = ArgsModule.args_to_table(nil)
      assert.equal(nil, result2[1])
    end)

    it("returns table with all args for multiple args", function()
      local result = ArgsModule.args_to_table(1, "string", true)
      assert.equal(3, #result)
      assert.equal(1, result[1])
      assert.equal("string", result[2])
      assert.equal(true, result[3])
    end)

    it("preserves nil values in the table", function()
      local result = ArgsModule.args_to_table(1, nil, 3)
      assert.equal(1, result[1])
      assert.equal(nil, result[2])
      assert.equal(3, result[3])
    end)

    it("works with complex data types", function()
      local tbl = { key = "value" }
      local result = ArgsModule.args_to_table(1, tbl, "string")
      assert.equal(3, #result)
      assert.equal(1, result[1])
      assert.equal(tbl, result[2])
      assert.equal("string", result[3])
    end)
  end)
end)
