LinesDataCrosscheck = require '../src/lines_data_crosscheck'

path         = require 'path'
jsondiff     = require 'json-diff/lib/cli'
difflet      = require('difflet')

exports.LinesDataCrosscheckTest =

    setUp: (callback) ->
        callback()

    tearDown: (callback) ->
        callback()


    "complete test": (test) ->
        fileA = "#{path.join(__dirname, 'fileA.txt')}"
        fileB = "#{path.join(__dirname, 'fileB.txt')}"
        fileC = "#{path.join(__dirname, 'fileC.txt')}"

        @same_checker = new LinesDataCrosscheck(
                                                fileB, fileA,
                                                3,
                                                (line1) -> JSON.parse(line1)['id'],
                                                (a, b)  -> console.log(difflet.compare(JSON.parse(a), JSON.parse(b))),
                                               )
        @same_checker.run( (is_same) -> test.equal(is_same, "no") )

        @diff_checker = new LinesDataCrosscheck(
                                                fileC, fileA,
                                                3,
                                                (line1) -> JSON.parse(line1)['id'],
                                                (a, b)  -> console.log(difflet.compare(JSON.parse(a), JSON.parse(b))),
                                               )
        @diff_checker.run( (is_diff) -> test.equal(is_diff, "no") )

        test.ok(@same_checker)
        test.ok(@diff_checker)
        test.done()
