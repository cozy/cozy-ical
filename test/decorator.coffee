path = require 'path'
should = require 'should'
moment = require 'moment-timezone'
{RRule} = require 'rrule'

{ICalParser, VCalendar, VAlarm, VTodo, VEvent} = require '../src/index'
{decorateAlarm, decorateEvent} = require '../src/index'

# mock classes
Alarm = class Alarm
    getAttendeesEmail: -> return ['test@cozycloud.cc']
Event = class Event
    @dateFormat = 'YYYY-MM-DD'
    @ambiguousDTFormat = 'YYYY-MM-DD[T]HH:mm:00.000'
    @utcDTFormat = 'YYYY-MM-DD[T]HH:mm:00.000[Z]'

describe "Cozy models decorator", ->

    globalSource = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Cozy Cloud//NONSGML Cozy Agenda//EN
        BEGIN:VEVENT
        UID:aeba6310b07a22a72423b2b11f320692
        DTSTAMP:20141107T153700Z
        DTSTART;TZID=Europe/Paris:20141106T120000
        DTEND;TZID=Europe/Paris:20141106T130000
        ATTENDEE;PARTSTAT=NEEDS-ACTION:mailto:test@cozycloud.cc
        DESCRIPTION:Crawling a hidden dungeon
        LOCATION:Hidden dungeon
        RRULE:FREQ=WEEKLY;INTERVAL=1;UNTIL=20150101T000000Z;BYDAY=TH
        SUMMARY:Recurring event
        END:VEVENT
        BEGIN:VTODO
        UID:aeba6310b07a22a72423b2b11f320693
        SUMMARY:Something to remind
        DTSTART:20141108T150000Z
        DTSTAMP:20141108T150000Z
        BEGIN:VALARM
        ACTION:EMAIL
        ATTENDEE:mailto:test@cozycloud.cc
        TRIGGER:PT0M
        DESCRIPTION:Something to remind
        END:VALARM
        END:VTODO
        END:VCALENDAR
    """

    describe "Event", ->
        it "decorating shouldn't trigger an error", ->
            decorateEvent.bind(null, Event).should.not.throw()

        it "::extractEvents should retrieve all the events from the source", (done) ->
            new ICalParser().parseString globalSource, (err, comp) =>
                should.not.exist err
                @events = Event.extractEvents comp
                should.exist @events
                @events.length.should.equal 1
                done()

        it "::fromIcal should generate a proper Cozy Event", ->
            # events comes from extractEvents, that uses fromIcal under the hood
            event = @events[0]
            should.exist event
            event.should.have.property 'id', 'aeba6310b07a22a72423b2b11f320692'
            event.should.have.property 'description', 'Recurring event'
            event.should.have.property 'start', '2014-11-06T12:00:00.000'
            event.should.have.property 'end', '2014-11-06T13:00:00.000'
            event.should.have.property 'place', 'Hidden dungeon'
            event.should.have.property 'details', 'Crawling a hidden dungeon'
            event.should.have.property 'rrule', 'FREQ=WEEKLY;INTERVAL=1;UNTIL=20150101T000000Z;BYDAY=TH'
            event.should.have.property 'alarms', []
            event.should.have.property 'timezone', 'Europe/Paris'
            event.should.have.property 'tags', ['my calendar']
            event.should.have.property 'lastModification', '2014-11-07T15:37:00.000Z'
            event.should.have.property 'attendees'
            event.attendees.length.should.equal 1
            event.attendees[0].should.have.property 'email', 'test@cozycloud.cc'
            event.attendees[0].should.have.property 'status', 'INVITATION-NOT-SENT'

        it "::toIcal should generate a proper vEvent based on Cozy Event", ->
            event = @events[0]
            should.exist event
            vEvent = event.toIcal()
            vEvent.toString().should.equal """
                BEGIN:VEVENT
                UID:aeba6310b07a22a72423b2b11f320692
                DTSTAMP:20141107T153700Z
                DTSTART;TZID=Europe/Paris:20141106T120000
                DTEND;TZID=Europe/Paris:20141106T130000
                ATTENDEE;PARTSTAT=NEEDS-ACTION;CN=test@cozycloud.cc:mailto:test@cozycloud.cc
                DESCRIPTION:Crawling a hidden dungeon
                LAST-MODIFIED:20141107T153700Z
                LOCATION:Hidden dungeon
                RRULE:FREQ=WEEKLY;INTERVAL=1;UNTIL=20150101T000000Z;BYDAY=TH
                SUMMARY:Recurring event
                END:VEVENT
                """.replace /\n/g, '\r\n'

        describe "Specific cases", ->
            it 'should generate identical ical as source', ->
                new ICalParser().parseString globalSource, (err, cal) ->
                    should.not.exist err
                    newCal = cal.toString().replace(new RegExp("\r", 'g'), "").split("\n")
                    sourceCal = globalSource.split("\n")
                    newCal.should.equal sourceCal

            it "should generate a propery Cozy Event for event with duration", ->
                source = """
                BEGIN:VCALENDAR
                VERSION:2.0
                PRODID:-//dmfs.org//mimedir.icalendar//EN
                BEGIN:VEVENT
                DTSTART;TZID=Europe/Paris:20141111T140000
                SUMMARY:Recurring
                RRULE:FREQ=WEEKLY;UNTIL=20141231T130000Z;WKST=MO;BYDAY=TU
                TRANSP:OPAQUE
                STATUS:CONFIRMED
                DURATION:PT1H
                LAST-MODIFIED:20141110T111600Z
                DTSTAMP:20141110T111600Z
                CREATED:20141110T111600Z
                UID:b4fc5c25-17d7-4849-b06a-af936cc08da8
                BEGIN:VALARM
                TRIGGER;VALUE=DURATION:-PT10M
                ACTION:DISPLAY
                DESCRIPTION:Default Event Notification
                X-WR-ALARMUID:d7c56cf9-52b0-4c89-8ba7-292e13cefcaa
                END:VALARM
                END:VEVENT
                END:VCALENDAR"""
                new ICalParser().parseString source, (err, comp) ->
                    should.not.exist err
                    should.exist comp
                    events = Event.extractEvents comp
                    events.length.should.equal 1
                    event = events[0]
                    event.should.have.property 'start', '2014-11-11T14:00:00.000'
                    event.should.have.property 'end', '2014-11-11T15:00:00.000'

            it "should generate a propery Cozy Event for event with attendees", ->
                source = """
                BEGIN:VCALENDAR
                VERSION:2.0
                PRODID:-//dmfs.org//mimedir.icalendar//EN
                BEGIN:VEVENT
                DTSTART;TZID=Europe/Paris:20141111T140000
                DESCRIPTION:Party
                SUMMARY:Attendees
                TRANSP:OPAQUE
                STATUS:CONFIRMED
                ATTENDEE;PARTSTAT=ACCEPTED;RSVP=TRUE;ROLE=REQ-PARTICIPANT:mailto:me@192.168.1
                 .67
                ATTENDEE;PARTSTAT=NEEDS-ACTION;RSVP=TRUE;ROLE=REQ-PARTICIPANT:mailto:test@cozy.io
                DTEND;TZID=Europe/Paris:20141111T200000
                LAST-MODIFIED:20141110T115555Z
                DTSTAMP:20141110T115555Z
                ORGANIZER:mailto:me@192.168.1.67
                CREATED:20141110T115555Z
                UID:240673b0-6dc0-4ced-9cec-d0e69e1d7cb5
                BEGIN:VALARM
                TRIGGER;VALUE=DURATION:-PT10M
                ACTION:DISPLAY
                DESCRIPTION:Default Event Notification
                X-WR-ALARMUID:5cf3c1d2-17ec-4f70-9309-3180472042d6
                END:VALARM
                END:VEVENT
                END:VCALENDAR"""
                new ICalParser().parseString source, (err, comp) ->
                    should.not.exist err
                    should.exist comp
                    events = Event.extractEvents comp
                    events.length.should.equal 1
                    event = events[0]
                    event.should.have.property 'attendees'
                    should.exist event.attendees
                    event.attendees.length.should.equal 2
                    attendee = event.attendees[1]
                    attendee.should.have.property 'id', 2
                    attendee.should.have.property 'email', 'test@cozy.io'
                    attendee.should.have.property 'contactid', null
                    attendee.should.have.property 'status', 'INVITATION-NOT-SENT'
