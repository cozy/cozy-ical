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
module.exports.VCalendar = class VCalendar extends VComponent
    name: 'VCALENDAR'

    constructor: (organization, title) ->
        super
        @fields =
            VERSION: "2.0"

        @fields['PRODID'] = "-//#{organization}//NONSGML #{title}//EN"
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
module.exports.VAlarm = class VAlarm extends VComponent
    name: 'VALARM'

    constructor: (trigger, action, description, attendee, summary) ->
        super

        # During parsing, VAlarm are initialized without any property,
        # so we skip the processing below
        if not startDate
            return @
        
        @fields =
            ACTION: action
            
            DESCRIPTION: description
            TRIGGER: trigger

        if action is 'EMAIL'
            @fields.ATTENDEE = attendee
            @fields.SUMMARY = summary


# The VTodo is used to described a dated action.
#
# cozy's alarm use VTodo to carry VAlarm. The VTodo handle the alarm datetime 
# on it's DTSTART field. 
# DURATION is a fixed stubbed value of 30 minutes, to avoid infinite tasks in
# external clients (as lightning).
# Nested VAlarm ring 0 minutes after (so: at) VTodo DTSTART.
module.exports.VTodo = class VTodo extends VComponent
    name: 'VTODO'

    constructor: (startDate, uid, summary, description) ->
        super

        # During parsing, VTodo are initialized without any property,
        # so we skip the processing below
        if not startDate
            return @

        @fields =
            DTSTART: startDate.format VTodo.icalDTUTCFormat
            SUMMARY: summary
            DURATION: 'PT30M' 
            UID: uid

        @fields.DESCRIPTION = description if description?

    addAlarm: (action, description, attendee, summary) ->
        @add new VAlarm 'PT0M', action, description, attendee, summary


# Additional components not supported yet by Cozy Cloud.
module.exports.VEvent = class VEvent extends VComponent
    name: 'VEVENT'

    constructor: (startDate, endDate, summary, location, uid, description, allDay, rrule, timezone) ->
        super

        # During parsing, VEvent are initialized without any property,
        # so we skip the processing below
        if not startDate
            return @

        @fields =
            SUMMARY:     summary
            LOCATION:    location
            UID:         uid

        @fields.DESCRIPTION = description if description?

        fieldS = 'DTSTART'
        fieldE = 'DTEND'
        valueS = null
        valueE = null

        if allDay
            fieldS += ";VALUE=DATE"
            fieldE += ";VALUE=DATE"
            valueS = startDate.format VEvent.icalDateFormat
            valueE = endDate.format VEvent.icalDateFormat

        else if rrule
            fieldS += ";TZID=#{timezone}"
            fieldE += ";TZID=#{timezone}"
            valueS = startDate.format VEvent.icalDTFormat
            valueE = endDate.format VEvent.icalDTFormat
            
            # Lightning can't parse RRULE with DTSTART field in it.
            # So skip it from the RRULE, which is formated like this :
            # RRULE:FREQ=WEEKLY;DTSTART=20141014T160000Z;INTERVAL=1;BYDAY=TU
            rrule = rrule.split ';'
                   .filter((s) -> s.indexOf('DTSTART') isnt 0
                   .join ';'

            @fields['RRULE'] = rrule

        else # Punctual event.
            valueS = startDate.format VEvent.icalDTUTCFormat
            valueE = endDate.format VEvent.icalDTUTCFormat

        @fields[fieldS] = valueS
        @fields[fieldE] = valueE


module.exports.VTimezone = class VTimezone extends VComponent
    name: 'VTIMEZONE'

    # constructor: (timezone) ->
    constructor: (startDate, timezone) ->
        super
        # During parsing, VTimezone are initialized without any property,
        # so we skip the processing below
        if not startDate
            return @
            
        @fields =
            TZID: timezone
            TZURL: "http://tzurl.org/zoneinfo/#{timezone}.ics"


        # zone = moment.tz.zone(timezone)
        # @add new VStandard 
        # startShift and endShift are equal because, actually, only alarm has timezone
        diff = moment.tz(startDate, timezone).format 'ZZ'
        vstandard = new VStandard startDate, diff, diff
        @add vstandard
        vdaylight = new VDaylight startDate, diff, diff
        @add vdaylight


module.exports.VJournal = class VJournal extends VComponent
    name: 'VJOURNAL'


module.exports.VFreeBusy = class VFreeBusy extends VComponent
    name: 'VFREEBUSY'


module.exports.VStandard = class VStandard extends VComponent
    name: 'STANDARD'

    constructor: (startDate, startShift, endShift) ->
        super
        # During parsing, VStandard are initialized without any property,
        # so we skip the processing below
        if not startDate
            return @
            
        @fields =
            DTSTART: moment(startDate).format VStandard.icalDTFormat
            TZOFFSETFROM: startShift
            TZOFFSETTO: endShift


module.exports.VDaylight = class VDaylight extends VComponent
    name: 'DAYLIGHT'

    constructor: (startDate, startShift, endShift) ->
        super
        # During parsing, VDaylight are initialized without any property,
        # so we skip the processing below
        if not startDate
            return @
            
        @fields =
            DTSTART: moment(startDate).format VDaylight.icalDTFormat
            TZOFFSETFROM: startShift
            TZOFFSETTO: endShift


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
                    sendError "Cannot import more than one calendar"
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
