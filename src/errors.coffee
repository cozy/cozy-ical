module.exports.MissingFieldError = class MissingFieldError
    constructor: (field) ->
        @name = 'MissingFieldError'
        @message = "Mandatory field `#{field}` is missing"
        Error.captureStackTrace this
    @:: = new Error
    @::constructor = @

module.exports.FieldConflictError = class FieldConflictError
    constructor: (field1, field2) ->
        @name = 'FieldConflictError'
        @message = "Fields `#{field1}` and `#{field2}` can't be both present"
        Error.captureStackTrace this
    @:: = new Error
    @::constructor = @

module.exports.FieldDependencyError = class FieldDependencyError
    constructor: (field1, field2) ->
        @name = 'FieldDependencyError'
        @message = "Field `#{field1}` is missing and `#{field2}` requires " + \
                   "it to exist"
        Error.captureStackTrace this
    @:: = new Error
    @::constructor = @

module.exports.InvalidValueError = class InvalidValueError
    constructor: (field, value, expected) ->
        @name = 'InvalidValueError'
        @message = "Field `#{field}` has value \"#{value}\", expected " + \
                   "value to be in #{expected.join ', '}"
        Error.captureStackTrace this
    @:: = new Error
    @::constructor = @
