module.exports.MissingFieldError = class MissingFieldError extends Error
    constructor: (field) ->
        @name = 'MissingFieldError'
        @message = "Mandatory field `#{field}` is missing"
        Error.captureStackTrace this, arguments.callee

module.exports.FieldConflictError = class FieldConflictError extends Error
    constructor: (field1, field2) ->
        @name = 'FieldConflictError'
        @message = "Fields `#{field1}` and `#{field2}` can't be both present"
        Error.captureStackTrace this, arguments.callee

module.exports.FieldDependencyError = class FieldDependencyError extends Error
    constructor: (field1, field2) ->
        @name = 'FieldDependencyError'
        @message = "Field `#{field1}` is missing and `#{field2}` requires " + \
                   "it to exist"
        Error.captureStackTrace this, arguments.callee

module.exports.InvalidValueError = class InvalidValueError extends Error
    constructor: (field, value, expected) ->
        @name = 'InvalidValueError'
        @message = "Field `#{field}` has value \"#{value}\", expected " + \
                   "value to be in #{expected.join ', '}"
        Error.captureStackTrace this, arguments.callee
