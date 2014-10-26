_            = require 'underscore'
lineReader   = require 'line-reader'
Set          = require 'set'
assert       = require 'assert'
async        = require 'async'
ProgressBar  = require('progress')

# TODO sync output result to disk

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

        async.waterfall([
            (callback) ->
                # 1. 遍历 文件A, 取得随机测试样本, 顺便取得对应统计数据
                curr.reservoir_sampling curr.fileA, (sample_array) ->
                    fileA_sample = sample_array.reduce (dict, obj) ->
                                                            dict[obj.id] = obj.content
                                                            dict
                                                        , {}
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
                [same_count, total_count] = [0, item_ids.length]
                _.each item_ids, (item_id) ->
                    [itemA, itemB] = [fileA_sample[item_id], fileB_sample[item_id]]
                    if _.isEqual(itemA, itemB)
                        same_count += 1
                    else
                        curr.diff_items_func(itemA, itemB)
                callback(null, same_count is total_count)
            ,
            (is_all_same, callback) ->
                run_callback(is_all_same)
            ,
        ], (err, result) ->
            console.log(err, result)
        ,)


    reservoir_sampling: (file1, run_callback) ->
        # 参考文章。感谢 @晓光 提示。
        # http://en.wikipedia.org/wiki/Reservoir_sampling

        # Cloudera 也有介绍文章和对应实现。
        # http://blog.cloudera.com/blog/2013/04/hadoop-stratified-randosampling-algorithm/
        # https://github.com/cloudera/oryx/blob/7d9b3e2e7331b54c7744fd06038ae40c202e56e4/computation-common/src/main/java/com/cloudera/oryx/computation/common/sample/ReservoirSampling.java

        # 以下优化目的只是为了省 一遍取文件行数 的IO。

        randomInt = require('random-tools').randomInt

        [line_idx, sample_array, curr] = [1, [], this]

        # Reference from wikipedia
        bar = new Bar(@fileA_size, 'reservoir_sampling')
        lineReader.eachLine file1, (line1, is_end) =>
            bar.update(line1.length+1) # plus "\n"

            is_insert = true

            # 1. 把前 @compare_items_count 个 items 放到候选里。
            if line_idx <= curr.compare_items_count
                insert_at_idx = line_idx
            # 2. 在 当前遍历过的行数里 进行随机, 看看用当前行 是否去替换其中一个。
            #    但是得保证在整个遍历过程中 每行 都机会均等。
            else
                # n/k 概率选进来。   随机踢，随机选。
                random_idx = randomInt(line_idx, 1)
                if random_idx < curr.compare_items_count
                    insert_at_idx = random_idx
                else
                    is_insert = false

            if is_insert
                sample_array[insert_at_idx] = curr.convert_from_line(line1, bar.line_num)

            line_idx += 1

            if is_end
                # 3. 这样可以在未知具体行数的情况下, 就实现了 平稳的 随机取固定个数的测试数据。
                run_callback(sample_array)


    fetch_sample_by_item_ids: (file1, item_ids, run_callback) ->
        [sample_dict, curr] = [{}, this]

        bar = new Bar(@fileA_size, 'fetch_sample_by_item_ids')
        lineReader.eachLine file1, (line1, is_end) =>
            bar.update(line1.length+1) # plus "\n"

            item_id1 = curr.fetch_item_id_func(line1)
            if item_ids.contains(item_id1)
                item1 = curr.convert_from_line(line1, bar.line_num)
                sample_dict[item1.id] = item1.content
            if is_end
                run_callback(sample_dict)


    print_two_files_info :  ->
        filesize = require "filesize"

        table    = new (require('cli-table'))({
                      head : ["Filepath", "Filesize"]
                    })
        table.push([@fileA, filesize(@fileA_size)],
                   [@fileB, filesize(@fileB_size)])

        console.log("\n", Array(10).join("#"), "Begin LinesDataCrosscheck ...", Array(10).join("#"))
        console.log(table.toString(), "\n")

    class Bar
        constructor: (@total_size, @fmt) ->
            @line_num = 0 # 提供给外部使用

            @current_size = 0
            @min_chunk_size = @total_size / 100 / 4

            @bar = new ProgressBar(@fmt + " [:bar :percent] [estimated completion time]=:etas [time elapsed]=:elapsed  ", {
                        stream      : process.stdout,
                        total       : @total_size
                    })

        update: (str_size) ->
            # 优化 @bar.tick 每次都渲染
            @line_num     += 1
            @current_size += str_size

            is_reach_size = @current_size > @min_chunk_size
            is_end        = @total_size - @bar.curr < @min_chunk_size

            if is_reach_size or is_end
                @bar.tick(@current_size)
                @current_size = 0
            if @bar.complete
                console.log("\n")


module.exports = LinesDataCrosscheck
