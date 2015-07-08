# Tests for the fix of bug #32.
should = require 'should'

{ICalParser} = require '../src/index'

describe "Import ICS with dtstart and dtend with different date format", ->


    describe "dstart doesn't have a timezone, dtend has one", ->

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
        DTSTART:20130307T110000Z
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

    describe "dtstart is UTC, dtend is local time", ->

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
        DTSTART:20130307T110000Z
        DTEND:20130307T160000
        TRANSP:OPAQUE
        SEQUENCE:0
        END:VEVENT
        END:VCALENDAR
        """


        it "shouldn't return an error", (done) ->
            parser = new ICalParser()

            options = defaultTimezone: "Europe/Moscow"
            parser.parseString icsEvent, options, (err, result) =>
                should.not.exist err
                @result = result
                should.exist @result
                @result.should.have.property 'subComponents'
                @result.subComponents.length.should.equal 1
                @result.subComponents[0].model
                done()

        it "and event sould be well formed", ->
            {endDate} = @result.subComponents[0].model
            endDate.toISOString().should.equal '2013-03-07T12:00:00.000Z'


