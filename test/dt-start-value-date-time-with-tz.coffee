# Tests for the fix of bug https://forum.cozy.io/t/calendar-quelques-retours/875/25
should = require 'should'
moment = require 'moment-timezone'

{ICalParser, decorateEvent} = require '../src/index'

# mock classes
Event = class Event
    @dateFormat = 'YYYY-MM-DD'
    @ambiguousDTFormat = 'YYYY-MM-DD[T]HH:mm:00.000'
    @utcDTFormat = 'YYYY-MM-DD[T]HH:mm:00.000[Z]'

describe "VALUE=DATE-TIME in DTSTART with a TZ indicator", ->

    icsEvent = """
    BEGIN:VCALENDAR
    PRODID:-//Microsoft Corporation//Outlook 12.0 MIMEDIR//EN
    VERSION:2.0
    CALSCALE:GREGORIAN
    BEGIN:VEVENT
    UID:AF 32220150807T19100020150807T19100020150723T105024
    DTSTAMP:20150723T105024
    DTSTART;VALUE=DATE-TIME;TZID=Europe/Paris:20150807T191000
    DTEND;VALUE=DATE-TIME;TZID=Europe/Paris:20150808T030000
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
        moment.tz(event.startDate, 'Europe/Paris').toISOString().should.equal  "2015-08-07T17:10:00.000Z"
        moment.tz(event.endDate, 'Europe/Paris').toISOString().should.equal  "2015-08-08T01:00:00.000Z"
