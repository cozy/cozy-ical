# Handle only unique units strings.
module.exports.iCalDurationToUnitValue = (string, unit) ->
    regex = new RegExp "(\\d+)#{unit}"
    match = string.match regex

    if match?
        return parseInt match[1]
    else
        return 0
