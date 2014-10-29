SampleDiff = require '../src/sample_diff'

path         = require 'path'
difflet      = require('difflet')
_            = require 'underscore'
fs           = require 'fs'

fetch_item_id_func = (line1) ->
    #_.each(Array(8), -> Array(Math.pow(10, 7)).join("=").length) # mimic slow cpu
                JSON.parse(line1)['id']

opts = {
            "fetch_item_id_func" : (line1) -> fetch_item_id_func(line1),
            "diff_items_func"    :
                                   (a, b)  ->
                                       a = JSON.parse(a)
                                       b = JSON.parse(b)
                                       console.log(difflet.compare(a, b), "\n")
                                       _.isEqual(a, b)
            ,
        }

exports.SampleDiffTest =

    "same test": (test) ->
        fileA = "#{path.join(__dirname, 'fileA.txt')}"
        fileB = "#{path.join(__dirname, 'fileB.txt')}"

        @same_checker = new SampleDiff(fileB, fileA, 3, opts)
        @same_checker.run(
            (is_same) ->
                test.equal(is_same, true)
                test.done()
        )


    "diff test": (test) ->
        fileA = "#{path.join(__dirname, 'fileA.txt')}"
        fileC = "#{path.join(__dirname, 'fileC.txt')}"

        @diff_checker = new SampleDiff(fileC, fileA, 3, opts)
        @diff_checker.run(
          (is_same) ->
            test.equal(is_same, false)
            test.done()
        )

    "enable cache" : (test) ->
        fileA = "#{path.join(__dirname, 'fileA.txt')}"
        fileB = "#{path.join(__dirname, 'fileB.txt')}"
        opts  = _.clone opts
        opts.enable_cache = true
        #test.done()

        @cache_checker1 = new SampleDiff(fileB, fileA, 3, opts)
        @cache_checker1.run(
            () ->
                1
                @cache_checker2 = new SampleDiff("not_exist", "not_exist", 3, opts)
                @cache_checker2.run(
                    (is_same) ->
                        test.equal(is_same, true)
                        test.done()
                )
                console.log "[run] unlink"
                fs.unlinkSync path.join(process.cwd(), "sample-diff.json")
        )
