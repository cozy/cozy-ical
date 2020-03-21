# Tests for the fix of bug cozy/cozy-ical#59
should = require 'should'
moment = require 'moment-timezone'

{ICalParser, VCalendar, VEvent} = require '../src/index'

describe "Parsing and serializing our own input", ->
    parseAndSerialize = (input, done) ->
        parser = new ICalParser()
        parser.parseString input, (err, parsed) =>
            should.not.exist err
            should.exist parsed
            calendar = new VCalendar parsed.model
            parsed.subComponents.forEach (event) ->
                calendar.add(new VEvent event.model )
            done err, calendar.toString().replace /\r/g, ''

    it "does not change a punctual event without timezone", (done) ->
        icsEvent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Organization//NONSGML Title//EN
        BEGIN:VEVENT
        UID:uid
        DTSTAMP:20200202T000000Z
        DTSTART:20200202T000000Z
        DTEND:20200202T010000Z
        END:VEVENT
        END:VCALENDAR
        """
        parseAndSerialize icsEvent, (err, serialized) ->
            serialized.should.equal icsEvent
            done err
