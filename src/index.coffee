fs = require 'fs'
moment = require 'moment-timezone'
lazy = require 'lazy'
extend = require 'extend'
uuid = require 'uuid'
{RRule} = require 'rrule'

VALID_TZ_LIST = moment.tz.names()

{MissingFieldError, FieldConflictError, \
FieldDependencyError, InvalidValueError} = require './errors'
helpers = require './helpers'

module.exports.decorateEvent = require './event'

# Small module to generate iCal file from JS Objects or to parse iCal file
# to obtain explicit JS Objects.
#
# This module is inpired by the icalendar Python module.


# Buffer manager to easily build long string.
class iCalBuffer
    # TODO Make this buffer streamable

    txt: ''

    addString: (text) ->
        @txt += text

    addStrings: (texts) ->
        @addString text for text in texts

    addLine: (text) ->
        @addString "#{text}\r\n"

    addLines: (texts) ->
        @addLine text for text in texts

    toString: -> @txt


# Base ICal Component. This class is aimed to be extended not to be used
# directly.
module.exports.VComponent = class VComponent
    name: 'VCOMPONENT'

    @icalDTUTCFormat: 'YYYYMMDD[T]HHmm[00Z]'
    @icalDTFormat: 'YYYYMMDDTHHmm[00]'
    @icalDateFormat: 'YYYYMMDD'

    constructor: (options) ->
        # deep clone the options
        @model = extend true, {}, options
        @subComponents = []
        @rawFields = []

        # don't validate nor build automatically if no options have been passed
        # i.e. during parsing
        if options?
            @validate()
            @build()

    validate: ->
        # should be defined by subclass

    build: -> @rawFields = []

    extract: -> @model = {}

    toString: ->
        buf = new iCalBuffer
        buf.addLine "BEGIN:#{@name}"
        @_toStringFields buf
        @_toStringComponents buf
        buf.addString "END:#{@name}"

    _toStringFields: (buf) ->
        for field in @rawFields
            buf.addLine "#{field.key}:#{field.value}" if field.value?

    _toStringComponents: (buf) ->
        for component in @subComponents
            buf.addLine component.toString()

    add: (component) ->
        @subComponents.push component if component? # Skip invalid component

    walk: (walker) ->
        walker this
        sub.walk walker for sub in @subComponents

    addRawField: (key, value, details = {}) ->
        @rawFields.push {key, value, details}

    addTextField: (key, value, details = {}) ->
        @addRawField key, helpers.escapeText(value), details

    getRawField: (key, findMany = false) ->

        defaultResult = if findMany then [] else null

        for field in @rawFields
            if field.key is key
                if findMany
                    defaultResult.push field
                else
                    return field if field.key

        return defaultResult

    getTextFieldValue: (key, defaults) ->
        field = @getRawField key, false
        value = helpers.unescapeText field?.value
        return value or defaults


# Calendar component. It's the representation of the root object of a Calendar.
# @param options { organization, title }
module.exports.VCalendar = class VCalendar extends VComponent
    name: 'VCALENDAR'

    constructor: (options) ->
        super
        @vtimezones = {}

    validate: ->
        unless @model.organization?
            throw new MissingFieldError 'organization'

        unless @model.title?
            throw new MissingFieldError 'title'

    build: ->
        super()
        prodid = "-//#{@model.organization}//NONSGML #{@model.title}//EN"
        @addRawField 'VERSION', '2.0'
        @addRawField 'PRODID', prodid

    extract: ->
        super()
        {value} = @getRawField 'PRODID'
        extractPRODID = /-\/\/([\w. ]+)\/\/?(?:NONSGML )?(.+)\/\/.*/
        results = value.match extractPRODID

        if results?
            [_, organization, title] = results
        else
            organization = 'Undefined organization'
            title = 'Undefined title'

        @model = {organization, title}

    # VTimezone management is not included as of 18/09/2014, but code exists
    # anyway to support them if necessary in future"
    addTimezone: (timezone) ->
        if not @vtimezones[timezone]?
            @vtimezones[timezone] = new VTimezone moment(), timezone

    toString: ->
        buf = new iCalBuffer
        buf.addLine "BEGIN:#{@name}"
        @_toStringFields buf
        buf.addLine vtimezone.toString() for _,vtimezone of @vtimezones
        @_toStringComponents buf
        buf.addString "END:#{@name}"


# An alarm is there to warn the calendar owner of something. It could be
# included in an event or in a todo.
# REPEAT field is ommited, as Lightning don't like the REPEAT: 0 value.
# @param options { trigger, action, description, attendee, summary }
module.exports.VAlarm = class VAlarm extends VComponent
    name: 'VALARM'

    @EMAIL_ACTION: 'EMAIL'
    @DISPLAY_ACTION: 'DISPLAY'
    @AUDIO_ACTION: 'AUDIO'

    validate: ->
        unless @model.action?
            throw new MissingFieldError 'action'

        unless @model.trigger?
            throw new MissingFieldError 'trigger'

        # If there is a `duration` field or a `repeat` field,
        # they must both occur
        if @model.duration? and not @model.repeat?
            throw new FieldDependencyError 'duration', 'repeat'
        else if (not @model.duration? and @model.repeat?)
            throw new FieldDependencyError 'repeat', 'duration'

        # Validates that action is in its range value
        # and specific case by action
        if @model.action is VAlarm.DISPLAY_ACTION
            unless @model.description?
                throw new MissingFieldError 'description'

        else if @model.action is VAlarm.EMAIL_ACTION
            unless @model.description?
                throw new MissingFieldError 'description'

            unless @model.summary?
                throw new MissingFieldError 'summary'

            unless @model.attendees?
                throw new MissingFieldError 'attendees'

        else if @model.action is VAlarm.AUDIO_ACTION
            # nothing to be done

        else
            expected = [
                VAlarm.DISPLAY_ACTION
                VAlarm.EMAIL_ACTION
                VAlarm.AUDIO_ACTION
            ]
            throw new InvalidValueError 'action', @model.action, expected

    build: ->
        super()
        @addRawField 'ACTION', @model.action
        @addRawField 'TRIGGER', @model.trigger

        if @model.attendees
            for attendee in @model.attendees
                status = attendee.details?.status or 'NEEDS-ACTION'
                details = ";PARTSTAT=#{status}"
                name = attendee.details?.name or attendee.email
                details += ";CN=#{name}"
                fieldValue = "mailto:#{attendee.email}"
                @addRawField "ATTENDEE#{details}", fieldValue, details
        @addTextField 'DESCRIPTION', @model.description
        @addRawField 'DURATION', @model.duration or null
        @addRawField 'REPEAT', @model.repeat or null
        @addTextField 'SUMMARY', @model.summary

    extract: ->
        super()

        trigger = @getRawField('TRIGGER')?.value or null

        description = @getTextFieldValue 'DESCRIPTION'

        attendees = @getRawField 'ATTENDEE', true
        attendees = attendees?.map (attendee) ->
            email = attendee.value.replace 'mailto:', ''

            # extracts additional values if they exist
            if attendee.details?.length > 0
                details = {}
                for detail in attendee.details
                    if detail.indexOf('PARTSTAT') isnt -1
                        [key, status] = detail.split '='
                        details.status = status
                    else if detail.indexOf('CN') isnt -1
                        [key, name] = detail.split '='
                        details.name = name
            else
                details = status: 'NEEDS-ACTION', name: email
            return {email, details}

        summary = @getTextFieldValue 'SUMMARY'

        expected = [
            VAlarm.DISPLAY_ACTION
            VAlarm.EMAIL_ACTION
            VAlarm.AUDIO_ACTION
        ]

        action = @getRawField('ACTION')?.value
        if action not in expected
            action = VAlarm.DISPLAY_ACTION
            unless description?
                description = @parent?.getTextFieldValue 'SUMMARY', ''

        # It must have mandatory fields filled based on action
        else if action is VAlarm.DISPLAY_ACTION
            unless description?
                description = @parent?.getTextFieldValue 'SUMMARY', ''

        else if action is VAlarm.EMAIL_ACTION
            unless description?
                description = @parent?.getTextFieldValue 'DESCRIPTION', ''

            unless summary?
                summary = @parent?.getTextFieldValue 'SUMMARY', ''

            unless attendees?
                attendees = []

        @model =
            action: action
            trigger: trigger
            attendees: attendees
            description: description
            repeat: @getRawField('REPEAT')?.value or null
            summary: summary

# The VTodo is used to described a dated action.
#
# cozy's alarm use VTodo to carry VAlarm. The VTodo handle the alarm datetime
# on it's DTSTART field.
# DURATION is a fixed stubbed value of 30 minutes, to avoid infinite tasks in
# external clients (as lightning).
# Nested VAlarm ring 0 minutes after (so: at) VTodo DTSTART.
# @param options {startDate, uid, summary, description }
module.exports.VTodo = class VTodo extends VComponent
    name: 'VTODO'

    validate: ->
        unless @model.uid?
            throw new MissingFieldError 'uid'

        unless @model.stampDate?
            throw new MissingFieldError 'stampDate'

        if @model.due? and @model.duration?
            throw new FieldConflictError 'due', 'duration'

        if @model.duration? and not @model.startDate?
            throw new FieldDependencyError 'startDate', 'duration'

    build: ->
        super()
        # Formats stamp date to valid iCal date
        stampDate = moment.tz @model.stampDate, 'UTC'

        # Adds UID and DTSTAMP fields
        @addRawField 'UID', @model.uid
        @addRawField 'DTSTAMP', stampDate.format VEvent.icalDTUTCFormat

        # Formats start date if it exists
        if @model.startDate?
            startDate = moment @model.startDate
            formattedStartDate = startDate.format VTodo.icalDTUTCFormat

        @addTextField 'DESCRIPTION', @model.description or null
        @addRawField 'DTSTART', formattedStartDate or null
        @addRawField 'DUE', @model.due or null
        @addRawField 'DURATION', @model.duration or null
        @addTextField 'SUMMARY', @model.summary or null

    extract: ->
        super()

        stampDate = @getRawField('DTSTAMP')?.value or moment().tz('UTC')

        startDate = @getRawField('DTSTART')?.value
        due = @getRawField('DUE')?.value
        duration = @getRawField('DURATION')?.value

        # Both can't exist, we remove duration
        if due? and duration?
            duration = null

        if startDate?
            details = @getRawField('DTSTART').details
            if details.length > 0
                [_, timezone] = details[0].split '='
                if timezone not in VALID_TZ_LIST
                    timezone = 'UTC'
            else
                timezone = 'UTC'
            startDate = moment.tz startDate, VTodo.icalDTUTCFormat, timezone
        else if not startDate? and duration?
            startDate = moment.tz moment(), 'UTC'

        @model =
            uid: @getRawField('UID')?.value or uuid.v1()
            stampDate: moment.tz(stampDate, VTodo.icalDTUTCFormat, 'UTC').toDate()
            description: @getTextFieldValue 'DESCRIPTION', ''
            startDate: startDate.toDate()
            due: due
            duration: duration
            summary: @getTextFieldValue 'SUMMARY', ''
            timezone: timezone

    # @param options { action, description, attendee, summary }
    addAlarm: (options) ->
        @add new VAlarm options

# @param options { startDate, endDate, summary, location, uid,
#                  description, allDay, rrule, timezone }
module.exports.VEvent = class VEvent extends VComponent
    name: 'VEVENT'

    validate: ->
        unless @model.uid?
            throw new MissingFieldError 'uid'

        unless @model.stampDate?
            throw new MissingFieldError 'stampDate'

        unless @model.startDate?
            throw new MissingFieldError 'startDate'

        if @model.endDate? and @model.duration?
            throw new FieldConflictError 'endDate', 'duration'

    build: ->
        super()

        # if there is not endDate nor duration AND not recurrence rule
        # then the default is 1 day
        if not @model.endDate? and not @model.duration? and not @model.rrule?
            @model.endDate = moment(@model.startDate).add(1, 'd').toDate()

        # Preparing start and end dates formatting
        fieldStart = "DTSTART"
        fieldEnd = "DTEND"
        formatStart = null
        formatEnd = null

        # By default we have no information on timezone for each date (it's UTC)
        timezoneStart = null
        timezoneEnd = null

        # "all-day" event
        if @model.allDay
            # for all day event timezone information is not needed
            fieldStart += ";VALUE=DATE"
            fieldEnd += ";VALUE=DATE"
            formatStart = formatEnd = VEvent.icalDateFormat

        # recurring event
        else if @model.rrule?
            # format is date-time with no trailing Z
            formatStart = formatEnd = VEvent.icalDTFormat
            timezoneStart = timezoneEnd = @model.timezone

        # punctual event
        else
            # if timezone is specified with options
            if @model.timezone and @model.timezone isnt 'UTC'
                # format is a date-time with no trailing Z
                formatStart = formatEnd = VEvent.icalDTFormat
                timezoneStart = timezoneEnd = @model.timezone

            # otherwise, try to get timezone information from Date itself
            else
                # if so, set format and timezone name like above
                if @model.startDate.getTimezone?
                    formatStart = VEvent.icalDTFormat
                    timezoneStart = @model.startDate.getTimezone()

                # else format is a UTC date-time
                else
                    formatStart = VEvent.icalDTUTCFormat

                # repeat for end date ...
                if @model.endDate.getTimezone?
                    formatEnd = VEvent.icalDTFormat
                    timezoneEnd = @model.startDate.getTimezone()
                else
                    formatEnd = VEvent.icalDTUTCFormat

        # fields name are different if there is a timezone or not
        fieldStart += ";TZID=#{timezoneStart}" if timezoneStart?
        fieldEnd += ";TZID=#{timezoneEnd}" if timezoneEnd?

        if @model.rrule?
            # if rrule `dtstart` property is specified, RRule outputs
            # a `dtstart` field in the rule, which is not part of the standard,
            # resulting in errors in some clients (i.e Lightning)
            delete @model.rrule.dtstart

            rrule = new RRule(@model.rrule).toString()

        # Formats stamp date to valid iCal date
        stampDate = moment(@model.stampDate).tz 'UTC'
        # Adds UID and DTSTAMP fields
        @addRawField 'UID', @model.uid
        @addRawField 'DTSTAMP', stampDate.format VEvent.icalDTUTCFormat

        @addRawField fieldStart, moment(@model.startDate).format formatStart
        if @model.endDate?
            @addRawField fieldEnd, moment(@model.endDate).format formatEnd

        if @model.attendees?
            for attendee in @model.attendees
                status = attendee.details?.status or 'NEEDS-ACTION'
                details = ";PARTSTAT=#{status}"
                name = attendee.details?.name or attendee.email
                details += ";CN=#{name}"
                @addRawField "ATTENDEE#{details}", "mailto:#{attendee.email}"

        if @model.lastModification?
            lastModification = moment.tz @model.lastModification, 'UTC'
                                .format VEvent.icalDTUTCFormat

        if @model.created?
            created = moment.tz @model.created, 'UTC'
                                .format VEvent.icalDTUTCFormat

        @addRawField 'CATEGORIES', @model.categories or null
        @addRawField 'CREATED', created or null
        @addTextField 'DESCRIPTION', @model.description or null
        @addRawField 'DURATION', @model.duration or null
        @addRawField 'LAST-MOD', lastModification or null
        @addTextField 'LOCATION', @model.location or null
        @addRawField 'ORGANIZER', @model.organizer or null
        @addRawField 'RRULE', rrule or null
        @addTextField 'SUMMARY', @model.summary or null

    extract: ->
        iCalFormat = 'YYYYMMDDTHHmmss'
        uid = @getRawField 'UID'
        stampDate = @getRawField('DTSTAMP')?.value or moment()

        # gets date start and its timezone if found
        dtstart = @getRawField 'DTSTART'
        if dtstart?
            startDate = dtstart.value
            # details for a dtstart field is timezone indicator
            if dtstart.details?.length > 0
                if dtstart.details[0] is 'VALUE=DATE'
                    timezoneStart = 'UTC'
                    allDay = true
                else
                    [_, timezoneStart] = dtstart.details[0].split '='
                    if timezoneStart     not in VALID_TZ_LIST
                        timezoneStart = 'UTC'
            else
                timezoneStart = 'UTC'
        else
            startDate = moment.tz(moment(), 'UTC').format iCalFormat
            timezoneStart = 'UTC'

        dtend = @getRawField 'DTEND'
        endDate = dtend?.value or null
        duration = @getRawField('DURATION')?.value or null

        # can't have both at the same time, drop duration if it's the case
        if endDate? and duration?
            duration = null

        # if there is none of them, fallback to default: start+1d
        else if not endDate? and not duration?
            endDate = moment.tz startDate, iCalFormat, timezoneStart
                        .add 1, 'd'
                        .toDate()

        # creates the end end date with the duration added to it
        else if not endDate? and duration?
            weeksNum = helpers.iCalDurationToUnitValue duration, 'W'
            daysNum = helpers.iCalDurationToUnitValue duration, 'D'
            hoursNum = helpers.iCalDurationToUnitValue duration, 'H'
            minutesNum = helpers.iCalDurationToUnitValue duration, 'M'
            secondsNum = helpers.iCalDurationToUnitValue duration, 'S'
            endDate = moment.tz startDate, iCalFormat, timezoneStart
            endDate = endDate.add weeksNum, 'w'
                .add daysNum, 'd'
                .add hoursNum, 'h'
                .add minutesNum, 'm'
                .add secondsNum, 's'
                .toDate()

            duration = null

        # gets end date and its timezone if found
        else if endDate?
            # details for a dtend field is timezone indicator
            if dtend.details?.length > 0
                [_, timezoneEnd] = dtstart.details[0].split '='
                if timezoneEnd not in VALID_TZ_LIST
                    timezoneEnd = 'UTC'
            else
                timezoneEnd = 'UTC'

            endDate = moment.tz(endDate, iCalFormat, timezoneEnd).toDate()

        rrule = @getRawField('RRULE')?.value
        if rrule?
            timezone = timezoneStart unless timezoneStart is 'UTC'
            rruleOptions = RRule.parseString rrule

        attendees = @getRawField 'ATTENDEE', true
        attendees = attendees?.map (attendee) ->
            email = attendee.value.replace 'mailto:', ''

            # extracts additional values if they exist
            if attendee.details?.length > 0
                details = {}
                for detail in attendee.details
                    if detail.indexOf('PARTSTAT') isnt -1
                        [key, status] = detail.split '='
                        details.status = status
                    else if detail.indexOf('CN') isnt -1
                        [key, name] = detail.split '='
                        details.name = name
            else
                details = status: 'NEEDS-ACTION', name: email
            return {email, details}

        # Put back in the right format
        lastModification = @getRawField('LAST-MOD')?.value
        if lastModification?
            lastModification = moment.tz lastModification, VEvent.icalDTUTCFormat, 'UTC'
                                .toISOString()

        # Put back in the right format
        created = @getRawField('CREATED')?.value
        if created?
            created = moment.tz created, VEvent.icalDTUTCFormat, 'UTC'
                        .toISOString()

        @model =
            uid: uid?.value or uuid.v1()
            stampDate: moment.tz(stampDate, VEvent.icalDTUTCFormat, 'UTC').toDate()
            startDate: moment.tz(startDate, iCalFormat, timezoneStart).toDate()
            endDate: endDate
            duration: duration
            attendees: attendees
            categories: @getRawField('CATEGORIES')?.value or null
            description: @getTextFieldValue 'DESCRIPTION', null
            location: @getTextFieldValue 'LOCATION', null
            organizer: @getRawField('ORGANIZER')?.value or null
            rrule: rruleOptions or null
            summary: @getTextFieldValue 'SUMMARY', null
            allDay: allDay or null
            timezone: timezone or null
            lastModification: lastModification or null
            created: created or null

# @param options { startDate, timezone }
module.exports.VTimezone = class VTimezone extends VComponent
    name: 'VTIMEZONE'

    # constructor: (timezone) ->
    constructor: (options) ->
        super
        # During parsing, VTimezone are initialized without any property,
        # so we skip the processing below
        if not options
            return @

        tzurl = "http://tzurl.org/zoneinfo/#{options.timezone}.ics"
        @rawFields = [
            {key: 'TZID', value: options.timezone}
            {key: 'TZURL', value: tzurl}
        ]

        # zone = moment.tz.zone(timezone)
        # @add new VStandard
        # startShift and endShift are equal because, actually
        # only alarm has timezone
        diff = moment.tz(options.startDate, options.timezone).format 'ZZ'
        vstandard = new VStandard options.startDate, diff, diff
        @add vstandard
        vdaylight = new VDaylight options.startDate, diff, diff
        @add vdaylight


# Additional components not supported yet by Cozy Cloud.

module.exports.VJournal = class VJournal extends VComponent
    name: 'VJOURNAL'


module.exports.VFreeBusy = class VFreeBusy extends VComponent
    name: 'VFREEBUSY'


# @param options { startDate, startShift, endShift }
module.exports.VStandard = class VStandard extends VComponent
    name: 'STANDARD'

    constructor: (options) ->
        super
        # During parsing, VStandard are initialized without any property,
        # so we skip the processing below
        if not options
            return @

        dtstart = moment options.startDate
                    .format VStandard.icalDTFormat
        @rawFields = [
            {key: 'DTSTART', value: dtstart}
            {key: 'TZOFFSETFROM', value: options.startShift}
            {key: 'TZOFFSETTO', value: options.endShift}
        ]


# @param options { startDate, startShift, endShift }
module.exports.VDaylight = class VDaylight extends VComponent
    name: 'DAYLIGHT'

    constructor: (options) ->
        super
        # During parsing, VDaylight are initialized without any property,
        # so we skip the processing below
        if not options
            return @

        dtstart = moment options.startDate
                    .format VDaylight.icalDTFormat
        @rawFields = [
            {key: 'DTSTART', value: dtstart}
            {key: 'TZOFFSETFROM', value: options.startShift}
            {key: 'TZOFFSETTO', value: options.endShift}
        ]


module.exports.ICalParser = class ICalParser

    @components:
        VTODO: VTodo
        VALARM: VAlarm
        VEVENT: VEvent
        VJOURNAL: VJournal
        VFREEBUSY: VFreeBusy
        VTIMEZONE: VTimezone
        STANDARD: VStandard
        DAYLIGHT: VDaylight

    parseFile: (file, callback) ->
        @parse fs.createReadStream(file), callback

    parseString: (string, callback) ->
        class FakeStream extends require('events').EventEmitter
            readable: true
            writable: false
            setEncoding: -> throw new Error 'not implemented'
            pipe: -> throw new Error 'not implemented'
            destroy: ->  # nothing to do
            resume: ->   # nothing to do
            pause: ->    # nothing to do
            send: (string) ->
                @emit 'data', string
                @emit 'end'

        fakeStream = new FakeStream
        @parse fakeStream, callback
        fakeStream.send string

    parse: (stream, callback) ->
        result = {}
        noerror = true
        lineNumber = 0
        component = null
        parent = null
        completeLine = null

        stream.on 'end', ->
            lineParser completeLine if completeLine
            callback null, result if noerror

        sendError = (msg) ->
            callback new Error "#{msg} (line #{lineNumber})" if noerror
            noerror = false

        createComponent = (name) ->
            parent = component

            if name is "VCALENDAR"
                if result.fields?
                    sendError "Cannot parse more than one calendar"
                component = new VCalendar()
                result = component

            else if name in Object.keys ICalParser.components
                component = new ICalParser.components[name]()

            else
                sendError "Malformed ical file"

            component?.parent = parent
            parent?.add component

        lineParser = (line) ->

            tuple = line.trim().split ':'

            if tuple.length < 2
                sendError "Malformed ical file"
            else
                key = tuple.shift()
                value = tuple.join ':'

                if key is "BEGIN"
                    createComponent value
                else if key is "END"
                    component.extract()
                    component = component.parent
                else if not (component? or result?)
                    sendError "Malformed ical file"
                else if key? and key isnt '' and component?
                    [key, details...] = key.split(';')
                    component.addRawField key, value, details
                    for detail in details
                        [pname, pvalue] = detail.split '='
                else
                    sendError "Malformed ical file"

        lazy(stream).lines.forEach (line) ->
            lineNumber++

            line = line.toString('utf-8').replace "\r", ''

            # Skip blank lines and a strange behaviour :
            # empty lines become <Buffer 30> which is '0' .
            if line is '' or line is '0'
                return

            if line[0] is ' '
                completeLine += line.substring 1
            else
                lineParser completeLine if completeLine
                completeLine = line
