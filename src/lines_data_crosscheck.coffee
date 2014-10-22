_ = require('underscore')


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

        _.isEqual


    run: ->


    reservoir_sampling: ->
        # 参考文章。感谢 @晓光 提示他之前拿类似问题面试过别人。
        # http://en.wikipedia.org/wiki/Reservoir_sampling

        # Cloudera 也有介绍文章和对应实现。
        # http://blog.cloudera.com/blog/2013/04/hadoop-stratified-randosampling-algorithm/
        # https://github.com/cloudera/oryx/blob/7d9b3e2e7331b54c7744fd06038ae40c202e56e4/computation-common/src/main/java/com/cloudera/oryx/computation/common/sample/ReservoirSampling.java

        # 以下优化目的只是为了省 一遍取文件行数 的IO。

        randomInt = require('random-tools').randomInt

        # Reference from wikipedia
        sample_array = []
        for idx1, line1 in file(@fileA) do:
            # 1. 把 @compare_items_count 个 items 放到候选里。
            if idx1 < @compare_items_count:
                sample_array.append(line1)
            # 2. 在 当前遍历过的行数里 进行随机, 看看用当前行 是否去替换其中一个。
            #    但是得保证在整个遍历过程中 每行 都机会均等。
            else:
                # n/k 概率选进来。   随机踢，随机选。
                random_idx = randomInt(0, idx1)
                if random_idx < @compare_items_count:
                    sample_array[random_idx] = line1
            # 3. 这样可以在未知具体行数的情况下, 就实现了 平稳的 随机取固定个数的测试数据。

        return sample_array

