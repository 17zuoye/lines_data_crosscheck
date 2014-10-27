_            = require 'underscore'
lineReader   = require 'line-reader'
Set          = require 'set'
assert       = require 'assert'
async        = require 'async'
Table        = require 'cli-table'
Bar          = require './bar'
require 'coffee-errors'


class LinesDataCrosscheck

    constructor: (@fileA, @fileB,
                  @compare_items_count,
                  opts) ->
        assert.ok(new String(@fileA) instanceof String)
        assert.ok(new String(@fileB) instanceof String)
        opts ?= {}

        # 解析得到该行的 item_id
        @fetch_item_id_func       = opts.fetch_item_id_func      ?= (line1) -> line1

        # diff两行数据
        @diff_items_func          = opts.diff_items_func         ?= (a, b) -> true

        # 数据 反序列化+规整化
        @data_normalization_func  = opts.data_normalization_func ?= (line1) -> line1

        # 过滤一些元素
        @filter_func              = opts.filter_func             ?= (line1) -> false

        # 获取和打印文件信息
        fs          = require "fs"
        @fileA_size = fs.statSync(@fileA)["size"]
        @fileB_size = fs.statSync(@fileB)["size"]
        @print_two_files_info()

    class ItemIdContent
        constructor: (@id, @content, @line_num) ->

    convert_from_line: (line1, line_num) ->
        item1 = @data_normalization_func(line1)
        new ItemIdContent(@fetch_item_id_func(item1), item1, line_num)


    run: (run_callback) ->
        curr = this
        curr.start_time = new Date()

        async.waterfall([
            (callback) ->
                # 1. 遍历 文件A, 取得随机测试样本, 顺便取得对应统计数据
                curr.reservoir_sampling curr.fileA, (fileA_sample) ->
                                                        callback(null, fileA_sample)
            ,
            (fileA_sample, callback) ->
                # 2. 遍历 文件B, 各自取得 文件A统计样本 对应的 统计数据
                curr.fetch_sample_by_item_ids curr.fileB,
                                              new Set(_.keys(fileA_sample)),
                                              (fileB_sample) ->
                                                  callback(null, fileA_sample, fileB_sample)
            ,
            (fileA_sample, fileB_sample, callback) ->
                # 3. 比较两个样本是否一一对应
                assert.ok(_.isEqual(new Set(_.keys(fileA_sample)), new Set(_.keys(fileB_sample))))
                callback(null, fileA_sample, fileB_sample)
            ,
            (fileA_sample, fileB_sample, callback) ->
                # 4. 全部一一对比
                item_ids = _.keys(fileA_sample)
                [curr.same_count, total_count] = [0, item_ids.length]
                _.each item_ids, (item_id) ->
                    [itemA, itemB] = [fileA_sample[item_id], fileB_sample[item_id]]

                    if itemA is undefined
                        console.log("item A is not found")
                    if itemB is undefined
                        console.log("item B is not found")

                    console.log("\n[line num] FIRST:" + itemA.line_num + " SECOND:" + itemB.line_num)

                    try # Compact with user defined functions have exceptions
                        if _.isEqual(itemA.content, itemB.content)
                            curr.same_count += 1
                        else
                            curr.diff_items_func(itemA.content, itemB.content)
                    catch err
                        console.log(err, "\n")
                        console.log("two items are: ", [itemA, itemB])

                callback(null, curr.same_count is total_count)
            ,
            (is_all_same, callback) ->
                run_callback(is_all_same)
                curr.print_process_summary()
            ,
        ], (err, result) ->
            console.log(err, result)
        ,)

    reservoir_sampling: (file1, run_callback) ->
        # 参考文章。感谢 @晓光 提示。
        # http://en.wikipedia.org/wiki/Reservoir_sampling

        # Cloudera 也有介绍文章和对应实现。
        # http://blog.cloudera.com/blog/2013/04/hadoop-stratified-randosampling-algorithm/
        #
        # https://github.com/cloudera/oryx/blob/7d9b3e2e7331b54c7744fd06038ae40c202e56e4/
        # computation-common/src/main/java/com/cloudera/oryx/computation/common/sample/ReservoirSampling.java

        # 以下优化目的只是为了省 一遍取文件行数 的IO。

        randomInt = require('random-tools').randomInt

        [sample_array, curr] = [[], this]

        # Reference from wikipedia
        bar = new Bar(@fileA_size, 'reservoir_sampling')
        lineReader.eachLine file1, (line1, is_end) =>
            bar.update(line1.length+1) # plus "\n"

            # 选择有些元素不进入结果，应该只是均等地给其他通过的元素增加了一些概率。
            if curr.filter_func(line1)
                return

            is_insert = true

            # 1. 把前 @compare_items_count 个 items 放到候选里。
            if bar.line_num <= curr.compare_items_count
                insert_at_idx = bar.line_num
            # 2. 在 当前遍历过的行数里 进行随机, 看看用当前行 是否去替换其中一个。
            #    但是得保证在整个遍历过程中 每行 都机会均等。
            else
                # n/k 概率选进来。   随机踢，随机选。
                random_idx = randomInt(bar.line_num, 1)
                if random_idx < curr.compare_items_count
                    insert_at_idx = random_idx
                else
                    is_insert = false

                # 分两步来理解 [keep, remove]
                # 1. 先是 remove ，为了保障对每一个元素都是公平的，所以在任何一步停下，他们的概率都是均等的。
                # 2. 后是 keep, 不管时间的发生顺序，抽签的最后一个就不用抽了。而这里是每个元素都有一定的概率。

                # 直观验证测试方法 就是看看最后两个文件选出来的行数在统计上是否分布均匀。

            if is_insert
                sample_array[insert_at_idx] = curr.convert_from_line(line1, bar.line_num)

            if is_end
                # 3. 这样可以在未知具体行数的情况下, 就实现了 平稳的 随机取固定个数的测试数据。
                fileA_sample = sample_array.reduce (dict, obj) ->
                                                        dict[obj.id] = obj
                                                        dict
                                                    , {}
                curr.fileA_items_count = bar.line_num
                run_callback(fileA_sample)


    fetch_sample_by_item_ids: (file1, item_ids, run_callback) ->
        [sample_dict, curr] = [{}, this]

        bar = new Bar(@fileA_size, 'fetch_sample_by_item_ids')
        lineReader.eachLine file1, (line1, is_end) =>
            bar.update(line1.length+1) # plus "\n"

            item_id1 = curr.fetch_item_id_func(line1)
            if item_ids.contains(item_id1)
                item1 = curr.convert_from_line(line1, bar.line_num)
                sample_dict[item1.id] = item1
            if is_end
                run_callback(sample_dict)
                curr.fileB_items_count = bar.line_num


    print_two_files_info :  ->
        filesize = require "filesize"

        table    = new Table({
                      head : ["Filepath", "Filesize"]
                    })
        table.push([@fileA, filesize(@fileA_size)],
                   [@fileB, filesize(@fileB_size)])

        console.log("\n", Array(10).join("#"), "Begin LinesDataCrosscheck ...", Array(10).join("#"))
        console.log(table.toString(), "\n")

    print_process_summary : ->
        HumanizeTime = require('humanize-time')
        [table, curr] = [new Table(), this]
        table.push(["time spent", HumanizeTime(new Date() - curr.start_time)])
        table.push([curr.fileA + " items count", curr.fileA_items_count])
        table.push([curr.fileB + " items count", curr.fileB_items_count])
        table.push(["sample count", curr.compare_items_count])
        table.push(["diff   count", curr.compare_items_count - curr.same_count])
        table.push(["same   count", curr.same_count])
        console.log(table.toString(), "\n")

module.exports = LinesDataCrosscheck
