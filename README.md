# multiple level cache

> [!warning]
> 这只是用来学习和测试的项目，用在 neovim 插件也许比较合适（毕竟不会出什么大岔子）

由于 Lua 中不支持将对象作为 map 的 key，因此我在思考是否存在一种解法能够实现类似的效果，最初思考时有两种思路

1. 将对象序列化为字符串后作为 map 的 key，比如：

   ```lua
   local key = { a = 1, b = 2 }
   local val = "something~"
   local serialized_key = serialize(key)
   local cache = {}
   cache[serialized_key] = val
   ```

2. 我们将这个 cache 设计为多层的，每一层对应着一个对象的字段，比如：

   ```lua
   local key = { a = 2, b = 1 }
   local val = "something~"
   local cache = {}
   cache[key.a] = {}
   cache[key.a][key.b] = val
   ```

   通过将对象的字段拓展为 cache 的深度，我们可以实现类似的效果。同时他的性能表现的还不错

二者之间的性能差异可以通过 benchmark 看出，后者速度明显更快一些：

```plaintext
===== 单键缓存 - 设置操作 =====
Running benchmark: MultLevelCache (20 iterations)
  Time: 5.805 ms (290235.450 ns per iteration)
Running benchmark: StrKeyCache (20 iterations)
  Time: 6.366 ms (318302.050 ns per iteration)
Comparison: MultLevelCache is 9.67% faster

===== 单键缓存 - 获取操作 =====
Running benchmark: MultLevelCache (20 iterations)
  Time: 4.343 ms (217137.500 ns per iteration)
Running benchmark: StrKeyCache (20 iterations)
  Time: 4.490 ms (224497.950 ns per iteration)
Comparison: MultLevelCache is 3.39% faster

===== 单键缓存 - has操作 =====
Running benchmark: MultLevelCache (20 iterations)
  Time: 4.518 ms (225881.250 ns per iteration)
Running benchmark: StrKeyCache (20 iterations)
  Time: 4.794 ms (239689.600 ns per iteration)
Comparison: MultLevelCache is 6.11% faster

===== 双键缓存 - 设置操作 =====
Running benchmark: MultLevelCache (20 iterations)
  Time: 21.437 ms (1071837.500 ns per iteration)
Running benchmark: StrKeyCache (20 iterations)
  Time: 35.355 ms (1767733.350 ns per iteration)
Comparison: MultLevelCache is 64.93% faster

===== 双键缓存 - 获取操作 =====
Running benchmark: MultLevelCache (20 iterations)
  Time: 12.904 ms (645206.250 ns per iteration)
Running benchmark: StrKeyCache (20 iterations)
  Time: 14.950 ms (747512.500 ns per iteration)
Comparison: MultLevelCache is 15.86% faster

===== 三键缓存 - 设置操作 =====
Running benchmark: MultLevelCache (10 iterations)
  Time: 5.700 ms (570016.700 ns per iteration)
Running benchmark: StrKeyCache (10 iterations)
  Time: 6.411 ms (641070.800 ns per iteration)
Comparison: MultLevelCache is 12.47% faster

===== 三键缓存 - 获取操作 =====
Running benchmark: MultLevelCache (10 iterations)
  Time: 3.449 ms (344920.900 ns per iteration)
Running benchmark: StrKeyCache (10 iterations)
  Time: 4.107 ms (410662.500 ns per iteration)
Comparison: MultLevelCache is 19.06% faster

===== 数字键操作 =====

===== 数字键设置操作 =====
Running benchmark: MultLevelCache (20 iterations)
  Time: 7.497 ms (374856.250 ns per iteration)
Running benchmark: StrKeyCache (20 iterations)
  Time: 8.173 ms (408631.250 ns per iteration)
Comparison: MultLevelCache is 9.01% faster

===== 字符串键操作 =====

===== 字符串键设置操作 =====
Running benchmark: MultLevelCache (20 iterations)
  Time: 7.978 ms (398889.600 ns per iteration)
Running benchmark: StrKeyCache (20 iterations)
  Time: 7.916 ms (395779.150 ns per iteration)
Comparison: StrKeyCache is 0.78% slower

===== 键类型比较 =====
MultLevelCache: 字符串键 vs 数字键比率: 1.06
StrKeyCache: 字符串键 vs 数字键比率: 0.97

===== 部分清除操作 =====
Running benchmark: MultLevelCache (10 iterations)
  Time: 0.041 ms (4050.000 ns per iteration)
Running benchmark: StrKeyCache (10 iterations)
  Time: 1.946 ms (194625.000 ns per iteration)
Comparison: MultLevelCache is 4705.56% faster

===== 测试结果汇总 =====
测试项目           | 获胜者         | 差异百分比
------------------ | ------------- | ----------
单键设置       | MultLevelCache | 9.67%
单键获取       | MultLevelCache | 3.39%
单键检查       | MultLevelCache | 6.11%
双键设置       | MultLevelCache | 64.93%
双键获取       | MultLevelCache | 15.86%
三键设置       | MultLevelCache | 12.47%
三键获取       | MultLevelCache | 19.06%
数字键          | MultLevelCache | 9.01%
字符串键       | StrKeyCache   | 0.78%
部分清除       | MultLevelCache | 4705.56%

总体获胜者: MultLevelCache
结果: MultLevelCache 9 - 1 StrKeyCache
```

内存占用方面也是后者更好一些

```plaintext
===== 单键缓存 - 空间占用 =====
Running memory benchmark: MultLevelCache
  Base memory usage: 398.13 KB
  Memory usage: 451.82 KB (53.70 KB increase)
  Final memory after cleanup: 400.71 KB (2.59 KB difference from base)
Running memory benchmark: StrKeyCache
  Base memory usage: 400.61 KB
  Memory usage: 497.45 KB (96.84 KB increase)
  Final memory after cleanup: 402.98 KB (2.38 KB difference from base)
比较结果: MultLevelCache 内存使用量少 80.36%

===== 双键缓存 - 空间占用 =====
Running memory benchmark: MultLevelCache
  Base memory usage: 403.06 KB
  Memory usage: 589.32 KB (186.25 KB increase)
  Final memory after cleanup: 408.46 KB (5.40 KB difference from base)
Running memory benchmark: StrKeyCache
  Base memory usage: 408.35 KB
  Memory usage: 735.91 KB (327.55 KB increase)
  Final memory after cleanup: 410.22 KB (1.87 KB difference from base)
比较结果: MultLevelCache 内存使用量少 75.86%

===== 三键缓存 - 空间占用 =====
Running memory benchmark: MultLevelCache
  Base memory usage: 410.27 KB
  Memory usage: 479.70 KB (69.44 KB increase)
  Final memory after cleanup: 414.95 KB (4.68 KB difference from base)
Running memory benchmark: StrKeyCache
  Base memory usage: 414.84 KB
  Memory usage: 515.43 KB (100.59 KB increase)
  Final memory after cleanup: 417.01 KB (2.17 KB difference from base)
比较结果: MultLevelCache 内存使用量少 44.86%

===== 数字键空间占用 =====

===== 数字键空间占用 =====
Running memory benchmark: MultLevelCache
  Base memory usage: 417.32 KB
  Memory usage: 469.89 KB (52.57 KB increase)
  Final memory after cleanup: 418.79 KB (1.46 KB difference from base)
Running memory benchmark: StrKeyCache
  Base memory usage: 418.68 KB
  Memory usage: 514.15 KB (95.47 KB increase)
  Final memory after cleanup: 419.68 KB (1.00 KB difference from base)
比较结果: MultLevelCache 内存使用量少 81.60%

===== 字符串键空间占用 =====

===== 字符串键空间占用 =====
Running memory benchmark: MultLevelCache
  Base memory usage: 419.73 KB
  Memory usage: 528.74 KB (109.01 KB increase)
  Final memory after cleanup: 422.42 KB (2.69 KB difference from base)
Running memory benchmark: StrKeyCache
  Base memory usage: 422.26 KB
  Memory usage: 534.06 KB (111.80 KB increase)
  Final memory after cleanup: 427.69 KB (5.43 KB difference from base)
比较结果: MultLevelCache 内存使用量少 2.55%

===== 键类型内存占用比较 =====
MultLevelCache: 字符串键 vs 数字键内存比率: 2.07
StrKeyCache: 字符串键 vs 数字键内存比率: 1.17

===== 大量数据空间占用 =====
Running memory benchmark: MultLevelCache
  Base memory usage: 427.59 KB
  Memory usage: 766.86 KB (339.27 KB increase)
  Final memory after cleanup: 431.13 KB (3.54 KB difference from base)
Running memory benchmark: StrKeyCache
  Base memory usage: 431.02 KB
  Memory usage: 1112.12 KB (681.09 KB increase)
  Final memory after cleanup: 432.03 KB (1.00 KB difference from base)
比较结果: MultLevelCache 内存使用量少 100.75%

===== 增量式内存增长测试 =====

--- 数据量: 100 ---
Running memory benchmark: MultLevelCache (100 条目)
  Base memory usage: 432.42 KB
  Memory usage: 438.89 KB (6.47 KB increase)
  Final memory after cleanup: 433.43 KB (1.00 KB difference from base)
Running memory benchmark: StrKeyCache (100 条目)
  Base memory usage: 433.46 KB
  Memory usage: 444.68 KB (11.21 KB increase)
  Final memory after cleanup: 434.47 KB (1.00 KB difference from base)
比较结果: MultLevelCache 内存使用量少 73.37%

--- 数据量: 500 ---
Running memory benchmark: MultLevelCache (500 条目)
  Base memory usage: 434.30 KB
  Memory usage: 460.78 KB (26.48 KB increase)
  Final memory after cleanup: 435.59 KB (1.28 KB difference from base)
Running memory benchmark: StrKeyCache (500 条目)
  Base memory usage: 435.58 KB
  Memory usage: 482.90 KB (47.32 KB increase)
  Final memory after cleanup: 435.69 KB (0.11 KB difference from base)
比较结果: MultLevelCache 内存使用量少 78.73%

--- 数据量: 1000 ---
Running memory benchmark: MultLevelCache (1000 条目)
  Base memory usage: 435.48 KB
  Memory usage: 486.70 KB (51.21 KB increase)
  Final memory after cleanup: 435.59 KB (0.11 KB difference from base)
Running memory benchmark: StrKeyCache (1000 条目)
  Base memory usage: 435.63 KB
  Memory usage: 530.20 KB (94.57 KB increase)
  Final memory after cleanup: 435.73 KB (0.11 KB difference from base)
比较结果: MultLevelCache 内存使用量少 84.66%

--- 数据量: 2000 ---
Running memory benchmark: MultLevelCache (2000 条目)
  Base memory usage: 435.57 KB
  Memory usage: 537.95 KB (102.37 KB increase)
  Final memory after cleanup: 435.68 KB (0.11 KB difference from base)
Running memory benchmark: StrKeyCache (2000 条目)
  Base memory usage: 435.67 KB
  Memory usage: 660.65 KB (224.98 KB increase)
  Final memory after cleanup: 435.78 KB (0.11 KB difference from base)
比较结果: MultLevelCache 内存使用量少 119.77%

--- 数据量: 5000 ---
Running memory benchmark: MultLevelCache (5000 条目)
  Base memory usage: 435.57 KB
  Memory usage: 772.75 KB (337.17 KB increase)
  Final memory after cleanup: 437.02 KB (1.44 KB difference from base)
Running memory benchmark: StrKeyCache (5000 条目)
  Base memory usage: 437.10 KB
  Memory usage: 1117.30 KB (680.20 KB increase)
  Final memory after cleanup: 437.21 KB (0.11 KB difference from base)
比较结果: MultLevelCache 内存使用量少 101.74%

内存增长率分析:
数据量     | MultLevelCache | StrKeyCache
---------- | -------------- | -----------
100 -> 500 | 4.09x          | 4.22x
500 -> 1000 | 1.93x          | 2.00x
1000 -> 2000 | 2.00x          | 2.38x
2000 -> 5000 | 3.29x          | 3.02x

===== 测试结果汇总 =====
测试项目           | 内存效率更高的实现 | 差异百分比
------------------ | ----------------- | ----------
单键缓存       | MultLevelCache    | 80.36%
双键缓存       | MultLevelCache    | 75.86%
三键缓存       | MultLevelCache    | 44.86%
数字键缓存    | MultLevelCache    | 81.60%
字符串键缓存 | MultLevelCache    | 2.55%
大数据集缓存 | MultLevelCache    | 100.75%

总体内存效率更高的实现: MultLevelCache
结果: MultLevelCache 6 - 0 StrKeyCache
```
