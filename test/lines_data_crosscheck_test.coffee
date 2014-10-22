LinesDataCrosscheck = require '../src/lines_data_crosscheck'


exports.LinesDataCrosscheckTest =

    setUp: (callback) ->
        @checker = new LinesDataCrosscheck()
        callback()

    "complete test": (test) ->
        test.ok(@checker)
        test.done()
