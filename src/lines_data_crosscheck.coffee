_            = require 'underscore'
lineReader   = require 'line-reader'
Set          = require 'set'
assert       = require 'assert'
jsondiff     = require 'json-diff/lib/cli'


class LinesDataCrosscheck

    constructor: (@fileA, @fileB,
                  @compare_items_count,
                  unserializable_func,
                  fetch_item_id_func,
                  data_normalization_func,) ->

        # 反序列化 单行数据 到 一个对象
        @unserializable_func     = unserializable_func     || (line1) -> line1

        # 解析得到该行的 item_id
        @fetch_item_id_func      = fetch_item_id_func      || (line1) -> line1

        # 数据规整化
        @data_normalization_func = data_normalization_func || (obj1) -> obj1


    class ItemIdContent
        constructor: (@id, @content) ->

    convert_from_line: (line1) ->
        item1 = @data_normalization_func(line1)
        ItemIdContent(@fetch_item_id_func(item1), item1)


    run: ->
        # 1. 遍历 文件A, 取得随机测试样本, 顺便取得对应统计数据
        fileA_sample = reservoir_sampling(@fileA).reduce (dict, obj) ->
                            dict[obj.id] = obj.content
                            dict
                        , {}

        # 2. 遍历 文件B, 各自取得 文件A统计样本 对应的 统计数据
        fileB_sample = fetch_sample_by_item_ids @fileB, new Set(fileA_sample.keys())

        # 3. 比较两个样本是否一一对应
        assert.equal(new Set(fileA_sample.keys()), new Set(fileB_sample.keys()))

        # 4. 全部一一对比
        [same_count, total_count] = [0, fileA_sample.length]
        _.each fileA_sample.keys(), (item_id) ->
            [itemA, itemB] = [fileA_sample[item_id], fileB_sample[item_id]]
            result = _.isEqual(itemA, itemB)
            if result
                same_count += 1
            else
                jsondiff(itemA, itemB)


    reservoir_sampling: (file1) ->
        # 参考文章。感谢 @晓光 提示。
        # http://en.wikipedia.org/wiki/Reservoir_sampling

        # Cloudera 也有介绍文章和对应实现。
        # http://blog.cloudera.com/blog/2013/04/hadoop-stratified-randosampling-algorithm/
        # https://github.com/cloudera/oryx/blob/7d9b3e2e7331b54c7744fd06038ae40c202e56e4/computation-common/src/main/java/com/cloudera/oryx/computation/common/sample/ReservoirSampling.java

        # 以下优化目的只是为了省 一遍取文件行数 的IO。

        randomInt = require('random-tools').randomInt

        [line_idx, sample_array] = [0, []]

        # Reference from wikipedia
        lineReader.eachLine file1, (line1) =>
            is_insert = true

            # 1. 把前 @compare_items_count 个 items 放到候选里。
            if line_idx < @compare_items_count
                insert_at_idx = line_idx
            # 2. 在 当前遍历过的行数里 进行随机, 看看用当前行 是否去替换其中一个。
            #    但是得保证在整个遍历过程中 每行 都机会均等。
            else
                # n/k 概率选进来。   随机踢，随机选。
                random_idx = randomInt(0, line_idx)
                if random_idx < @compare_items_count
                    insert_at_idx = random_idx
                else
                    is_insert = false

            if is_insert
                sample_array[insert_at_idx] = @convert_from_line(line1)
            line_idx += 1

        # 3. 这样可以在未知具体行数的情况下, 就实现了 平稳的 随机取固定个数的测试数据。
        sample_array


    fetch_sample_by_item_ids: (file1, item_ids) ->
        sample_dict = {}

        lineReader.eachLine file1, (line1) =>
            item_id1 = @fetch_item_id_func(line1)
            if item_ids.contains(item_id1)
                item1 = @convert_from_line(line1)
                sample_dict[item1.id] = item.content

        return sample_dict


module.exports = LinesDataCrosscheck
