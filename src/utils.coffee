diff         = require('json-diff/lib/index').diff
colorize     = require('json-diff/lib/colorize').colorize

json_color_diff = (a, b) ->
                   result = diff(a, b)
                   if result
                     console.log(colorize(result))
                   return !!result

module.exports = {
  "json_color_diff" : json_color_diff,
}
