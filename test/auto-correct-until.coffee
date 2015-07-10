# Tests for the fix of bug cozy/cozy-calendar#305.
should = require 'should'
moment = require 'moment-timezone'

{ICalParser} = require '../src/index'

describe "Import ICS with UNTIL property without 'Z' at the end", ->

    icsEvent = """
    BEGIN:VCALENDAR
    PRODID:-//Microsoft Corporation//Outlook 12.0 MIMEDIR//EN
    VERSION:2.0
    CALSCALE:GREGORIAN
    BEGIN:VEVENT
    CREATED:20150601T044431Z
    LAST-MODIFIED:20150601T044431Z
    DTSTAMP:20150601T044431Z
    UID:123-456
    SUMMARY:something random
    RRULE:FREQ=WEEKLY;UNTIL=20141204T110000
    DTSTART;TZID=Europe/Paris:20130307T110000
    DTEND;TZID=Europe/Paris:20130307T120000
    TRANSP:OPAQUE
    SEQUENCE:0
    END:VEVENT
    END:VCALENDAR
    """


    it "shouldn't return an error", (done) ->
        parser = new ICalParser()

        parser.parseString icsEvent, (err, result) =>
            should.not.exist err
            @result = result
            should.exist @result
            @result.should.have.property 'subComponents'
            @result.subComponents.length.should.equal 1
            done()

    it "and the event should be well formed", ->
        event = @result.subComponents[0].model
        untilField = event.rrule.until
        moment.tz(untilField, 'Europe/Paris').toISOString().should.equal  "2014-12-04T11:00:00.000Z"

