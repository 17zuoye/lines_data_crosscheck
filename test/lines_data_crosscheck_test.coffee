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

        test.done()
