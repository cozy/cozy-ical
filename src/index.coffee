fs = require 'fs'
moment = require 'moment-timezone'
lazy = require 'lazy'

module.exports.decorateAlarm = require './alarm'
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

    constructor: ->
        @subComponents = []
        @fields = {}

    toString: ->
        buf = new iCalBuffer
        buf.addLine "BEGIN:#{@name}"
        buf.addLine "#{att}:#{val}" for att, val of @fields
        buf.addLine component.toString() for component in @subComponents
        buf.addString "END:#{@name}"

    add: (component) ->
        @subComponents.push component if component? # Skip invalid component

    walk: (walker) ->
        walker this
        sub.walk walker for sub in @subComponents


# Calendar component. It's the representation of the root object of a Calendar.
# @param options { organization, title }
module.exports.VCalendar = class VCalendar extends VComponent
    name: 'VCALENDAR'

    constructor: (options) ->
        super
        # During parsing, VAlarm are initialized without any property,
        # so we skip the processing below
        return @ if not options

        @fields =
            VERSION: "2.0"

        @fields['PRODID'] = \
            "-//#{options.organization}//NONSGML #{options.title}//EN"
        @vtimezones = {}

    # VTimezone management is not included as of 18/09/2014, but code exists
    # anyway to support them if necessary in future"
    addTimezone: (timezone) ->
        if not @vtimezones[timezone]?
            @vtimezones[timezone] = new VTimezone moment(), timezone

    toString: ->
        buf = new iCalBuffer
        buf.addLine "BEGIN:#{@name}"
        buf.addLine "#{att}:#{val}" for att, val of @fields
        buf.addLine vtimezone.toString() for _,vtimezone of @vtimezones
        buf.addLine component.toString() for component in @subComponents
        buf.addString "END:#{@name}"


# An alarm is there to warn the calendar owner of something. It could be
# included in an event or in a todo.
# REPEAT field is ommited, as Lightning don't like the REPEAT: 0 value.
# @param options { trigger, action, description, attendee, summary }
module.exports.VAlarm = class VAlarm extends VComponent
    name: 'VALARM'

    constructor: (options) ->
        super

        # During parsing, VAlarm are initialized without any property,
        # so we skip the processing below
        if not options
            return @

        @fields =
            ACTION: options.action
            TRIGGER: options.trigger

        if options.description?
            @fields.DESCRIPTION = options.description

        if options.action is 'EMAIL'
            @fields.ATTENDEE = options.attendee
            @fields.SUMMARY = options.summary


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

    constructor: (options) ->
        super

        # During parsing, VTodo are initialized without any property,
        # so we skip the processing below
        if options
            startDate = moment options.startDate

            @fields =
                DTSTART: startDate.format VTodo.icalDTUTCFormat
                SUMMARY: options.summary
                DURATION: 'PT30M'
                UID: options.uid

            if options.description?
                @fields.DESCRIPTION = options.description

    # @param options { action, description, attendee, summary }
    addAlarm: (options) ->
        options.trigger = 'PT0M'
        @add new VAlarm options


# @param options { startDate, endDate, summary, location, uid,
#                  description, allDay, rrule, timezone }
module.exports.VEvent = class VEvent extends VComponent
    name: 'VEVENT'

    constructor: (options) ->
        super

        # During parsing, VEvent are initialized without any property,
        # so we skip the processing below
        if options

            @fields =
                SUMMARY:     options.summary
                LOCATION:    options.location
                UID:         options.uid

            if options.description?
                @fields.DESCRIPTION = options.description

            fieldS = 'DTSTART'
            fieldE = 'DTEND'
            formatS = null
            formatE = null
            # by default we have no information on timezone for each date
            tzS = null
            tzE = null

            if options.allDay
                # for all day event timezone information is not needed
                fieldS += ";VALUE=DATE"
                fieldE += ";VALUE=DATE"
                formatS = formatE = VEvent.icalDateFormat

            else if options.rrule
                formatS = formatE = VEvent.icalDTFormat # set format (date-time, not trailing Z)
                tzS = tzE = options.timezone # remember timezone

                # Lightning can't parse RRULE with DTSTART field in it.
                # So skip it from the RRULE, which is formated like this :
                # RRULE:FREQ=WEEKLY;DTSTART=20141014T160000Z;INTERVAL=1;BYDAY=TU
                rrule = options.rrule.split ';'
                       .filter (s) -> s.indexOf('DTSTART') isnt 0
                       .join ';'

                @fields['RRULE'] = rrule

            else # Punctual event.
                if options.timezone
                    # if timezone is specified with options
                    formatS = formatE = VEvent.icalDTFormat # set format (date-time, no trailing Z)
                    tzS = tzE = options.timezone # remember timezone
                else
                    # otherwise, try to get timezone information from Date itself
                    if options.startDate.getTimezone?
                        # if so, set format and tz name like above
                        formatS = VEvent.icalDTFormat
                        tzS = options.startDate.getTimezone()
                    else
                        # if there are not tz info - use UTC formatting (date-time with trailing Z)
                        formatS = VEvent.icalDTUTCFormat

                    # repeat for end date ...
                    if options.endDate.getTimezone?
                        formatE = VEvent.icalDTFormat
                        tzE = options.startDate.getTimezone()
                    else
                        formatE = VEvent.icalDTUTCFormat

            # if we have tz information - add it to field names
            fieldS += ";TZID=#{tzS}" if tzS
            fieldE += ";TZID=#{tzE}" if tzE

            @fields[fieldS] = moment(options.startDate).format formatS
            @fields[fieldE] = moment(options.endDate).format formatE


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

        @fields =
            TZID: options.timezone
            TZURL: "http://tzurl.org/zoneinfo/#{options.timezone}.ics"


        # zone = moment.tz.zone(timezone)
        # @add new VStandard
        # startShift and endShift are equal because, actually, only alarm has timezone
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

        @fields =
            DTSTART: moment(options.startDate).format VStandard.icalDTFormat
            TZOFFSETFROM: options.startShift
            TZOFFSETTO: options.endShift


# @param options { startDate, startShift, endShift }
module.exports.VDaylight = class VDaylight extends VComponent
    name: 'DAYLIGHT'

    constructor: (options) ->
        super
        # During parsing, VDaylight are initialized without any property,
        # so we skip the processing below
        if not options
            return @

        @fields =
            DTSTART: moment(options.startDate).format VDaylight.icalDTFormat
            TZOFFSETFROM: options.startShift
            TZOFFSETTO: options.endShift


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
            setEncoding: -> throw 'not implemented'
            pipe: -> throw 'not implemented'
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
                key = tuple[0]
                tuple.shift()
                value = tuple.join('')

                if key is "BEGIN"
                    createComponent value
                else if key is "END"
                    component = component.parent
                else if not (component? or result?)
                    sendError "Malformed ical file"
                else if key? and key isnt '' and component?
                    [key, details...] = key.split(';')
                    component.fields[key] = value
                    for detail in details
                        [pname, pvalue] = detail.split '='
                        component.fields["#{key}-#{pname}"] = pvalue
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
