# Handle only unique units strings.
module.exports.iCalDurationToUnitValue = (string, unit) ->
    regex = new RegExp "(\\d+)#{unit}"
    match = string.match regex

    if match?
        return parseInt match[1]
    else
        return 0

module.exports.escapeText = (s) ->
    if not s?
        return s
    t = s.replace /([,;\\])/ig, "\\$1"
    t = t.replace /\n/g, '\\n'

    return t

module.exports.unescapeText = (t) ->
    if not t?
        return t
    s = t.replace /\\n/g, '\n'
    s = s.replace /\\([,;\\])/ig, "$1"
    
    return s