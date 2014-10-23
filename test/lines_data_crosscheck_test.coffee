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
        @checker = new LinesDataCrosscheck(
                                            fileA, fileB,
                                            1,
                                            (line1) -> JSON.parse(line1),
                                            (line1) -> JSON.parse(line1)['id'],
                                          )
        @checker.run()

        test.ok(@checker)
        test.done()
