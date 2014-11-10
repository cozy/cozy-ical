path = require 'path'
should = require 'should'
moment = require 'moment-timezone'
{RRule} = require 'rrule'

{ICalParser, VCalendar, VAlarm, VTodo, VEvent} = require '../src/index'
{decorateAlarm, decorateEvent} = require '../src/index'

# mock classes
Alarm = class Alarm
Event = class Event
    @dateFormat = 'YYYY-MM-DD'
    @ambiguousDTFormat = 'YYYY-MM-DD[T]HH:mm:00'
    @utcDTFormat = 'YYYY-MM-DD[T]HH:mm:00.000Z'

describe "Cozy models decorator", ->

    source = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Cozy Cloud//NONSGML Cozy Agenda//EN
        BEGIN:VEVENT
        UID:aeba6310b07a22a72423b2b11f320692
        DTSTAMP:20141107T153700Z
        DTSTART;TZID=Europe/Paris:20141106T120000
        DTEND;TZID=Europe/Paris:20141106T130000
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
        ACTION:DISPLAY
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
            new ICalParser().parseString source, (err, comp) =>
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
            event.should.have.property 'start', '2014-11-06T12:00:00'
            event.should.have.property 'end', '2014-11-06T13:00:00'
            event.should.have.property 'place', 'Hidden dungeon'
            event.should.have.property 'details', 'Crawling a hidden dungeon'
            event.should.have.property 'rrule', 'FREQ=WEEKLY;INTERVAL=1;UNTIL=20150101T000000Z;BYDAY=TH'
            event.should.have.property 'alarms', []
            event.should.have.property 'timezone', 'Europe/Paris'
            event.should.have.property 'tags', ['my calendar']

        it "::toIcal should generate a proper vEvent based on Cozy Event", ->
            event = @events[0]
            should.exist event
            vEvent = event.toIcal()
            now = moment.tz(moment(), 'UTC').format VEvent.icalDTUTCFormat
            vEvent.toString().should.equal """
                BEGIN:VEVENT
                UID:aeba6310b07a22a72423b2b11f320692
                DTSTAMP:#{now}
                DTSTART;TZID=Europe/Paris:20141106T120000
                DTEND;TZID=Europe/Paris:20141106T130000
                DESCRIPTION:Crawling a hidden dungeon
                LOCATION:Hidden dungeon
                RRULE:FREQ=WEEKLY;INTERVAL=1;UNTIL=20150101T000000Z;BYDAY=TH
                SUMMARY:Recurring event
                END:VEVENT
                """.replace /\n/g, '\r\n'

    describe "Alarm", ->
        it "decorating shouldn't trigger an error", ->
            decorateAlarm.bind(null, Alarm).should.not.throw()

        it "::extractAlarms should retrieve all the alarms from the source", (done) ->
            new ICalParser().parseString source, (err, comp) =>
                should.not.exist err
                @alarms = Alarm.extractAlarms comp
                should.exist @alarms
                @alarms.length.should.equal 1
                done()

        it "::fromIcal should generate a proper Cozy Alarm", ->
            # alarms comes from extractEvents, that uses fromIcal under the hood
            alarm = @alarms[0]
            should.exist alarm
            alarm.should.have.property 'id', 'aeba6310b07a22a72423b2b11f320693'
            alarm.should.have.property 'description', 'Something to remind'
            alarm.should.have.property 'trigg', '2014-11-08T15:00:00.000Z'
            alarm.should.have.property 'action', 'DISPLAY'
            alarm.should.have.property 'tags', ['my calendar']

        it "::toIcal should generate a proper vEvent based on Cozy Event", ->
            alarm = @alarms[0]
            should.exist alarm
            vTodo = alarm.toIcal()
            now = moment.tz(moment(), 'UTC').format VTodo.icalDTUTCFormat
            vTodo.toString().should.equal """
                BEGIN:VTODO
                UID:aeba6310b07a22a72423b2b11f320693
                DTSTAMP:#{now}
                DTSTART:20141108T150000Z
                SUMMARY:Something to remind
                BEGIN:VALARM
                ACTION:DISPLAY
                TRIGGER:PT0M
                DESCRIPTION:Something to remind
                END:VALARM
                END:VTODO
                """.replace /\n/g, '\r\n'
