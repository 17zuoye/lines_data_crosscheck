LinesDataCrosscheck = require '../src/lines_data_crosscheck'

path         = require 'path'
difflet      = require('difflet')

opts = {
            "fetch_item_id_func" : (line1) -> JSON.parse(line1)['id'],
            "diff_items_func"    : (a, b)  -> console.log(difflet.compare(JSON.parse(a), JSON.parse(b))),
        }

exports.LinesDataCrosscheckTest =

    "same test": (test) ->
        fileA = "#{path.join(__dirname, 'fileA.txt')}"
        fileB = "#{path.join(__dirname, 'fileB.txt')}"

        @same_checker = new LinesDataCrosscheck(
                                                fileB, fileA,
                                                3, opts
                                               )
        @same_checker.run(
            (is_same) ->
                test.equal(is_same, true)
                test.done()
        )


    "diff test": (test) ->
        fileA = "#{path.join(__dirname, 'fileA.txt')}"
        fileC = "#{path.join(__dirname, 'fileC.txt')}"

        @diff_checker = new LinesDataCrosscheck(
                                                fileC, fileA,
                                                3, opts
                                               )
        @diff_checker.run(
          (is_same) ->
            test.equal(is_same, false)
            test.done()
        )
