ProgressBar  = require('progress')


class Bar

    constructor: (@total_size, @fmt) ->
        @line_num = 0 # 提供给外部使用

        @current_size = 0
        @min_chunk_size = @total_size / 100 / 4

        @bar = new ProgressBar(@fmt + " [:bar :percent] [estimated completion" +
                                      "time]=:etas [time elapsed]=:elapsed  ",
                               {
                                   stream      : process.stdout,
                                   total       : @total_size
                               })

    update: (str_size) ->
        # 主要是优化了 @bar.tick 每次都渲染
        @line_num     += 1
        @current_size += str_size

        is_reach_size = @current_size > @min_chunk_size
        is_end        = @total_size - @bar.curr < @min_chunk_size

        if is_reach_size or is_end
            @bar.tick(@current_size)
            @current_size = 0
        if @bar.complete
            console.log("\n")



module.exports = Bar
