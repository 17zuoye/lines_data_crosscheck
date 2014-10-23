LinesDataCrosscheck = require '../src/lines_data_crosscheck'

path = require 'path'

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
                                                fileA, fileB,
                                                1,
                                                (line1) -> JSON.parse(line1),
                                                (line1) -> JSON.parse(line1)['id'],
                                               )
        @same_checker.run( (is_same) -> test.equal(is_same, true) )

        @diff_checker = new LinesDataCrosscheck(
                                                fileA, fileC,
                                                1,
                                                (line1) -> JSON.parse(line1),
                                                (line1) -> JSON.parse(line1)['id'],
                                               )
        @diff_checker.run( (is_diff) -> test.equal(is_diff, false) )

        test.ok(@same_checker)
        test.ok(@diff_checker)
        test.done()
